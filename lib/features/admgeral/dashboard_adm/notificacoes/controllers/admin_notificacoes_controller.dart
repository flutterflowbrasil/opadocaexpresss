import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/admin_notificacao_model.dart';
import '../repositories/admin_notificacoes_repository.dart';

// ── State ─────────────────────────────────────────────────────────────────────

class AdminNotificacoesState {
  final bool isLoading;
  final List<AdminNotificacaoModel> alertas;
  final Set<String> dismissedIds;
  final String? error;

  const AdminNotificacoesState({
    this.isLoading = false,
    this.alertas = const [],
    this.dismissedIds = const {},
    this.error,
  });

  AdminNotificacoesState copyWith({
    bool? isLoading,
    List<AdminNotificacaoModel>? alertas,
    Set<String>? dismissedIds,
    String? error,
  }) {
    return AdminNotificacoesState(
      isLoading: isLoading ?? this.isLoading,
      alertas: alertas ?? this.alertas,
      dismissedIds: dismissedIds ?? this.dismissedIds,
      error: error,
    );
  }

  List<AdminNotificacaoModel> get alertasVisiveis =>
      alertas.where((a) => !dismissedIds.contains(a.id)).toList(growable: false);

  /// Total de alertas urgentes + atenção visíveis para o badge
  int get totalCriticos => alertasVisiveis
      .where((a) =>
          a.prioridade == AdminNotificacaoPrioridade.urgente ||
          a.prioridade == AdminNotificacaoPrioridade.atencao)
      .length;

  List<AdminNotificacaoModel> get urgentes => alertasVisiveis
      .where((a) => a.prioridade == AdminNotificacaoPrioridade.urgente)
      .toList(growable: false);

  List<AdminNotificacaoModel> get atencao => alertasVisiveis
      .where((a) => a.prioridade == AdminNotificacaoPrioridade.atencao)
      .toList(growable: false);

  List<AdminNotificacaoModel> get info => alertasVisiveis
      .where((a) => a.prioridade == AdminNotificacaoPrioridade.info)
      .toList(growable: false);
}

// ── Providers ─────────────────────────────────────────────────────────────────

final adminNotificacoesRepositoryProvider =
    Provider<AdminNotificacoesRepository>((ref) {
  return AdminNotificacoesRepository(Supabase.instance.client);
});

final adminNotificacoesControllerProvider = StateNotifierProvider
    .autoDispose<AdminNotificacoesController, AdminNotificacoesState>((ref) {
  ref.keepAlive();
  final repo = ref.watch(adminNotificacoesRepositoryProvider);
  return AdminNotificacoesController(repo);
});

// ── Controller ────────────────────────────────────────────────────────────────

class AdminNotificacoesController
    extends StateNotifier<AdminNotificacoesState> {
  static const _prefsPrefix = 'admin_notif_dismissed_';

  final AdminNotificacoesRepository _repository;
  Timer? _pollingTimer;
  bool _dismissLoaded = false;

  AdminNotificacoesController(this._repository)
      : super(const AdminNotificacoesState()) {
    unawaited(_loadDismissedIds());
    fetchAlertas();
    // Polling a cada 30 segundos
    _pollingTimer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => fetchAlertas(silent: true),
    );
  }

  String? get _adminUserId => Supabase.instance.client.auth.currentUser?.id;

  Future<void> _loadDismissedIds() async {
    final userId = _adminUserId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      final stored = prefs.getStringList('$_prefsPrefix$userId') ?? const [];
      if (!mounted) return;
      state = state.copyWith(dismissedIds: stored.toSet());
      _dismissLoaded = true;
    } catch (e) {
      debugPrint('[AdminNotificacoes] load dismissed erro: $e');
    }
  }

  Future<void> _persistDismissedIds(Set<String> ids) async {
    final userId = _adminUserId;
    if (userId == null) return;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setStringList('$_prefsPrefix$userId', ids.toList());
    } catch (e) {
      debugPrint('[AdminNotificacoes] persist dismissed erro: $e');
    }
  }

  /// Marca alerta como visto ao clicar — some da lista e do badge.
  Future<void> dismissAlerta(String id) async {
    if (state.dismissedIds.contains(id)) return;
    final updated = {...state.dismissedIds, id};
    state = state.copyWith(dismissedIds: updated);
    await _persistDismissedIds(updated);
  }

  @override
  void dispose() {
    _pollingTimer?.cancel();
    super.dispose();
  }

  Future<void> fetchAlertas({bool silent = false}) async {
    if (!_dismissLoaded && _adminUserId != null) {
      await _loadDismissedIds();
    }
    if (!silent) {
      state = state.copyWith(isLoading: true, error: null);
    }
    try {
      final alertas = await _repository.fetchAlertas();
      final freshIds = alertas.map((a) => a.id).toSet();
      // Remove dismiss de alertas que já não existem (pendência resolvida).
      final dismissed = state.dismissedIds.intersection(freshIds);
      if (dismissed.length != state.dismissedIds.length) {
        await _persistDismissedIds(dismissed);
      }
      state = state.copyWith(
        isLoading: false,
        alertas: alertas,
        dismissedIds: dismissed,
      );
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Erro ao carregar notificações: $e',
      );
    }
  }
}
