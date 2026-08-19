import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/pagamento/models/cobranca_asaas_model.dart';

class PagamentoRepository {
  final SupabaseClient _supabase;

  PagamentoRepository(this._supabase);

  // ── Obter ID do cliente autenticado ──────────────────────────────────────
  Future<String?> getClienteId(String userId) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e) {
      debugPrint('[PagamentoRepository] getClienteId erro: $e');
      return null;
    }
  }

  /// Cria o pedido no servidor (preços, cupom e taxas recalculados no banco).
  Future<String> criarPedidoValidado({
    required String estabelecimentoId,
    required String enderecoEntregaId,
    required String pagamentoMetodo,
    String? cupomCodigo,
    String? observacaoGeral,
  }) async {
    try {
      final response = await _supabase.rpc('criar_pedido_validado', params: {
        'p_estabelecimento_id': estabelecimentoId,
        'p_endereco_entrega_id': enderecoEntregaId,
        'p_pagamento_metodo': pagamentoMetodo,
        'p_cupom_codigo': cupomCodigo,
        'p_observacao_geral': observacaoGeral,
      });
      final data = Map<String, dynamic>.from(response as Map);
      if (data['ok'] != true) {
        throw Exception(data['erro'] ?? 'Erro ao registrar pedido.');
      }
      return data['pedido_id'] as String;
    } catch (e) {
      debugPrint('[PagamentoRepository] criarPedidoValidado erro: $e');
      if (e is Exception) rethrow;
      throw Exception('Erro ao registrar pedido. Tente novamente.');
    }
  }

  // ── Chamar Edge Function asaas-criar-pagamento-pedido ─────────────────────
  Future<CobrancaAsaasModel> criarCobrancaAsaas({
    required String pedidoId,
    required String metodoPagamento,
    Map<String, dynamic>? dadosCartao,
  }) async {
    try {
      final resp = await _supabase.functions.invoke(
        'asaas-criar-pagamento-pedido',
        body: {
          'pedido_id': pedidoId,
          'metodo_pagamento': metodoPagamento,
          if (dadosCartao != null) 'cartao': dadosCartao,
        },
      );

      if (resp.status != 200) {
        final data = resp.data as Map<String, dynamic>?;
        throw Exception(data?['error'] ?? 'Erro ao processar pagamento');
      }

      final data = resp.data as Map<String, dynamic>;

      return CobrancaAsaasModel.fromJson(data);
    } catch (e) {
      debugPrint('[PagamentoRepository] criarCobrancaAsaas erro: $e');
      if (e is Exception) rethrow;
      throw Exception('Erro ao criar cobrança. Verifique sua conexão.');
    }
  }

  /// Pedido pendente ainda sem cobrança Asaas (carrinho já tinha sido apagado).
  Future<String?> buscarPedidoPendenteSemCobranca({
    required String clienteId,
    required String estabelecimentoId,
  }) async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select('id')
          .eq('cliente_id', clienteId)
          .eq('estabelecimento_id', estabelecimentoId)
          .eq('status', 'pendente')
          .inFilter('pagamento_status', ['pendente', 'aguardando_pagamento'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
      return response?['id'] as String?;
    } catch (e) {
      debugPrint('[PagamentoRepository] buscarPedidoPendenteSemCobranca erro: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>?> buscarPedidoPixPendente(
      String clienteId) async {
    try {
      return await _supabase
          .from('pedidos')
          .select('id, created_at, total')
          .eq('cliente_id', clienteId)
          .eq('pagamento_metodo', 'pix')
          .inFilter('pagamento_status', ['pendente', 'aguardando_pagamento'])
          .order('created_at', ascending: false)
          .limit(1)
          .maybeSingle();
    } catch (e) {
      debugPrint('[PagamentoRepository] buscarPedidoPixPendente erro: $e');
      return null;
    }
  }
}

final pagamentoRepositoryProvider = Provider<PagamentoRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PagamentoRepository(supabase);
});
