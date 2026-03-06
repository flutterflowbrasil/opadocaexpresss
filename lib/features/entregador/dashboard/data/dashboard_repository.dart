import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:geolocator/geolocator.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  // ── Carrega dados do entregador ─────────────────────────────────────────
  Future<Map<String, dynamic>> fetchDriverProfile(String userId) async {
    // Busca dados do entregador e faz inner join com saldo (entregador_saldos) e avaliações.
    final data = await _supabase.from('entregadores').select('''
          id,
          tipo_veiculo,
          status_online,
          raio_atuacao_km,
          usuarios!inner(nome_completo_fantasia),
          entregador_saldos(saldo_disponivel),
          avaliacoes(nota_entregador)
        ''').eq('usuario_id', userId).single();

    return data;
  }

  // ── Carrega ganhos ──────────────────────────────────────────────────────
  Future<Map<String, dynamic>> fetchEarnings(String entregadorIdDb) async {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = inicioHoje.subtract(Duration(days: hoje.weekday - 1));

    // Ganhos hoje - faz join com pedidos para garantir filtro pelo entregador_id
    final pedidosHoje = await _supabase
        .from('splits_pagamento')
        .select('entregador_valor_total, pedidos!inner(entregador_id)')
        .eq('pedidos.entregador_id', entregadorIdDb)
        .gte('created_at', inicioHoje.toIso8601String());

    // Ganhos semana
    final pedidosSemana = await _supabase
        .from('splits_pagamento')
        .select('entregador_valor_total, pedidos!inner(entregador_id)')
        .eq('pedidos.entregador_id', entregadorIdDb)
        .gte('created_at', inicioSemana.toIso8601String());

    return {
      'pedidosHoje': pedidosHoje,
      'pedidosSemana': pedidosSemana,
    };
  }

  // ── Toggle online/offline ────────────────────────────────────────────────
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _supabase
        .from('entregadores')
        .update({'status_online': isOnline}).eq('usuario_id', userId);
  }

  // ── Atualiza Localização ─────────────────────────────────────────────────
  Future<void> updateLocation(String userId, String entregadorId) async {
    final perm = await Geolocator.checkPermission();
    if (perm == LocationPermission.denied ||
        perm == LocationPermission.deniedForever) {
      await Geolocator.requestPermission();
    }
    final pos = await Geolocator.getCurrentPosition(
        desiredAccuracy: LocationAccuracy.high);

    await _supabase.from('entregador_localizacao_atual').upsert({
      'entregador_id': entregadorId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'updated_at': DateTime.now().toIso8601String(),
    });
  }
}
