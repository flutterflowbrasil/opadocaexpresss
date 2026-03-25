import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/auth/presentation/esqueceu_senha/esqueceu_senha_repository.dart';
import 'package:padoca_express/features/auth/presentation/esqueceu_senha/esqueceu_senha_controller.dart';
import 'package:padoca_express/features/auth/presentation/esqueceu_senha/esqueceu_senha_state.dart';

class MockEsqueceuSenhaRepository extends Mock implements EsqueceuSenhaRepository {}

void main() {
  late MockEsqueceuSenhaRepository mockRepository;
  late EsqueceuSenhaController controller;

  setUp(() {
    mockRepository = MockEsqueceuSenhaRepository();
    controller = EsqueceuSenhaController(mockRepository);
  });

  group('EsqueceuSenhaController', () {
    test('Estado inicial deve ser default (tudo no false/null)', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.emailSent, isFalse);
      expect(controller.state.error, isNull);
    });

    test('Envio com sucesso seta isLoading para true e depois false com emailSent true', () async {
      when(() => mockRepository.sendResetEmail(any())).thenAnswer((_) async => {});

      // O future roda, e não bloquearemos o flow manual do state tracker pra este caso basico,
      // usaremos delay ou await pra ver o estado final.
      final futureEnvio = controller.sendResetEmail('teste@teste.com');
      
      // Ironicamente Riverpod sincroniza state, logo logo apos chamar, 
      // ja devia ser isLoading true (mas testamos o final por simplicidade)
      expect(controller.state.isLoading, isTrue);

      await futureEnvio;

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.emailSent, isTrue);
      expect(controller.state.error, isNull);
      
      verify(() => mockRepository.sendResetEmail('teste@teste.com')).called(1);
    });

    test('Envio com erro de rede exibe mensagem padrao de erro', () async {
      when(() => mockRepository.sendResetEmail(any())).thenThrow(Exception('No internet'));

      await controller.sendResetEmail('teste@teste.com');

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.emailSent, isFalse);
      expect(controller.state.error, 'Ocorreu um erro ao enviar o e-mail. Tente novamente.');
    });

    test('Envio com erro de Autenticação Supabase exibe mensagem real da API', () async {
      when(() => mockRepository.sendResetEmail(any()))
          .thenThrow(const AuthException('Too many requests, try again later'));

      await controller.sendResetEmail('teste@teste.com');

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.emailSent, isFalse);
      expect(controller.state.error, 'Too many requests, try again later');
    });
  });
}
