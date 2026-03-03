import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/controllers/pedidos_kanban_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/data/pedidos_kanban_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/models/pedido_kanban_model.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/componentes_kanban/kanban_card.dart'; // KanbanStatus
import 'package:supabase_flutter/supabase_flutter.dart';

class MockPedidosKanbanRepository extends Mock
    implements PedidosKanbanRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late PedidosKanbanController controller;
  late MockPedidosKanbanRepository mockRepo;
  late MockAuthRepository mockAuth;

  setUp(() {
    mockRepo = MockPedidosKanbanRepository();
    mockAuth = MockAuthRepository();

    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user-123');
    when(() => mockAuth.currentUser).thenReturn(mockUser);
  });

  PedidoKanbanModel _criarPedidoMock(String id, String status) {
    return PedidoKanbanModel(
      id: id,
      numeroPedido: 1,
      status: status,
      total: 50.0,
      createdAt: DateTime.now(),
      cliente: const ClienteResumoModel(nome: 'Joao Mock'),
      itensResumo: '1x Teste',
    );
  }

  test('Deve inicializar separando os arrays por status corretamente',
      () async {
    // Arrange
    when(() => mockRepo.buscarPedidosAbertos(any())).thenAnswer((_) async => [
          _criarPedidoMock('1', 'pendente'),
          _criarPedidoMock('2', 'confirmado'),
          _criarPedidoMock('3', 'preparando'),
          _criarPedidoMock('4', 'pronto'),
          _criarPedidoMock('5', 'em_entrega'),
        ]);

    // Act
    controller = PedidosKanbanController(mockRepo, mockAuth);
    // Aguarda o microtask de carregarPedidos do constructor ser finalizado
    await Future.delayed(Duration.zero);

    // Assert
    final state = controller.state;
    expect(state.isLoading, isFalse);
    expect(state.recebidos.length, 2); // pendente e confirmado
    expect(state.emPreparo.length, 1);
    expect(state.prontos.length, 1);
    expect(state.emEntrega.length, 1);
  });

  test(
      'Alteração Otimista: Deve mover um pedido de "recebidos" para "emPreparo" imediatamente',
      () async {
    // Arrange
    when(() => mockRepo.buscarPedidosAbertos(any())).thenAnswer((_) async => [
          _criarPedidoMock('10', 'pendente'),
        ]);

    // Simula a request API demorando 1 seg sem dar erro para o mock
    when(() => mockRepo.atualizarStatus('10', 'preparando'))
        .thenAnswer((_) async => Future.delayed(const Duration(seconds: 1)));

    controller = PedidosKanbanController(mockRepo, mockAuth);
    await Future.delayed(Duration.zero);

    expect(controller.state.recebidos.length, 1);
    expect(controller.state.emPreparo.length, 0);

    // Act - Sem dar Await vamos forçar o optimistic check
    final futureApiCall =
        controller.alterarStatusPedido('10', KanbanStatus.preparo);

    // Assert 1: Optimistic Update bateu instantâneo em memória (State local muda antes da API)
    expect(controller.state.recebidos.length, 0); // Saiu daqui
    expect(controller.state.emPreparo.length, 1); // Entrou aqui
    expect(controller.state.emPreparo.first.id, '10');

    await futureApiCall;
  });

  test(
      'Alteração Otimista Error Rollback: Deve desfazer a movimentação se a API falhar',
      () async {
    // Arrange
    when(() => mockRepo.buscarPedidosAbertos(any())).thenAnswer((_) async => [
          _criarPedidoMock('20', 'pendente'),
        ]);

    // Simula API falhando
    when(() => mockRepo.atualizarStatus('20', 'preparando'))
        .thenThrow(Exception('Supabase connection lost'));

    controller = PedidosKanbanController(mockRepo, mockAuth);
    await Future.delayed(Duration.zero);

    // Act
    await controller.alterarStatusPedido('20', KanbanStatus.preparo);

    // Assert - Voltou para a origem
    expect(controller.state.recebidos.length, 1);
    expect(controller.state.emPreparo.length, 0);
    expect(controller.state.recebidos.first.id, '20');
    expect(controller.state.error, contains('Falha ao mover pedido'));
  });
}
