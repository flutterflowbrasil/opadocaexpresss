import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'kanban_column.dart';
import 'kanban_card.dart';
import '../models/pedido_kanban_model.dart';
import '../controllers/pedidos_kanban_controller.dart';

class KanbanBoard extends ConsumerStatefulWidget {
  const KanbanBoard({super.key});

  @override
  ConsumerState<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends ConsumerState<KanbanBoard> {
  @override
  void initState() {
    super.initState();
    // A inicialização principal dos dados ocorre automaticamente ao
    // dar 'ref.watch' no provider abaixo durante o build inicial ou
    // via constructor do Controller.
  }

  void _onItemDropped(String idPedido, KanbanStatus newStatus) {
    ref
        .read(pedidosKanbanControllerProvider.notifier)
        .alterarStatusPedido(idPedido, newStatus);
  }

  List<KanbanCard> _buildCards(
      List<PedidoKanbanModel> items, KanbanStatus status) {
    return items
        .map((item) => KanbanCard(
              key: ValueKey(item.id),
              pedido: item,
              status: status,
              animatePulse: status ==
                  KanbanStatus.preparo, // Pulse effect only in preparo
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pedidosKanbanControllerProvider);

    if (state.isLoading && state.recebidos.isEmpty && state.emPreparo.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null && state.recebidos.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, color: Colors.red, size: 48),
            const SizedBox(height: 16),
            Text(state.error!, style: const TextStyle(color: Colors.red)),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () => ref
                  .read(pedidosKanbanControllerProvider.notifier)
                  .carregarPedidos(),
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      );
    }

    final recebidosCards = _buildCards(state.recebidos, KanbanStatus.recebido);
    final preparoCards = _buildCards(state.emPreparo, KanbanStatus.preparo);
    final prontoCards = _buildCards(state.prontos, KanbanStatus.pronto);
    final entregaCards = _buildCards(state.emEntrega, KanbanStatus.entrega);

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Recebidos
          KanbanColumn(
            title: 'Recebidos',
            count: recebidosCards.length,
            statusType: KanbanStatus.recebido,
            isEmpty: recebidosCards.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.recebido),
            children: recebidosCards,
          ),

          // Em Preparo
          KanbanColumn(
            title: 'Em Preparo',
            count: preparoCards.length,
            statusType: KanbanStatus.preparo,
            isEmpty: preparoCards.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.preparo),
            children: preparoCards,
          ),

          // Pronto
          KanbanColumn(
            title: 'Pronto',
            count: prontoCards.length,
            statusType: KanbanStatus.pronto,
            isEmpty: prontoCards.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.pronto),
            children: prontoCards,
          ),

          // Saiu para Entrega
          KanbanColumn(
            title: 'Saiu para Entrega',
            count: entregaCards.length,
            statusType: KanbanStatus.entrega,
            isEmpty: entregaCards.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.entrega),
            children: entregaCards,
          ),
        ],
      ),
    );
  }
}
