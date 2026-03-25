import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/configuracoes/controllers/config_adm_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/configuracoes/data/config_adm_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/configuracoes/models/config_adm_models.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockConfigAdmRepository extends Mock implements ConfigAdmRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

ConfigItem _item({
  String id = 'id01',
  String secao = 'financeiro',
  String chave = 'split_estabelecimento_pct',
  String valor = '85',
  String tipo = 'number',
  String label = 'Estabelecimento recebe',
  bool editavel = true,
}) =>
    ConfigItem(
      id: id,
      secao: secao,
      chave: chave,
      valor: valor,
      tipo: tipo,
      label: label,
      editavel: editavel,
      updatedAt: DateTime(2026, 3, 1),
    );

ProviderContainer _makeContainer(MockConfigAdmRepository repo) {
  return ProviderContainer(
    overrides: [
      configAdmRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late MockConfigAdmRepository repo;

  setUp(() {
    repo = MockConfigAdmRepository();
  });

  // 1. Estado inicial
  test('estado inicial: isLoading=true, configs vazio, modificacoes vazio', () {
    when(() => repo.buscarConfigs()).thenAnswer((_) async => []);
    final container = _makeContainer(repo);
    addTearDown(container.dispose);

    final state = container.read(configAdmControllerProvider);
    expect(state.isLoading, isTrue);
    expect(state.configs, isEmpty);
    expect(state.modificacoes, isEmpty);
  });

  // 2. fetch sucesso
  test('fetch sucesso: carrega configs e isLoading=false', () async {
    final items = [
      _item(chave: 'split_estabelecimento_pct', valor: '85'),
      _item(id: 'id02', chave: 'split_plataforma_pct', valor: '5'),
    ];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    final state = container.read(configAdmControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.configs.length, 2);
    expect(state.errorMessage, isNull);
  });

  // 3. fetch erro
  test('fetch erro: errorMessage preenchido, isLoading=false', () async {
    when(() => repo.buscarConfigs()).thenThrow(Exception('connection error'));

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    final state = container.read(configAdmControllerProvider);
    expect(state.isLoading, isFalse);
    expect(state.errorMessage, isNotNull);
    expect(state.configs, isEmpty);
  });

  // 4. setValor com campo editável
  test('setValor em campo editavel: entra em modificacoes', () async {
    final items = [_item(chave: 'split_estabelecimento_pct', valor: '85')];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    container.read(configAdmControllerProvider.notifier)
        .setValor('split_estabelecimento_pct', '80');

    final state = container.read(configAdmControllerProvider);
    expect(state.modificacoes['split_estabelecimento_pct'], '80');
    expect(state.temModificacoes, isTrue);
  });

  // 5. setValor em campo não editável → ignorado
  test('setValor em campo editavel=false: ignorado', () async {
    final items = [
      _item(chave: 'campo_readonly', valor: 'original', editavel: false),
    ];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    container.read(configAdmControllerProvider.notifier)
        .setValor('campo_readonly', 'novo_valor');

    final state = container.read(configAdmControllerProvider);
    expect(state.modificacoes.containsKey('campo_readonly'), isFalse);
    expect(state.temModificacoes, isFalse);
  });

  // 6. setValor com valor igual ao original → desfaz
  test('setValor igual ao original: remove de modificacoes', () async {
    final items = [_item(chave: 'split_estabelecimento_pct', valor: '85')];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    final notifier = container.read(configAdmControllerProvider.notifier);
    notifier.setValor('split_estabelecimento_pct', '80'); // modifica
    notifier.setValor('split_estabelecimento_pct', '85'); // desfaz

    final state = container.read(configAdmControllerProvider);
    expect(state.modificacoes.containsKey('split_estabelecimento_pct'), isFalse);
    expect(state.temModificacoes, isFalse);
  });

  // 7. descartarModificacoes
  test('descartarModificacoes: limpa mapa sem chamar backend', () async {
    final items = [_item(chave: 'split_estabelecimento_pct', valor: '85')];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    final notifier = container.read(configAdmControllerProvider.notifier);
    notifier.setValor('split_estabelecimento_pct', '80');
    expect(container.read(configAdmControllerProvider).temModificacoes, isTrue);

    notifier.descartarModificacoes();

    final state = container.read(configAdmControllerProvider);
    expect(state.modificacoes, isEmpty);
    expect(state.temModificacoes, isFalse);
    // Backend não deve ser chamado
    verifyNever(() => repo.salvarModificacoes(
          modificacoes: any(named: 'modificacoes'),
          adminId: any(named: 'adminId'),
        ));
  });

  // 8. modificacoesSensiveis
  test('modificacoesSensiveis: true quando chave sensível está modificada', () async {
    final items = [
      _item(chave: 'modo_manutencao', valor: 'false', secao: 'sistema'),
      _item(id: 'id02', chave: 'taxa_entrega_fixa_padrao', valor: '5',
          secao: 'entrega'),
    ];
    when(() => repo.buscarConfigs()).thenAnswer((_) async => items);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    final notifier = container.read(configAdmControllerProvider.notifier);

    // Modifica campo NÃO sensível → modificacoesSensiveis = false
    notifier.setValor('taxa_entrega_fixa_padrao', '6');
    expect(container.read(configAdmControllerProvider).modificacoesSensiveis,
        isFalse);

    // Modifica campo sensível → modificacoesSensiveis = true
    notifier.setValor('modo_manutencao', 'true');
    expect(container.read(configAdmControllerProvider).modificacoesSensiveis,
        isTrue);
  });

  // 9. setAba muda abaSelecionada
  test('setAba: muda abaSelecionada corretamente', () async {
    when(() => repo.buscarConfigs()).thenAnswer((_) async => []);

    final container = _makeContainer(repo);
    addTearDown(container.dispose);

    container.read(configAdmControllerProvider.notifier).setAba('sistema');

    expect(container.read(configAdmControllerProvider).abaSelecionada, 'sistema');
  });

  // 10. clearError
  test('clearError: limpa errorMessage', () async {
    when(() => repo.buscarConfigs()).thenThrow(Exception('error'));

    final container = _makeContainer(repo);
    addTearDown(container.dispose);
    await container.read(configAdmControllerProvider.notifier).fetch();

    expect(container.read(configAdmControllerProvider).errorMessage, isNotNull);

    container.read(configAdmControllerProvider.notifier).clearError();

    expect(container.read(configAdmControllerProvider).errorMessage, isNull);
  });
}
