import 'package:flutter/foundation.dart';
import '../models/pedido_kanban_model.dart';
import '../componentes_kanban/kanban_card.dart'; // Para acessar KanbanStatus

@immutable
class PedidosKanbanState {
  final bool isLoading;
  final String? error;

  final List<PedidoKanbanModel> recebidos; // pendente, confirmado
  final List<PedidoKanbanModel> emPreparo; // preparando
  final List<PedidoKanbanModel> prontos; // pronto
  final List<PedidoKanbanModel> emEntrega; // em_entrega

  const PedidosKanbanState({
    this.isLoading = false,
    this.error,
    this.recebidos = const [],
    this.emPreparo = const [],
    this.prontos = const [],
    this.emEntrega = const [],
  });

  PedidosKanbanState copyWith({
    bool? isLoading,
    String? error,
    List<PedidoKanbanModel>? recebidos,
    List<PedidoKanbanModel>? emPreparo,
    List<PedidoKanbanModel>? prontos,
    List<PedidoKanbanModel>? emEntrega,
  }) {
    return PedidosKanbanState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Limpar erro ao iniciar/sucesso passando null no factory copyWith error:null
      recebidos: recebidos ?? this.recebidos,
      emPreparo: emPreparo ?? this.emPreparo,
      prontos: prontos ?? this.prontos,
      emEntrega: emEntrega ?? this.emEntrega,
    );
  }

  // Helper function to map from App DB Status string to KanbanStatus enum
  static KanbanStatus stringToKanbanEnum(String status) {
    if (status == 'pendente' || status == 'confirmado') {
      return KanbanStatus.recebido;
    } else if (status == 'preparando') {
      return KanbanStatus.preparo;
    } else if (status == 'pronto') {
      return KanbanStatus.pronto;
    } else if (status == 'em_entrega') {
      return KanbanStatus.entrega;
    }
    return KanbanStatus.recebido; // Default Fallback
  }

  // Helper map from KanbanStatus to Supabase App DB Status string
  static String kanbanEnumToString(KanbanStatus status) {
    switch (status) {
      case KanbanStatus.recebido:
        return 'pendente'; // Move for pending/confirming
      case KanbanStatus.preparo:
        return 'preparando';
      case KanbanStatus.pronto:
        return 'pronto';
      case KanbanStatus.entrega:
        return 'em_entrega';
    }
  }
}
