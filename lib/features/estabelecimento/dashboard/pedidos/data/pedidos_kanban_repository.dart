import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido_kanban_model.dart';

final pedidosKanbanRepositoryProvider =
    Provider<PedidosKanbanRepository>((ref) {
  return PedidosKanbanRepository(Supabase.instance.client);
});

class PedidosKanbanRepository {
  final SupabaseClient _supabase;

  PedidosKanbanRepository(this._supabase);

  Future<List<PedidoKanbanModel>> buscarPedidosAbertos(
      String estabelecimentoId) async {
    try {
      final data = await _supabase
          .from('pedidos')
          .select('''
            id,
            numero_pedido,
            status,
            total,
            created_at,
            itens,
            clientes!inner (
              id,
              foto_perfil_url,
              usuarios!inner (
                nome_completo_fantasia
              )
            )
          ''')
          .eq('estabelecimento_id', estabelecimentoId)
          .inFilter('status',
              ['pendente', 'confirmado', 'preparando', 'pronto', 'em_entrega'])
          .order('created_at',
              ascending: true); // Mais antigos primeiro no Kanban

      return (data as List)
          .map((json) => PedidoKanbanModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos abertos: \$e');
    }
  }

  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'status': novoStatus}).eq('id', pedidoId);
    } catch (e) {
      throw Exception('Falha ao atualizar o status no banco');
    }
  }
}
