import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/busca/models/resultado_busca_model.dart';

class BuscaRepository {
  final SupabaseClient _client;

  BuscaRepository(this._client);

  /// Chama a função RPC buscar_estabelecimentos no Supabase.
  Future<List<ResultadoBuscaModel>> buscar(String termo) async {
    if (termo.trim().isEmpty) return [];
    try {
      final response = await _client.rpc(
        'buscar_estabelecimentos',
        params: {'termo': termo.trim()},
      );

      return (response as List)
          .map((json) =>
              ResultadoBuscaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final buscaRepositoryProvider = Provider<BuscaRepository>((ref) {
  return BuscaRepository(Supabase.instance.client);
});

/// Provider com família: recebe o termo como parâmetro.
final buscaProvider = FutureProvider.family<List<ResultadoBuscaModel>, String>(
    (ref, termo) async {
  if (termo.trim().isEmpty) return [];
  final repo = ref.watch(buscaRepositoryProvider);
  return repo.buscar(termo);
});
