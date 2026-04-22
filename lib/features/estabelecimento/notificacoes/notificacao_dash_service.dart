// lib/features/estabelecimento/notificacoes/notificacao_dash_service.dart
//
// Escuta eventos INSERT na tabela `pedidos` via Supabase Realtime,
// limitado ao estabelecimento logado.  Web-only.

import 'dart:developer';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'notificacao_dash_model.dart';
import 'notificacao_dash_controller.dart';

class NotificacaoDashService {
  final Ref _ref;
  final SupabaseClient _supabase;
  RealtimeChannel? _channel;

  NotificacaoDashService(this._ref, this._supabase);

  void startListening(String estabelecimentoId) {
    if (_channel != null) return;

    log('[NotifDash] Iniciando escuta Realtime para estab=$estabelecimentoId');

    _channel = _supabase
        .channel('dash-notif-$estabelecimentoId')
        .onPostgresChanges(
          event: PostgresChangeEvent.insert,
          schema: 'public',
          table: 'pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'estabelecimento_id',
            value: estabelecimentoId,
          ),
          callback: (payload) {
            _handleNovoPedido(payload.newRecord);
          },
        )
        .subscribe();
  }

  void stopListening() {
    _channel?.unsubscribe();
    _channel = null;
  }

  void _handleNovoPedido(Map<String, dynamic> record) {
    final pedidoId = record['id'] as String? ?? '';
    final numeroPedido = record['numero_pedido']?.toString() ?? '';
    final clienteNome = record['cliente_nome'] as String? ?? 'Cliente';

    log('[NotifDash] Novo pedido recebido: #$numeroPedido');

    final notif = NotificacaoDashModel(
      id: 'pedido-$pedidoId-${DateTime.now().millisecondsSinceEpoch}',
      tipo: NotifTipo.novoPedido,
      titulo: '🛒 Novo Pedido #$numeroPedido',
      mensagem: '$clienteNome acabou de fazer um pedido!',
      pedidoId: pedidoId,
      numeroPedido: numeroPedido,
    );

    _ref.read(notificacaoDashProvider.notifier).adicionarNotificacao(notif);
  }
}

final notificacaoDashServiceProvider = Provider<NotificacaoDashService>((ref) {
  final supabase = Supabase.instance.client;
  return NotificacaoDashService(ref, supabase);
});
