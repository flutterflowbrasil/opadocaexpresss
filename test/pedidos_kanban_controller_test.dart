import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/controllers/pedidos_kanban_controller.dart';

import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/data/pedidos_kanban_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/models/pedido_kanban_model.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';

class MockPedidosKanbanRepository extends Mock
    implements PedidosKanbanRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}

class MockUser extends Mock implements User {}

void main() {
  late PedidosKanbanController controller;
  late MockPedidosKanbanRepository mockRepo;
  late MockAuthRepository mockAuthObj;

  setUp(() {
    mockRepo = MockPedidosKanbanRepository();
    mockAuthObj = MockAuthRepository();
  });

  final fakePedido = PedidoKanbanModel(
    id: 'pt-1',
    numero: 204,
    cliente: 'João',
    tel: '1199999',
    itens: const [],
    total: 50.0,
    tx: 5.0,
    pgto: 'pix',
    status: 'pendente',
    at: DateTime.now(),
    end: 'Rua A',
  );

  test('carregarPedidos - sucess - change state properly', () async {
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthObj.currentUser).thenReturn(mockUser);
    when(() => mockAuthObj.getEstabelecimentoId('user123'))
        .thenAnswer((_) async => 'estab123');
    when(() => mockRepo.buscarPedidosDia('estab123'))
        .thenAnswer((_) async => [fakePedido]);

    controller = PedidosKanbanController(mockRepo, mockAuthObj);
    // controller calls carregarPedidos in constructor so it runs async immediately.

    // allow async task to complete
    await Future.delayed(Duration.zero);

    expect(controller.state.isLoading, false);
    expect(controller.state.pedidos.length, 1);
    expect(controller.state.pedidos.first.status, 'pendente');
    expect(controller.state.totalAtivos, 1);
  });

  test('alterarStatusPedido updates otimisticamente and save', () async {
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthObj.currentUser).thenReturn(mockUser);
    when(() => mockAuthObj.getEstabelecimentoId('user123'))
        .thenAnswer((_) async => 'estab123');
    when(() => mockRepo.buscarPedidosDia('estab123'))
        .thenAnswer((_) async => [fakePedido]);
    when(() => mockRepo.atualizarStatus('pt-1', 'confirmado'))
        .thenAnswer((_) async {});

    controller = PedidosKanbanController(mockRepo, mockAuthObj);
    await Future.delayed(Duration.zero);

    // Act
    await controller.alterarStatusPedido('pt-1', 'confirmado');

    // Assert Optimistic Update
    expect(controller.state.pedidos.first.status, 'confirmado');
    verify(() => mockRepo.atualizarStatus('pt-1', 'confirmado')).called(1);
  });

  test('alterarStatusPedido rollbacks when fail', () async {
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthObj.currentUser).thenReturn(mockUser);
    when(() => mockAuthObj.getEstabelecimentoId('user123'))
        .thenAnswer((_) async => 'estab123');
    when(() => mockRepo.buscarPedidosDia('estab123'))
        .thenAnswer((_) async => [fakePedido]);
    when(() => mockRepo.atualizarStatus('pt-1', 'preparando'))
        .thenThrow(Exception('Falha Banco'));

    controller = PedidosKanbanController(mockRepo, mockAuthObj);
    await Future.delayed(Duration.zero);

    // Act
    await controller.alterarStatusPedido('pt-1', 'preparando');

    // Assert Rollback
    expect(controller.state.pedidos.first.status, 'pendente',
        reason: 'Deveria voltar o status em caso de exception');
    expect(controller.state.error, 'Falha ao mover pedido. Tente novamente.');
  });
}
