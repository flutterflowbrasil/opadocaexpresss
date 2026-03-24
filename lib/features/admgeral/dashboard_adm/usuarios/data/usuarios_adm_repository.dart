import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/usuario_adm_model.dart';

class UsuariosAdmRepository {
  final SupabaseClient _supabase;

  UsuariosAdmRepository(this._supabase);

  /// Busca todos os usuários com dados extras de cada tipo em paralelo.
  /// 4 queries paralelas — sem N+1.
  Future<List<UsuarioAdmModel>> fetchUsuarios() async {
    try {
      final results = await Future.wait([
        // 1: usuarios
        _supabase
            .from('usuarios')
            .select(
              'id, nome_completo_fantasia, email, telefone, '
              'tipo_usuario, status, email_verificado, telefone_verificado, '
              'ultimo_login, created_at',
            )
            .order('created_at', ascending: false)
            .limit(200),

        // 2: dados do cliente
        _supabase
            .from('clientes')
            .select('usuario_id, total_pedidos, valor_total_gasto, pontos_fidelidade'),

        // 3: dados do entregador
        _supabase
            .from('entregadores')
            .select('usuario_id, status_cadastro, total_entregas, avaliacao_media'),

        // 4: dados do estabelecimento
        _supabase
            .from('estabelecimentos')
            .select('usuario_id, status_cadastro, nome_fantasia, total_pedidos'),
      ]);

      final usuarios = (results[0] as List).cast<Map<String, dynamic>>();
      final clientes = (results[1] as List).cast<Map<String, dynamic>>();
      final entregadores = (results[2] as List).cast<Map<String, dynamic>>();
      final estabelecimentos = (results[3] as List).cast<Map<String, dynamic>>();

      // Índices rápidos por usuario_id
      final clienteMap = {for (final c in clientes) c['usuario_id'] as String: c};
      final entregadorMap = {for (final e in entregadores) e['usuario_id'] as String: e};
      final estabMap = {for (final e in estabelecimentos) e['usuario_id'] as String: e};

      return usuarios.map((u) {
        final id = u['id'] as String;
        return UsuarioAdmModel.fromJson(
          u,
          clienteData: clienteMap[id],
          entregadorData: entregadorMap[id],
          estabelecimentoData: estabMap[id],
        );
      }).toList();
    } catch (e) {
      throw Exception('Erro ao buscar usuários: $e');
    }
  }

  /// Atualiza o status de um usuário (suspender / banir / reativar).
  /// Apenas admin pode fazer isso via RLS is_admin().
  Future<void> atualizarStatus(String id, String novoStatus) async {
    try {
      await _supabase
          .from('usuarios')
          .update({'status': novoStatus})
          .eq('id', id);
    } catch (e) {
      throw Exception('Erro ao atualizar status: $e');
    }
  }
}
