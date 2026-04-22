import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/cliente/notificacoes/services/cliente_realtime_service.dart';
import 'package:padoca_express/services/notifications/app_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class AppNotificationModel {
  final String pedidoId;
  final String numeroPedido;
  final String status;
  final String title;
  final String body;
  final DateTime date;

  AppNotificationModel({
    required this.pedidoId,
    required this.numeroPedido,
    required this.status,
    required this.title,
    required this.body,
    required this.date,
  });
}

class NotificacoesController extends StateNotifier<List<AppNotificationModel>> {
  final ClienteRealtimeService _realtimeService;
  final AppNotificationService _notificationService;
  final AuthRepository _authRepository;
  
  bool _initialized = false;

  NotificacoesController(
    this._realtimeService,
    this._notificationService,
    this._authRepository,
  ) : super([]);

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    // Solicita permissão
    await _notificationService.init();
    await _notificationService.requestPermission();

    // Começa a escutar se o usuário for um cliente
    final currentUser = _authRepository.currentUser;
    if (currentUser != null) {
      // Idealmente deveríamos usar clienteId (da tabela clientes) e não userId (da tabela auth.users)
      // Porém, na arquitetura do app, normalmente o cliente é filtrado pela foreign key.
      // Vamos buscar o cliente_id deste usuário:
      try {
        final SupabaseClient supabase = Supabase.instance.client;
        final res = await supabase
            .from('clientes')
            .select('id')
            .eq('usuario_id', currentUser.id)
            .maybeSingle();
            
        if (res != null) {
          final clienteId = res['id'] as String;
          _realtimeService.startListening(clienteId, _addNotification);
        }
      } catch (e) {
        // Ignorar se não conseguir achar o cliente
      }
    }
  }

  void _addNotification(String pedidoId, String numeroPedido, String status, String title, String body) {
    final notification = AppNotificationModel(
      pedidoId: pedidoId,
      numeroPedido: numeroPedido,
      status: status,
      title: title,
      body: body,
      date: DateTime.now(),
    );
    state = [notification, ...state];
  }

  void removeNotification(String pedidoId) {
    state = state.where((n) => n.pedidoId != pedidoId).toList();
  }

  void clearAll() {
    state = [];
  }

  @override
  void dispose() {
    _realtimeService.stopListening();
    super.dispose();
  }
}

final notificacoesControllerProvider = StateNotifierProvider<NotificacoesController, List<AppNotificationModel>>((ref) {
  final realtimeService = ref.watch(clienteRealtimeServiceProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  final authRepository = ref.watch(authRepositoryProvider);
  return NotificacoesController(realtimeService, notificationService, authRepository);
});
