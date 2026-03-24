import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/financeiro/controllers/financeiro_adm_controller.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/financeiro/data/financeiro_adm_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/financeiro/models/financeiro_adm_models.dart';

// ── Mock ──────────────────────────────────────────────────────────────────────

class MockFinanceiroAdmRepository extends Mock
    implements FinanceiroAdmRepository {}

// ── Helpers ───────────────────────────────────────────────────────────────────

PedidoFinanceiro _pedido({
  String id = 'p01',
  String metodo = 'pix',
  String pgtoStatus = 'pago',
  String status = 'pronto',
  bool splitProcessado = false,
  double total = 55.90,
  double taxaServico = 2.55,
}) =>
    PedidoFinanceiro(
      id: id,
      numeroPedido: 1,
      status: status,
      pagamentoStatus: pgtoStatus,
      pagamentoMetodo: metodo,
      subtotalProdutos: 50.0,
      taxaEntrega: 5.0,
      taxaServico: taxaServico,
      descontoCupom: 0,
      total: total,
      splitProcessado: splitProcessado,
      createdAt: DateTime.now(),
    );

ProviderContainer _makeContainer(MockFinanceiroAdmRepository repo) {
  return ProviderContainer(
    overrides: [
      financeiroAdmRepositoryProvider.overrideWithValue(repo),
    ],
  );
}

// ── Testes ────────────────────────────────────────────────────────────────────

void main() {
  late MockFinanceiroAdmRepository repo;

  setUp(() {
    repo = MockFinanceiroAdmRepository();
  });

  group('FinanceiroAdmController —', () {
    test('estado inicial: isLoading = true, listas vazias', () {
      when(() => repo.buscarPedidos()).thenAnswer((_) async => []);
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      // Lê o estado ANTES do fetch completar
      final initial = container.read(financeiroAdmControllerProvider);
      expect(initial.isLoading, isTrue);
      expect(initial.pedidos, isEmpty);
      expect(initial.errorMessage, isNull);
    });

    test('fetch sucesso: carrega pedidos e limpa loading', () async {
      final pedidos = [_pedido(id: 'p01'), _pedido(id: 'p02')];
      when(() => repo.buscarPedidos()).thenAnswer((_) async => pedidos);
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      // Aguarda fetch completar
      await Future<void>.delayed(Duration.zero);

      final state = container.read(financeiroAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.pedidos.length, 2);
      expect(state.errorMessage, isNull);
      expect(state.lastSync, isNotNull);
    });

    test('fetch erro: seta errorMessage e limpa loading', () async {
      when(() => repo.buscarPedidos()).thenThrow(Exception('conexão falhou'));
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);

      await Future<void>.delayed(Duration.zero);

      final state = container.read(financeiroAdmControllerProvider);
      expect(state.isLoading, isFalse);
      expect(state.errorMessage, isNotNull);
      expect(state.pedidos, isEmpty);
    });

    test('setAba muda abaAtiva corretamente', () async {
      when(() => repo.buscarPedidos()).thenAnswer((_) async => []);
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(financeiroAdmControllerProvider).abaAtiva,
        'visao_geral',
      );

      container.read(financeiroAdmControllerProvider.notifier).setAba('pedidos');
      expect(
        container.read(financeiroAdmControllerProvider).abaAtiva,
        'pedidos',
      );
    });

    test('filtroMetodo filtra pedidos corretamente', () async {
      final pedidos = [
        _pedido(id: 'p01', metodo: 'pix'),
        _pedido(id: 'p02', metodo: 'cartao_credito'),
        _pedido(id: 'p03', metodo: 'pix'),
      ];
      when(() => repo.buscarPedidos()).thenAnswer((_) async => pedidos);
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      // Sem filtro: 3 pedidos
      expect(
        container.read(financeiroAdmControllerProvider).pedidosFiltrados.length,
        3,
      );

      // Filtra apenas pix: 2 pedidos
      container
          .read(financeiroAdmControllerProvider.notifier)
          .setFiltroMetodo('pix');
      expect(
        container.read(financeiroAdmControllerProvider).pedidosFiltrados.length,
        2,
      );

      // Filtra cartao_credito: 1 pedido
      container
          .read(financeiroAdmControllerProvider.notifier)
          .setFiltroMetodo('cartao_credito');
      expect(
        container.read(financeiroAdmControllerProvider).pedidosFiltrados.length,
        1,
      );
    });

    test('KPI splitsPendentes conta apenas pedidos pagos sem split', () async {
      final pedidos = [
        _pedido(id: 'p01', pgtoStatus: 'pago', splitProcessado: false),
        _pedido(id: 'p02', pgtoStatus: 'confirmed', splitProcessado: false),
        _pedido(id: 'p03', pgtoStatus: 'pago', splitProcessado: true),
        _pedido(id: 'p04', pgtoStatus: 'pendente', splitProcessado: false),
      ];
      when(() => repo.buscarPedidos()).thenAnswer((_) async => pedidos);
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      // p01 e p02: pagos sem split → 2
      expect(
        container.read(financeiroAdmControllerProvider).splitsPendentes,
        2,
      );
    });

    test('clearError limpa errorMessage', () async {
      when(() => repo.buscarPedidos()).thenThrow(Exception('erro'));
      when(() => repo.buscarSplits()).thenAnswer((_) async => []);
      when(() => repo.buscarSaques()).thenAnswer((_) async => []);
      when(() => repo.buscarSubcontas()).thenAnswer((_) async => []);

      final container = _makeContainer(repo);
      addTearDown(container.dispose);
      await Future<void>.delayed(Duration.zero);

      expect(
        container.read(financeiroAdmControllerProvider).errorMessage,
        isNotNull,
      );

      container.read(financeiroAdmControllerProvider.notifier).clearError();

      expect(
        container.read(financeiroAdmControllerProvider).errorMessage,
        isNull,
      );
    });
  });
}
