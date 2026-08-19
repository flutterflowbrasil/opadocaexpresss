import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/services/entregador/entregador_gps_service.dart';

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  return DashboardRepository(Supabase.instance.client);
});

class DespachoRespostaException implements Exception {
  final String codigo;
  final String mensagem;

  const DespachoRespostaException(this.codigo, this.mensagem);

  @override
  String toString() => mensagem;
}

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>> fetchDriverProfile() async {
    final data = await _supabase.from('entregadores').select('''
      id,
      tipo_veiculo,
      status_online,
      status_cadastro,
      raio_atuacao_km,
      avaliacao_media,
      total_avaliacoes,
      total_entregas,
      foto_perfil_url,
      status_despacho,
      pedido_atual_id,
      usuarios!entregadores_usuario_id_fkey(nome_completo_fantasia),
      entregador_saldos(saldo_disponivel, saldo_bloqueado, total_ganho),
      entregador_kyc(status)
    ''').single();

    return data;
  }

  /// Valida se o entregador pode ficar online.
  Future<String?> validateCanGoOnline(Map<String, dynamic> profile) async {
    final statusCadastro = profile['status_cadastro'] as String? ?? '';
    if (statusCadastro != 'aprovado' && statusCadastro != 'ativo') {
      return 'Seu cadastro ainda não foi aprovado. Aguarde a análise.';
    }

    Map<String, dynamic>? kycMap;
    final kyc = profile['entregador_kyc'];
    if (kyc is Map<String, dynamic>) {
      kycMap = kyc;
    } else if (kyc is List && kyc.isNotEmpty && kyc.first is Map) {
      kycMap = Map<String, dynamic>.from(kyc.first as Map);
    }
    if (kycMap != null) {
      final kycStatus = kycMap['status'] as String? ?? '';
      if (kycStatus == 'reprovado') {
        return 'Verificação de identidade reprovada. Entre em contato com o suporte.';
      }
      if (kycStatus.isNotEmpty &&
          kycStatus != 'aprovado' &&
          kycStatus != 'approved') {
        return 'Complete a verificação de identidade antes de ficar online.';
      }
    }

    if (profile['status_despacho'] == 'em_pedido') {
      return 'Finalize a entrega em andamento antes de alterar o status.';
    }

    return null;
  }

  Future<Map<String, dynamic>?> fetchDespachoById(String despachoId) async {
    try {
      return await _supabase
          .from('despacho_pedidos')
          .select('id, pedido_id, distancia_km, expira_em, status')
          .eq('id', despachoId)
          .maybeSingle();
    } catch (e) {
      debugPrint('[DashboardRepository] fetchDespachoById error: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> fetchEarnings() async {
    final hoje = DateTime.now();
    final inicioHoje = DateTime(hoje.year, hoje.month, hoje.day);
    final inicioSemana = inicioHoje.subtract(Duration(days: hoje.weekday - 1));

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

  Future<Map<String, dynamic>?> fetchPedidoTaxaEntrega(String pedidoId) async {
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

  Future<Map<String, dynamic>?> fetchPendingDespacho(String entregadorId) async {
    try {
      final data = await _supabase
          .from('despacho_pedidos')
          .select('id, pedido_id, distancia_km, expira_em')
          .eq('entregador_id', entregadorId)
          .eq('status', 'aguardando')
          .gt('expira_em', DateTime.now().toUtc().toIso8601String())
          .order('ofertado_em', ascending: false)
          .limit(1)
          .maybeSingle();
      return data;
    } catch (e) {
      debugPrint('[DashboardRepository] fetchPendingDespacho error: $e');
      return null;
    }
  }

  Future<void> updateOnlineStatus(bool isOnline) async {
    await _supabase
        .from('entregadores')
        .update({'status_online': isOnline})
        .eq('usuario_id', _supabase.auth.currentUser!.id);
  }

  Future<void> aceitarDespacho(String despachoId) async {
    await _responderDespacho(despachoId, 'aceitar');
  }

  Future<void> rejeitarDespacho(String despachoId, {String? motivo}) async {
    await _responderDespacho(
      despachoId,
      'recusar',
      motivo: motivo ?? 'Recusado pelo entregador',
    );
  }

  Future<void> _responderDespacho(
    String despachoId,
    String acao, {
    String? motivo,
  }) async {
    final response = await _supabase.rpc('responder_despacho', params: {
      'p_despacho_id': despachoId,
      'p_acao': acao,
      'p_motivo': motivo,
    });

    final data = Map<String, dynamic>.from(response as Map);
    if (data['ok'] == true) return;

    throw DespachoRespostaException(
      data['codigo'] as String? ?? 'erro_responder_despacho',
      data['mensagem'] as String? ?? 'Erro ao responder oferta.',
    );
  }

  Future<void> confirmarEntrega(String pedidoId, {required String codigo}) async {
    final response = await _supabase.rpc('fn_confirmar_entrega', params: {
      'p_pedido_id': pedidoId,
      'p_codigo': codigo,
    });
    final data = Map<String, dynamic>.from(response as Map);
    if (data['ok'] != true) {
      throw DespachoRespostaException(
        'entrega_recusada',
        data['erro'] as String? ?? 'Nao foi possivel confirmar a entrega.',
      );
    }
  }

  Future<void> updateLocation(String entregadorId) async {
    final ok = await EntregadorGpsService.instance.ensurePermission();
    if (!ok) {
      throw Exception('Permissão de localização negada.');
    }
    final pos = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
      ),
    );

    await _supabase.from('entregador_localizacao_atual').upsert({
      'entregador_id': entregadorId,
      'latitude': pos.latitude,
      'longitude': pos.longitude,
      'updated_at': DateTime.now().toUtc().toIso8601String(),
    }, onConflict: 'entregador_id');

    await _supabase.from('entregadores').update({
      'latitude': pos.latitude,
      'longitude': pos.longitude,
    }).eq('id', entregadorId);
  }
}
