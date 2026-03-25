import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'esqueceu_senha_repository.dart';
import 'esqueceu_senha_state.dart';

final esqueceuSenhaControllerProvider = StateNotifierProvider.autoDispose<
    EsqueceuSenhaController, EsqueceuSenhaState>((ref) {
  final repository = ref.watch(esqueceuSenhaRepositoryProvider);
  return EsqueceuSenhaController(repository);
});

class EsqueceuSenhaController extends StateNotifier<EsqueceuSenhaState> {
  final EsqueceuSenhaRepository _repository;

  EsqueceuSenhaController(this._repository) : super(const EsqueceuSenhaState());

  Future<void> sendResetEmail(String email) async {
    if (email.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.sendResetEmail(email.trim());
      state = state.copyWith(isLoading: false, emailSent: true);
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains('security purposes') || msg.toLowerCase().contains('seconds')) {
        msg = 'Por segurança, aguarde alguns segundos antes de tentar novamente.';
      } else if (msg.toLowerCase().contains('not found')) {
        msg = 'Usuário não encontrado.';
      } else if (msg.toLowerCase().contains('rate limit')) {
        msg = 'Muitas tentativas. Tente novamente mais tarde.';
      }
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ocorreu um erro ao enviar o e-mail. Tente novamente.',
      );
    }
  }

  void resetarMensagemSucesso() {
    state = state.copyWith(emailSent: false, error: null);
  }
}
