import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/dashboard_repository.dart';
import 'dashboard_state.dart';

final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>(
        (ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository, Supabase.instance.client);
});

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;
  final SupabaseClient _supabase;
  RealtimeChannel? _pedidosChannel;

  DashboardController(this._repository, this._supabase)
      : super(const DashboardState()) {
    loadDashboard();
  }

  @override
  void dispose() {
    _cancelarRealtime();
    super.dispose();
  }

  Future<void> loadDashboard() async {
    final userId = _supabase.auth.currentUser?.id;
    if (userId == null) {
      state =
          state.copyWith(error: 'Usuário não autenticado', isLoading: false);
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      // 1. Fetch Profile
      final profile = await _repository.fetchDriverProfile(userId);
      final driverId = profile['id'] as String;

      final usuarios = profile['usuarios'] as Map<String, dynamic>?;
      final nome = usuarios?['nome_completo_fantasia'] ?? 'Entregador';

      final isOnline = profile['status_online'] == true;
      final radius = (profile['raio_atuacao_km'] ?? 6).toDouble();

      // Parse avaliações
      final avaliacoes = profile['avaliacoes'] as List<dynamic>? ?? [];
      double ratingObj = 5.0;
      int totalRatings = 0;
      if (avaliacoes.isNotEmpty) {
        double sum = 0;
        int count = 0;
        for (var a in avaliacoes) {
          if (a['nota_entregador'] != null) {
            sum += (a['nota_entregador'] as num).toDouble();
            count++;
          }
        }
        if (count > 0) {
          ratingObj = sum / count;
          totalRatings = count;
        }
      }

      // 2. Fetch Earnings
      final earnings = await _repository.fetchEarnings(driverId);
      final pedidosHoje = earnings['pedidosHoje'] as List<dynamic>? ?? [];
      final pedidosSemana = earnings['pedidosSemana'] as List<dynamic>? ?? [];

      double ganhoHoje = pedidosHoje.fold(
          0.0, (s, p) => s + (p['entregador_valor_total'] as num? ?? 0.0));
      double ganhoSemana = pedidosSemana.fold(
          0.0, (s, p) => s + (p['entregador_valor_total'] as num? ?? 0.0));

      state = state.copyWith(
        isLoading: false,
        driverId: driverId,
        driverName: nome,
        vehicleType: _labelVeiculo(profile['tipo_veiculo']),
        isOnline: isOnline,
        searchRadius: radius,
        rating: ratingObj,
        totalRatings: totalRatings,
        todaysDeliveries: pedidosHoje.length,
        todaysEarnings: ganhoHoje,
        weeklyEarnings: ganhoSemana,
      );

      // Start Realtime se já estiver online na carga inicial
      if (isOnline) {
        _iniciarRealtimePedidos(driverId);
      }
    } catch (e) {
      state = state.copyWith(
          isLoading: false, error: 'Erro ao carregar dados do dashboard: $e');
    }
  }

  Future<void> toggleOnlineStatus() async {
    if (state.isTogglingStatus) return;

    final userId = _supabase.auth.currentUser?.id;
    if (userId == null || state.driverId.isEmpty) return;

    state = state.copyWith(isTogglingStatus: true, clearError: true);
    final novoStatus = !state.isOnline;

    try {
      await _repository.updateOnlineStatus(userId, novoStatus);

      if (novoStatus) {
        // Ignora erro de localização caso recuse perm, p/ não travar o app completamente
        try {
          await _repository.updateLocation(userId, state.driverId);
        } catch (_) {}

        _iniciarRealtimePedidos(state.driverId);
      } else {
        _cancelarRealtime();
      }

      state = state.copyWith(
        isOnline: novoStatus,
        isTogglingStatus: false,
      );
    } catch (e) {
      state = state.copyWith(
        isTogglingStatus: false,
        error: 'Erro ao mudar status: $e',
      );
    }
  }

  void _iniciarRealtimePedidos(String driverId) {
    _cancelarRealtime();
    _pedidosChannel = _supabase
        .channel('pedidos-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'despacho_pedidos',
          filter: PostgresChangeFilter(
              type: PostgresChangeFilterType.eq,
              column: 'entregador_id',
              value: driverId),
          callback: (payload) {
            // No cenário real usaríamos o go_router na view para navegar.
            // Para manter Controller purista, podemos disparar um evento (ex: usando eventBus ou ouvindo do widget com ref.listen)
            // Aqui guardamos no estado um "novoPedidoDespachadoID" ou algo similar se precisasse.
          },
        )
        .subscribe();
  }

  void _cancelarRealtime() {
    _pedidosChannel?.unsubscribe();
    _pedidosChannel = null;
  }

  String _labelVeiculo(String? tipo) {
    switch (tipo) {
      case 'moto':
        return 'Moto';
      case 'carro':
        return 'Carro';
      case 'bicicleta':
        return 'Bicicleta';
      case 'van':
        return 'Van';
      default:
        return 'Veículo';
    }
  }
}
