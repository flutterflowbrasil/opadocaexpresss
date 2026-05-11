import 'dart:async';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_notificacao_model.dart';
import '../repositories/admin_notificacoes_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AdminNotificacoesState {
  final bool isLoading;
  final List<AdminNotificacaoModel> alertas;
  final String? error;

  const AdminNotificacoesState({
    this.isLoading = false,
    this.alertas = const [],
    this.error,
  });

  AdminNotificacoesState copyWith({
    bool? isLoading,
    List<AdminNotificacaoModel>? alertas,
    String? error,
  }) {
    return AdminNotificacoesState(
      isLoading: isLoading ?? this.isLoading,
      alertas: alertas ?? this.alertas,
      error: error,
    );
  }

  /// Total de alertas urgentes + atenção para o badge
  int get totalCriticos => alertas
      .where((a) =>
          a.prioridade == AdminNotificacaoPrioridade.urgente ||
          a.prioridade == AdminNotificacaoPrioridade.atencao)
      .length;

  List<AdminNotificacaoModel> get urgentes =>
      alertas.where((a) => a.prioridade == AdminNotificacaoPrioridade.urgente).toList();

  List<AdminNotificacaoModel> get atencao =>
      alertas.where((a) => a.prioridade == AdminNotificacaoPrioridade.atencao).toList();

  List<AdminNotificacaoModel> get info =>
      alertas.where((a) => a.prioridade == AdminNotificacaoPrioridade.info).toList();
}

// ── Providers ─────────────────────────────────────────────────────────────────

final adminNotificacoesRepositoryProvider =
    Provider<AdminNotificacoesRepository>((ref) {
  return AdminNotificacoesRepository(Supabase.instance.client);
});

final adminNotificacoesControllerProvider = StateNotifierProvider
    .autoDispose<AdminNotificacoesController, AdminNotificacoesState>((ref) {
  final repo = ref.watch(adminNotificacoesRepositoryProvider);
  return AdminNotificacoesController(repo);
});

// ── Controller ────────────────────────────────────────────────────────────────

class AdminNotificacoesController
    extends StateNotifier<AdminNotificacoesState> {
  final AdminNotificacoesRepository _repository;
  Timer? _pollingTimer;

  AdminNotificacoesController(this._repository)
      : super(const AdminNotificacoesState()) {
    fetchAlertas();
    // Polling a cada 30 segundos
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchAlertas(silent: true),
    );
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAlertas({bool silent = false}) async {
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final alertas = await _repository.fetchAlertas();
      state = state.copyWith(isLoading: false, alertas: alertas);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar notificações: $e',
      );
    }
  }
}
