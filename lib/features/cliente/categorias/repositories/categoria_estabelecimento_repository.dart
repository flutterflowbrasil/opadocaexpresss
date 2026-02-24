import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';

class CategoriaEstabelecimentoRepository {
  final SupabaseClient _client;

  CategoriaEstabelecimentoRepository(this._client);

  /// Busca todas as categorias ativas ordenadas por ordem_exibicao.
  Future<List<CategoriaEstabelecimentoModel>> fetchCategorias() async {
    try {
      final response = await _client
          .from('categorias_estabelecimento')
          .select('id, nome, icone, ativa, imagem_url, slug, ordem_exibicao')
          .eq('ativa', true)
          .order('ordem_exibicao', ascending: true);

      return (response as List)
          .map((json) => CategoriaEstabelecimentoModel.fromJson(
                json as Map<String, dynamic>,
              ))
          .toList();
    } catch (e) {
      return [];
    }
  }
}

final categoriaEstabelecimentoRepositoryProvider =
    Provider<CategoriaEstabelecimentoRepository>((ref) {
  return CategoriaEstabelecimentoRepository(Supabase.instance.client);
});

final categoriasEstabelecimentoProvider =
    FutureProvider<List<CategoriaEstabelecimentoModel>>((ref) async {
  final repo = ref.watch(categoriaEstabelecimentoRepositoryProvider);
  return repo.fetchCategorias();
});
