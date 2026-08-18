import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/pedido_kanban_model.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

final pedidosKanbanRepositoryProvider =
    Provider<PedidosKanbanRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PedidosKanbanRepository(supabase);
});

class PedidosKanbanRepository {
  final SupabaseClient _supabase;

  PedidosKanbanRepository(this._supabase);

  Future<List<PedidoKanbanModel>> buscarPedidosDia(
      String estabelecimentoId) async {
    try {
      final now = DateTime.now();
      final todayStart =
          DateTime(now.year, now.month, now.day).toUtc().toIso8601String();

      final data = await _supabase
          .from('pedidos')
          .select('''
            id,
            numero_pedido,
            status,
            total,
            taxa_entrega,
            pagamento_metodo,
            created_at,
            itens,
            endereco_entrega_snapshot,
            codigo_coleta_balcao,
            clientes (
              usuarios (
                nome_completo_fantasia,
                telefone
              )
            )
          ''')
          .eq('estabelecimento_id', estabelecimentoId)
          .gte('created_at', todayStart)
          .order('created_at', ascending: true); // Mais antigos primeiro

      List<PedidoKanbanModel> parsedList = [];
      for (var json in (data as List)) {
        try {
          parsedList.add(PedidoKanbanModel.fromJson(json));
        } catch (e) {
          // Silent catch for failed order parsing, or add analytics later
        }
      }

      return parsedList;
    } catch (e) {
      throw Exception('Erro ao buscar pedidos no Supabase: $e');
    }
  }

  Future<void> atualizarStatus(String pedidoId, String novoStatus) async {
    try {
      final response = await _supabase.rpc(
        'fn_atualizar_status_pedido_estab',
        params: {
          'p_pedido_id': pedidoId,
          'p_novo_status': novoStatus,
        },
      );
      final data = Map<String, dynamic>.from(response as Map);
      if (data['ok'] != true) {
        throw Exception(data['erro'] ?? 'Falha ao atualizar o status.');
      }
    } catch (e) {
      throw Exception('Falha ao atualizar o status no banco: $e');
    }
  }

}
