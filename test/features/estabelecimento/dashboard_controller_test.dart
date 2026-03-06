import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/components/period_filter_bar.dart';

// Mocks
class MockDashboardRepository extends Mock implements DashboardRepository {}

void main() {
  late MockDashboardRepository mockRepository;
  late DashboardController controller;

  setUp(() {
    mockRepository = MockDashboardRepository();

    // Comportamento base do repository para não quebrar no init()
    when(() => mockRepository.getEstabelecimentoLogado())
        .thenAnswer((_) async => {
              'id': 'teste-estab',
              'nome_fantasia': 'Padoca Teste',
              'is_aberto': true,
              'avaliacao_media': 4.8,
            });

    when(() => mockRepository.getDashboardMetrics(any(), any(), any()))
        .thenAnswer((_) async => {
              'vendasTotal': 1500.0,
              'pedidosAtivos': 3,
              'ticketMedio': 50.0,
              'totalPedidos': 30,
              'pendentes': 1,
              'confirmados': 2,
              'preparando': 3,
              'prontos': 4,
              'emEntrega': 5,
              'entregues': 15,
              'ranking': <Map<String, dynamic>>[],
              'clientesUnicos': 20,
              'clientesNovos': 15,
              'clientesRecorrentes': 5,
              'deltaVendas': 12.5,
              'deltaPedidos': 5,
              'deltaTicket': -2.0,
            });
  });

  group('DashboardController Unit Tests -', () {
    test('Inicialização carrega estabelecimento e métricas corretamente',
        () async {
      controller = DashboardController(mockRepository);

      // Espera as operações microtasks concluírem
      await Future.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.error, isNull);
      expect(controller.state.estabelecimentoId, 'teste-estab');
      expect(controller.state.estabelecimentoNome, 'Padoca Teste');
      expect(controller.state.vendasTotal, 1500.0);
      expect(controller.state.entregues, 15);
      expect(controller.state.periodoAtual, DashboardPeriodo.hoje);

      // New assertions for KPIs and recurrent clients
      expect(controller.state.clientesNovos, 15);
      expect(controller.state.clientesRecorrentes, 5);
      expect(controller.state.deltaVendas, 12.5);
      expect(controller.state.deltaPedidos, 5);
      expect(controller.state.deltaTicket, -2.0);
    });

    test('Erro no login lança mensagem de erro', () async {
      when(() => mockRepository.getEstabelecimentoLogado())
          .thenAnswer((_) async => null);

      controller = DashboardController(mockRepository);
      await Future.delayed(Duration.zero);

      expect(controller.state.error, 'Estabelecimento não logado.');
      expect(controller.state.isLoading, isFalse);
    });

    test('Mudar período atualiza o filtro e dispara recarregamento', () async {
      controller = DashboardController(mockRepository);
      await Future.delayed(Duration.zero);

      // Limpa as chamadas de init
      clearInteractions(mockRepository);

      when(() => mockRepository.getDashboardMetrics(any(), any(), any()))
          .thenAnswer((_) async => {
                'vendasTotal': 5000.0,
                'pedidosAtivos': 10,
                'ticketMedio': 45.0,
                'totalPedidos': 110,
                'pendentes': 0,
                'confirmados': 0,
                'preparando': 0,
                'prontos': 0,
                'emEntrega': 0,
                'entregues': 100,
                'ranking': <Map<String, dynamic>>[],
                'clientesUnicos': 80,
                'clientesNovos': 50,
                'clientesRecorrentes': 30,
                'deltaVendas': 50.0,
                'deltaPedidos': 10,
                'deltaTicket': 5.0,
              });

      controller.mudarPeriodo(DashboardPeriodo.semana, null);

      // Logo após mudar, o status é de loading
      expect(controller.state.isLoading, isTrue);
      expect(controller.state.periodoAtual, DashboardPeriodo.semana);

      // Esperamos os dados resolverem
      await Future.delayed(Duration.zero);

      expect(controller.state.isLoading, isFalse);
      expect(controller.state.vendasTotal, 5000.0);

      // Verifica se repositório foi chamado com as datas corretamente computadas
      verify(() => mockRepository.getDashboardMetrics(any(), any(), any()))
          .called(1);
    });
  });
}
