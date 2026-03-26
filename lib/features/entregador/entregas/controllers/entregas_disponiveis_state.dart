import '../models/pedido_disponivel_model.dart';

class EntregasDisponiveisState {
  final bool isLoading;
  final String? error;
  final List<PedidoDisponivelModel> pedidos;
  final bool isAceitando;

  const EntregasDisponiveisState({
    required this.isLoading,
    this.error,
    required this.pedidos,
    required this.isAceitando,
  });

  factory EntregasDisponiveisState.initial() {
    return const EntregasDisponiveisState(
      isLoading: true,
      pedidos: [],
      isAceitando: false,
    );
  }

  EntregasDisponiveisState copyWith({
    bool? isLoading,
    String? error,
    List<PedidoDisponivelModel>? pedidos,
    bool? isAceitando,
  }) {
    return EntregasDisponiveisState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // nullable, if not provided, keeps current. Oh, wait, copyWith usually takes nullable so we need to either pass `String? error` or `this.error`
      pedidos: pedidos ?? this.pedidos,
      isAceitando: isAceitando ?? this.isAceitando,
    );
  }

  // To properly clear error
  EntregasDisponiveisState copyWithClearError() {
    return EntregasDisponiveisState(
      isLoading: isLoading,
      error: null,
      pedidos: pedidos,
      isAceitando: isAceitando,
    );
  }
}
