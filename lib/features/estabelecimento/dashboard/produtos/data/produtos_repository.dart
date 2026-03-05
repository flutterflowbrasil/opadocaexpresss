import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/produto_model.dart';
import '../../../models/categoria_cardapio_model.dart'; // Modelo reutilizado da feature maior!

final produtosRepositoryProvider = Provider<ProdutosRepository>((ref) {
  return ProdutosRepository(Supabase.instance.client);
});

class ProdutosRepository {
  final SupabaseClient _supabase;

  ProdutosRepository(this._supabase);

  // Busca todos os produtos do estabelecimento com um INNER JOIN em categorias_cardapio.
  // Evita o problema de query N+1 na UI para descobrir o 'nome' de cada categoria!
  Future<List<ProdutoModel>> fetchProdutos(String estabelecimentoId) async {
    final response = await _supabase
        .from('produtos')
        .select('*, categorias_cardapio:categoria_cardapio_id(nome)')
        .eq('estabelecimento_id', estabelecimentoId)
        .order('ordem_exibicao');

    return response.map((json) => ProdutoModel.fromJson(json)).toList();
  }

  // Busca as categorias do cardápio separadamente para popular o controle de "Tabs" e Comboboxes
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

  // Realiza um Merge Insere/Atualiza (Upsert)
  Future<ProdutoModel> saveProduto(ProdutoModel produto) async {
    final data = produto.toJson();
    // Remover campos gerados apenas pelo BD para não conflitar no upsert
    data.remove('created_at');
    data.remove('updated_at');

    final response = await _supabase
        .from('produtos')
        .upsert(data)
        .select('*, categorias_cardapio:categoria_cardapio_id(nome)')
        .single();

    return ProdutoModel.fromJson(response);
  }

  /// Deleta fisicamente o produto do banco de dados
  Future<void> deleteProduto(String produtoId) async {
    await _supabase.from('produtos').delete().eq('id', produtoId);
  }

  /// Toggle rápido para disponibilidade do produto direto na Home Grid
  Future<void> updateDisponibilidade(String produtoId, bool disponivel) async {
    await _supabase
        .from('produtos')
        .update({'disponivel': disponivel}).eq('id', produtoId);
  }
}
