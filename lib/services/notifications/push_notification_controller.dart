import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/services/notifications/onesignal_service.dart';
import 'package:padoca_express/services/notifications/push_device_registrar.dart';
import 'package:padoca_express/services/notifications/push_notification_repository.dart';

class PushNotificationState {
  final bool isReady;
  final String? pendingRoute;
  final String? pendingDespachoId;
  final String? error;

  const PushNotificationState({
    this.isReady = false,
    this.pendingRoute,
    this.pendingDespachoId,
    this.error,
  });

  PushNotificationState copyWith({
    bool? isReady,
    String? pendingRoute,
    String? pendingDespachoId,
    String? error,
    bool clearPendingRoute = false,
    bool clearPendingDespacho = false,
  }) {
    return PushNotificationState(
      isReady: isReady ?? this.isReady,
      pendingRoute: clearPendingRoute ? null : (pendingRoute ?? this.pendingRoute),
      pendingDespachoId: clearPendingDespacho
          ? null
          : (pendingDespachoId ?? this.pendingDespachoId),
      error: error,
    );
  }
}

class PushNotificationController extends StateNotifier<PushNotificationState> {
  PushNotificationController(this._authRepository, this._repository)
      : super(const PushNotificationState()) {
    _bindClickListener();
  }

  final AuthRepository _authRepository;
  final PushNotificationRepository _repository;
  bool _clickBound = false;

  Future<void> syncAfterAuth() => PushDeviceRegistrar.sync();

  Future<void> logout() => PushDeviceRegistrar.logout();

  Future<Map<String, dynamic>?> getUserPreferences(String usuarioId) {
    return _repository.getUserPreferences(usuarioId);
  }

  void clearPendingRoute() {
    state = state.copyWith(clearPendingRoute: true, clearPendingDespacho: true);
  }

  void clearPendingDespacho() {
    state = state.copyWith(clearPendingDespacho: true);
  }

  void _bindClickListener() {
    if (_clickBound) return;
    _clickBound = true;
    try {
      OneSignalService.bridge.addClickListener((data) {
        _handleClick(data);
      });
    } catch (e) {
      debugPrint('[PushNotificationController] click listener: $e');
    }
  }

  Future<void> _handleClick(Map<String, dynamic> data) async {
    try {
      final user = _authRepository.currentUser;
      if (user == null) return;
      final tipo = await _authRepository.getUserType(user.id);
      final pedidoId = data['pedido_id']?.toString();
      final despachoId = data['despacho_id']?.toString() ??
          data['entidade_id']?.toString();
      final route = routeFor(tipo, pedidoId, despachoId: despachoId);
      if (route == null && despachoId == null) return;
      state = state.copyWith(
        isReady: true,
        pendingRoute: route,
        pendingDespachoId: despachoId,
      );
    } catch (e) {
      debugPrint('[PushNotificationController] click: $e');
    }
  }

  @visibleForTesting
  static String? routeFor(String? tipo, String? pedidoId, {String? despachoId}) {
    switch (tipo) {
      case 'entregador':
        if (pedidoId != null && pedidoId.isNotEmpty) {
          return '/dashboard_entregador/entrega/$pedidoId';
        }
        if (despachoId != null && despachoId.isNotEmpty) {
          return '/dashboard_entregador';
        }
        return '/dashboard_entregador';
      case 'estabelecimento':
        return '/dashboard_estabelecimento/pedidos';
      case 'admin':
      case 'administrador':
        return '/admin/dashboard';
      default:
        if (pedidoId != null && pedidoId.isNotEmpty) {
          return '/cliente/pedido/$pedidoId';
        }
        if (despachoId != null && despachoId.isNotEmpty) {
          return '/home';
        }
        return '/home';
    }
  }
}

final pushNotificationControllerProvider =
    StateNotifierProvider<PushNotificationController, PushNotificationState>((ref) {
  return PushNotificationController(
    ref.watch(authRepositoryProvider),
    ref.watch(pushNotificationRepositoryProvider),
  );
});
