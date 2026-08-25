import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/financeiro_models.dart';

final financeiroRepositoryProvider = Provider((ref) {
  return FinanceiroRepository(Supabase.instance.client);
});

class FinanceiroRepository {
  final SupabaseClient _supabase;

  FinanceiroRepository(this._supabase);

  // Busca dados do estabelecimento logado (ou do primeiro que vier, pro MVP/admin)
  // De acordo com as outras telas, geralmente filtramos pelo user id ou simplesmente limit 1.
  Future<EstabelecimentoFinanceiro?> buscarEstabelecimento() async {
    try {
      final uid = _supabase.auth.currentUser?.id;
      if (uid == null) return null;
      final response = await _supabase
          .from('estabelecimentos')
          .select(
              'id, nome_fantasia, faturamento_total, total_pedidos, dados_bancarios')
          .eq('usuario_id', uid)
          .maybeSingle();

      if (response != null) {
        final estab = EstabelecimentoFinanceiro.fromJson(response);
        try {
          final sub = await _supabase
              .from('v_asaas_subcontas_app')
              .select('status_conta, homologada')
              .eq('entidade_tipo', 'estabelecimento')
              .eq('entidade_id', estab.id)
              .maybeSingle();
          if (sub != null) {
            return EstabelecimentoFinanceiro(
              id: estab.id,
              nomeFantasia: estab.nomeFantasia,
              faturamentoTotal: estab.faturamentoTotal,
              totalPedidos: estab.totalPedidos,
              dadosBancarios: estab.dadosBancarios,
              asaasStatus: sub['status_conta'] as String?,
              asaasHomologada: sub['homologada'] == true,
            );
          }
        } catch (_) {}
        return estab;
      }
      return null;
    } catch (_) {
      throw Exception('Falha ao buscar dados do estabelecimento.');
    }
  }

  // Busca pedidos para a tela financeira no intervalo
  Future<List<PedidoFinanceiro>> buscarPedidosPeriodo(
      String estabelecimentoId, DateTime inicio, DateTime fim) async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select(
              'id, numero_pedido, status, total, subtotal_produtos, taxa_entrega, desconto_cupom, pagamento_metodo, pagamento_status, repasse_processado, created_at')
          .eq('estabelecimento_id', estabelecimentoId)
          .gte('created_at', inicio.toIso8601String())
          .lte('created_at', fim.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PedidoFinanceiro.fromJson(json))
          .toList();
    } catch (_) {
      throw Exception('Falha ao carregar transações.');
    }
  }

  // Busca splits do período
  Future<List<SplitFinanceiro>> buscarSplitsPeriodo(
      String estabelecimentoId, DateTime inicio, DateTime fim) async {
    try {
      // Inner join nativo com pedidos
      final response = await _supabase
          .from('splits_pagamento')
          .select(
              'id, status, estabelecimento_valor, repasse_estab_processado, asaas_transfer_ids, pedidos!inner(numero_pedido, created_at, estabelecimento_id)')
          .eq('pedidos.estabelecimento_id', estabelecimentoId)
          .gte('pedidos.created_at', inicio.toIso8601String())
          .lte('pedidos.created_at', fim.toIso8601String())
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => SplitFinanceiro.fromJson(json))
          .toList();
    } catch (_) {
      throw Exception('Falha ao carregar consolidação de divisão de valores.');
    }
  }
}
