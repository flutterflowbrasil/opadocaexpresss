import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../features/auth/data/auth_repository.dart';
import '../data/entregas_disponiveis_repository.dart';
import 'entregas_disponiveis_state.dart';

final entregasDisponiveisControllerProvider = StateNotifierProvider.autoDispose<
    EntregasDisponiveisController, EntregasDisponiveisState>((ref) {
  final repo = ref.watch(entregasDisponiveisRepositoryProvider);
  final authRepo = ref.watch(authRepositoryProvider);
  return EntregasDisponiveisController(repo, authRepo);
});

class EntregasDisponiveisController extends StateNotifier<EntregasDisponiveisState> {
  final EntregasDisponiveisRepository _repo;
  final AuthRepository _authRepo;

  EntregasDisponiveisController(this._repo, this._authRepo)
      : super(EntregasDisponiveisState.initial()) {
    carregarDisponiveis();
  }

  Future<void> carregarDisponiveis() async {
    state = state.copyWith(isLoading: true).copyWithClearError();
    try {
      final pedidos = await _repo.buscarPedidosDisponiveis();
      state = state.copyWith(isLoading: false, pedidos: pedidos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: 'Erro ao carregar pedidos.');
    }
  }

  Future<bool> aceitarEntrega(String pedidoId) async {
    state = state.copyWith(isAceitando: true).copyWithClearError();

    // Optimistic remove
    final currentList = List.of(state.pedidos);
    final optList = state.pedidos.where((p) => p.id != pedidoId).toList();
    state = state.copyWith(pedidos: optList);

    try {
      final uid = _authRepo.currentUser?.id;
      if (uid == null) throw Exception('Não logado');

      final entregadorId = await _authRepo.getEntregadorId(uid);
      if (entregadorId == null) throw Exception('Sessão inválida');

      await _repo.aceitarEntrega(pedidoId, entregadorId);

      // Successfully updated!
      state = state.copyWith(isAceitando: false);
      return true;
    } catch (e) {
      // Rollback
      state = state.copyWith(
          isAceitando: false,
          error: 'Erro ao aceitar pedido. Outro entregador pode ter aceito.',
          pedidos: currentList);
      return false;
    }
  }
}
