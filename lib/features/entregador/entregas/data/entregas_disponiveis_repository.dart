import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../models/pedido_disponivel_model.dart';

final entregasDisponiveisRepositoryProvider =
    Provider<EntregasDisponiveisRepository>((ref) {
  return EntregasDisponiveisRepository(Supabase.instance.client);
});

class EntregasDisponiveisRepository {
  EntregasDisponiveisRepository(SupabaseClient _);

  Future<List<PedidoDisponivelModel>> buscarPedidosDisponiveis() async {
    // O despacho automatico agora oferta um pedido para um entregador por vez
    // via despacho_pedidos. Esta tela antiga nao deve listar pedidos prontos.
    return const [];
  }

  Future<void> aceitarEntrega(String pedidoId, String entregadorId) async {
    throw UnsupportedError(
      'Use o fluxo de despacho individual para aceitar entregas.',
    );
  }
}
