import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/estabelecimento/financeiro/data/financeiro_repository.dart';
import 'package:padoca_express/features/estabelecimento/financeiro/financeiro_controller.dart';
import 'package:padoca_express/features/estabelecimento/financeiro/models/financeiro_models.dart';

class MockFinanceiroRepository extends Mock implements FinanceiroRepository {}

void main() {
  late FinanceiroController controller;
  late MockFinanceiroRepository mockRepository;

  setUp(() {
    mockRepository = MockFinanceiroRepository();
    controller = FinanceiroController(mockRepository);
  });

  group('FinanceiroController - Testes de Regra de Negócio', () {
    final estab = EstabelecimentoFinanceiro(
      id: 'estab-123',
      nomeFantasia: 'Padaria Fictícia',
      faturamentoTotal: 5000.0,
      totalPedidos: 100,
    );

    final pedidosMockados = [
      PedidoFinanceiro(
        id: '1',
        numeroPedido: '001',
        status: 'entregue',
        total: 100.0,
        subtotalProdutos: 90.0,
        taxaEntrega: 10.0,
        taxaServicoApp: 5.0,
        descontoCupom: 0.0,
        pagamentoMetodo: 'pix',
        createdAt: DateTime.now(),
      ),
      PedidoFinanceiro(
        id: '2',
        numeroPedido: '002',
        status: 'entregue',
        total: 50.0,
        subtotalProdutos: 40.0,
        taxaEntrega: 10.0,
        taxaServicoApp: 2.0,
        descontoCupom: 5.0,
        pagamentoMetodo: 'cartao_credito',
        createdAt: DateTime.now(),
      ),
      PedidoFinanceiro(
        id: '3',
        numeroPedido: '003',
        status: 'cancelado',
        total: 200.0,
        subtotalProdutos: 180.0,
        taxaEntrega: 20.0,
        taxaServicoApp: 10.0,
        descontoCupom: 0.0,
        pagamentoMetodo: 'pix',
        createdAt: DateTime.now(),
      ),
    ];

    test('Deve iniciar o controller sem dados e isLoading falso', () {
      expect(controller.state.isLoading, isFalse);
      expect(controller.state.estabelecimento, isNull);
    });

    test('carregarDadosIniciais() com sucesso', () async {
      when(() => mockRepository.buscarEstabelecimento())
          .thenAnswer((_) async => estab);
      when(() => mockRepository.buscarPedidosPeriodo(any(), any(), any()))
          .thenAnswer((_) async => pedidosMockados);
      when(() => mockRepository.buscarSplitsPeriodo(any(), any(), any()))
          .thenAnswer((_) async => []);

      await controller.carregarDadosIniciais();

      expect(controller.state.error, isNull);
      expect(controller.state.estabelecimento, estab);
      expect(controller.state.pedidos, pedidosMockados);

      // Validação das lógicas de negócio dos Getters:

      // 1. Faturamento bruto: Apenas pedidos "entregues" (100.0 + 50.0 = 150.0)
      expect(controller.state.faturamentoBruto, 150.0);

      // 2. Taxa de cancelamento: (1 cancelado / 3 pedidos total) = 33.33%
      expect(controller.state.taxaCancelamento.toStringAsFixed(2), '33.33');

      // 3. Ticket médio entregues: 150.0 / 2 = 75.0
      expect(controller.state.ticketMedio, 75.0);
    });

    test('carregarDadosIniciais() quando estabelecimento é null', () async {
      when(() => mockRepository.buscarEstabelecimento())
          .thenAnswer((_) async => null);

      await controller.carregarDadosIniciais();

      expect(controller.state.error, 'Estabelecimento não encontrado.');
      expect(controller.state.isLoading, isFalse);
    });

    test('carregarDadosIniciais() lidando com erros/exceptions', () async {
      when(() => mockRepository.buscarEstabelecimento())
          .thenThrow(Exception('Falha de Rede'));

      await controller.carregarDadosIniciais();

      print('DEBUG ERROR MESSAGE: ${controller.state.error}');

      expect(controller.state.error?.contains('Falha de Rede'), isTrue);
      expect(controller.state.isLoading, isFalse);
    });
  });
}
