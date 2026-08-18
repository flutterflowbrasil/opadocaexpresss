import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PushNotificationRepository {
  PushNotificationRepository(this._client);

  final SupabaseClient _client;

  Future<void> upsertPushDevice({
    required String usuarioId,
    required String token,
    required String plataforma,
    String? appVersion,
    String? deviceModel,
  }) async {
    await _client.from('dispositivos_push').upsert(
      buildUpsertRow(
        usuarioId: usuarioId,
        token: token,
        plataforma: plataforma,
        appVersion: appVersion,
        deviceModel: deviceModel,
      ),
      onConflict: 'token',
    );
  }

  static Map<String, dynamic> buildUpsertRow({
    required String usuarioId,
    required String token,
    required String plataforma,
    String? appVersion,
    String? deviceModel,
    DateTime? now,
  }) {
    final stamp = (now ?? DateTime.now()).toUtc().toIso8601String();
    return {
      'usuario_id': usuarioId,
      'token': token,
      'plataforma': plataforma,
      'ativo': true,
      'invalido': false,
      'invalido_em': null,
      'motivo_invalido': null,
      if (appVersion != null) 'app_version': appVersion,
      if (deviceModel != null) 'device_model': deviceModel,
      'ultimo_uso_em': stamp,
      'updated_at': stamp,
    };
  }

  static Map<String, dynamic> buildDeactivateRow({DateTime? now}) {
    return {
      'ativo': false,
      'updated_at': (now ?? DateTime.now()).toUtc().toIso8601String(),
    };
  }

  Future<void> deactivatePushDevice(String token) async {
    await _client.from('dispositivos_push').update(buildDeactivateRow()).eq('token', token);
  }

  Future<void> deactivateAllForUser(String usuarioId) async {
    await _client.from('dispositivos_push').update(buildDeactivateRow()).eq('usuario_id', usuarioId);
  }

  Future<Map<String, dynamic>?> getUserPreferences(String usuarioId) async {
    return _client
        .from('notificacao_preferencias')
        .select()
        .eq('usuario_id', usuarioId)
        .maybeSingle();
  }
}

final pushNotificationRepositoryProvider =
    Provider<PushNotificationRepository>((ref) {
  return PushNotificationRepository(ref.watch(supabaseClientProvider));
});
