import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../../auth/data/auth_repository.dart';
import '../data/pedidos_kanban_repository.dart';
import '../models/pedido_kanban_model.dart';
import 'pedidos_kanban_state.dart';

class PedidosKanbanController extends StateNotifier<PedidosKanbanState> {
  final PedidosKanbanRepository _repository;
  final AuthRepository _authRepository;
  final SupabaseClient _supabase;

  RealtimeChannel? _pedidosChannel;

  PedidosKanbanController(this._repository, this._authRepository, this._supabase)
      : super(const PedidosKanbanState()) {
    carregarPedidos();
  }

  @override
  void dispose() {
    _pedidosChannel?.unsubscribe();
    super.dispose();
  }

  Future<void> carregarPedidos() async {
    if (state.pedidos.isEmpty) {
      state = state.copyWith(isLoading: true, error: null);
    }

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

      _iniciarRealtime(estabId);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void _iniciarRealtime(String estabId) {
    if (_pedidosChannel != null) return;
    _pedidosChannel = _supabase
        .channel('kanban-pedidos-$estabId')
        .onPostgresChanges(
          event: PostgresChangeEvent.all,
          schema: 'public',
          table: 'pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'estabelecimento_id',
            value: estabId,
          ),
          callback: (_) {
            if (mounted) carregarPedidos();
          },
        )
        .subscribe();
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

      // Quando pedido fica pronto, despacha automaticamente para entregadores disponíveis
      if (novoStatus == 'pronto') {
        try {
          await _repository.despacharParaEntregadoresDisponiveis(pedidoId);
        } catch (e) {
          debugPrint('🚨 [KanbanController] ERRO AO DESPACHAR: $e');
        }
      }
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
  ref.keepAlive(); // Mantém o estado vivo para navegação instantânea
  final repo = ref.watch(pedidosKanbanRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  return PedidosKanbanController(repo, auth, Supabase.instance.client);
});
