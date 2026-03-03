import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/pedidos/data/pedidos_cliente_repository.dart';
import 'package:padoca_express/features/cliente/pedidos/controllers/pedidos_cliente_controller.dart';
import 'package:padoca_express/features/cliente/pedidos/models/pedido_cliente_model.dart';
import 'package:gotrue/src/types/user.dart' as gotrue;

// Mocks
class MockRepository extends Mock implements PedidosClienteRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockGoTrueClient extends Mock implements GoTrueClient {}

class MockPostgrestQueryBuilder extends Mock implements SupabaseQueryBuilder {}

class MockPostgrestFilterBuilder extends Mock
    implements PostgrestFilterBuilder<List<Map<String, dynamic>>> {}

void main() {
  late MockRepository mockRepository;
  late MockSupabaseClient mockSupabase;
  late MockGoTrueClient mockAuth;

  setUp(() {
    mockRepository = MockRepository();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockGoTrueClient();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
  });

  group('PedidosClienteController ->', () {
    test('carregarPedidos - falha quando usuário não logado', () async {
      // Arrange
      when(() => mockAuth.currentUser).thenReturn(null);

      // Act
      final controller = PedidosClienteController(mockRepository, mockSupabase);
      await Future.delayed(Duration.zero);

      // Assert
      expect(controller.state.isLoading, false);
      expect(controller.state.error, 'Usuário não logado');
      expect(controller.state.pedidosAtivos, isEmpty);
      expect(controller.state.pedidosAnteriores, isEmpty);
    });

    test('carregarPedidos - separa corretamente pedidos ativos e anteriores',
        () async {
      // Arrange
      final fakeUser = gotrue.User(
        id: 'user_123',
        appMetadata: {},
        userMetadata: {},
        aud: '',
        createdAt: '',
      );

      when(() => mockAuth.currentUser).thenReturn(fakeUser);

      // Mock da requisição do ClienteId pelo Repositório
      when(() => mockRepository.getClienteId('user_123'))
          .thenAnswer((_) async => 'cliente_123');

      // Mock dos Pedidos do Banco
      final pedidosFake = [
        PedidoClienteModel(
          id: '1',
          status: 'preparando',
          total: 50.0,
          createdAt: DateTime.now(),
          itensJson: [],
        ),
        PedidoClienteModel(
          id: '2',
          status: 'entregue',
          total: 30.0,
          createdAt: DateTime.now(),
          itensJson: [],
        ),
        PedidoClienteModel(
          id: '3',
          status: 'cancelado_cliente',
          total: 20.0,
          createdAt: DateTime.now(),
          itensJson: [],
        ),
      ];

      when(() => mockRepository.getPedidosCliente('cliente_123'))
          .thenAnswer((_) async => pedidosFake);

      // Act
      final controller = PedidosClienteController(mockRepository, mockSupabase);
      await Future.delayed(Duration.zero);

      // Assert
      expect(controller.state.isLoading, false);
      expect(controller.state.error, isNull);

      // Deve ter 1 ativo (preparando)
      expect(controller.state.pedidosAtivos.length, 1);
      expect(controller.state.pedidosAtivos.first.id, '1');

      // Devem ter 2 anteriores (entregue, cancelado)
      expect(controller.state.pedidosAnteriores.length, 2);
    });
  });
}
