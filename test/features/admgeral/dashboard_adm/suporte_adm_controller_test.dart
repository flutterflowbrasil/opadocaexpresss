import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/suporte/controllers/suporte_adm_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/suporte/data/suporte_adm_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/suporte/models/suporte_adm_models.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockSuporteAdmRepository extends Mock implements SuporteAdmRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

SupporteChamado _chamado({
  String id = 'c01',
  String status = 'aberto',
  String prioridade = 'normal',
  String? tipoSolicitante = 'cliente',
}) =>
    SupporteChamado(
      id: id,
      categoria: 'pagamento',
      descricao: 'Descrição do chamado',
      status: status,
      prioridade: prioridade,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
      tipoSolicitante: tipoSolicitante,
      solicitanteNome: 'Usuário Teste',
      solicitanteEmail: 'teste@email.com',
    );

NotificacaoFila _notif({
  String id = 'n01',
  String status = 'pendente',
  int tentativas = 3,
  int maxTentativas = 3,
}) =>
    NotificacaoFila(
      id: id,
      usuarioId: 'u01',
      evento: 'novo_pedido',
      titulo: 'Novo pedido',
      corpo: 'Pedido disponível',
      status: status,
      tentativas: tentativas,
      maxTentativas: maxTentativas,
      createdAt: DateTime.now(),
    );

ProviderContainer _makeContainer(MockSuporteAdmRepository repo) {
  return ProviderContainer(
    overrides: [
      suporteAdmRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late MockSuporteAdmRepository repo;

  setUp(() {
    repo = MockSuporteAdmRepository();
  });

  group('SuporteAdmController —', () {
    test('estado inicial: isLoading = true, listas vazias', () {
      when(() => repo.buscarChamados()).thenAnswer((_) async => []);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      final initial = container.read(suporteAdmControllerProvider);
      expect(initial.isLoading, isTrue);
      expect(initial.chamados, isEmpty);
      expect(initial.notificacoes, isEmpty);
      expect(initial.avaliacoes, isEmpty);
      expect(initial.errorMessage, isNull);
    });

    test('fetch sucesso: carrega todas as listas e limpa loading', () async {
      final chamados = [_chamado(id: 'c01'), _chamado(id: 'c02')];
      final notifs = [_notif(id: 'n01')];
      when(() => repo.buscarChamados()).thenAnswer((_) async => chamados);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => notifs);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(suporteAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.chamados.length, 2);
      expect(state.notificacoes.length, 1);
      expect(state.avaliacoes, isEmpty);
      expect(state.errorMessage, isNull);
      expect(state.lastSync, isNotNull);
    });

    test('fetch erro: seta errorMessage e limpa loading', () async {
      when(() => repo.buscarChamados())
          .thenThrow(Exception('conexão falhou'));
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(suporteAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.chamados, isEmpty);
    });

    test('setAba muda abaAtiva corretamente', () async {
      when(() => repo.buscarChamados()).thenAnswer((_) async => []);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(suporteAdmControllerProvider).abaAtiva,
        'chamados',
      );

      container
          .read(suporteAdmControllerProvider.notifier)
          .setAba('notificacoes');
      expect(
        container.read(suporteAdmControllerProvider).abaAtiva,
        'notificacoes',
      );
    });

    test('chamadosFiltrados filtra por status corretamente', () async {
      final chamados = [
        _chamado(id: 'c01', status: 'aberto'),
        _chamado(id: 'c02', status: 'resolvido'),
        _chamado(id: 'c03', status: 'aberto'),
      ];
      when(() => repo.buscarChamados()).thenAnswer((_) async => chamados);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      // Sem filtro: 3 chamados
      expect(
        container
            .read(suporteAdmControllerProvider)
            .chamadosFiltrados
            .length,
        3,
      );

      // Filtra abertos: 2
      container
          .read(suporteAdmControllerProvider.notifier)
          .setFiltroStatus('aberto');
      expect(
        container
            .read(suporteAdmControllerProvider)
            .chamadosFiltrados
            .length,
        2,
      );

      // Filtra resolvidos: 1
      container
          .read(suporteAdmControllerProvider.notifier)
          .setFiltroStatus('resolvido');
      expect(
        container
            .read(suporteAdmControllerProvider)
            .chamadosFiltrados
            .length,
        1,
      );
    });

    test('chamadosUrgentes KPI: conta apenas abertos com prioridade urgente',
        () async {
      final chamados = [
        _chamado(id: 'c01', status: 'aberto', prioridade: 'urgente'),
        _chamado(id: 'c02', status: 'aberto', prioridade: 'urgente'),
        _chamado(id: 'c03', status: 'resolvido', prioridade: 'urgente'),
        _chamado(id: 'c04', status: 'aberto', prioridade: 'normal'),
      ];
      when(() => repo.buscarChamados()).thenAnswer((_) async => chamados);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      // c01 e c02: abertos+urgente → 2
      expect(
        container.read(suporteAdmControllerProvider).chamadosUrgentes,
        2,
      );
    });

    test('notifsErro KPI: conta notifs com tentativas >= maxTentativas',
        () async {
      final notifs = [
        _notif(id: 'n01', tentativas: 3, maxTentativas: 3), // esgotado
        _notif(id: 'n02', tentativas: 2, maxTentativas: 3), // não esgotado
        _notif(id: 'n03', tentativas: 3, maxTentativas: 3), // esgotado
      ];
      when(() => repo.buscarChamados()).thenAnswer((_) async => []);
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => notifs);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(suporteAdmControllerProvider).notifsErro,
        2,
      );
    });

    test('clearError limpa errorMessage', () async {
      when(() => repo.buscarChamados()).thenThrow(Exception('erro'));
      when(() => repo.buscarNotificacoes()).thenAnswer((_) async => []);
      when(() => repo.buscarAvaliacoes()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(suporteAdmControllerProvider).errorMessage,
        isNotNull,
      );

      container.read(suporteAdmControllerProvider.notifier).clearError();

      expect(
        container.read(suporteAdmControllerProvider).errorMessage,
        isNull,
      );
    });
  });
}
