import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/estabelecimento/repositories/estabelecimento_repository.dart';

class EstabelecimentoState {
  final EstabelecimentoModel? estabelecimento;
  final List<CategoriaCardapioModel> categorias;
  final List<ProdutoModel> produtos;
  final bool isLoading;
  final String? errorMessage;
  final String searchQuery;
  final String selectedCategoriaId;

  EstabelecimentoState({
    this.estabelecimento,
    this.categorias = const [],
    this.produtos = const [],
    this.isLoading = true,
    this.errorMessage,
    this.searchQuery = '',
    this.selectedCategoriaId = 'tudo',
  });

  EstabelecimentoState copyWith({
    EstabelecimentoModel? estabelecimento,
    List<CategoriaCardapioModel>? categorias,
    List<ProdutoModel>? produtos,
    bool? isLoading,
    String? errorMessage,
    String? searchQuery,
    String? selectedCategoriaId,
  }) {
    return EstabelecimentoState(
      estabelecimento: estabelecimento ?? this.estabelecimento,
      categorias: categorias ?? this.categorias,
      produtos: produtos ?? this.produtos,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage ?? this.errorMessage,
      searchQuery: searchQuery ?? this.searchQuery,
      selectedCategoriaId: selectedCategoriaId ?? this.selectedCategoriaId,
    );
  }

  List<ProdutoModel> get produtosFiltrados {
    var filtered = produtos;

    if (searchQuery.isNotEmpty) {
      final query = _removeDiacritics(searchQuery.toLowerCase());
      filtered = filtered
          .where((p) => _removeDiacritics(p.nome.toLowerCase()).contains(query))
          .toList();
    }

    if (selectedCategoriaId != 'tudo') {
      filtered = filtered
          .where((p) => p.categoriaCardapioId == selectedCategoriaId)
          .toList();
    }

    return filtered;
  }

  String _removeDiacritics(String str) {
    const withDia =
        'ÀÁÂÃÄÅàáâãäåÒÓÔÕÕÖØòóôõöøÈÉÊËèéêëðÇçÐÌÍÎÏìíîïÙÚÛÜùúûüÑñŠšŸÿýŽž';
    const withoutDia =
        'AAAAAAaaaaaaOOOOOOOooooooEEEEeeeeeCcDIIIIiiiiUUUUuuuuNnSsYyyZz';

    String result = str;
    for (int i = 0; i < withDia.length; i++) {
      result = result.replaceAll(withDia[i], withoutDia[i]);
    }
    return result;
  }
}

final estabelecimentoControllerProvider = StateNotifierProvider.family<
    EstabelecimentoController, EstabelecimentoState, String>(
  (ref, estabelecimentoId) {
    return EstabelecimentoController(
      ref.watch(estabelecimentoRepositoryProvider),
      estabelecimentoId,
    );
  },
);

class EstabelecimentoController extends StateNotifier<EstabelecimentoState> {
  final EstabelecimentoRepository _repository;
  final String _estabelecimentoId;

  EstabelecimentoController(this._repository, this._estabelecimentoId)
      : super(EstabelecimentoState()) {
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      state = state.copyWith(isLoading: true, errorMessage: null);

      final estabelecimento = await _repository.getDetalhes(_estabelecimentoId);
      final categorias =
          await _repository.getCategoriasCardapio(_estabelecimentoId);
      final produtos = await _repository.getProdutos(_estabelecimentoId);

      // Adicionar categoria 'tudo' virtual
      final allCategories = [
        CategoriaCardapioModel(
          id: 'tudo',
          estabelecimentoId: _estabelecimentoId,
          nome: 'Tudo',
          ordemExibicao: -1,
          ativa: true,
        ),
        ...categorias,
      ];

      state = state.copyWith(
        estabelecimento: estabelecimento,
        categorias: allCategories,
        produtos: produtos,
        isLoading: false,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar os dados do estabelecimento: $e',
      );
    }
  }

  void setSearchQuery(String query) {
    state = state.copyWith(searchQuery: query);
  }

  void selectCategoria(String categoriaId) {
    state = state.copyWith(selectedCategoriaId: categoriaId);
  }
}
