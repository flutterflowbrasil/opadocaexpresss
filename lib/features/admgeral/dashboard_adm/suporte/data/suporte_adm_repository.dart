import 'package:flutter/foundation.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/suporte_adm_models.dart';

// ── Repository ────────────────────────────────────────────────────────────────

class SuporteAdmRepository {
  final SupabaseClient _client;

  const SuporteAdmRepository(this._client);

  /// Busca chamados de suporte com join no usuarios para nome/email.
  Future<List<SupporteChamado>> buscarChamados() async {
    try {
      final r = await _client.from('suporte_chamados').select('''
        id, usuario_id, entregador_id, pedido_id, categoria, descricao,
        status, resposta_suporte, tipo_solicitante, prioridade,
        respondido_por, respondido_em, resolvido_em, created_at, updated_at,
        usuarios!suporte_chamados_usuario_id_fkey(nome_completo_fantasia, email)
      ''').order('created_at', ascending: false).limit(100);
      return (r as List)
          .map((j) => SupporteChamado.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SuporteAdmRepository] buscarChamados erro: $e');
      rethrow;
    }
  }

  /// Busca fila de notificações FCM (pendentes e com erro).
  Future<List<NotificacaoFila>> buscarNotificacoes() async {
    try {
      final r = await _client
          .from('notificacoes_fila')
          .select(
            'id,usuario_id,evento,titulo,corpo,status,'
            'tentativas,max_tentativas,created_at,erro_codigo,erro_detalhe',
          )
          .order('created_at', ascending: false)
          .limit(50);
      return (r as List)
          .map((j) => NotificacaoFila.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SuporteAdmRepository] buscarNotificacoes erro: $e');
      rethrow;
    }
  }

  /// Busca avaliações com join em clientes→usuarios e estabelecimentos.
  Future<List<Avaliacao>> buscarAvaliacoes() async {
    try {
      final r = await _client.from('avaliacoes').select('''
        id, pedido_id, cliente_id, estabelecimento_id, entregador_id,
        nota_estabelecimento, nota_entregador,
        comentario_estabelecimento, comentario_entregador, created_at,
        clientes(usuarios(nome_completo_fantasia)),
        estabelecimentos(nome_fantasia)
      ''').order('created_at', ascending: false).limit(50);
      return (r as List)
          .map((j) => Avaliacao.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (e) {
      debugPrint('[SuporteAdmRepository] buscarAvaliacoes erro: $e');
      rethrow;
    }
  }

  /// Atualiza chamado com resposta do admin.
  Future<void> responderChamado({
    required String chamadoId,
    required String status,
    required String prioridade,
    required String resposta,
    required String adminId,
  }) async {
    try {
      final body = <String, dynamic>{
        'status': status,
        'prioridade': prioridade,
        'resposta_suporte': resposta,
        'respondido_por': adminId,
        'respondido_em': DateTime.now().toUtc().toIso8601String(),
      };
      if (status == 'resolvido') {
        body['resolvido_em'] = DateTime.now().toUtc().toIso8601String();
      }
      await _client
          .from('suporte_chamados')
          .update(body)
          .eq('id', chamadoId);
    } catch (e) {
      debugPrint('[SuporteAdmRepository] responderChamado erro: $e');
      rethrow;
    }
  }

  /// Enfileira notificação para o usuário via RPC Supabase.
  Future<void> notificarUsuario({
    required String usuarioId,
    required String chamadoId,
  }) async {
    try {
      await _client.rpc('enfileirar_notificacao', params: {
        'p_usuario_id': usuarioId,
        'p_evento': 'suporte_resposta',
        'p_entidade_tipo': 'chamado',
        'p_entidade_id': chamadoId,
        'p_variaveis': {'id': chamadoId},
      });
    } catch (e) {
      // Falha na notificação não bloqueia a resposta do chamado
      debugPrint('[SuporteAdmRepository] notificarUsuario erro (não crítico): $e');
    }
  }
}
