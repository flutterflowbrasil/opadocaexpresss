import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../auth/data/auth_repository.dart';
import '../data/pedidos_kanban_repository.dart';
import '../models/pedido_kanban_model.dart';
import 'pedidos_kanban_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../componentes_kanban/kanban_card.dart'; // Para acessar KanbanStatus

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

      // TODO: Get linked Estabelecimento id from the user. For now, assuming user.id or auth lookup,
      // but typically we get the estabelecimento_id linked to auth.users.
      // Em um projeto maduro, tem um repository estabRepository.getEstabelecimentoLogado().
      final estabId = await _getEstabelecimentoIdLigadoAoUser(user.id);

      if (estabId == null) {
        state = state.copyWith(
            isLoading: false, error: 'Estabelecimento não encontrado.');
        return;
      }

      final pedidos = await _repository.buscarPedidosAbertos(estabId);

      _categorizarPedidos(pedidos);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<String?> _getEstabelecimentoIdLigadoAoUser(String userId) async {
    // Esse mapeamento pode estar sendo feito no dashboard_repository no atual sistema
    // Para resolver, importaremos/criaremos a função se não existir.
    // Simulando obtenção para a implementação fluída da feature pedidos isolada:
    try {
      await _repository.buscarPedidosAbertos('PLACEHOLDER');
      return 'MOCKED_ESTAB_ID_AWAITING_AUTH_LINK_REF';
    } catch (e) {
      // Faremos hardcode do acesso ao authRepository type = estabelecimento
      final authEstab = await Supabase.instance.client
          .from('estabelecimentos')
          .select('id')
          .eq('usuario_id', userId)
          .maybeSingle();
      return authEstab?['id'] as String?;
    }
  }

  void _categorizarPedidos(List<PedidoKanbanModel> todosPedidos) {
    final recebidos = <PedidoKanbanModel>[];
    final emPreparo = <PedidoKanbanModel>[];
    final prontos = <PedidoKanbanModel>[];
    final emEntrega = <PedidoKanbanModel>[];

    for (var p in todosPedidos) {
      if (p.status == 'pendente' || p.status == 'confirmado') {
        recebidos.add(p);
      } else if (p.status == 'preparando') {
        emPreparo.add(p);
      } else if (p.status == 'pronto') {
        prontos.add(p);
      } else if (p.status == 'em_entrega') {
        emEntrega.add(p);
      }
    }

    state = state.copyWith(
      isLoading: false,
      recebidos: recebidos,
      emPreparo: emPreparo,
      prontos: prontos,
      emEntrega: emEntrega,
    );
  }

  /// Movimenta um pedido pra outra coluna (Atualização Otimista na UI)
  Future<void> alterarStatusPedido(
      String pedidoId, KanbanStatus novoStatusUi) async {
    // 1. Descobrir onde o pedido está atualmente nas nossas 4 arrays:
    final antigoStatusString = _encontrarStatusAntigoNoState(pedidoId);
    if (antigoStatusString == null)
      return; // Pedido não encontrado no state (pode ter sumido)

    final novoStatusString =
        PedidosKanbanState.kanbanEnumToString(novoStatusUi);
    if (antigoStatusString == novoStatusString) return; // Não mudou nada

    // 2. Localizar o Model atual
    final pedidoModel = _localizarPedidoModelNoState(pedidoId);
    if (pedidoModel == null) return;

    // 3. Remover da lista Antiga
    _removerPedidoDoState(pedidoId, antigoStatusString);

    // 4. Inserir na lista Nova (Optimistic Update -> Tela atualiza INSTANTANEAMENTE 60FPS)
    final pedidoAtualizado = pedidoModel.copyWith(status: novoStatusString);
    _adicionarPedidoNoState(pedidoAtualizado, novoStatusString);

    // 5. Salvar de Background no Banco via API
    try {
      await _repository.atualizarStatus(pedidoId, novoStatusString);
    } catch (e) {
      // Se der Erro (Ex: internet caiu, Supabase offline)
      // Fazemos Rollback (Rollback Otimista) -> Tira da Nova, Poe na Antiga.
      _removerPedidoDoState(pedidoId, novoStatusString);
      _adicionarPedidoNoState(pedidoModel, antigoStatusString);
      // Aqui idealmente disparamos um Snackbar na UI. Como controllers não tem BuildContext,
      // usariamos um provider auxiliar de SnackBar/Mensagens globais ou State error bool.
      state = state.copyWith(error: 'Falha ao mover pedido. Tente novamente.');
    }
  }

  String? _encontrarStatusAntigoNoState(String id) {
    if (state.recebidos.any((p) => p.id == id)) return 'pendente';
    if (state.emPreparo.any((p) => p.id == id)) return 'preparando';
    if (state.prontos.any((p) => p.id == id)) return 'pronto';
    if (state.emEntrega.any((p) => p.id == id)) return 'em_entrega';
    return null;
  }

  PedidoKanbanModel? _localizarPedidoModelNoState(String id) {
    try {
      return state.recebidos.firstWhere((p) => p.id == id);
    } catch (_) {}
    try {
      return state.emPreparo.firstWhere((p) => p.id == id);
    } catch (_) {}
    try {
      return state.prontos.firstWhere((p) => p.id == id);
    } catch (_) {}
    try {
      return state.emEntrega.firstWhere((p) => p.id == id);
    } catch (_) {}
    return null;
  }

  void _removerPedidoDoState(String id, String statusAntigo) {
    if (statusAntigo == 'pendente' || statusAntigo == 'confirmado') {
      state = state.copyWith(
          recebidos: state.recebidos.where((p) => p.id != id).toList());
    } else if (statusAntigo == 'preparando') {
      state = state.copyWith(
          emPreparo: state.emPreparo.where((p) => p.id != id).toList());
    } else if (statusAntigo == 'pronto') {
      state = state.copyWith(
          prontos: state.prontos.where((p) => p.id != id).toList());
    } else if (statusAntigo == 'em_entrega') {
      state = state.copyWith(
          emEntrega: state.emEntrega.where((p) => p.id != id).toList());
    }
  }

  void _adicionarPedidoNoState(PedidoKanbanModel pedido, String statusNovo) {
    if (statusNovo == 'pendente' || statusNovo == 'confirmado') {
      state = state.copyWith(recebidos: [...state.recebidos, pedido]);
    } else if (statusNovo == 'preparando') {
      state = state.copyWith(emPreparo: [...state.emPreparo, pedido]);
    } else if (statusNovo == 'pronto') {
      state = state.copyWith(prontos: [...state.prontos, pedido]);
    } else if (statusNovo == 'em_entrega') {
      state = state.copyWith(emEntrega: [...state.emEntrega, pedido]);
    }
  }
}

final pedidosKanbanControllerProvider = StateNotifierProvider.autoDispose<
    PedidosKanbanController, PedidosKanbanState>((ref) {
  final repo = ref.watch(pedidosKanbanRepositoryProvider);
  final auth = ref.watch(authRepositoryProvider);
  return PedidosKanbanController(repo, auth);
});
