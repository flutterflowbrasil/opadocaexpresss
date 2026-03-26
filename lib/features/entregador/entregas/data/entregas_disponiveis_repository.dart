import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/pedido_disponivel_model.dart';

final entregasDisponiveisRepositoryProvider = Provider<EntregasDisponiveisRepository>((ref) {
  return EntregasDisponiveisRepository(Supabase.instance.client);
});

class EntregasDisponiveisRepository {
  final SupabaseClient _client;

  EntregasDisponiveisRepository(this._client);

  Future<List<PedidoDisponivelModel>> buscarPedidosDisponiveis() async {
    final res = await _client
        .from('pedidos')
        .select('''
          id,
          numero_pedido,
          total,
          taxa_entrega,
          endereco_entrega_snapshot,
          created_at,
          estabelecimentos (nome_fantasia, endereco),
          clientes (nome)
        ''')
        .eq('status', 'pronto')
        .isFilter('entregador_id', null)
        .order('created_at', ascending: true);

    return (res as List).map((e) => PedidoDisponivelModel.fromMap(e)).toList();
  }

  Future<void> aceitarEntrega(String pedidoId, String entregadorId) async {
    await _client.from('pedidos').update({
      'status': 'em_entrega',
      'entregador_id': entregadorId,
    }).eq('id', pedidoId).eq('status', 'pronto');
  }
}
