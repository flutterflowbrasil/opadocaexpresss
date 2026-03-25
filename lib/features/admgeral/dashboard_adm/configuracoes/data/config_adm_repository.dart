import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/config_adm_models.dart';

class ConfigAdmRepository {
  final SupabaseClient _client;

  const ConfigAdmRepository(this._client);

  /// Lê todas as configurações da plataforma de uma vez.
  /// RLS garante que apenas admin autenticado consegue fazer SELECT.
  Future<List<ConfigItem>> buscarConfigs() async {
    try {
      final r = await _client
          .from('plataforma_configuracoes')
          .select(
            'id,secao,chave,valor,tipo,label,descricao,editavel,updated_at,updated_by',
          )
          .order('secao')
          .order('chave');
      return (r as List)
          .map((j) => ConfigItem.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[ConfigAdmRepository] buscarConfigs erro: $e');
      rethrow;
    }
  }

  /// Salva apenas as chaves modificadas.
  ///
  /// Segurança:
  /// - RLS impede que não-admins façam UPDATE.
  /// - Apenas UPDATE — nunca INSERT/DELETE de linhas de config.
  /// - `updated_by` registra o UUID do admin para auditoria.
  /// - O filtro por `chave` garante que cada update toca exatamente 1 linha.
  Future<void> salvarModificacoes({
    required Map<String, String> modificacoes,
    required String adminId,
  }) async {
    if (modificacoes.isEmpty) return;

    try {
      // Executa em paralelo: cada update é isolado por chave
      await Future.wait(
        modificacoes.entries.map(
          (e) => _client
              .from('plataforma_configuracoes')
              .update({
                'valor': e.value,
                'updated_at': DateTime.now().toUtc().toIso8601String(),
                'updated_by': adminId,
              })
              .eq('chave', e.key),
        ),
      );
    } catch (e) {
      debugPrint('[ConfigAdmRepository] salvarModificacoes erro: $e');
      rethrow;
    }
  }
}
