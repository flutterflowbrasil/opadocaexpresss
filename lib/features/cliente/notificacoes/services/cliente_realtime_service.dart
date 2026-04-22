import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/services/notifications/app_notification_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:developer';

class ClienteRealtimeService {
  final SupabaseClient _supabase;
  final AppNotificationService _notificationService;
  RealtimeChannel? _channel;

  // Cache do último status para evitar notificações duplicadas (caso o Supabase mande múltiplos eventos)
  final Map<String, String> _lastStatusMap = {};

  ClienteRealtimeService(this._supabase, this._notificationService);

  void startListening(String clienteId, void Function(String, String, String, String, String) onNewNotification) {
    if (_channel != null) return;

    log('Notificações: Iniciando escuta Realtime para cliente_id=$clienteId');

    _channel = _supabase
        .channel('public:pedidos:cliente_$clienteId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'cliente_id',
            value: clienteId,
          ),
          callback: (payload) {
            _handlePedidoUpdate(payload.newRecord, onNewNotification);
          },
        )
        .subscribe();
  }

  Future<void> _handlePedidoUpdate(Map<String, dynamic> record, void Function(String, String, String, String, String) onNewNotification) async {
    final status = record['status'] as String?;
    final pedidoId = record['id'] as String?;
    final numeroPedido = record['numero_pedido']?.toString() ?? 'Recente';

    if (status == null || pedidoId == null) return;

    final lastStatus = _lastStatusMap[pedidoId];
    if (lastStatus == status) return; // Evita notificação repetida
    
    _lastStatusMap[pedidoId] = status;

    if (status == 'pronto') {
      final title = 'Seu pedido está pronto!';
      final body = 'O pedido #$numeroPedido já está aguardando o entregador.';
      await _notificationService.show(
        title: title,
        body: body,
      );
      onNewNotification(pedidoId, numeroPedido, status, title, body);
    } else if (status == 'em_entrega') {
      final title = 'Pedido saiu para entrega!';
      final body = 'O entregador está a caminho com o seu pedido #$numeroPedido.';
      await _notificationService.show(
        title: title,
        body: body,
      );
      onNewNotification(pedidoId, numeroPedido, status, title, body);
    }
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
    _lastStatusMap.clear();
  }
}

final clienteRealtimeServiceProvider = Provider<ClienteRealtimeService>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  final notificationService = ref.watch(notificationServiceProvider);
  return ClienteRealtimeService(supabase, notificationService);
});
