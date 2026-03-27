import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
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
  RealtimeChannel? _despachoChannel;
  final AudioPlayer _audioPlayer = AudioPlayer();

  DashboardController(this._repository, this._supabase)
      : super(const DashboardState()) {
    loadDashboard();
  }

  @override
  void dispose() {
    _cancelarRealtime();
    _audioPlayer.dispose();
    super.dispose();
  }

  // ── Carga inicial ────────────────────────────────────────────────────────
  Future<void> loadDashboard() async {
    if (_supabase.auth.currentUser == null) {
      state = state.copyWith(
          isLoading: false, error: 'Usuário não autenticado');
      return;
    }

    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final profile = await _repository.fetchDriverProfile();
      final driverId = profile['id'] as String;
      final usuarios = profile['usuarios'] as Map<String, dynamic>?;
      final saldoData =
          profile['entregador_saldos'] as Map<String, dynamic>?;

      state = state.copyWith(
        driverId: driverId,
        driverName:
            usuarios?['nome_completo_fantasia'] as String? ?? 'Entregador',
        vehicleType: _labelVeiculo(profile['tipo_veiculo'] as String?),
        fotoPerfilUrl: profile['foto_perfil_url'] as String?,
        isOnline: profile['status_online'] == true,
        searchRadius:
            ((profile['raio_atuacao_km'] as num?) ?? 6).toDouble(),
        statusDespacho:
            profile['status_despacho'] as String? ?? 'livre',
        pedidoAtualId: profile['pedido_atual_id'] as String?,
        rating: ((profile['avaliacao_media'] as num?) ?? 5.0).toDouble(),
        totalRatings: (profile['total_avaliacoes'] as int?) ?? 0,
        totalEntregas: (profile['total_entregas'] as int?) ?? 0,
        saldoDisponivel:
            ((saldoData?['saldo_disponivel'] as num?) ?? 0.0).toDouble(),
        saldoBloqueado:
            ((saldoData?['saldo_bloqueado'] as num?) ?? 0.0).toDouble(),
      );

      // Carrega ganhos e entregas recentes em paralelo
      await Future.wait([
        _loadEarnings(),
        _loadRecentDeliveries(driverId),
      ]);

      // Se há pedido ativo, carrega os detalhes
      final pedidoId = profile['pedido_atual_id'] as String?;
      if (pedidoId != null) {
        await _loadActivePedido(pedidoId);
      }

      // Inicia realtime se online
      if (profile['status_online'] == true) {
        _iniciarRealtimeDespacho(driverId);
      }

      state = state.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('[DashboardController] loadDashboard error: $e');
      state = state.copyWith(
          isLoading: false,
          error: 'Erro ao carregar dados. Tente novamente.');
    }
  }

  // ── Ganhos ───────────────────────────────────────────────────────────────
  Future<void> _loadEarnings() async {
    try {
      final earnings = await _repository.fetchEarnings();
      final pedidosHoje =
          earnings['pedidosHoje'] as List<dynamic>? ?? [];
      final pedidosSemana =
          earnings['pedidosSemana'] as List<dynamic>? ?? [];

      double ganhoHoje = 0.0;
      for (final p in pedidosHoje) {
        final splits = p['splits_pagamento'] as Map<String, dynamic>?;
        if (splits != null) {
          ganhoHoje +=
              (splits['entregador_valor_total'] as num? ?? 0.0).toDouble();
        } else {
          ganhoHoje += (p['taxa_entrega'] as num? ?? 0.0).toDouble();
        }
      }

      double ganhoSemana = 0.0;
      for (final p in pedidosSemana) {
        final splits = p['splits_pagamento'] as Map<String, dynamic>?;
        if (splits != null) {
          ganhoSemana +=
              (splits['entregador_valor_total'] as num? ?? 0.0).toDouble();
        }
      }

      state = state.copyWith(
        todaysDeliveries: pedidosHoje.length,
        todaysEarnings: ganhoHoje,
        weeklyEarnings: ganhoSemana,
      );
    } catch (e) {
      debugPrint('[DashboardController] _loadEarnings error: $e');
    }
  }

  // ── Entregas recentes ────────────────────────────────────────────────────
  Future<void> _loadRecentDeliveries(String driverId) async {
    state = state.copyWith(isLoadingDeliveries: true);
    try {
      final raw = await _repository.fetchRecentDeliveries();
      final deliveries =
          raw.map((j) => EntregaRecente.fromJson(j)).toList();
      state = state.copyWith(
          recentDeliveries: deliveries, isLoadingDeliveries: false);
    } catch (e) {
      debugPrint('[DashboardController] _loadRecentDeliveries error: $e');
      state = state.copyWith(isLoadingDeliveries: false);
    }
  }

  // ── Pedido ativo ─────────────────────────────────────────────────────────
  Future<void> _loadActivePedido(String pedidoId) async {
    try {
      final data = await _repository.fetchActivePedido(pedidoId);
      if (data != null) {
        state = state.copyWith(pedidoAtivo: PedidoAtivo.fromJson(data));
      }
    } catch (e) {
      debugPrint('[DashboardController] _loadActivePedido error: $e');
    }
  }

  // ── Toggle online/offline ────────────────────────────────────────────────
  Future<void> toggleOnlineStatus() async {
    if (state.isTogglingStatus) return;
    state = state.copyWith(isTogglingStatus: true, clearError: true);

    final novoStatus = !state.isOnline;
    try {
      await _repository.updateOnlineStatus(novoStatus);

      if (novoStatus) {
        try {
          await _repository.updateLocation(state.driverId);
        } catch (_) {}
        _iniciarRealtimeDespacho(state.driverId);
      } else {
        _cancelarRealtime();
      }

      state = state.copyWith(isOnline: novoStatus, isTogglingStatus: false);
    } catch (e) {
      debugPrint('[DashboardController] toggleOnlineStatus error: $e');
      state = state.copyWith(
          isTogglingStatus: false, error: 'Erro ao mudar status.');
    }
  }

  // ── Aceitar despacho ─────────────────────────────────────────────────────
  Future<void> aceitarDespacho() async {
    final despacho = state.despachoRecebido;
    if (despacho == null || state.isRespondingDespacho) return;

    state = state.copyWith(isRespondingDespacho: true, clearError: true);
    try {
      await _repository.aceitarDespacho(despacho.id);
      await _loadActivePedido(despacho.pedidoId);
      state = state.copyWith(
        isRespondingDespacho: false,
        clearDespacho: true,
        statusDespacho: 'em_pedido',
        pedidoAtualId: despacho.pedidoId,
      );
    } catch (e) {
      debugPrint('[DashboardController] aceitarDespacho error: $e');
      state = state.copyWith(
          isRespondingDespacho: false,
          clearDespacho: true, // Limpa para próximo despacho poder exibir o modal
          error: 'Erro ao aceitar pedido. Tente novamente.');
    }
  }

  // ── Rejeitar despacho ────────────────────────────────────────────────────
  Future<void> rejeitarDespacho() async {
    final despacho = state.despachoRecebido;
    if (despacho == null || state.isRespondingDespacho) return;

    state = state.copyWith(isRespondingDespacho: true, clearError: true);
    try {
      await _repository.rejeitarDespacho(despacho.id,
          motivo: 'Recusado pelo entregador');
      state = state.copyWith(
        isRespondingDespacho: false,
        clearDespacho: true,
        statusDespacho: 'livre',
      );
    } catch (e) {
      debugPrint('[DashboardController] rejeitarDespacho error: $e');
      state =
          state.copyWith(isRespondingDespacho: false, clearDespacho: true);
    }
  }

  // ── Confirmar entrega ────────────────────────────────────────────────────
  Future<void> confirmarEntrega() async {
    final pedidoId = state.pedidoAtualId;
    if (pedidoId == null) return;

    try {
      await _repository.confirmarEntrega(pedidoId);
      // Triggers disparam automaticamente: libera entregador, atualiza ganhos
      await Future.wait([
        _loadEarnings(),
        _loadRecentDeliveries(state.driverId),
      ]);
      // Recarrega perfil para saldo atualizado
      final profile = await _repository.fetchDriverProfile();
      final saldoData =
          profile['entregador_saldos'] as Map<String, dynamic>?;
      state = state.copyWith(
        statusDespacho: 'livre',
        clearPedidoAtualId: true,
        clearPedidoAtivo: true,
        totalEntregas: (profile['total_entregas'] as int?) ?? state.totalEntregas,
        saldoDisponivel:
            ((saldoData?['saldo_disponivel'] as num?) ?? state.saldoDisponivel)
                .toDouble(),
      );
    } catch (e) {
      debugPrint('[DashboardController] confirmarEntrega error: $e');
      state = state.copyWith(error: 'Erro ao confirmar entrega.');
    }
  }

  // ── Realtime: aguarda despachos ──────────────────────────────────────────
  void _iniciarRealtimeDespacho(String driverId) {
    _cancelarRealtime();
    _despachoChannel = _supabase
        .channel('despacho-$driverId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'despacho_pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'entregador_id',
            value: driverId,
          ),
          callback: (payload) async {
            final record = payload.newRecord;
            if (record['status'] != 'aguardando') { return; }

            final despachoId = record['id'] as String?;
            final pedidoId = record['pedido_id'] as String?;
            final distancia =
                (record['distancia_km'] as num?)?.toDouble() ?? 0.0;
            final expiraEm = record['expira_em'] != null
                ? DateTime.tryParse(record['expira_em'] as String)
                : null;

            if (despachoId == null || pedidoId == null || expiraEm == null) {
              return;
            }

            // Busca taxa da entrega para exibir ao entregador
            double valorEntrega = 0.0;
            try {
              final pedido =
                  await _repository.fetchPedidoTaxaEntrega(pedidoId);
              valorEntrega =
                  (pedido?['taxa_entrega'] as num?)?.toDouble() ?? 0.0;
            } catch (_) {}

            if (!mounted) { return; }

            // Alerta sonoro ao receber novo pedido
            try {
              await _audioPlayer.stop();
              await _audioPlayer.play(
                AssetSource('sons/notificacoes_entregador.wav'),
              );
            } catch (e) {
              debugPrint('[DashboardController] audio error: $e');
            }

            state = state.copyWith(
              statusDespacho: 'aguardando_aceite',
              despachoRecebido: DespachoRecebido(
                id: despachoId,
                pedidoId: pedidoId,
                distanciaKm: distancia,
                valorEntrega: valorEntrega,
                expiraEm: expiraEm,
              ),
            );
          },
        )
        .subscribe();
  }

  void _cancelarRealtime() {
    _despachoChannel?.unsubscribe();
    _despachoChannel = null;
  }

  // ── Helpers ──────────────────────────────────────────────────────────────
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
