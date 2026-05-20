import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'produtos_state.dart';
import '../data/produtos_repository.dart';
import '../models/produto_model.dart';
import '../models/produto_preco_tamanho_model.dart';
import '../../../models/categoria_cardapio_model.dart';
import 'package:padoca_express/features/cliente/categorias/models/categoria_estabelecimento_model.dart';

final produtosControllerProvider =
    StateNotifierProvider.autoDispose<ProdutosController, ProdutosState>((ref) {
  ref.keepAlive(); // Mantém o estado vivo para navegação instantânea
  final repository = ref.read(produtosRepositoryProvider);
  return ProdutosController(repository);
});

class ProdutosController extends StateNotifier<ProdutosState> {
  final ProdutosRepository _repository;

  ProdutosController(this._repository) : super(const ProdutosState());

  /// Carrega os dados primários usando a Injeção de Dependências
  Future<void> loadDados(String estabelecimentoId) async {
    if (state.produtos.isEmpty) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final results = await Future.wait([
        _repository.fetchProdutos(estabelecimentoId),
        _repository.fetchCategorias(estabelecimentoId),
        _repository.fetchCategoriasPrincipais(),
      ]);

      final produtos = results[0] as List<dynamic>;
      final categorias = results[1] as List<dynamic>;
      final categoriasPrincipais = results[2] as List<dynamic>;

      state = state.copyWith(
        isLoading: false,
        produtos: produtos.cast(),
        produtosFiltrados: produtos.cast(),
        categorias: categorias.cast(),
        categoriasPrincipais: categoriasPrincipais.cast(),
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar dados do cardápio: $e',
      );
    }
  }

  /// Altera o modo de visualização entre List e Grid
  void toggleFilterMode(String mode) {
    state = state.copyWith(filterMode: mode);
  }

  /// Aplica filtros combinados (Busca, Categoria, e Status)
  void aplicarFiltros({
    String? query,
    String? categoriaId,
    bool setCategoriaId = false,
    String? status,
    bool setStatus = false,
  }) {
    state = state.copyWith(
      searchQuery: query != null ? () => query : () => state.searchQuery,
      selectedCategoriaId: (categoriaId != null || setCategoriaId)
          ? () => categoriaId
          : () => state.selectedCategoriaId,
      selectedStatusFilter: (status != null || setStatus)
          ? () => status
          : () => state.selectedStatusFilter,
    );

    final q = state.searchQuery?.toLowerCase().trim() ?? '';
    final catId = state.selectedCategoriaId;
    final stat = state.selectedStatusFilter;

    final result = state.produtos.where((p) {
      final matchName = q.isEmpty || p.nome.toLowerCase().contains(q);
      final matchCat =
          catId == null || catId.isEmpty || p.categoriaCardapioId == catId;

      bool matchStatus = true;
      if (stat != null && stat.isNotEmpty) {
        if (stat == 'disponivel') {
          matchStatus = p.disponivel && p.ativo;
        } else if (stat == 'indisponivel') {
          matchStatus = !(p.disponivel && p.ativo);
        } else if (stat == 'destaque') {
          matchStatus = p.destaque;
        } else if (stat == 'promo') {
          matchStatus = (p.precoPromocional != null && p.precoPromocional! > 0);
        } else if (stat == 'estoque_baixo') {
          matchStatus = p.controleEstoque &&
              (p.quantidadeEstoque != null && p.quantidadeEstoque! <= 5);
        }
      }

      return matchName && matchCat && matchStatus;
    }).toList();

    state = state.copyWith(produtosFiltrados: result);
  }

  /// Anula todos os filtros locais e restaura todos os produtos
  void limparFiltros() {
    state = state.clearFilters();
  }

  /// Retorna a CategoriaEstabelecimentoModel de uma categoria principal pelo ID.
  /// Útil para verificar permiteAdicionais e permiteMultiplosPrecos.
  CategoriaEstabelecimentoModel? getCategoriaById(String? categoriaId) {
    if (categoriaId == null) return null;
    try {
      return state.categoriasPrincipais
          .firstWhere((c) => c.id == categoriaId);
    } catch (_) {
      return null;
    }
  }

  /// Altera rapidamente a disponibilidade do switch na tela Principal
  Future<void> toggleDisponibilidade(
      String produtoId, bool wasDisponivel) async {
    final novoProdutoValor = !wasDisponivel;
    final updatedList = state.produtos
        .map((p) =>
            p.id == produtoId ? p.copyWith(disponivel: novoProdutoValor) : p)
        .toList();
    state = state.copyWith(produtos: updatedList);
    aplicarFiltros(
        query: state.searchQuery,
        categoriaId: state.selectedCategoriaId,
        status: state.selectedStatusFilter);

    try {
      await _repository.updateDisponibilidade(produtoId, novoProdutoValor);
    } catch (e) {
      final rollbackList = state.produtos
          .map((p) =>
              p.id == produtoId ? p.copyWith(disponivel: wasDisponivel) : p)
          .toList();
      state = state.copyWith(
          produtos: rollbackList, error: 'Falha ao alterar status online: $e');
      aplicarFiltros(
          query: state.searchQuery,
          categoriaId: state.selectedCategoriaId,
          status: state.selectedStatusFilter);
    }
  }

  /// Ativa o modo Última Mordida em um produto.
  Future<void> ativarUltimaMordida(
    String produtoId, {
    int? descontoPct,
    String? chamada,
    int? duracaoHoras,
  }) async {
    try {
      await _repository.ativarUltimaMordida(
        produtoId,
        descontoPct: descontoPct,
        chamada: chamada,
        duracaoHoras: duracaoHoras,
      );
      final produto = state.produtos.firstWhere((p) => p.id == produtoId);
      await _recarregarProduto(produtoId, produto.estabelecimentoId);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao ativar Última Mordida: $e');
    }
  }

  /// Desativa o modo Última Mordida em um produto.
  Future<void> desativarUltimaMordida(String produtoId) async {
    try {
      await _repository.desativarUltimaMordida(produtoId);
      final produto = state.produtos.firstWhere((p) => p.id == produtoId);
      await _recarregarProduto(produtoId, produto.estabelecimentoId);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao desativar Última Mordida: $e');
    }
  }

  Future<void> _recarregarProduto(
      String produtoId, String estabelecimentoId) async {
    final todos = await _repository.fetchProdutos(estabelecimentoId);
    state = state.copyWith(produtos: todos);
    aplicarFiltros(
      query: state.searchQuery,
      categoriaId: state.selectedCategoriaId,
      status: state.selectedStatusFilter,
    );
  }

  // ── Categorias ─────────────────────────────────────────────────────────────

  Future<void> salvarCategoria(CategoriaCardapioModel categoria) async {
    try {
      final saved = await _repository.saveCategoria(categoria);
      final isNew = !state.categorias.any((c) => c.id == saved.id);
      final updated = isNew
          ? [...state.categorias, saved]
          : state.categorias
              .map((c) => c.id == saved.id ? saved : c)
              .toList();
      state = state.copyWith(categorias: updated);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao salvar categoria: $e');
      rethrow;
    }
  }

  Future<void> deletarCategoria(String categoriaId) async {
    try {
      await _repository.deleteCategoria(categoriaId);
      final updated =
          state.categorias.where((c) => c.id != categoriaId).toList();
      final newCatFilter = state.selectedCategoriaId == categoriaId
          ? null
          : state.selectedCategoriaId;
      state = state.copyWith(categorias: updated);
      aplicarFiltros(
        query: state.searchQuery,
        categoriaId: newCatFilter,
        status: state.selectedStatusFilter,
        setStatus: newCatFilter == null && state.selectedCategoriaId != null,
      );
    } catch (e) {
      state = state.copyWith(error: 'Erro ao remover categoria: $e');
      rethrow;
    }
  }

  // ── Produtos ────────────────────────────────────────────────────────────────

  /// Cria ou atualiza um produto. Valida permissões de categoria antes de salvar.
  Future<void> salvarProduto(
    ProdutoModel produto, {
    bool categoriaPermiteAdicionais = true,
    List<ProdutoPrecoTamanhoModel> tamanhos = const [],
    bool categoriaPermiteMultiplosPrecos = false,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _repository.saveProduto(
        produto,
        categoriaPermiteAdicionais: categoriaPermiteAdicionais,
      );

      // Salva tamanhos somente se a categoria permitir múltiplos preços
      if (categoriaPermiteMultiplosPrecos && tamanhos.isNotEmpty) {
        await _repository.saveTamanhosBatch(saved.id, tamanhos);
      } else if (!categoriaPermiteMultiplosPrecos) {
        // Desativa tamanhos ao mudar para categoria sem suporte a múltiplos preços
        await _repository.desativarTodosTamanhos(saved.id);
      }

      final isNew = !state.produtos.any((p) => p.id == saved.id);
      final updated = isNew
          ? [...state.produtos, saved]
          : state.produtos.map((p) => p.id == saved.id ? saved : p).toList();

      state = state.copyWith(isLoading: false, produtos: updated);
      aplicarFiltros(
        query: state.searchQuery,
        categoriaId: state.selectedCategoriaId,
        status: state.selectedStatusFilter,
      );
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Erro ao salvar produto: $e');
    }
  }

  // ── Tamanhos (Pizza) ────────────────────────────────────────────────────────

  Future<List<ProdutoPrecoTamanhoModel>> fetchTamanhos(
      String produtoId) async {
    try {
      return await _repository.fetchTamanhos(produtoId);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao carregar tamanhos: $e');
      return [];
    }
  }

  Future<void> deletarTamanho(String tamanhoId) async {
    try {
      await _repository.deleteTamanho(tamanhoId);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao remover tamanho: $e');
      rethrow;
    }
  }
}
