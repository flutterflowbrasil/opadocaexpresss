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

Map<String, dynamic>? embedRelacao(dynamic value) {
  if (value == null) return null;
  if (value is Map<String, dynamic>) return value;
  if (value is Map) return Map<String, dynamic>.from(value);
  if (value is List && value.isNotEmpty && value.first is Map) {
    return Map<String, dynamic>.from(value.first as Map);
  }
  return null;
}

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>> fetchDriverProfile() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) {
      throw StateError('Usuário não autenticado');
    }

    // RLS também deixa ver entregadores online de terceiros — filtrar o próprio.
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
      entregador_kyc(status)
    ''').eq('usuario_id', uid).maybeSingle();

    if (data == null) {
      throw StateError('Perfil de entregador não encontrado');
    }

    final saldos = await _saldosDeSplits(data['id'] as String);

    return {
      ...data,
      'usuarios': embedRelacao(data['usuarios']),
      'entregador_saldos': saldos,

      'entregador_kyc': embedRelacao(data['entregador_kyc']),
    };
  }

  Future<Map<String, double>> _saldosDeSplits(String entregadorId) async {
    final rows = await _supabase
        .from('splits_pagamento')
        .select(
          'entregador_valor_total, entregador_taxa_entrega_valor, repasse_entregador_processado',
        )
        .eq('entregador_id', entregadorId);
    var disponivel = 0.0;
    var bloqueado = 0.0;
    var ganho = 0.0;
    for (final raw in rows as List) {
      final r = Map<String, dynamic>.from(raw as Map);
      final v = (r['entregador_valor_total'] as num?)?.toDouble() ??
          (r['entregador_taxa_entrega_valor'] as num?)?.toDouble() ??
          0;
      ganho += v;
      if (r['repasse_entregador_processado'] == true) {
        disponivel += v;
      } else {
        bloqueado += v;
      }
    }
    return {
      'saldo_disponivel': disponivel,
      'saldo_bloqueado': bloqueado,
      'total_ganho': ganho,
    };
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

  Future<List<Map<String, dynamic>>> fetchNotificacoes() async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return [];
    try {
      final data = await _supabase
          .from('notificacoes_historico')
          .select('id, evento, titulo, corpo, status, created_at')
          .eq('usuario_id', uid)
          .order('created_at', ascending: false)
          .limit(20);
      return List<Map<String, dynamic>>.from(data);
    } catch (e) {
      debugPrint('[DashboardRepository] fetchNotificacoes error: $e');
      return [];
    }
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
        accuracy: LocationAccuracy.medium,
        timeLimit: Duration(seconds: 8),
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
