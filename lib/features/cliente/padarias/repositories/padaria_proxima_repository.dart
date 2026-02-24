import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';

class PadariaProximaRepository {
  final SupabaseClient _client;
  PadariaProximaRepository(this._client);

  /// Busca estabelecimentos próximos à [lat]/[lng] num raio de [raioKm] km.
  Future<List<PadariaModel>> buscarProximas({
    required double lat,
    required double lng,
    double raioKm = 20,
    int limite = 10,
  }) async {
    try {
      final response = await _client.rpc(
        'buscar_padarias_proximas',
        params: {
          'lat': lat,
          'lng': lng,
          'raio_km': raioKm,
          'limite': limite,
        },
      );
      return (response as List)
          .map((j) => PadariaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }

  /// Fallback: retorna os mais bem avaliados (sem localização).
  Future<List<PadariaModel>> buscarMelhoresAvaliadas({int limite = 10}) async {
    try {
      final response = await _client.rpc(
        'buscar_melhores_avaliadas',
        params: {'limite': limite},
      );
      return (response as List)
          .map((j) => PadariaModel.fromJson(j as Map<String, dynamic>))
          .toList();
    } catch (_) {
      return [];
    }
  }
}

final padariaProximaRepositoryProvider = Provider<PadariaProximaRepository>(
  (ref) => PadariaProximaRepository(Supabase.instance.client),
);
