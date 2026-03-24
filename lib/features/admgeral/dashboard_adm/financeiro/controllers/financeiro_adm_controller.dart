import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../data/financeiro_adm_repository.dart';
import '../models/financeiro_adm_models.dart';
import 'financeiro_adm_state.dart';

// ── Providers ──────────────────────────────────────────────────────────────────

final financeiroAdmRepositoryProvider = Provider<FinanceiroAdmRepository>((ref) {
  return FinanceiroAdmRepository(Supabase.instance.client);
});

final financeiroAdmControllerProvider =
    StateNotifierProvider.autoDispose<FinanceiroAdmController, FinanceiroAdmState>(
  (ref) {
    final repo = ref.watch(financeiroAdmRepositoryProvider);
    return FinanceiroAdmController(repo);
  },
);

// ── Controller ─────────────────────────────────────────────────────────────────

class FinanceiroAdmController extends StateNotifier<FinanceiroAdmState> {
  final FinanceiroAdmRepository _repo;

  FinanceiroAdmController(this._repo) : super(const FinanceiroAdmState()) {
    fetch();
  }

  /// Carrega todos os dados financeiros em paralelo (4 queries simultâneas).
  Future<void> fetch() async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final results = await Future.wait([
        _repo.buscarPedidos(),
        _repo.buscarSplits(),
        _repo.buscarSaques(),
        _repo.buscarSubcontas(),
      ]);

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        pedidos: results[0] as List<PedidoFinanceiro>,
        splits: results[1] as List<SplitPagamento>,
        saques: results[2] as List<EntregadorSaque>,
        subcontas: results[3] as List<AsaasSubconta>,
        lastSync: DateTime.now(),
      );
    } catch (e) {
      debugPrint('[FinanceiroAdm] fetch erro: $e');
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Não foi possível carregar os dados financeiros. Verifique sua conexão.',
      );
    }
  }

  void setAba(String aba) => state = state.copyWith(abaAtiva: aba);

  void setFiltroMetodo(String metodo) =>
      state = state.copyWith(filtroMetodo: metodo);

  void setFiltroPgtoStatus(String status) =>
      state = state.copyWith(filtroPgtoStatus: status);

  void setFiltroSplit(String split) =>
      state = state.copyWith(filtroSplit: split);

  void clearError() => state = state.copyWith(clearError: true);
}
