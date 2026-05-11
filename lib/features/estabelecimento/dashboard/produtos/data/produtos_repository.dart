import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import '../models/produto_model.dart';
import '../../../models/categoria_cardapio_model.dart';

final produtosRepositoryProvider = Provider<ProdutosRepository>((ref) {
  return ProdutosRepository(Supabase.instance.client);
});

class ProdutosRepository {
  final SupabaseClient _supabase;

  ProdutosRepository(this._supabase);

  static const _produtoSelect =
      '*, categorias_cardapio:categoria_cardapio_id(nome), '
      'produto_categorias_estabelecimento(categoria_id, '
      'categorias_estabelecimento:categoria_id(id, nome))';

  Future<List<ProdutoModel>> fetchProdutos(String estabelecimentoId) async {
    final response = await _supabase
        .from('produtos')
        .select(_produtoSelect)
        .eq('estabelecimento_id', estabelecimentoId)
        .order('ordem_exibicao');

    return response.map((json) => ProdutoModel.fromJson(json)).toList();
  }

  Future<List<CategoriaCardapioModel>> fetchCategorias(
      String estabelecimentoId) async {
    final response = await _supabase
        .from('categorias_cardapio')
        .select()
        .eq('estabelecimento_id', estabelecimentoId)
        .order('ordem_exibicao');

    return response
        .map((json) => CategoriaCardapioModel.fromJson(json))
        .toList();
  }

  Future<List<CategoriaEstabelecimentoModel>> fetchCategoriasPrincipais() async {
    final response = await _supabase
        .from('categorias_estabelecimento')
        .select('id, nome, icone, ativa, imagem_url, slug, ordem_exibicao')
        .eq('ativa', true)
        .order('ordem_exibicao', ascending: true);

    return response
        .map((json) => CategoriaEstabelecimentoModel.fromJson(json))
        .toList();
  }

  Future<ProdutoModel> saveProduto(ProdutoModel produto) async {
    final data = produto.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    if ((data['id'] as String?)?.isEmpty ?? false) data.remove('id');

    final response = await _supabase
        .from('produtos')
        .upsert(data)
        .select('id')
        .single();

    final produtoId = response['id'] as String;
    await _saveCategoriasPrincipais(
      produtoId,
      produto.categoriaPrincipalIds,
    );

    return _fetchProdutoById(produtoId);
  }

  Future<void> deleteProduto(String produtoId) async {
    await _supabase.from('produtos').delete().eq('id', produtoId);
  }

  Future<void> updateDisponibilidade(String produtoId, bool disponivel) async {
    await _supabase
        .from('produtos')
        .update({'disponivel': disponivel}).eq('id', produtoId);
  }

  Future<Map<String, dynamic>> ativarUltimaMordida(
    String produtoId, {
    int? descontoPct,
    String? chamada,
    int? duracaoHoras,
  }) async {
    final result = await _supabase.rpc('fn_ativar_ultima_mordida', params: {
      'p_produto_id': produtoId,
      if (descontoPct != null) 'p_desconto_pct': descontoPct,
      if (chamada != null) 'p_chamada': chamada,
      if (duracaoHoras != null) 'p_duracao_horas': duracaoHoras,
      'p_origem': 'manual',
    });
    return result as Map<String, dynamic>;
  }

  Future<void> desativarUltimaMordida(String produtoId) async {
    await _supabase.rpc('fn_desativar_ultima_mordida', params: {
      'p_produto_id': produtoId,
    });
  }

  Future<CategoriaCardapioModel> saveCategoria(
      CategoriaCardapioModel categoria) async {
    final data = categoria.toJson();
    if (categoria.id.isEmpty) data.remove('id');

    final response = await _supabase
        .from('categorias_cardapio')
        .upsert(data)
        .select()
        .single();

    return CategoriaCardapioModel.fromJson(response);
  }

  Future<void> deleteCategoria(String categoriaId) async {
    await _supabase
        .from('categorias_cardapio')
        .delete()
        .eq('id', categoriaId);
  }

  Future<void> _saveCategoriasPrincipais(
    String produtoId,
    List<String> categoriaIds,
  ) async {
    await _supabase
        .from('produto_categorias_estabelecimento')
        .delete()
        .eq('produto_id', produtoId);

    if (categoriaIds.isEmpty) return;

    final rows = categoriaIds
        .toSet()
        .map((categoriaId) => {
              'produto_id': produtoId,
              'categoria_id': categoriaId,
            })
        .toList();

    await _supabase.from('produto_categorias_estabelecimento').insert(rows);
  }

  Future<ProdutoModel> _fetchProdutoById(String produtoId) async {
    final response = await _supabase
        .from('produtos')
        .select(_produtoSelect)
        .eq('id', produtoId)
        .single();

    return ProdutoModel.fromJson(response);
  }
}
