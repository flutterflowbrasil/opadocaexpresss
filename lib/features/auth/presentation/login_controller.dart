import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/auth/domain/user_type.dart';
import 'package:padoca_express/core/utils/supabase_error_handler.dart';

class LoginState {
  final bool isLoading;
  final String? error;
  final String? targetRoute; // rota vinda do banco
  final UserType? userType;  // derivado da rota, para UI (ícones, labels)
  final bool success;

  LoginState({
    this.isLoading = false,
    this.error,
    this.targetRoute,
    this.userType,
    this.success = false,
  });

  LoginState copyWith({
    bool? isLoading,
    String? error,
    String? targetRoute,
    UserType? userType,
    bool? success,
  }) {
    return LoginState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      targetRoute: targetRoute ?? this.targetRoute,
      userType: userType ?? this.userType,
      success: success ?? this.success,
    );
  }
}

class LoginController extends StateNotifier<LoginState> {
  final AuthRepository _authRepository;
  final Ref _ref;

  LoginController(this._authRepository, this._ref) : super(LoginState());

  Future<void> loginComGoogle() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final route = await _authRepository.loginComGoogle();
      if (!mounted) return;
      _ref.invalidate(sessionRouteProvider);
      state = state.copyWith(
        isLoading: false,
        success: true,
        targetRoute: route,
        userType: UserTypeX.fromRoute(route),
      );
    } catch (e) {
      if (!mounted) return;
      final code = e is Exception ? e.toString().replaceAll('Exception: ', '') : '';
      if (code == 'cancelado') {
        state = state.copyWith(isLoading: false);
        return;
      }
      state = state.copyWith(
        isLoading: false,
        error: SupabaseErrorHandler.parseError(e),
      );
    }
  }

  Future<void> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final response = await _authRepository.signIn(
        email: email,
        password: password,
      );

      if (!mounted) return;

      if (response.user != null) {
        final route = await _authRepository.validateSessionAndRoute();
        if (!mounted) return;
        // Invalida o cache para que o router use a rota atualizada
        _ref.invalidate(sessionRouteProvider);
        state = state.copyWith(
          isLoading: false,
          success: true,
          targetRoute: route,
          userType: UserTypeX.fromRoute(route),
        );
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
  return LoginController(authRepository, ref);
});
