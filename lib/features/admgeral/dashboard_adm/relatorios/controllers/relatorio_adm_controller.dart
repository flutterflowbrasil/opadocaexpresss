import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/relatorio_adm_repository.dart';
import 'relatorio_adm_state.dart';

final relatorioAdmControllerProvider =
    StateNotifierProvider.autoDispose<RelatorioAdmController, RelatorioAdmState>(
  (ref) => RelatorioAdmController(ref.watch(relatorioAdmRepositoryProvider)),
);

class RelatorioAdmController extends StateNotifier<RelatorioAdmState> {
  final RelatorioAdmRepository _repo;

  RelatorioAdmController(this._repo) : super(const RelatorioAdmState()) {
    fetch();
  }

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final snapshot = await _repo.fetchSnapshot(state.periodo);
      state = state.copyWith(
        isLoading: false,
        snapshot: snapshot,
        lastSync: DateTime.now(),
      );
    } catch (e, st) {
      debugPrint('[RelatorioAdmController] fetch error: $e\n$st');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar relatórios. Tente novamente.',
      );
    }
  }

  Future<void> setPeriodo(String periodo) async {
    state = state.copyWith(periodo: periodo);
    await fetch();
  }

  void setAba(String aba) {
    state = state.copyWith(abaAtiva: aba);
  }
}
