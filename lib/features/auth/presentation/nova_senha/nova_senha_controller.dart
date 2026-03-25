import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'nova_senha_repository.dart';
import 'nova_senha_state.dart';

final novaSenhaControllerProvider = StateNotifierProvider.autoDispose<
    NovaSenhaController, NovaSenhaState>((ref) {
  final repository = ref.watch(novaSenhaRepositoryProvider);
  return NovaSenhaController(repository);
});

class NovaSenhaController extends StateNotifier<NovaSenhaState> {
  final NovaSenhaRepository _repository;

  NovaSenhaController(this._repository) : super(const NovaSenhaState());

  Future<void> updatePassword(String novaSenha) async {
    if (novaSenha.isEmpty) return;

    state = state.copyWith(isLoading: true, error: null);

    try {
      await _repository.updatePassword(novaSenha.trim());
      state = state.copyWith(isLoading: false, sucesso: true);
    } on AuthException catch (e) {
      String msg = e.message;
      if (msg.toLowerCase().contains('session missing') || msg.toLowerCase().contains('unauthorized')) {
        msg = 'Sessão inválida ou expirada. Solicite um novo link de recuperação.';
      } else if (msg.toLowerCase().contains('password')) {
        msg = 'Ocorreu um erro ao definir a senha. Tente outra.';
      }
      state = state.copyWith(isLoading: false, error: msg);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Ocorreu um erro ao atualizar a senha. Tente novamente.',
      );
    }
  }
}
