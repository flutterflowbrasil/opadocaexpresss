import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/pedidos/data/pedidos_cliente_repository.dart';
import 'package:padoca_express/features/cliente/pedidos/controllers/pedidos_cliente_state.dart';

class PedidosClienteController extends StateNotifier<PedidosClienteState> {
  final PedidosClienteRepository _repository;
  final SupabaseClient _supabase;

  PedidosClienteController(this._repository, this._supabase)
      : super(const PedidosClienteState()) {
    carregarPedidos();
  }

  Future<void> carregarPedidos() async {
    try {
      state = state.copyWith(isLoading: true, error: null);

      final user = _supabase.auth.currentUser;
      if (user == null) {
        state = state.copyWith(isLoading: false, error: 'Usuário não logado');
        return;
      }

      // 1. Buscar o ID do Cliente logado
      final clienteId = await _repository.getClienteId(user.id);

      if (!mounted) return;

      if (clienteId == null) {
        state = state.copyWith(
            isLoading: false, error: 'Perfil de cliente não encontrado');
        return;
      }

      // 2. Buscar os Pedidos no Repository
      final todosPedidos = await _repository.getPedidosCliente(clienteId);

      if (!mounted) return;

      // 3. Separar Ativos de Anteriores (Baseado na regra do Model)
      final ativos = todosPedidos.where((p) => p.isAtivo).toList();
      final anteriores = todosPedidos.where((p) => !p.isAtivo).toList();

      state = state.copyWith(
        isLoading: false,
        pedidosAtivos: ativos,
        pedidosAnteriores: anteriores,
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
    }
  }
}

// OBRIGATÓRIO NA AUDITORIA: autoDispose para limpar memória quando sair da tela
final pedidosClienteControllerProvider = StateNotifierProvider.autoDispose<
    PedidosClienteController, PedidosClienteState>((ref) {
  final repository = ref.watch(pedidosClienteRepositoryProvider);
  final supabase = ref.watch(supabaseClientProvider);
  return PedidosClienteController(repository, supabase);
});
