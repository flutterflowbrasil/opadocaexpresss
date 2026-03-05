import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/auth/presentation/login_controller.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';

// === MOCK REPOSITORY MANUAL ===
class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String mockUserType = 'cliente';

  @override
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    if (shouldFail) {
      throw const AuthException('Invalid credentials');
    }
    // Return a fake user response
    return AuthResponse(
      session: Session(
        accessToken: 'mock_token',
        tokenType: 'bearer',
        user: User(
          id: 'test_user_id',
          appMetadata: {},
          userMetadata: {},
          aud: 'authenticated',
          createdAt: DateTime.now().toIso8601String(),
        ),
      ),
      user: User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      ),
    );
  }

  @override
  Future<String?> getUserType(String userId) async {
    return mockUserType;
  }

  @override
  Future<Map<String, dynamic>?> getProfile(String userId) async => null;

  @override
  Future<void> signOut() async {}

  @override
  Future<void> signUpCliente(
      {required String email,
      required String password,
      required String nome,
      required String telefone}) async {}

  @override
  Future<void> signUpEstabelecimento(
      {required CadastroEstabelecimentoState dadosCadastro,
      required dynamic storageService}) async {}

  @override
  Future<String?> getEstabelecimentoId(String userId) async => null;

  @override
  User? get currentUser => null;
}

void main() {
  test('Fluxo de login com sucesso: define success como true e pega userType',
      () async {
    final mockRepo = MockAuthRepository();
    final controller = LoginController(mockRepo);

    expect(controller.state.isLoading, false);

    // Dispara o login
    await controller.login('teste@padoca.com', '123456');

    final state = controller.state;
    expect(state.isLoading, false);
    expect(state.success, true);
    expect(state.error, isNull);
    expect(state.userType, 'cliente');
  });

  test('Fluxo de login com falha: captura exception e emite state.error',
      () async {
    final mockRepo = MockAuthRepository()..shouldFail = true;
    final controller = LoginController(mockRepo);

    await controller.login('errado@padoca.com', 'wrongpassword');

    final state = controller.state;
    expect(state.isLoading, false);
    expect(state.success, false);
    expect(state.error, isNotNull);
  });
}
