import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/data/admin_dashboard_repository.dart';
import 'package:padoca_express/features/admgeral/dashboard_adm/presentation/controllers/admin_dashboard_controller.dart';

class MockAdminDashboardRepository extends Mock implements AdminDashboardRepository {}

void main() {
  late MockAdminDashboardRepository mockRepository;

  setUpAll(() {
    registerFallbackValue(DashboardPeriod.mes);
  });

  setUp(() {
    mockRepository = MockAdminDashboardRepository();
  });

  test('Deve inicializar o estado com dados reais do repositório', () async {
    final mockData = {
      'estabelecimentos': [
        {'id': '1', 'status_cadastro': 'aprovado', 'status_aberto': true, 'avaliacao_media': 4.8},
        {'id': '2', 'status_cadastro': 'pendente', 'status_aberto': false, 'avaliacao_media': null},
      ],
      'entregadores': [
        {'id': '1', 'status_cadastro': 'aprovado', 'status_online': true},
        {'id': '2', 'status_cadastro': 'pendente', 'status_online': false},
        {'id': '3', 'status_cadastro': 'aprovado', 'status_online': false},
      ],
      'usuarios': [
        {'id': '1', 'tipo_usuario': 'cliente'},
        {'id': '2', 'tipo_usuario': 'cliente'},
        {'id': '3', 'tipo_usuario': 'admin'},
      ],
      'pedidos': [
        {'id': '1', 'status': 'entregue', 'total': 150.0, 'created_at': DateTime.now().toIso8601String()},
        {'id': '2', 'status': 'pendente', 'total': 50.0, 'created_at': DateTime.now().subtract(const Duration(days: 2)).toIso8601String()},
      ],
      'splits': [
        {'plataforma_valor': 7.5, 'status': 'pago'},
      ],
      'chamados': [
        {'id': '1', 'status': 'aberto'},
        {'id': '2', 'status': 'aberto'},
      ],
    };

    when(() => mockRepository.fetchDashboardStats(any())).thenAnswer((_) async => mockData);

    // Instancia o controller diretamente (sem Riverpod) para evitar acesso a Supabase.instance
    final controller = AdminDashboardController(mockRepository);

    // Aguarda o fetchData disparado no construtor
    await Future.delayed(const Duration(milliseconds: 200));

    expect(controller.state.isLoading, false);
    expect(controller.state.hasError, false);

    expect(controller.state.totalEstab, 2);
    expect(controller.state.estabAtivos, 1);
    expect(controller.state.estabPendentesCount, 1);

    expect(controller.state.totalEntregadores, 3);
    expect(controller.state.entregOnline, 1);
    expect(controller.state.entregPendentesCount, 1);

    expect(controller.state.totalUsuarios, 3);
    expect(controller.state.totalClientes, 2);

    expect(controller.state.totalPedidos, 2);
    expect(controller.state.pedidosConcluidos, 1);

    expect(controller.state.receitaBruta, 150.0);
    expect(controller.state.receitaPlataforma, 7.5);

    expect(controller.state.chamadosAbertosCount, 2);
    // Estab1 = 4.8, Estab2 = 0.0 → média 2.4
    expect(controller.state.avaliacaoMedia, 2.4);

    controller.dispose();
  });

  test('Deve lidar com erros do repositório corretamente', () async {
    when(() => mockRepository.fetchDashboardStats(any()))
        .thenThrow(Exception('Erro no servidor'));

    final controller = AdminDashboardController(mockRepository);
    await Future.delayed(const Duration(milliseconds: 200));

    expect(controller.state.isLoading, false);
    expect(controller.state.hasError, true);
    expect(controller.state.errorMessage, isNotNull);
    expect(controller.state.errorMessage!, contains('Não foi possível'));

    controller.dispose();
  });
}
