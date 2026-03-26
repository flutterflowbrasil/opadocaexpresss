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
            clientes (
              usuarios (
                nome_completo_fantasia,
                telefone
              )
            ),
            entregadores!pedidos_entregador_id_fkey (
              veiculo_modelo,
              veiculo_placa,
              usuarios (
                nome_completo_fantasia
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
      await _supabase
          .from('pedidos')
          .update({'status': novoStatus}).eq('id', pedidoId);
    } catch (e) {
      throw Exception('Falha ao atualizar o status no banco: $e');
    }
  }

  Future<void> atualizarEntregador(
      String pedidoId, String? entregadorId) async {
    try {
      await _supabase
          .from('pedidos')
          .update({'entregador_id': entregadorId}).eq('id', pedidoId);
    } catch (e) {
      throw Exception('Falha ao atualizar o entregador selecionado');
    }
  }

  /// Despacha o pedido para todos os entregadores online e livres.
  /// Chamado automaticamente quando o pedido passa para 'pronto'.
  Future<void> despacharParaEntregadoresDisponiveis(String pedidoId) async {
    try {
      final entregadores = await _supabase
          .from('entregadores')
          .select('id')
          .eq('status_online', true)
          .eq('status_despacho', 'livre')
          .limit(5);

      if ((entregadores as List).isEmpty) {
        throw Exception('Sem entregadores online/livres OU Estabelecimento sem RLS para tabela "entregadores".');
      }

      final agora = DateTime.now();
      final expiraEm = agora.add(const Duration(minutes: 2)).toIso8601String();
      final ofertadoEm = agora.toIso8601String();

      for (final ent in entregadores) {
        await _supabase.from('despacho_pedidos').insert({
          'pedido_id': pedidoId,
          'entregador_id': ent['id'] as String,
          'status': 'aguardando',
          'ofertado_em': ofertadoEm,
          'expira_em': expiraEm,
          'distancia_km': 0,
        });
      }
    } catch (e) {
      throw Exception('Falha ao despachar pedido: $e');
    }
  }
}
