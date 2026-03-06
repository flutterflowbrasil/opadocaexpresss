import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/data/auth_repository.dart';
import '../data/pedidos_kanban_repository.dart';
import '../models/pedido_kanban_model.dart';
import 'pedidos_kanban_state.dart';

class PedidosKanbanController extends StateNotifier<PedidosKanbanState> {
  final PedidosKanbanRepository _repository;
  final AuthRepository _authRepository;

  PedidosKanbanController(this._repository, this._authRepository)
      : super(const PedidosKanbanState()) {
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final user = _authRepository.currentUser;
      if (user == null) {
        state =
            state.copyWith(isLoading: false, error: 'Usuário não autenticado.');
        return;
      }

      final estabId = await _authRepository.getEstabelecimentoId(user.id);

      if (estabId == null) {
        state = state.copyWith(
            isLoading: false, error: 'Estabelecimento não encontrado.');
        return;
      }

      final pedidos = await _repository.buscarPedidosDia(estabId);

      state = state.copyWith(isLoading: false, pedidos: pedidos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> alterarStatusPedido(String pedidoId, String novoStatus) async {
    final oldPedidoIdx = state.pedidos.indexWhere((p) => p.id == pedidoId);
    if (oldPedidoIdx == -1) return;

    final pedidoData = state.pedidos[oldPedidoIdx];
    final statusAntigo = pedidoData.status;
    if (statusAntigo == novoStatus) return;

    // Optimistic Update
    final newStateList = List<PedidoKanbanModel>.from(state.pedidos);
    newStateList[oldPedidoIdx] = pedidoData.copyWith(status: novoStatus);
    state = state.copyWith(pedidos: newStateList);

    // Save
    try {
      await _repository.atualizarStatus(pedidoId, novoStatus);
    } catch (e) {
      // Rollback
      final rollbackList = List<PedidoKanbanModel>.from(state.pedidos);
      rollbackList[oldPedidoIdx] = pedidoData.copyWith(status: statusAntigo);
      state = state.copyWith(
          pedidos: rollbackList,
          error: 'Falha ao mover pedido. Tente novamente.');
    }
  }

  Future<void> rejeitarPedido(String pedidoId) async {
    await alterarStatusPedido(pedidoId, 'cancelado_estab');
  }

  // Auto-reload to fetch deliveries, new orders etc.
  Future<void> recarregar() async {
    await carregarPedidos();
  }
}

final pedidosKanbanControllerProvider = StateNotifierProvider.autoDispose<
    PedidosKanbanController, PedidosKanbanState>((ref) {
  final repo = ref.watch(pedidosKanbanRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  return PedidosKanbanController(repo, auth);
});
