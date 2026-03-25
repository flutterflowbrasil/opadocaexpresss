import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mocktail/mocktail.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:padoca_express/features/cliente/localizacao/endereco_model.dart';
import 'package:padoca_express/features/cliente/localizacao/localizacao_controller.dart';
import 'package:padoca_express/features/cliente/localizacao/localizacao_repository.dart';
import 'package:padoca_express/features/cliente/localizacao/localizacao_state.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockLocalizacaoRepository extends Mock
    implements LocalizacaoRepository {}

// ── Dados de teste ────────────────────────────────────────────────────────────
final _enderecoFake = EnderecoCliente(
  id: 'uuid-123',
  clienteId: 'cliente-abc',
  cep: '01310100',
  logradouro: 'Avenida Paulista',
  numero: '1000',
  bairro: 'Bela Vista',
  cidade: 'São Paulo',
  estado: 'SP',
  latitude: -23.561,
  longitude: -46.655,
  isPadrao: false,
);

// ── Helper: cria container de teste com repository mockado ────────────────────
ProviderContainer _makeContainer(LocalizacaoRepository repo) {
  return ProviderContainer(
    overrides: [
      localizacaoRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

void main() {
  late MockLocalizacaoRepository mockRepo;

  setUpAll(() {
    registerFallbackValue(_enderecoFake);
  });

  setUp(() {
    mockRepo = MockLocalizacaoRepository();
  });

  group('LocalizacaoController — estado inicial', () {
    test('deve iniciar sem loading, sem erro e lista vazia', () {
      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final state = container.read(localizacaoControllerProvider);

      expect(state.isLoading, isFalse);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNull);
      expect(state.enderecos, isEmpty);
      expect(state.isEmpty, isTrue);
    });
  });

  group('LocalizacaoController — carregarEnderecos', () {
    test('deve atualizar lista no sucesso', () async {
      when(() => mockRepo.buscarEnderecos())
          .thenAnswer((_) async => [_enderecoFake]);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(localizacaoControllerProvider.notifier)
          .carregarEnderecos();

      final state = container.read(localizacaoControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.enderecos, hasLength(1));
      expect(state.enderecos.first.logradouro, equals('Avenida Paulista'));
      expect(state.error, isNull);
    });

    test('deve setar error no falha', () async {
      when(() => mockRepo.buscarEnderecos())
          .thenThrow(Exception('timeout'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(localizacaoControllerProvider.notifier)
          .carregarEnderecos();

      final state = container.read(localizacaoControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.enderecos, isEmpty);
      expect(state.error, isNotNull);
    });
  });

  group('LocalizacaoController — salvar', () {
    test('deve adicionar endereço ao estado no sucesso', () async {
      when(() => mockRepo.salvarEndereco(any()))
          .thenAnswer((_) async => _enderecoFake);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container
          .read(localizacaoControllerProvider.notifier)
          .salvar(_enderecoFake);

      final state = container.read(localizacaoControllerProvider);
      expect(result, isNotNull);
      expect(result!.id, equals('uuid-123'));
      expect(state.isSubmitting, isFalse);
      expect(state.enderecos, hasLength(1));
    });

    test('deve setar error quando salvarEndereco retorna null', () async {
      when(() => mockRepo.salvarEndereco(any()))
          .thenAnswer((_) async => null);

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container
          .read(localizacaoControllerProvider.notifier)
          .salvar(_enderecoFake);

      final state = container.read(localizacaoControllerProvider);
      expect(result, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNotNull);
    });

    test('deve setar error em caso de exceção', () async {
      when(() => mockRepo.salvarEndereco(any()))
          .thenThrow(Exception('network error'));

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      final result = await container
          .read(localizacaoControllerProvider.notifier)
          .salvar(_enderecoFake);

      final state = container.read(localizacaoControllerProvider);
      expect(result, isNull);
      expect(state.isSubmitting, isFalse);
      expect(state.error, isNotNull);
    });
  });

  group('LocalizacaoController — excluir', () {
    test('deve remover endereço do estado', () async {
      // Carrega um endereço primeiro
      when(() => mockRepo.buscarEnderecos())
          .thenAnswer((_) async => [_enderecoFake]);
      when(() => mockRepo.excluirEndereco(any()))
          .thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(localizacaoControllerProvider.notifier)
          .carregarEnderecos();

      expect(container.read(localizacaoControllerProvider).enderecos,
          hasLength(1));

      await container
          .read(localizacaoControllerProvider.notifier)
          .excluir('uuid-123');

      final state = container.read(localizacaoControllerProvider);
      expect(state.enderecos, isEmpty);
    });
  });

  group('LocalizacaoController — definirPadrao', () {
    test('deve marcar apenas o endereço selecionado como padrão', () async {
      final e1 = _enderecoFake.copyWith(id: 'id-1', isPadrao: false);
      final e2 = _enderecoFake.copyWith(id: 'id-2', isPadrao: false);

      when(() => mockRepo.buscarEnderecos())
          .thenAnswer((_) async => [e1, e2]);
      when(() => mockRepo.definirPadrao(any()))
          .thenAnswer((_) async {});

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(localizacaoControllerProvider.notifier)
          .carregarEnderecos();

      await container
          .read(localizacaoControllerProvider.notifier)
          .definirPadrao('id-2');

      final state = container.read(localizacaoControllerProvider);
      final padrao = state.enderecos.where((e) => e.isPadrao).toList();
      expect(padrao, hasLength(1));
      expect(padrao.first.id, equals('id-2'));
    });
  });

  group('LocalizacaoController — limparErro', () {
    test('deve limpar o error do estado', () async {
      when(() => mockRepo.buscarEnderecos()).thenThrow(Exception());

      final container = _makeContainer(mockRepo);
      addTearDown(container.dispose);

      await container
          .read(localizacaoControllerProvider.notifier)
          .carregarEnderecos();

      expect(container.read(localizacaoControllerProvider).error, isNotNull);

      container.read(localizacaoControllerProvider.notifier).limparErro();

      expect(
          container.read(localizacaoControllerProvider).error, isNull);
    });
  });

  group('LocalizacaoState — isEmpty getter', () {
    test('isEmpty = true quando não carregando, sem erro e sem endereços', () {
      const state = LocalizacaoState();
      expect(state.isEmpty, isTrue);
    });

    test('isEmpty = false quando isLoading = true', () {
      const state = LocalizacaoState(isLoading: true);
      expect(state.isEmpty, isFalse);
    });

    test('isEmpty = false quando há endereços', () {
      final state = LocalizacaoState(enderecos: [_enderecoFake]);
      expect(state.isEmpty, isFalse);
    });
  });
}
