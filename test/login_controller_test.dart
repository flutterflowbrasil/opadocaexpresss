import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/auth/presentation/login_controller.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/auth/domain/user_type.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';

// === MOCK REPOSITORY MANUAL ===
class MockAuthRepository implements AuthRepository {
  bool shouldFail = false;
  String mockRoute = '/home';

  @override
  Future<AuthResponse> signIn(
      {required String email, required String password}) async {
    if (shouldFail) {
      throw const AuthException('Invalid credentials');
    }
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
  Future<String> loginComGoogle() async => mockRoute;

  @override
  Future<String> validateSessionAndRoute() async => mockRoute;

  @override
  Future<String?> getUserType(String userId) async => 'cliente';

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
  Future<Map<String, dynamic>?> getMeuCadastroEntregador() async => null;

  @override
  Future<void> reenviarDocumentoEntregador({
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {}

  @override
  Future<Map<String, dynamic>?> getMeuCadastroEstabelecimento() async => null;

  @override
  Future<void> reenviarDocumentoEstabelecimento({
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {}

  @override
  Future<void> signUpEntregador({
    required String nome,
    required String telefone,
    required String cpf,
    required String dataNascimento,
    required String tipoVeiculo,
    required String placaVeiculo,
    required String modeloVeiculo,
    required String email,
    required String senha,
    required Map<String, dynamic> endereco,
    Uint8List? identidadeFrenteBytes,
    String? identidadeFrenteFileName,
    Uint8List? identidadeVersoBytes,
    String? identidadeVersoFileName,
    Uint8List? cnhFrenteBytes,
    String? cnhFrenteFileName,
    Uint8List? cnhVersoBytes,
    String? cnhVersoFileName,
    required Uint8List fotoPerfilBytes,
    required String fotoPerfilFileName,
  }) async {}

  @override
  Future<String?> getEstabelecimentoId(String userId) async => null;

  @override
  Future<String?> getEntregadorId(String userId) async => null;

  @override
  User? get currentUser => null;
}

void main() {
  test('Fluxo de login com sucesso: define success como true e pega userType',
      () async {
    final mockRepo = MockAuthRepository();
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    await container
        .read(loginControllerProvider.notifier)
        .login('teste@padoca.com', '123456');

    final state = container.read(loginControllerProvider);
    expect(state.isLoading, false);
    expect(state.success, true);
    expect(state.error, isNull);
    expect(state.userType, UserType.cliente);
  });

  test('Fluxo de login com falha: captura exception e emite state.error',
      () async {
    final mockRepo = MockAuthRepository()..shouldFail = true;
    final container = ProviderContainer(
      overrides: [authRepositoryProvider.overrideWithValue(mockRepo)],
    );
    addTearDown(container.dispose);

    await container
        .read(loginControllerProvider.notifier)
        .login('errado@padoca.com', 'wrongpassword');

    final state = container.read(loginControllerProvider);
    expect(state.isLoading, false);
    expect(state.success, false);
    expect(state.error, isNotNull);
  });
}
