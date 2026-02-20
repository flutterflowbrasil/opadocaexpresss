import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final String? userType;
  final bool success;

  LoginState({
    this.isLoading = false,
    this.error,
    this.userType,
    this.success = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    String? userType,
    bool? success,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      userType: userType ?? this.userType,
      success: success ?? this.success,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;

  LoginController(this._authRepository) : super(LoginState());

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        final type = await _authRepository.getUserType(response.user!.id);
        if (!mounted) return;
        state = state.copyWith(isLoading: false, success: true, userType: type);
      } else {
        state = state.copyWith(isLoading: false, error: 'Erro ao fazer login');
      }
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: SupabaseErrorHandler.parseError(e),
      );
    }
  }
}

final loginControllerProvider =
    StateNotifierProvider<LoginController, LoginState>((ref) {
      final authRepository = ref.watch(authRepositoryProvider);
      return LoginController(authRepository);
    });
