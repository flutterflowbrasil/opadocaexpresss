import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'data/financeiro_repository.dart';
import 'financeiro_state.dart';
import 'models/financeiro_models.dart';

final financeiroControllerProvider =
    StateNotifierProvider.autoDispose<FinanceiroController, FinanceiroState>(
        (ref) {
  final repo = ref.watch(financeiroRepositoryProvider);
  return FinanceiroController(repo)..carregarDadosIniciais();
});

class FinanceiroController extends StateNotifier<FinanceiroState> {
  final FinanceiroRepository _repository;

  FinanceiroController(this._repository) : super(FinanceiroState());

  Future<void> carregarDadosIniciais() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final estab = await _repository.buscarEstabelecimento();
      if (estab == null) {
        state = state.copyWith(
            isLoading: false, error: 'Estabelecimento não encontrado.');
        return;
      }

      state = state.copyWith(estabelecimento: estab);
      await buscarDadosPorPeriodo(state.periodoAtual, loadingState: false);
    } catch (e) {
      state =
          state.copyWith(isLoading: false, error: 'Erro ao carregar dados: $e');
    }
  }

  Future<void> buscarDadosPorPeriodo(String periodoId,
      {bool loadingState = true}) async {
    if (loadingState) {
      state =
          state.copyWith(isLoading: true, error: null, periodoAtual: periodoId);
    } else {
      state = state.copyWith(periodoAtual: periodoId);
    }

    try {
      if (state.estabelecimento == null) {
        throw Exception('Sem ID de estabelecimento');
      }

      final dates = _getDateTimeRangeForPeriodo(periodoId);
      final inicio = dates[0];
      final fim = dates[1];

      // Busca Paralela
      final results = await Future.wait([
        _repository.buscarPedidosPeriodo(
            state.estabelecimento!.id, inicio, fim),
        _repository.buscarSplitsPeriodo(state.estabelecimento!.id, inicio, fim),
      ]);

      state = state.copyWith(
        isLoading: false,
        pedidos: results[0] as List<PedidoFinanceiro>,
        splits: results[1] as List<SplitFinanceiro>,
      );
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Falha ao processar período: $e');
    }
  }

  // Define os cortes de data (Hoje, 7 Dias, Mês, Trimestre, Ano)
  List<DateTime> _getDateTimeRangeForPeriodo(String p) {
    final now = DateTime.now();
    switch (p) {
      case 'hoje':
        final start = DateTime(now.year, now.month, now.day);
        return [start, now];
      case 'semana':
        final start = now.subtract(const Duration(days: 6));
        final startZero = DateTime(start.year, start.month, start.day);
        return [startZero, now];
      case 'trimestre':
        final start = DateTime(now.year, now.month - 2, 1);
        return [start, now];
      case 'ano':
        final start = DateTime(now.year, 1, 1);
        return [start, now];
      case 'mes':
      default:
        final start = DateTime(now.year, now.month, 1);
        return [start, now];
    }
  }
}
