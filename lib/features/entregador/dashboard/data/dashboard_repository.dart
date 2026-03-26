import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  // ── Perfil completo (RLS filtra por auth.uid()) ──────────────────────────
  Future<Map<String, dynamic>> fetchDriverProfile() async {
    final data = await _supabase.from('entregadores').select('''
      id,
      tipo_veiculo,
      status_online,
      raio_atuacao_km,
      avaliacao_media,
      total_avaliacoes,
      total_entregas,
      foto_perfil_url,
      status_despacho,
      pedido_atual_id,
      usuarios!inner(nome_completo_fantasia),
      entregador_saldos(saldo_disponivel, saldo_bloqueado, total_ganho)
    ''').single();

    return data;
  }

  // ── Ganhos de hoje e da semana ────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEarnings() async {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = inicioHoje.subtract(Duration(days: hoje.weekday - 1));

    // RLS filtra pedidos onde entregador_id = get_entregador_id()
    final pedidosHoje = await _supabase
        .from('pedidos')
        .select('id, taxa_entrega, splits_pagamento(entregador_valor_total)')
        .eq('status', 'entregue')
        .gte('entregue_em', inicioHoje.toIso8601String());

    final pedidosSemana = await _supabase
        .from('pedidos')
        .select('id, splits_pagamento(entregador_valor_total)')
        .eq('status', 'entregue')
        .gte('entregue_em', inicioSemana.toIso8601String());

    return {
      'pedidosHoje': pedidosHoje,
      'pedidosSemana': pedidosSemana,
    };
  }

  // ── Últimas 5 entregas concluídas ────────────────────────────────────────
  Future<List<Map<String, dynamic>>> fetchRecentDeliveries() async {
    final data = await _supabase
        .from('pedidos')
        .select('''
          id,
          numero_pedido,
          entregue_em,
          taxa_entrega,
          splits_pagamento(entregador_valor_total),
          estabelecimentos!inner(razao_social, logo_url, nome_fantasia)
        ''')
        .eq('status', 'entregue')
        .order('entregue_em', ascending: false)
        .limit(5);

    return List<Map<String, dynamic>>.from(data);
  }

  // ── Pedido em andamento ───────────────────────────────────────────────────
  Future<Map<String, dynamic>?> fetchActivePedido(String pedidoId) async {
    try {
      final data = await _supabase
          .from('pedidos')
          .select('''
            id,
            numero_pedido,
            status,
            total,
            taxa_entrega,
            endereco_entrega_snapshot,
            estabelecimentos!inner(razao_social, nome_fantasia)
          ''')
          .eq('id', pedidoId)
          .single();
      return data;
    } catch (e) {
      debugPrint('[DashboardRepository] fetchActivePedido error: $e');
      return null;
    }
  }

  // ── Detalhes do pedido para despacho recebido ────────────────────────────
  Future<Map<String, dynamic>?> fetchPedidoTaxaEntrega(
      String pedidoId) async {
    try {
      final data = await _supabase
          .from('pedidos')
          .select('id, taxa_entrega')
          .eq('id', pedidoId)
          .single();
      return data;
    } catch (e) {
      debugPrint('[DashboardRepository] fetchPedidoTaxaEntrega error: $e');
      return null;
    }
  }

  // ── Toggle online/offline ────────────────────────────────────────────────
  Future<void> updateOnlineStatus(bool isOnline) async {
    // RLS restringe a linha do entregador logado
    await _supabase
        .from('entregadores')
        .update({'status_online': isOnline})
        .eq('usuario_id', _supabase.auth.currentUser!.id);
  }

  // ── Aceitar despacho ─────────────────────────────────────────────────────
  // TODO: mover para Edge Function 'responder-despacho' quando criada
  Future<void> aceitarDespacho(String despachoId) async {
    // Busca pedido_id e entregador_id antes de atualizar
    final despacho = await _supabase
        .from('despacho_pedidos')
        .select('pedido_id, entregador_id')
        .eq('id', despachoId)
        .single();

    await _supabase.from('despacho_pedidos').update({
      'status': 'aceito',
      'respondido_em': DateTime.now().toIso8601String(),
    }).eq('id', despachoId);

    // Atualiza pedido para em_entrega e vincula o entregador
    await _supabase.from('pedidos').update({
      'status': 'em_entrega',
      'entregador_id': despacho['entregador_id'],
    }).eq('id', despacho['pedido_id'] as String);
  }

  // ── Rejeitar despacho ────────────────────────────────────────────────────
  Future<void> rejeitarDespacho(String despachoId,
      {String? motivo}) async {
    await _supabase.from('despacho_pedidos').update({
      'status': 'rejeitado',
      'respondido_em': DateTime.now().toIso8601String(),
      if (motivo != null) 'motivo_rejeicao': motivo,
    }).eq('id', despachoId);
  }

  // ── Confirmar entrega ────────────────────────────────────────────────────
  // Trigger 'atualizar_stats_entregador' e 'trg_pedido_libera_entregador'
  // disparam automaticamente após este UPDATE
  Future<void> confirmarEntrega(String pedidoId) async {
    await _supabase
        .from('pedidos')
        .update({'status': 'entregue'}).eq('id', pedidoId);
  }

  // ── Atualiza localização ─────────────────────────────────────────────────
  Future<void> updateLocation(String entregadorId) async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition(
        locationSettings:
            const LocationSettings(accuracy: LocationAccuracy.high));

    await _supabase.from('entregador_localizacao_atual').upsert({
      'entregador_id': entregadorId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    }, onConflict: 'entregador_id');
  }
}
