import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/auth/presentation/nova_senha/nova_senha_repository.dart';
import 'package:padoca_express/features/auth/presentation/nova_senha/nova_senha_controller.dart';
import 'package:padoca_express/features/auth/presentation/nova_senha/nova_senha_state.dart';

class MockNovaSenhaRepository extends Mock implements NovaSenhaRepository {}

void main() {
  late MockNovaSenhaRepository mockRepository;
  late NovaSenhaController controller;

  setUp(() {
    mockRepository = MockNovaSenhaRepository();
    controller = NovaSenhaController(mockRepository);
  });

  group('NovaSenhaController', () {
    test('Estado inicial deve ser default', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.sucesso, isFalse);
      expect(controller.state.error, isNull);
    });

    test('Não deve chamar repositório se a senha for vazia', () async {
      await controller.updatePassword('');
      
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.sucesso, isFalse);
      verifyNever(() => mockRepository.updatePassword(any()));
    });

    test('Sucesso na atualização seta o estado', () async {
      when(() => mockRepository.updatePassword(any())).thenAnswer((_) async => {});

      final futureUpdate = controller.updatePassword('SenhaForte123');
      expect(controller.state.isLoading, isTrue);

      await futureUpdate;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.sucesso, isTrue);
      expect(controller.state.error, isNull);
      
      verify(() => mockRepository.updatePassword('SenhaForte123')).called(1);
    });

    test('Falha na atualização de auth exibe mensagem da api', () async {
      when(() => mockRepository.updatePassword(any()))
          .thenThrow(const AuthException('Novo password fraco demais'));

      await controller.updatePassword('Valida8c');

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.sucesso, isFalse);
      expect(controller.state.error, 'Novo password fraco demais');
    });
  });
}
