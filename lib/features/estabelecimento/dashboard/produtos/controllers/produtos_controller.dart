import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'produtos_state.dart';
import '../data/produtos_repository.dart';
import '../models/produto_model.dart';

final produtosControllerProvider =
    StateNotifierProvider.autoDispose<ProdutosController, ProdutosState>((ref) {
  final repository = ref.read(produtosRepositoryProvider);
  return ProdutosController(repository);
});

class ProdutosController extends StateNotifier<ProdutosState> {
  final ProdutosRepository _repository;

  ProdutosController(this._repository) : super(const ProdutosState());

  /// Carrega os dados primários usando a Injeção de Dependências
  Future<void> loadDados(String estabelecimentoId) async {
    state = state.copyWith(
        isLoading: true, clearError: true); // Anula o erro anterior, se houver

    try {
      // Usamos Future.wait para paralelizar chamadas independentes ao invés de await sequencial.
      final results = await Future.wait([
        _repository.fetchProdutos(estabelecimentoId),
        _repository.fetchCategorias(estabelecimentoId),
      ]);

      final produtos = results[0] as List<dynamic>;
      final categorias = results[1] as List<dynamic>;

      state = state.copyWith(
        isLoading: false,
        produtos: produtos.cast(),
        produtosFiltrados:
            produtos.cast(), // Inicialmente, os filtrados são todos os produtos
        categorias: categorias.cast(),
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
  void aplicarFiltros(
      {String? query,
      String? categoriaId,
      String? status,
      bool setStatus = false}) {
    // Guarda o filtro atual para persistir na UI
    state = state.copyWith(
      searchQuery: query != null ? () => query : () => state.searchQuery,
      selectedCategoriaId: categoriaId != null
          ? () => categoriaId
          : () => state.selectedCategoriaId,
      // Se `setStatus` for true, força o valor (inclusive null), senão mantém o atual
      selectedStatusFilter: (status != null || setStatus)
          ? () => status
          : () => state.selectedStatusFilter,
    );

    final q = state.searchQuery?.toLowerCase().trim() ?? '';
    final catId = state.selectedCategoriaId;
    final stat = state.selectedStatusFilter;

    final result = state.produtos.where((p) {
      // 1. Busca por nome
      final matchName = q.isEmpty || p.nome.toLowerCase().contains(q);

      // 2. Por categoria
      final matchCat =
          catId == null || catId.isEmpty || p.categoriaCardapioId == catId;

      // 3. Status dinâmico
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

  /// Altera rapidamente a disponibilidade do switch na tela Principal
  Future<void> toggleDisponibilidade(
      String produtoId, bool wasDisponivel) async {
    // Optimistic UI Update -> Mudamos rapidamente na tela para feedback imediato
    final novoProdutoValor = !wasDisponivel;

    final updatedList = state.produtos
        .map((p) =>
            p.id == produtoId ? p.copyWith(disponivel: novoProdutoValor) : p)
        .toList();

    // Reaplica no estado base
    state = state.copyWith(produtos: updatedList);
    // Para renderizar o novo "Disponivel/Indisponivel", re-rodamos o filtro atual.
    aplicarFiltros(
        query: state.searchQuery,
        categoriaId: state.selectedCategoriaId,
        status: state.selectedStatusFilter);

    try {
      // Comunica Repository
      await _repository.updateDisponibilidade(produtoId, novoProdutoValor);
    } catch (e) {
      // Se falhar (falta de net), faz o Rollback reverso
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
      // Recarrega os produtos para refletir os novos campos
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
    final todos =
        await _repository.fetchProdutos(estabelecimentoId);
    state = state.copyWith(produtos: todos);
    aplicarFiltros(
      query: state.searchQuery,
      categoriaId: state.selectedCategoriaId,
      status: state.selectedStatusFilter,
    );
  }

  /// Cria ou atualiza um produto via upsert e atualiza a lista local.
  Future<void> salvarProduto(ProdutoModel produto) async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final saved = await _repository.saveProduto(produto);
      final isNew = !state.produtos.any((p) => p.id == saved.id);

      final updated = isNew
          ? [...state.produtos, saved]
          : state.produtos.map((p) => p.id == saved.id ? saved : p).toList();

      state = state.copyWith(isLoading: false, produtos: updated);
      // Re-aplica filtros para refletir na lista filtrada
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
}
