import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/financeiro_adm_models.dart';

class FinanceiroAdmRepository {
  final SupabaseClient _supabase;

  FinanceiroAdmRepository(this._supabase);

  /// Busca pedidos com join aninhado para nome do cliente e estabelecimento.
  /// Evita N+1 — uma única requisição com nested select.
  Future<List<PedidoFinanceiro>> buscarPedidos() async {
    try {
      final response = await _supabase.from('pedidos').select(
        'id, numero_pedido, status, pagamento_status, pagamento_metodo, '
        'subtotal_produtos, taxa_entrega, taxa_servico_app, desconto_cupom, '
        'total, split_processado, created_at, '
        'clientes(usuarios(nome_completo_fantasia)), '
        'estabelecimentos(nome_fantasia)',
      ).order('created_at', ascending: false).limit(100);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(PedidoFinanceiro.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[FinanceiroRepo] buscarPedidos erro: $e');
      throw Exception('Erro ao buscar pedidos financeiros.');
    }
  }

  /// Busca splits de pagamento processados (READ-ONLY — INSERT/UPDATE via Edge Function).
  Future<List<SplitPagamento>> buscarSplits() async {
    try {
      final response = await _supabase.from('splits_pagamento').select(
        'id, pedido_id, valor_total, estabelecimento_percentual, estabelecimento_valor, '
        'entregador_valor_total, plataforma_percentual, plataforma_valor, '
        'status, created_at, processado_em, motivo_falha',
      ).order('created_at', ascending: false).limit(50);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(SplitPagamento.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[FinanceiroRepo] buscarSplits erro: $e');
      throw Exception('Erro ao buscar splits de pagamento.');
    }
  }

  /// Busca saques PIX dos entregadores (READ-ONLY — status atualizado via webhook Asaas).
  Future<List<EntregadorSaque>> buscarSaques() async {
    try {
      final response = await _supabase.from('entregador_saques').select(
        'id, entregador_id, valor, pix_chave, pix_tipo, status, '
        'asaas_transfer_id, solicitado_em, processado_em, motivo_falha',
      ).order('solicitado_em', ascending: false).limit(50);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(EntregadorSaque.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[FinanceiroRepo] buscarSaques erro: $e');
      throw Exception('Erro ao buscar saques PIX.');
    }
  }

  /// Busca subcontas Asaas de estabelecimentos e entregadores (READ-ONLY).
  Future<List<AsaasSubconta>> buscarSubcontas() async {
    try {
      final response = await _supabase.from('asaas_subcontas').select(
        'id, entidade_tipo, entidade_id, asaas_account_id, asaas_wallet_id, '
        'status_conta, created_at',
      ).order('created_at', ascending: false);

      return (response as List)
          .cast<Map<String, dynamic>>()
          .map(AsaasSubconta.fromJson)
          .toList();
    } catch (e) {
      debugPrint('[FinanceiroRepo] buscarSubcontas erro: $e');
      throw Exception('Erro ao buscar subcontas Asaas.');
    }
  }
}
