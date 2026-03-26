import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/entregador/entregas/controllers/entregas_disponiveis_controller.dart';
import 'package:padoca_express/features/entregador/entregas/data/entregas_disponiveis_repository.dart';
import 'package:padoca_express/features/entregador/entregas/models/pedido_disponivel_model.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MockEntregasDisponiveisRepository extends Mock
    implements EntregasDisponiveisRepository {}

class MockAuthRepository extends Mock implements AuthRepository {}
class MockUser extends Mock implements User {}

void main() {
  late EntregasDisponiveisController controller;
  late MockEntregasDisponiveisRepository mockRepo;
  late MockAuthRepository mockAuthObj;

  setUp(() {
    mockRepo = MockEntregasDisponiveisRepository();
    mockAuthObj = MockAuthRepository();
  });

  final fakePedido = PedidoDisponivelModel(
    id: 'pt-1',
    numero: 204,
    enderecoCliente: 'Rua A',
    clienteNome: 'João',
    nomeEstabelecimento: 'Padoca 1',
    enderecoEstabelecimento: 'Rua B',
    total: 50.0,
    taxaEntrega: 5.0,
    at: DateTime.now(),
  );

  test('carregarDisponiveis - sucesso', () async {
    when(() => mockRepo.buscarPedidosDisponiveis())
        .thenAnswer((_) async => [fakePedido]);

    controller = EntregasDisponiveisController(mockRepo, mockAuthObj);
    await Future.delayed(Duration.zero);

    expect(controller.state.isLoading, false);
    expect(controller.state.pedidos.length, 1);
    expect(controller.state.pedidos.first.id, 'pt-1');
  });

  test('aceitarEntrega - optimistic update e salvar', () async {
    when(() => mockRepo.buscarPedidosDisponiveis())
        .thenAnswer((_) async => [fakePedido]);
        
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthObj.currentUser).thenReturn(mockUser);
    when(() => mockAuthObj.getEntregadorId('user123'))
        .thenAnswer((_) async => 'entregador123');
    when(() => mockRepo.aceitarEntrega('pt-1', 'entregador123'))
        .thenAnswer((_) async {});

    controller = EntregasDisponiveisController(mockRepo, mockAuthObj);
    await Future.delayed(Duration.zero);

    final result = await controller.aceitarEntrega('pt-1');

    expect(result, true);
    expect(controller.state.pedidos.isEmpty, true);
    verify(() => mockRepo.aceitarEntrega('pt-1', 'entregador123')).called(1);
  });

  test('aceitarEntrega - rollback on failure', () async {
    when(() => mockRepo.buscarPedidosDisponiveis())
        .thenAnswer((_) async => [fakePedido]);
        
    final mockUser = MockUser();
    when(() => mockUser.id).thenReturn('user123');
    when(() => mockAuthObj.currentUser).thenReturn(mockUser);
    when(() => mockAuthObj.getEntregadorId('user123'))
        .thenAnswer((_) async => 'entregador123');
    when(() => mockRepo.aceitarEntrega('pt-1', 'entregador123'))
        .thenThrow(Exception('Falha no banco'));

    controller = EntregasDisponiveisController(mockRepo, mockAuthObj);
    await Future.delayed(Duration.zero);

    final result = await controller.aceitarEntrega('pt-1');

    expect(result, false);
    expect(controller.state.pedidos.length, 1);
    expect(controller.state.error, 'Erro ao aceitar pedido. Outro entregador pode ter aceito.');
  });
}
