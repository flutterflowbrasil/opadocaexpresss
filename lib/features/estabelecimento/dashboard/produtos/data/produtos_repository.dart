import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';
import '../models/produto_model.dart';
import '../models/produto_preco_tamanho_model.dart';
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
      'categorias_estabelecimento:categoria_id(id, nome)), '
      'produto_precos_tamanhos(id, produto_id, nome_tamanho, preco, ordem, ativo)';

  // ── Produtos ──────────────────────────────────────────────────────────

  Future<List<ProdutoModel>> fetchProdutos(String estabelecimentoId) async {
    final response = await _supabase
        .from('produtos')
        .select(_produtoSelect)
        .eq('estabelecimento_id', estabelecimentoId)
        .order('ordem_exibicao');

    return response.map((json) => ProdutoModel.fromJson(json)).toList();
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

  /// Salva (cria ou atualiza) um produto.
  /// Garante que opcoes seja [] se a categoria não permitir adicionais.
  Future<ProdutoModel> saveProduto(
    ProdutoModel produto, {
    bool categoriaPermiteAdicionais = true,
  }) async {
    final data = produto.toJson();
    data.remove('created_at');
    data.remove('updated_at');
    if ((data['id'] as String?)?.isEmpty ?? false) data.remove('id');

    // Sanitiza UUIDs vazios para evitar erro de sintaxe PostgrestException
    if ((data['categoria_id'] as String?)?.isEmpty ?? false) {
      data['categoria_id'] = null;
    }
    if ((data['categoria_cardapio_id'] as String?)?.isEmpty ?? false) {
      data['categoria_cardapio_id'] = null;
    }

    // Segurança backend: força opcoes=[] se categoria não permite adicionais
    if (!categoriaPermiteAdicionais) {
      data['opcoes'] = [];
    }

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

  Future<void> _saveCategoriasPrincipais(
    String produtoId,
    List<String> categoriaIds,
  ) async {
    final atuaisResp = await _supabase
        .from('produto_categorias_estabelecimento')
        .select('categoria_id')
        .eq('produto_id', produtoId);
    final atuais = (atuaisResp as List)
        .map((row) => (row as Map)['categoria_id'] as String)
        .toSet();
    final novos = categoriaIds.toSet();
    final toAdd = novos.difference(atuais);
    final toRemove = atuais.difference(novos);

    // Insere primeiro para o trigger não zerar opções/tamanhos no meio da troca.
    if (toAdd.isNotEmpty) {
      await _supabase.from('produto_categorias_estabelecimento').insert(
            toAdd
                .map((categoriaId) => {
                      'produto_id': produtoId,
                      'categoria_id': categoriaId,
                    })
                .toList(),
          );
    }
    if (toRemove.isNotEmpty) {
      await _supabase
          .from('produto_categorias_estabelecimento')
          .delete()
          .eq('produto_id', produtoId)
          .inFilter('categoria_id', toRemove.toList());
    }
  }

  Future<ProdutoModel> _fetchProdutoById(String produtoId) async {
    final response = await _supabase
        .from('produtos')
        .select(_produtoSelect)
        .eq('id', produtoId)
        .single();

    return ProdutoModel.fromJson(response);
  }

  // ── Categorias do cardápio ────────────────────────────────────────────

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

  /// Verifica se o usuário logado pode criar/editar categorias do cardápio (RLS).
  Future<bool> podeGerenciarCategoriasCardapio(String estabelecimentoId) async {
    final uid = _supabase.auth.currentUser?.id;
    if (uid == null) return false;

    final row = await _supabase
        .from('administradores_estabelecimento')
        .select('id')
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('usuario_id', uid)
        .eq('ativo', true)
        .maybeSingle();

    return row != null;
  }

  /// Busca categorias principais com os novos campos de permissão.
  Future<List<CategoriaEstabelecimentoModel>> fetchCategoriasPrincipais() async {
    final response = await _supabase
        .from('categorias_estabelecimento')
        .select(
          'id, nome, icone, ativa, imagem_url, slug, ordem_exibicao, '
          'permite_adicionais, permite_multiplos_precos',
        )
        .eq('ativa', true)
        .order('ordem_exibicao', ascending: true);

    return response
        .map((json) => CategoriaEstabelecimentoModel.fromJson(json))
        .toList();
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

  // ── Tamanhos/Preços (Pizza) ───────────────────────────────────────────

  Future<List<ProdutoPrecoTamanhoModel>> fetchTamanhos(String produtoId) async {
    final response = await _supabase
        .from('produto_precos_tamanhos')
        .select()
        .eq('produto_id', produtoId)
        .order('ordem');

    return response
        .map((json) => ProdutoPrecoTamanhoModel.fromJson(json))
        .toList();
  }

  Future<ProdutoPrecoTamanhoModel> saveTamanho(
      ProdutoPrecoTamanhoModel tamanho) async {
    final data = tamanho.toJson();

    if (tamanho.id.isEmpty) {
      final response = await _supabase
          .from('produto_precos_tamanhos')
          .insert(data)
          .select()
          .single();
      return ProdutoPrecoTamanhoModel.fromJson(response);
    }

    final response = await _supabase
        .from('produto_precos_tamanhos')
        .update(data)
        .eq('id', tamanho.id)
        .select()
        .single();

    return ProdutoPrecoTamanhoModel.fromJson(response);
  }

  Future<void> deleteTamanho(String tamanhoId) async {
    await _supabase
        .from('produto_precos_tamanhos')
        .delete()
        .eq('id', tamanhoId);
  }

  /// Desativa todos os tamanhos de um produto (quando categoria muda para não-pizza).
  Future<void> desativarTodosTamanhos(String produtoId) async {
    await _supabase
        .from('produto_precos_tamanhos')
        .update({'ativo': false})
        .eq('produto_id', produtoId);
  }

  /// Salva a lista completa de tamanhos de um produto (insert novos + update existentes).
  Future<List<ProdutoPrecoTamanhoModel>> saveTamanhosBatch(
    String produtoId,
    List<ProdutoPrecoTamanhoModel> tamanhos,
  ) async {
    if (tamanhos.isEmpty) return [];

    final novos = <Map<String, dynamic>>[];
    final existentes = <Map<String, dynamic>>[];

    for (final t in tamanhos) {
      final json = t.copyWith(produtoId: produtoId).toJson();
      if (t.id.isEmpty) {
        // Upsert em lote com linhas sem id faz o PostgREST enviar id=null.
        if (t.ativo) novos.add(json);
      } else {
        existentes.add(json);
      }
    }

    final results = <ProdutoPrecoTamanhoModel>[];

    if (novos.isNotEmpty) {
      final inserted = await _supabase
          .from('produto_precos_tamanhos')
          .insert(novos)
          .select();
      results.addAll(
        inserted.map((json) => ProdutoPrecoTamanhoModel.fromJson(json)),
      );
    }

    if (existentes.isNotEmpty) {
      final updated = await _supabase
          .from('produto_precos_tamanhos')
          .upsert(existentes, onConflict: 'id')
          .select();
      results.addAll(
        updated.map((json) => ProdutoPrecoTamanhoModel.fromJson(json)),
      );
    }

    return results;
  }
}
