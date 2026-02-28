import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class DashboardRepository {
  final SupabaseClient _supabase;

  DashboardRepository(this._supabase);

  Future<Map<String, dynamic>?> getEstabelecimentoLogado() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;

    try {
      final response = await _supabase
          .from('estabelecimentos')
          .select('id, razao_social, nome_fantasia, avaliacao_media')
          .eq('usuario_id', user.id)
          .maybeSingle();

      return response;
    } catch (e) {
      return null;
    }
  }

  Future<Map<String, dynamic>> getMetricasHoje(String estabelecimentoId) async {
    try {
      final hojeInicio = DateTime.now()
          .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0)
          .toUtc()
          .toIso8601String();

      final response = await _supabase
          .from('pedidos')
          .select('total, status')
          .eq('estabelecimento_id', estabelecimentoId)
          .gte('created_at', hojeInicio);

      double vendasHoje = 0.0;
      int concluidos = 0;
      int ativos = 0;

      for (var p in response) {
        final status = p['status'] as String;
        if (status == 'entregue') {
          vendasHoje += (p['total'] as num).toDouble();
          concluidos++;
        } else if (status != 'cancelado_cliente' &&
            status != 'cancelado_estab' &&
            status != 'cancelado_sistema') {
          ativos++;
        }
      }

      double ticketMedio = concluidos > 0 ? vendasHoje / concluidos : 0.0;

      return {
        'vendasHoje': vendasHoje,
        'pedidosAtivos': ativos,
        'ticketMedio': ticketMedio,
      };
    } catch (e) {
      return {
        'vendasHoje': 0.0,
        'pedidosAtivos': 0,
        'ticketMedio': 0.0,
      };
    }
  }

  Future<List<Map<String, dynamic>>> getMaisVendidos(
      String estabelecimentoId) async {
    try {
      final response = await _supabase
          .from('produtos')
          .select('id, nome, preco, total_vendidos')
          .eq('estabelecimento_id', estabelecimentoId)
          .order('total_vendidos', ascending: false)
          .limit(5);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }

  Future<List<Map<String, dynamic>>> getPedidosRecentes(
      String estabelecimentoId) async {
    try {
      final response = await _supabase
          .from('pedidos')
          .select(
              'id, status, total, created_at, numero_pedido, clientes!inner(nome_completo_fantasia)')
          .eq('estabelecimento_id', estabelecimentoId)
          .order('created_at', ascending: false)
          .limit(10);

      return List<Map<String, dynamic>>.from(response);
    } catch (e) {
      return [];
    }
  }
}

final dashboardRepositoryProvider = Provider<DashboardRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return DashboardRepository(supabase);
});
