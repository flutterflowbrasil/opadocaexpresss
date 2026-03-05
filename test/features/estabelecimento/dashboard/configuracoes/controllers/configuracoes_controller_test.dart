import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/configuracoes/controllers/configuracoes_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/configuracoes/models/estabelecimento_model.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/configuracoes/data/configuracoes_repository.dart';

class MockConfiguracoesRepository extends Mock
    implements ConfiguracoesRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

void main() {
  late MockConfiguracoesRepository mockRepository;
  late MockSupabaseClient mockSupabaseClient;
  late MockGoTrueClient mockAuth;

  final defaultEstabelecimento = EstabelecimentoModel(
    id: 'test_id',
    usuarioId: 'test_user_id',
    razaoSocial: 'Padoca Teste LTDA',
    nomeFantasia: 'Padoca Express',
    cnpj: '00.000.000/0001-00',
    telefoneComercial: '(11) 99999-9999',
    statusAberto: false,
    endereco: const EnderecoModel(
      cep: '00000-000',
      logradouro: 'Rua Teste',
      numero: '123',
      bairro: 'Centro',
      cidade: 'São Paulo',
      estado: 'SP',
    ),
    configEntrega: const ConfigEntregaModel(
      taxaPorKm: 1.5,
      pedidoMinimo: 10.0,
      raioMaximoKm: 5,
      gratisAcimaDe: 50.0,
      taxaEntregaFixa: 5.0,
      tempoMedioPreparoMin: 30,
    ),
    dadosBancarios: const DadosBancariosModel(
      banco: '001',
      agencia: '1234',
      conta: '123456',
      tipoConta: 'corrente',
      cpfCnpjTitular: 'teste@padoca.com',
      titular: 'Padoca Express',
    ),
    configAvancada: const ConfigAvancadaModel(
      aceitaAgendamento: false,
      tempoMaximoEntregaMin: 60,
      tempoMinimoEntregaMin: 30,
      intervaloAtualizacaoEstoqueMin: 5,
      tempoAntecedenciaAgendamentoMin: 60,
    ),
    horarioFuncionamento: {},
  );

  setUp(() {
    mockRepository = MockConfiguracoesRepository();
    mockSupabaseClient = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabaseClient.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(null);
  });

  group('ConfiguracoesController Tests', () {
    test('Deve carregar dados com sucesso se autenticado', () async {
      final mockUser = User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockRepository.getEstabelecimentoIdByUserId(mockUser.id))
          .thenAnswer((_) async => 'test_id');
      when(() => mockRepository.getEstabelecimento('test_id'))
          .thenAnswer((_) async => defaultEstabelecimento);

      // Ao invés de usar setUp que dá throw via auth null, recriamos aqui o scope.
      final newController =
          ConfiguracoesController(mockRepository, mockSupabaseClient);

      // Dá tempo as futures resolvidas no constructor
      await Future.delayed(Duration.zero);

      expect(newController.state.isLoading, isFalse);
      expect(newController.state.originalEstab?.id, equals('test_id'));
      expect(newController.state.originalEstab?.razaoSocial,
          equals('Padoca Teste LTDA'));
      expect(newController.state.editedEstab?.id, equals('test_id'));
      expect(newController.state.editedEstab?.razaoSocial,
          equals('Padoca Teste LTDA'));
      expect(newController.state.hasChanges, isFalse);
    });

    test('updateStatusAberto atualiza property localmente e ativa hasChanges',
        () async {
      // Mock Setup auth -> carregar
      final mockUser = User(
        id: 'test_user_id',
        appMetadata: {},
        userMetadata: {},
        aud: 'authenticated',
        createdAt: DateTime.now().toIso8601String(),
      );
      when(() => mockAuth.currentUser).thenReturn(mockUser);
      when(() => mockRepository.getEstabelecimentoIdByUserId(mockUser.id))
          .thenAnswer((_) async => 'test_id');
      when(() => mockRepository.getEstabelecimento('test_id'))
          .thenAnswer((_) async => defaultEstabelecimento);

      final newController =
          ConfiguracoesController(mockRepository, mockSupabaseClient);
      await Future.delayed(Duration.zero); // Load

      // Action
      newController.updateStatusAberto(true);

      // Assert
      expect(newController.state.editedEstab?.statusAberto, isTrue);
      expect(newController.state.hasChanges, isTrue);
    });
  });
}
