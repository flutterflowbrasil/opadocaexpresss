import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/estabs_adm_repository.dart';
import 'estabs_adm_state.dart';

final estabsAdmControllerProvider =
    StateNotifierProvider.autoDispose<EstabsAdmController, EstabsAdmState>(
  (ref) => EstabsAdmController(ref.watch(estabsAdmRepositoryProvider))..fetch(),
);

class EstabsAdmController extends StateNotifier<EstabsAdmState> {
  final EstabsAdmRepository _repo;

  EstabsAdmController(this._repo) : super(const EstabsAdmState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final lista = await _repo.listarEstabelecimentos();
      state = state.copyWith(isLoading: false, estabelecimentos: lista);
    } catch (e) {
      debugPrint('[EstabsAdm] fetch error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar estabelecimentos. Tente novamente.',
      );
    }
  }

  void setFiltro(String status) {
    state = state.copyWith(filtroStatus: status);
  }

  void setBusca(String termo) {
    state = state.copyWith(termoBusca: termo);
  }

  Future<void> executarAcao(
    String acao,
    String estabId, {
    String? motivo,
  }) async {
    final novoStatus = switch (acao) {
      'aprovar' => 'aprovado',
      'rejeitar' => 'rejeitado',
      'suspender' => 'suspenso',
      'reativar' => 'aprovado',
      _ => throw ArgumentError('Ação inválida: $acao'),
    };

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.atualizarStatus(estabId, novoStatus, motivo: motivo);
      // Atualização otimista na lista local
      final updated = state.estabelecimentos.map((e) {
        if (e.id != estabId) return e;
        return e.copyWith(
          statusCadastro: novoStatus,
          motivoSuspensao: motivo,
          clearMotivo: novoStatus == 'aprovado',
        );
      }).toList();
      state = state.copyWith(isSubmitting: false, estabelecimentos: updated);
    } catch (e) {
      debugPrint('[EstabsAdm] executarAcao error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro ao executar ação. Tente novamente.',
      );
    }
  }
}

// ignore: avoid_print
void debugPrint(String msg) => print(msg);
