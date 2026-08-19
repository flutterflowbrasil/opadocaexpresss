import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/localizacao/endereco_model.dart';
import 'package:padoca_express/features/cliente/pagamento/data/pagamento_repository.dart';
import 'package:padoca_express/features/cliente/pagamento/models/dados_cartao_model.dart';
import 'package:padoca_express/features/cliente/pagamento/state/pagamento_state.dart';

class PagamentoController extends StateNotifier<PagamentoState> {
  final PagamentoRepository _repository;
  final SupabaseClient _supabase;
  RealtimeChannel? _realtimeChannel;

  static const int _pixExpiracaoSegundos = 300; // 5 minutos

  PagamentoController(this._repository, this._supabase)
      : super(const PagamentoState());

  @override
  void dispose() {
    _realtimeChannel?.unsubscribe();
    super.dispose();
  }

  // ── Verificar PIX pendente ao abrir a tela ────────────────────────────────
  /// Retorna true se há um PIX pendente ainda dentro do prazo de 5 min.
  /// Nesse caso, o state já fica em `aguardandoPix` com os dados da cobrança.
  Future<bool> verificarPixPendente() async {
    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) return false;

      final clienteId = await _repository.getClienteId(userId);
      if (clienteId == null) return false;

      final pedido =
          await _repository.buscarPedidoPixPendente(clienteId);
      if (pedido == null) return false;

      final createdAt = DateTime.parse(pedido['created_at'] as String);
      final expiresAt =
          createdAt.add(const Duration(seconds: _pixExpiracaoSegundos));
      if (DateTime.now().isAfter(expiresAt)) return false;

      final segundosRestantes =
          expiresAt.difference(DateTime.now()).inSeconds;
      final pedidoId = pedido['id'] as String;

      // Reobter a cobrança (Edge Function é idempotente para o mesmo pedido_id)
      final cobranca =
          await _repository.criarCobrancaAsaas(
        pedidoId: pedidoId,
        metodoPagamento: 'pix',
      );

      state = state.copyWith(
        pedidoCriadoId: pedidoId,
        cobranca: cobranca,
        status: PagamentoStatus.aguardandoPix,
        segundosRestantes: segundosRestantes,
      );

      _iniciarRealtimePix(pedidoId);
      return true;
    } catch (e) {
      debugPrint('[PagamentoController] verificarPixPendente erro: $e');
      return false;
    }
  }

  // ── Fluxo principal: criar pedido + cobrança ──────────────────────────────
  Future<void> finalizarPedido({
    required CarrinhoState carrinho,
    required EnderecoCliente endereco,
    required String metodoPagamento,
    DadosCartaoModel? dadosCartao,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      status: PagamentoStatus.submitting,
      clearError: true,
    );

    try {
      final userId = _supabase.auth.currentUser?.id;
      if (userId == null) throw Exception('Usuário não autenticado.');

      final clienteId = await _repository.getClienteId(userId);
      if (clienteId == null) {
        throw Exception('Perfil de cliente não encontrado.');
      }

      final estabelecimento = carrinho.estabelecimento!;
      final enderecoId = endereco.id;
      if (enderecoId == null || enderecoId.isEmpty) {
        throw Exception('Selecione um endereço de entrega salvo.');
      }

      String? pedidoId;
      try {
        pedidoId = await _repository.criarPedidoValidado(
          estabelecimentoId: estabelecimento.id,
          enderecoEntregaId: enderecoId,
          pagamentoMetodo: metodoPagamento,
          cupomCodigo: carrinho.cupomAplicado?.codigo,
          observacaoGeral: carrinho.observacaoGeral,
        );
      } catch (e) {
        final msg = e.toString();
        if (msg.contains('Carrinho vazio')) {
          pedidoId = await _repository.buscarPedidoPendenteSemCobranca(
            clienteId: clienteId,
            estabelecimentoId: estabelecimento.id,
          );
        }
        if (pedidoId == null) rethrow;
      }

      if (pedidoId == null) {
        throw Exception('Carrinho vazio.');
      }

      // 2. Criar cobrança no Asaas via Edge Function
      final cobranca = await _repository.criarCobrancaAsaas(
        pedidoId: pedidoId,
        metodoPagamento: metodoPagamento,
        dadosCartao: dadosCartao?.toJson(),
      );

      // 3. Atualizar estado baseado no método
      final isPix = metodoPagamento == 'pix';

      state = state.copyWith(
        isSubmitting: false,
        pedidoCriadoId: pedidoId,
        cobranca: cobranca,
        status: isPix
            ? PagamentoStatus.aguardandoPix
            : PagamentoStatus.confirmado,
        segundosRestantes: isPix ? _pixExpiracaoSegundos : null,
      );

      if (isPix) _iniciarRealtimePix(pedidoId);
    } catch (e) {
      debugPrint('[PagamentoController] finalizarPedido erro: $e');
      state = state.copyWith(
        isSubmitting: false,
        status: PagamentoStatus.erro,
        errorMessage: e is Exception
            ? e.toString().replaceFirst('Exception: ', '')
            : 'Erro ao processar pagamento. Tente novamente.',
      );
    }
  }

  // ── Realtime: escutar confirmação do pagamento ────────────────────────────
  void _iniciarRealtimePix(String pedidoId) {
    _realtimeChannel?.unsubscribe();
    _realtimeChannel = _supabase
        .channel('pix_pagamento_$pedidoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: pedidoId,
          ),
          callback: (payload) {
            final novoStatus =
                payload.newRecord['pagamento_status'] as String?;
            if (novoStatus == 'confirmado') {
              _realtimeChannel?.unsubscribe();
              state = state.copyWith(status: PagamentoStatus.confirmado);
            } else if (novoStatus == 'vencido' || novoStatus == 'falhou') {
              _realtimeChannel?.unsubscribe();
              state = state.copyWith(
                status: PagamentoStatus.expirado,
                errorMessage: 'Pagamento expirado ou falhou.',
              );
            }
          },
        )
        .subscribe();
  }

  // ── Countdown expirou ─────────────────────────────────────────────────────
  void onPixExpirado() {
    _realtimeChannel?.unsubscribe();
    state = state.copyWith(status: PagamentoStatus.expirado);
  }

  // ── Limpar erro ───────────────────────────────────────────────────────────
  void limparErro() {
    state = state.copyWith(
      clearError: true,
      status: PagamentoStatus.idle,
    );
  }

  // ── Validação CPF mod-11 (client-side) ────────────────────────────────────
  static bool validarCpf(String cpf) {
    return BrazilianDocumentValidator.isValidCpf(cpf);
  }

  // ── Validação CNPJ mod-11 ─────────────────────────────────────────────────
  static bool validarCnpj(String cnpj) {
    return BrazilianDocumentValidator.isValidCnpj(cnpj);
  }

  /// Valida CPF (11 dígitos) ou CNPJ (14 dígitos) automaticamente.
  static bool validarCpfOuCnpj(String value) {
    return BrazilianDocumentValidator.isValidCpfOrCnpj(value);
  }
}

final pagamentoControllerProvider = StateNotifierProvider.autoDispose<
    PagamentoController, PagamentoState>((ref) {
  final repo = ref.watch(pagamentoRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return PagamentoController(repo, supabase);
});
