import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/pedidos/models/pedido_cliente_model.dart';

class PedidosClienteRepository {
  final SupabaseClient _supabase;

  PedidosClienteRepository(this._supabase);

  Future<List<PedidoClienteModel>> getPedidosCliente(String clienteId) async {
    try {
      // Usando query otimizada: JOIN unico em estabelecimentos
      // Os itens ficam embutidos na coluna 'itens' (jsonb)
      final response = await _supabase
          .from('pedidos')
          .select(
              'id, numero_pedido, total, status, created_at, pagamento_metodo, itens, estabelecimentos(nome_fantasia, logo_url)')
          .eq('cliente_id', clienteId)
          .order('created_at', ascending: false);

      return (response as List)
          .map((json) => PedidoClienteModel.fromJson(json))
          .toList();
    } catch (e) {
      throw Exception('Erro ao buscar pedidos: $e');
    }
  }

  Future<String?> getClienteId(String userId) async {
    try {
      final response = await _supabase
          .from('clientes')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();

      return response?['id'] as String?;
    } catch (e) {
      return null;
    }
  }
}

final pedidosClienteRepositoryProvider =
    Provider<PedidosClienteRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return PedidosClienteRepository(supabase);
});
