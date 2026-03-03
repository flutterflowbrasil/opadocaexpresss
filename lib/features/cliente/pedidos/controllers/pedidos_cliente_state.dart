import 'package:padoca_express/features/cliente/pedidos/models/pedido_cliente_model.dart';

class PedidosClienteState {
  final bool isLoading;
  final String? error;
  final List<PedidoClienteModel> pedidosAtivos;
  final List<PedidoClienteModel> pedidosAnteriores;

  const PedidosClienteState({
    this.isLoading = true,
    this.error,
    this.pedidosAtivos = const [],
    this.pedidosAnteriores = const [],
  });

  PedidosClienteState copyWith({
    bool? isLoading,
    String? error,
    List<PedidoClienteModel>? pedidosAtivos,
    List<PedidoClienteModel>? pedidosAnteriores,
  }) {
    return PedidosClienteState(
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
      pedidosAtivos: pedidosAtivos ?? this.pedidosAtivos,
      pedidosAnteriores: pedidosAnteriores ?? this.pedidosAnteriores,
    );
  }
}
