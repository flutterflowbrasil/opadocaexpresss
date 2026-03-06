import 'package:flutter/foundation.dart';
import '../models/pedido_kanban_model.dart';

@immutable
class PedidosKanbanState {
  final bool isLoading;
  final String? error;
  final List<PedidoKanbanModel> pedidos;

  const PedidosKanbanState({
    this.isLoading = false,
    this.error,
    this.pedidos = const [],
  });

  PedidosKanbanState copyWith({
    bool? isLoading,
    String? error,
    List<PedidoKanbanModel>? pedidos,
  }) {
    return PedidosKanbanState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // overwrite explicitly
      pedidos: pedidos ?? this.pedidos,
    );
  }

  // Getters para filtragem das colunas e stats
  List<PedidoKanbanModel> getPorStatus(String status) {
    return pedidos.where((p) => p.status == status).toList();
  }

  int get totalAtivos => pedidos
      .where((p) =>
          p.status != 'em_entrega' &&
          p.status != 'entregue' &&
          !p.status.startsWith('cancelado'))
      .length;

  double get receitaHoje => pedidos
      .where((p) =>
          p.status != 'cancelado_cliente' &&
          p.status != 'cancelado_estab' &&
          p.status != 'cancelado_sistema')
      .fold(0.0, (sum, p) => sum + p.total + p.tx);

  int get countEntreguesHoje =>
      pedidos.where((p) => p.status == 'entregue').length;

  List<PedidoKanbanModel> get pedidosEntregues =>
      pedidos.where((p) => p.status == 'entregue').toList();
}
