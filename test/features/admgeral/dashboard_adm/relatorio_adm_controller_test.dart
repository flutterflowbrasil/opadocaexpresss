import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/relatorios/controllers/relatorio_adm_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/relatorios/data/relatorio_adm_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/relatorios/models/relatorio_adm_model.dart';

// ── Mocks ─────────────────────────────────────────────────────────────────────
class MockRelatorioAdmRepository extends Mock
    implements RelatorioAdmRepository {}

// ── Helper builders ───────────────────────────────────────────────────────────
RelatorioSnapshot _buildSnapshot({
  int pedidosCount = 0,
  int usuariosCount = 0,
  int entregadoresCount = 0,
}) {
  final now = DateTime.now();
  return RelatorioSnapshot(
    pedidos: List.generate(
      pedidosCount,
      (i) => PedidoResumo(
        id: 'ped_$i',
        status: i % 3 == 0 ? 'entregue' : (i % 3 == 1 ? 'cancelado_cliente' : 'pendente'),
        pagamentoStatus: i % 3 == 0 ? 'pago' : null,
        pagamentoMetodo: 'pix',
        total: 50.0,
        taxaServicApp: 2.5,
        createdAt: now.subtract(Duration(days: i)),
      ),
    ),
    usuarios: List.generate(
      usuariosCount,
      (i) => UsuarioResumo(
        id: 'usr_$i',
        tipoUsuario: i % 2 == 0 ? 'cliente' : 'entregador',
        status: 'ativo',
        createdAt: now.subtract(Duration(days: i)),
      ),
    ),
    entregadores: List.generate(
      entregadoresCount,
      (i) => EntregadorResumo(
        id: 'ent_$i',
        statusCadastro: 'aprovado',
        totalEntregas: i * 10,
        ganhosTotal: i * 100.0,
        statusOnline: i % 2 == 0,
      ),
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
void main() {
  late MockRelatorioAdmRepository mockRepo;

  setUp(() {
    mockRepo = MockRelatorioAdmRepository();
  });

  ProviderContainer _makeContainer() {
    final container = ProviderContainer(
      overrides: [
        relatorioAdmRepositoryProvider.overrideWithValue(mockRepo),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  // ── Estado inicial ──────────────────────────────────────────────────────────
  group('Estado inicial', () {
    test('começa com isLoading=true e periodo="12m"', () {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenAnswer((_) async => _buildSnapshot());

      final container = _makeContainer();
      final state = container.read(relatorioAdmControllerProvider);

      expect(state.isLoading, isTrue);
      expect(state.periodo, '12m');
      expect(state.abaAtiva, 'visao_geral');
      expect(state.snapshot, isNull);
    });
  });

  // ── Fetch com sucesso ───────────────────────────────────────────────────────
  group('fetch()', () {
    test('popula snapshot após fetch bem-sucedido', () async {
      final snap = _buildSnapshot(pedidosCount: 10, usuariosCount: 5);
      when(() => mockRepo.fetchSnapshot(any())).thenAnswer((_) async => snap);

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});

      await pumpEventQueue();

      final state = container.read(relatorioAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.snapshot, isNotNull);
      expect(state.snapshot!.pedidos.length, 10);
      expect(state.snapshot!.usuarios.length, 5);
      expect(state.lastSync, isNotNull);
      expect(state.errorMessage, isNull);
    });

    test('define errorMessage quando fetch lança exceção', () async {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenThrow(Exception('Falha de conexão'));

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});

      await pumpEventQueue();

      final state = container.read(relatorioAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.snapshot, isNull);
    });
  });

  // ── setPeriodo ──────────────────────────────────────────────────────────────
  group('setPeriodo()', () {
    test('altera o período e refaz o fetch', () async {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenAnswer((_) async => _buildSnapshot());

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});
      await pumpEventQueue();

      await container
          .read(relatorioAdmControllerProvider.notifier)
          .setPeriodo('7d');

      final state = container.read(relatorioAdmControllerProvider);
      expect(state.periodo, '7d');
      verify(() => mockRepo.fetchSnapshot('7d')).called(1);
    });

    test('calls fetchSnapshot com "30d" quando setPeriodo("30d")', () async {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenAnswer((_) async => _buildSnapshot());

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});
      await pumpEventQueue();

      await container
          .read(relatorioAdmControllerProvider.notifier)
          .setPeriodo('30d');

      verify(() => mockRepo.fetchSnapshot('30d')).called(1);
    });
  });

  // ── setAba ──────────────────────────────────────────────────────────────────
  group('setAba()', () {
    test('muda abaAtiva sem refazer fetch', () async {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenAnswer((_) async => _buildSnapshot());

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});
      await pumpEventQueue();

      container.read(relatorioAdmControllerProvider.notifier).setAba('financeiro');

      final state = container.read(relatorioAdmControllerProvider);
      expect(state.abaAtiva, 'financeiro');
      // fetch só foi chamado 1 vez (no init), não 2x
      verify(() => mockRepo.fetchSnapshot(any())).called(1);
    });

    test('setAba para todas as 5 abas válidas', () async {
      when(() => mockRepo.fetchSnapshot(any()))
          .thenAnswer((_) async => _buildSnapshot());

      final container = _makeContainer();
      container.listen(relatorioAdmControllerProvider, (_, __) {});
      await pumpEventQueue();

      for (final aba in ['visao_geral', 'financeiro', 'operacional', 'usuarios', 'qualidade']) {
        container.read(relatorioAdmControllerProvider.notifier).setAba(aba);
        expect(container.read(relatorioAdmControllerProvider).abaAtiva, aba);
      }
    });
  });

  // ── KPIs do model ──────────────────────────────────────────────────────────
  group('RelatorioSnapshot KPIs', () {
    test('receitaTotal soma total dos pedidos entregues', () {
      final snap = _buildSnapshot(pedidosCount: 6);
      // 6 pedidos: posições 0,3 com status='entregue', outros não
      final entregues = snap.pedidos.where((p) => p.status == 'entregue').length;
      expect(snap.receitaTotal, entregues * 50.0);
    });

    test('taxaCancelamento calcula corretamente', () {
      final snap = _buildSnapshot(pedidosCount: 9);
      // 1/3 são cancelados: índices 1,4,7
      expect(snap.taxaCancelamento, closeTo(33.3, 0.1));
    });

    test('ticketMedio é 0 quando não há pedidos entregues', () {
      final snap = _buildSnapshot(pedidosCount: 0);
      expect(snap.ticketMedio, 0);
    });

    test('funil tem 4 etapas e começa em 100%', () {
      final snap = _buildSnapshot(pedidosCount: 10);
      expect(snap.funil.length, 4);
      expect(snap.funil.first['pct'], 100);
    });

    test('entregadoresOnline conta corretamente', () {
      final snap = _buildSnapshot(entregadoresCount: 4);
      // statusOnline = i % 2 == 0: índices 0,2 → 2 online
      expect(snap.entregadoresOnline, 2);
    });
  });
}
