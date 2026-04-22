import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
          await _repository.criarCobrancaAsaas(pedidoId: pedidoId);

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
      final enderecoId = endereco.id ?? '';
      final subtotal = carrinho.valorTotalProdutos;
      final taxaEntrega = estabelecimento.taxaEntregaValor;
      const taxaServicoPct = 0.05; // 5% — conforme plataforma_configuracoes
      final taxaServicoApp =
          double.parse((subtotal * taxaServicoPct).toStringAsFixed(2));
      final desconto = carrinho.desconto;
      // Total = subtotal + taxas - desconto cupom (nunca negativo)
      final total = (subtotal + taxaEntrega + taxaServicoApp - desconto)
          .clamp(0.0, double.infinity);

      // Cupom (se aplicado)
      final cupom = carrinho.cupomAplicado;

      // 1. INSERT pedido
      final pedidoId = await _repository.inserirPedido(
        estabelecimentoId: estabelecimento.id,
        clienteId: clienteId,
        itens: carrinho.itens,
        subtotalProdutos: subtotal,
        taxaEntrega: taxaEntrega,
        taxaServicoApp: taxaServicoApp,
        total: total,
        pagamentoMetodo: metodoPagamento,
        enderecoEntregaId: enderecoId,
        enderecoSnapshot: endereco.toJson(),
        cupomId: cupom?.id,
        descontoCupom: desconto > 0 ? desconto : null,
      );

      // 2. Criar cobrança no Asaas via Edge Function
      final cobranca = await _repository.criarCobrancaAsaas(
        pedidoId: pedidoId,
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
    final d = cpf.replaceAll(RegExp(r'\D'), '');
    if (d.length != 11 || RegExp(r'^(\d)\1{10}$').hasMatch(d)) return false;
    for (final check in [9, 10]) {
      int sum = 0;
      for (int i = 0; i < check; i++) {
        sum += int.parse(d[i]) * (check + 1 - i);
      }
      int rem = (sum * 10) % 11;
      if (rem >= 10) rem = 0;
      if (rem != int.parse(d[check])) return false;
    }
    return true;
  }

  // ── Validação CNPJ mod-11 ─────────────────────────────────────────────────
  static bool validarCnpj(String cnpj) {
    final d = cnpj.replaceAll(RegExp(r'\D'), '');
    if (d.length != 14 || RegExp(r'^(\d)\1{13}$').hasMatch(d)) return false;

    const pesos1 = [5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];
    const pesos2 = [6, 5, 4, 3, 2, 9, 8, 7, 6, 5, 4, 3, 2];

    for (final par in [(pesos1, 12), (pesos2, 13)]) {
      final pesos = par.$1;
      final pos = par.$2;
      int sum = 0;
      for (int i = 0; i < pesos.length; i++) {
        sum += int.parse(d[i]) * pesos[i];
      }
      int rem = sum % 11;
      final expected = rem < 2 ? 0 : 11 - rem;
      if (expected != int.parse(d[pos])) return false;
    }
    return true;
  }

  /// Valida CPF (11 dígitos) ou CNPJ (14 dígitos) automaticamente.
  static bool validarCpfOuCnpj(String value) {
    final d = value.replaceAll(RegExp(r'\D'), '');
    if (d.length == 11) return validarCpf(d);
    if (d.length == 14) return validarCnpj(d);
    return false;
  }
}

final pagamentoControllerProvider = StateNotifierProvider.autoDispose<
    PagamentoController, PagamentoState>((ref) {
  final repo = ref.watch(pagamentoRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return PagamentoController(repo, supabase);
});
