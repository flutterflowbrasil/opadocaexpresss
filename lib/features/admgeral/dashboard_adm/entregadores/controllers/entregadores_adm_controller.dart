import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/entregadores_adm_repository.dart';
import '../models/entregador_adm_model.dart';
import 'entregadores_adm_state.dart';

final entregadoresAdmControllerProvider = StateNotifierProvider.autoDispose<
    EntregadoresAdmController, EntregadoresAdmState>(
  (ref) =>
      EntregadoresAdmController(ref.watch(entregadoresAdmRepositoryProvider))
        ..fetch(),
);

class EntregadoresAdmController
    extends StateNotifier<EntregadoresAdmState> {
  final EntregadoresAdmRepository _repo;

  EntregadoresAdmController(this._repo)
      : super(const EntregadoresAdmState());

  Future<void> fetch() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final lista = await _repo.listarEntregadores();
      state = state.copyWith(isLoading: false, entregadores: lista);
    } catch (e) {
      debugPrint('[EntregadoresAdm] fetch error: $e');
      state = state.copyWith(
        isLoading: false,
        errorMessage: 'Erro ao carregar entregadores. Tente novamente.',
      );
    }
  }

  void setFiltroStatus(String status) {
    state = state.copyWith(filtroStatus: status);
  }

  void setFiltroVeiculo(String veiculo) {
    state = state.copyWith(filtroVeiculo: veiculo);
  }

  void setBusca(String termo) {
    state = state.copyWith(termoBusca: termo);
  }

  Future<void> executarAcao(
    String acao,
    String entregadorId, {
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
      await _repo.atualizarStatus(entregadorId, novoStatus, motivo: motivo);
      final updated = state.entregadores.map((e) {
        if (e.id != entregadorId) return e;
        return e.copyWith(
          statusCadastro: novoStatus,
          motivoRejeicao: motivo,
          clearMotivo: novoStatus == 'aprovado',
        );
      }).toList();
      state = state.copyWith(isSubmitting: false, entregadores: updated);
    } catch (e) {
      debugPrint('[EntregadoresAdm] executarAcao error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro ao executar ação. Tente novamente.',
      );
    }
  }

  Future<void> revisarSelfie(
    String entregadorId,
    String status, {
    String? observacao,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.revisarSelfie(entregadorId, status, observacao: observacao);
      // Atualização otimista do KYC local
      final updated = state.entregadores.map((e) {
        if (e.id != entregadorId) return e;
        final novoKyc = (e.selfieRevisao ?? const EntregadorKycInfo(status: 'pendente'))
            .copyWith(
          status: status,
          observacaoAdmin: observacao,
          revisadoEm: DateTime.now(),
        );
        return e.copyWith(selfieRevisao: novoKyc);
      }).toList();
      state = state.copyWith(isSubmitting: false, entregadores: updated);
    } catch (e) {
      debugPrint('[EntregadoresAdm] revisarSelfie error: $e');
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: 'Erro ao revisar selfie. Verifique se a função '
            'revisar_selfie_entregador existe no banco.',
      );
    }
  }
}
