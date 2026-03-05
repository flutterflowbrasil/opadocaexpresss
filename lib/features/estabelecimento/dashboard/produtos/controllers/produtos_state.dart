import '../models/produto_model.dart';
import '../../../models/categoria_cardapio_model.dart';

class ProdutosState {
  final List<ProdutoModel> produtos;
  final List<ProdutoModel> produtosFiltrados;
  final List<CategoriaCardapioModel> categorias;
  final bool isLoading;
  final String? error;

  // Filtros locais da UI
  final String filterMode; // 'grid' ou 'list'
  final String? searchQuery;
  final String? selectedCategoriaId;
  final String? selectedStatusFilter; // 'disponivel', 'destaque', etc.

  const ProdutosState({
    this.produtos = const [],
    this.produtosFiltrados = const [],
    this.categorias = const [],
    this.isLoading = false,
    this.error,
    this.filterMode = 'grid',
    this.searchQuery,
    this.selectedCategoriaId,
    this.selectedStatusFilter,
  });

  ProdutosState copyWith({
    List<ProdutoModel>? produtos,
    List<ProdutoModel>? produtosFiltrados,
    List<CategoriaCardapioModel>? categorias,
    bool? isLoading,
    String? error,
    bool clearError = false,
    String? filterMode,
    String? Function()? searchQuery,
    String? Function()? selectedCategoriaId,
    String? Function()? selectedStatusFilter,
  }) {
    return ProdutosState(
      produtos: produtos ?? this.produtos,
      produtosFiltrados: produtosFiltrados ?? this.produtosFiltrados,
      categorias: categorias ?? this.categorias,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      filterMode: filterMode ?? this.filterMode,
      searchQuery: searchQuery != null ? searchQuery() : this.searchQuery,
      selectedCategoriaId: selectedCategoriaId != null
          ? selectedCategoriaId()
          : this.selectedCategoriaId,
      selectedStatusFilter: selectedStatusFilter != null
          ? selectedStatusFilter()
          : this.selectedStatusFilter,
    );
  }

  // Helper para anular as flags de filtro
  ProdutosState clearFilters() {
    return copyWith(
      searchQuery: () => null,
      selectedCategoriaId: () => null,
      selectedStatusFilter: () => null,
      produtosFiltrados: produtos,
    );
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;

    return other is ProdutosState &&
        other.produtos == produtos &&
        other.produtosFiltrados == produtosFiltrados &&
        other.categorias == categorias &&
        other.isLoading == isLoading &&
        other.error == error &&
        other.filterMode == filterMode &&
        other.searchQuery == searchQuery &&
        other.selectedCategoriaId == selectedCategoriaId &&
        other.selectedStatusFilter == selectedStatusFilter;
  }

  @override
  int get hashCode {
    return produtos.hashCode ^
        produtosFiltrados.hashCode ^
        categorias.hashCode ^
        isLoading.hashCode ^
        error.hashCode ^
        filterMode.hashCode ^
        searchQuery.hashCode ^
        selectedCategoriaId.hashCode ^
        selectedStatusFilter.hashCode;
  }
}
