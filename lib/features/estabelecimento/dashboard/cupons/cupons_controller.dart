import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_controller.dart';
import 'models/cupom_model.dart';
import 'data/cupons_repository.dart';

final cuponsControllerProvider =
    StateNotifierProvider.autoDispose<CuponsController, CuponsState>((ref) {
  final repository = ref.watch(cuponsRepositoryProvider);
  // Precisamos do estabelecimento logado atual para amarrar os cupons à ele
  final estabState = ref.watch(dashboardControllerProvider);
  final estabelecimentoId = estabState.estabelecimentoId;

  return CuponsController(repository, estabelecimentoId);
});

class CuponsState {
  final bool isLoading;
  final bool isSaving;
  final String? error;
  final List<CupomModel> cupons;
  final String searchQuery;
  final String
      statusFilter; // 'todos', 'ativo', 'inativo', 'expirado', 'esgotado'
  final String
      tipoFilter; // 'todos', 'percentual', 'valor_fixo', 'entrega_gratis'

  CuponsState({
    this.isLoading = false,
    this.isSaving = false,
    this.error,
    this.cupons = const [],
    this.searchQuery = '',
    this.statusFilter = 'todos',
    this.tipoFilter = 'todos',
  });

  CuponsState copyWith({
    bool? isLoading,
    bool? isSaving,
    String? error,
    List<CupomModel>? cupons,
    String? searchQuery,
    String? statusFilter,
    String? tipoFilter,
    bool cleanError = false,
  }) {
    return CuponsState(
      isLoading: isLoading ?? this.isLoading,
      isSaving: isSaving ?? this.isSaving,
      error: cleanError ? null : (error ?? this.error),
      cupons: cupons ?? this.cupons,
      searchQuery: searchQuery ?? this.searchQuery,
      statusFilter: statusFilter ?? this.statusFilter,
      tipoFilter: tipoFilter ?? this.tipoFilter,
    );
  }

  // Derived properties for UI Filtering
  List<CupomModel> get filtrados {
    return cupons.where((c) {
      final q = searchQuery.toLowerCase();
      final matchSearch = q.isEmpty ||
          c.codigo.toLowerCase().contains(q) ||
          (c.descricao?.toLowerCase().contains(q) ?? false);

      var cupomStatus = 'ativo';
      final now = DateTime.now();
      if (!c.ativo) {
        cupomStatus = 'inativo';
      } else if (c.dataFim != null && c.dataFim!.isBefore(now)) {
        cupomStatus = 'expirado';
      } else if (c.limiteUsos != null && c.usosAtuais >= c.limiteUsos!) {
        cupomStatus = 'esgotado';
      }

      final matchStatus =
          statusFilter == 'todos' || cupomStatus == statusFilter;
      final matchTipo = tipoFilter == 'todos' || c.tipo == tipoFilter;

      return matchSearch && matchStatus && matchTipo;
    }).toList();
  }
}

class CuponsController extends StateNotifier<CuponsState> {
  final CuponsRepository _repository;
  final String? _estabelecimentoId;

  CuponsController(this._repository, this._estabelecimentoId)
      : super(CuponsState()) {
    carregarCupons();
  }

  Future<void> carregarCupons() async {
    if (_estabelecimentoId == null) return;

    state = state.copyWith(isLoading: true, cleanError: true);
    try {
      final lista = await _repository.fetchCupons(_estabelecimentoId);
      state = state.copyWith(isLoading: false, cupons: lista);
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Falha ao carregar cupons: \$e');
    }
  }

  Future<bool> criarCupom(CupomModel cupom) async {
    if (_estabelecimentoId == null) return false;

    state = state.copyWith(isSaving: true, cleanError: true);
    try {
      final cupomReal = CupomModel(
        id: cupom.id,
        estabelecimentoId: _estabelecimentoId,
        codigo: cupom.codigo.toUpperCase().trim(),
        tipo: cupom.tipo,
        valor: cupom.valor,
        valorMinimoPedido: cupom.valorMinimoPedido,
        ativo: cupom.ativo,
        descricao: cupom.descricao,
        limiteUsos: cupom.limiteUsos,
        limiteUsosPorCliente: cupom.limiteUsosPorCliente,
        dataInicio: cupom.dataInicio ?? DateTime.now(),
        dataFim: cupom.dataFim,
        usosAtuais: 0,
      );

      final novoCupom = await _repository.criarCupom(cupomReal);
      state = state.copyWith(
        isSaving: false,
        cupons: [novoCupom, ...state.cupons],
      );
      return true;
    } catch (e) {
      // Often unique constraint fails
      final msg = e.toString().contains('409')
          ? 'Código já existe. Tente outro.'
          : 'Erro ao criar cupom.';
      state = state.copyWith(isSaving: false, error: msg);
      return false;
    }
  }

  Future<bool> atualizarCupom(CupomModel cupom) async {
    state = state.copyWith(isSaving: true, cleanError: true);
    try {
      final cupomAtualizado = await _repository.atualizarCupom(cupom);
      final list = state.cupons
          .map((c) => c.id == cupomAtualizado.id ? cupomAtualizado : c)
          .toList();
      state = state.copyWith(isSaving: false, cupons: list);
      return true;
    } catch (e) {
      state = state.copyWith(
          isSaving: false, error: 'Erro ao atualizar cupom: \$e');
      return false;
    }
  }

  Future<void> excluirCupom(String id) async {
    try {
      await _repository.excluirCupom(id);
      final list = state.cupons.where((c) => c.id != id).toList();
      state = state.copyWith(cupons: list);
    } catch (e) {
      state = state.copyWith(error: 'Erro ao excluir cupom: \$e');
    }
  }

  Future<bool> alternarStatus(CupomModel cupom) async {
    try {
      await _repository.toggleAtivo(cupom.id, cupom.ativo);
      final list = state.cupons
          .map((c) => c.id == cupom.id ? c.copyWith(ativo: !c.ativo) : c)
          .toList();
      state = state.copyWith(cupons: list);
      return true;
    } catch (e) {
      state = state.copyWith(error: 'Erro ao alterar status: \$e');
      return false;
    }
  }

  void setPesquisa(String q) {
    state = state.copyWith(searchQuery: q);
  }

  void setFiltroStatus(String sf) {
    state = state.copyWith(statusFilter: sf);
  }

  void setFiltroTipo(String tf) {
    state = state.copyWith(tipoFilter: tf);
  }

  void limparErro() {
    state = state.copyWith(cleanError: true);
  }
}
