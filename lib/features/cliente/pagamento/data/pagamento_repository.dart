import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
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

  // ── Inserir pedido na tabela pedidos ─────────────────────────────────────
  Future<String> inserirPedido({
    required String estabelecimentoId,
    required String clienteId,
    required List<ItemCarrinhoModel> itens,
    required double subtotalProdutos,
    required double taxaEntrega,
    required double taxaServicoApp,
    required double total,
    required String pagamentoMetodo,
    required String enderecoEntregaId,
    required Map<String, dynamic> enderecoSnapshot,
  }) async {
    try {
      final itensJson = itens
          .map((item) => {
                'produto_id': item.produto.id,
                'produto_nome': item.produto.nome,
                'quantidade': item.quantidade,
                'preco_unitario': item.produto.precoAtual,
                'subtotal': item.subtotal,
                if (item.observacao != null && item.observacao!.isNotEmpty)
                  'observacao': item.observacao,
              })
          .toList();

      final result = await _supabase.from('pedidos').insert({
        'estabelecimento_id': estabelecimentoId,
        'cliente_id': clienteId,
        'itens': itensJson,
        'subtotal_produtos': subtotalProdutos,
        'taxa_entrega': taxaEntrega,
        'taxa_servico_app': taxaServicoApp,
        'total': total,
        'pagamento_metodo': pagamentoMetodo,
        'pagamento_status': 'pendente',
        'status': 'pendente',
        'endereco_entrega_id': enderecoEntregaId,
        'endereco_entrega_snapshot': enderecoSnapshot,
      }).select('id').single();

      return result['id'] as String;
    } catch (e) {
      debugPrint('[PagamentoRepository] inserirPedido erro: $e');
      throw Exception('Erro ao registrar pedido. Tente novamente.');
    }
  }

  // ── Chamar Edge Function criar-cobranca-asaas ─────────────────────────────
  Future<CobrancaAsaasModel> criarCobrancaAsaas({
    required String pedidoId,
    Map<String, dynamic>? dadosCartao,
  }) async {
    try {
      final accessToken = _supabase.auth.currentSession?.accessToken;
      if (accessToken == null) {
        throw Exception('Sessão expirada. Faça login novamente.');
      }

      final url = Uri.parse(
          '${SupabaseConfig.url}/functions/v1/criar-cobranca-asaas');

      final httpResponse = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $accessToken',
        },
        body: jsonEncode({
          'pedido_id': pedidoId,
          if (dadosCartao != null) 'cartao': dadosCartao,
        }),
      );

      final data = jsonDecode(httpResponse.body) as Map<String, dynamic>;

      if (httpResponse.statusCode != 200) {
        throw Exception(data['error'] ?? 'Erro ao processar pagamento');
      }

      return CobrancaAsaasModel.fromJson(data);
    } catch (e) {
      debugPrint('[PagamentoRepository] criarCobrancaAsaas erro: $e');
      if (e is Exception) rethrow;
      throw Exception('Erro ao criar cobrança. Verifique sua conexão.');
    }
  }

  // ── Buscar PIX pendente do cliente ────────────────────────────────────────
  Future<Map<String, dynamic>?> buscarPedidoPixPendente(
      String clienteId) async {
    try {
      return await _supabase
          .from('pedidos')
          .select('id, created_at, total')
          .eq('cliente_id', clienteId)
          .eq('pagamento_metodo', 'pix')
          .eq('pagamento_status', 'pendente')
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
