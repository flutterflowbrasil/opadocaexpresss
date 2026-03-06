import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/entregador/dashboard/data/dashboard_repository.dart';
import 'package:padoca_express/features/entregador/dashboard/presentation/controllers/dashboard_controller.dart';

class MockDashboardRepository extends Mock implements DashboardRepository {}

class MockSupabaseClient extends Mock implements SupabaseClient {}

class MockAuth extends Mock implements GoTrueClient {}

class MockUser extends Mock implements User {}

class MockRealtimeChannel extends Mock implements RealtimeChannel {}

void main() {
  setUpAll(() {
    registerFallbackValue(PostgresChangeEvent.insert);
  });

  late DashboardController controller;
  late MockDashboardRepository mockRepo;
  late MockSupabaseClient mockSupabase;
  late MockAuth mockAuth;
  late MockUser mockUser;
  late MockRealtimeChannel mockChannel;

  setUp(() {
    mockRepo = MockDashboardRepository();
    mockSupabase = MockSupabaseClient();
    mockAuth = MockAuth();
    mockUser = MockUser();
    mockChannel = MockRealtimeChannel();

    when(() => mockSupabase.auth).thenReturn(mockAuth);
    when(() => mockAuth.currentUser).thenReturn(mockUser);
    when(() => mockUser.id).thenReturn('user123');

    // Mocks for Realtime Channel
    when(() => mockSupabase.channel(any())).thenReturn(mockChannel);
    when(() => mockChannel.onPostgresChanges(
          event: any(named: 'event'),
          schema: any(named: 'schema'),
          table: any(named: 'table'),
          filter: any(named: 'filter'),
          callback: any(named: 'callback'),
        )).thenReturn(mockChannel);
    when(() => mockChannel.subscribe(any(), any())).thenReturn(mockChannel);
  });

  test(
      'loadDashboard updates state correctly with success profile and earnings',
      () async {
    // Arrange
    when(() => mockRepo.fetchDriverProfile('user123')).thenAnswer((_) async => {
          'id': 'entregador123',
          'status_online': true,
          'raio_atuacao_km': 10,
          'tipo_veiculo': 'moto',
          'usuarios': {'nome_completo_fantasia': 'João Entregador'},
          'avaliacoes': [
            {'nota_entregador': 5},
            {'nota_entregador': 4}
          ],
        });

    when(() => mockRepo.fetchEarnings('entregador123'))
        .thenAnswer((_) async => {
              'pedidosHoje': [
                {'entregador_valor_total': 15.0}
              ],
              'pedidosSemana': [
                {'entregador_valor_total': 15.0},
                {'entregador_valor_total': 10.0}
              ],
            });

    // Como o controller chama o loadDashboard no construtor, podemos instanciá-lo agora
    controller = DashboardController(mockRepo, mockSupabase);

    // Act
    // Precisamos aguardar o load eventuality que foi disparado no construtor
    await Future.delayed(const Duration(milliseconds: 100));

    // Assert
    final state = controller.state;
    expect(state.isLoading, false);
    expect(state.driverId, 'entregador123');
    expect(state.driverName, 'João Entregador');
    expect(state.vehicleType, 'Moto');
    expect(state.isOnline, true);
    expect(state.searchRadius, 10.0);
    expect(state.rating, 4.5); // (5+4)/2
    expect(state.totalRatings, 2);
    expect(state.todaysDeliveries, 1);
    expect(state.todaysEarnings, 15.0);
    expect(state.weeklyEarnings, 25.0);
    expect(state.error, isNull);
  });

  test('toggleOnlineStatus calls repository and updates state true/false',
      () async {
    // Arrange Initial state
    when(() => mockRepo.fetchDriverProfile(any())).thenAnswer((_) async => {
          'id': 'entregador123',
          'status_online': false,
          'raio_atuacao_km': 10,
          'tipo_veiculo': 'moto',
          'usuarios': {'nome_completo_fantasia': 'João Entregador'},
          'avaliacoes': [],
        });
    when(() => mockRepo.fetchEarnings(any())).thenAnswer((_) async => {
          'pedidosHoje': [],
          'pedidosSemana': [],
        });
    when(() => mockRepo.updateOnlineStatus(any(), any()))
        .thenAnswer((_) async {});
    when(() => mockRepo.updateLocation(any(), any())).thenAnswer((_) async {});

    controller = DashboardController(mockRepo, mockSupabase);
    await Future.delayed(const Duration(milliseconds: 100));
    expect(controller.state.isOnline, false);

    // Act
    await controller.toggleOnlineStatus();

    // Assert
    expect(controller.state.isOnline, true);
    verify(() => mockRepo.updateOnlineStatus('user123', true)).called(1);
    verify(() => mockRepo.updateLocation('user123', 'entregador123')).called(1);
  });
}
