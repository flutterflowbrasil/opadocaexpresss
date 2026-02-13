import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';

// Estado do formulário de cadastro
class CadastroClienteState {
  final bool isLoading;
  final String? error;
  final bool success;

  CadastroClienteState({
    this.isLoading = false,
    this.error,
    this.success = false,
  });

  CadastroClienteState copyWith({
    bool? isLoading,
    String? error,
    bool? success,
  }) {
    return CadastroClienteState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // Se não passar erro, limpa o anterior (se passar null)
      success: success ?? this.success,
    );
  }
}

class CadastroClienteController extends StateNotifier<CadastroClienteState> {
  final AuthRepository _authRepository;

  CadastroClienteController(this._authRepository)
    : super(CadastroClienteState());

  Future<void> cadastrar({
    required String nome,
    required String email,
    required String telefone,
    required String senha,
  }) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      await _authRepository.signUpCliente(
        email: email,
        password: senha,
        nome: nome,
        telefone: telefone,
      );
      state = state.copyWith(isLoading: false, success: true);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: SupabaseErrorHandler.parseError(e),
      );
    }
  }
}

final cadastroClienteControllerProvider =
    StateNotifierProvider<CadastroClienteController, CadastroClienteState>((
      ref,
    ) {
      final authRepository = ref.watch(authRepositoryProvider);
      return CadastroClienteController(authRepository);
    });
