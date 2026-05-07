import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/estabs_adm_repository.dart';
import '../models/estab_adm_model.dart';
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
    } catch (_) {
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
      _ => throw ArgumentError('Acao invalida: $acao'),
    };

    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.atualizarStatus(estabId, novoStatus, motivo: motivo);
      final lista = await _repo.listarEstabelecimentos();
      state = state.copyWith(isSubmitting: false, estabelecimentos: lista);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  Future<void> revisarDocumento(
    String estabId,
    String tipo,
    String status, {
    String? motivo,
  }) async {
    state = state.copyWith(isSubmitting: true, clearError: true);
    try {
      await _repo.revisarDocumento(estabId, tipo, status, motivo: motivo);
      final updated = state.estabelecimentos.map((e) {
        if (e.id != estabId) return e;
        final docs = Map<String, String?>.from(e.docs);
        docs[tipo] = status;
        final documentos =
            Map<String, EstabDocumentoInfo>.from(e.documentosRevisao);
        final atual = documentos[tipo];
        if (atual != null) {
          documentos[tipo] = atual.copyWith(
            status: status,
            motivoRejeicao: motivo,
            validadoEm: DateTime.now(),
            clearMotivo: status == 'aprovado',
          );
        }
        return e.copyWith(docs: docs, documentosRevisao: documentos);
      }).toList();
      state = state.copyWith(isSubmitting: false, estabelecimentos: updated);
    } catch (e) {
      state = state.copyWith(
        isSubmitting: false,
        errorMessage: _friendlyError(e),
      );
    }
  }

  String _friendlyError(Object error) {
    final message = error.toString().replaceFirst('Exception: ', '').trim();
    if (message.isEmpty) {
      return 'Erro ao executar acao. Tente novamente.';
    }
    return message;
  }
}
