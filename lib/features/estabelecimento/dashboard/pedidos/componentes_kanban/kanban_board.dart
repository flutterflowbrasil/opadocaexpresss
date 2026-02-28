import 'package:flutter/material.dart';
import 'kanban_column.dart';
import 'kanban_card.dart';

class KanbanItem {
  final String idPedido;
  final String clienteNome;
  final String itensResumo;
  final double total;
  final String tempoDesde;
  final bool animatePulse;
  KanbanStatus status;

  KanbanItem({
    required this.idPedido,
    required this.clienteNome,
    required this.itensResumo,
    required this.total,
    required this.tempoDesde,
    this.animatePulse = false,
    required this.status,
  });
}

class KanbanBoard extends StatefulWidget {
  const KanbanBoard({super.key});

  @override
  State<KanbanBoard> createState() => _KanbanBoardState();
}

class _KanbanBoardState extends State<KanbanBoard> {
  final List<KanbanItem> _items = [
    KanbanItem(
      status: KanbanStatus.recebido,
      idPedido: '#001',
      clienteNome: 'João Silva',
      itensResumo: '2x Pão na Chapa, 1x Pingado Médio, 1x Suco...',
      total: 42.50,
      tempoDesde: 'Há 5 min',
    ),
    KanbanItem(
      status: KanbanStatus.recebido,
      idPedido: '#004',
      clienteNome: 'Maria Oliveira',
      itensResumo: '1x Croissant Frango, 1x Espresso Curto',
      total: 28.90,
      tempoDesde: 'Há 2 min',
    ),
    KanbanItem(
      status: KanbanStatus.preparo,
      idPedido: '#002',
      clienteNome: 'Roberto Santos',
      itensResumo: '3x Pão de Queijo, 1x Capuccino Grande',
      total: 22.00,
      tempoDesde: '12 min',
      animatePulse: true,
    ),
    KanbanItem(
      status: KanbanStatus.pronto,
      idPedido: '#003',
      clienteNome: 'Ana Paula',
      itensResumo: '1x Combo Café da Manhã Familiar',
      total: 85.90,
      tempoDesde: 'Aguardando Retirada',
    ),
  ];

  void _onItemDropped(String idPedido, KanbanStatus newStatus) {
    setState(() {
      final itemIndex = _items.indexWhere((item) => item.idPedido == idPedido);
      if (itemIndex != -1) {
        // Remove and re-add to place at the bottom of the new column
        final item = _items.removeAt(itemIndex);
        item.status = newStatus;
        _items.add(item);
      }
    });
  }

  List<KanbanCard> _buildCards(KanbanStatus status) {
    return _items
        .where((item) => item.status == status)
        .map((item) => KanbanCard(
              key: ValueKey(item.idPedido),
              status: item.status,
              idPedido: item.idPedido,
              clienteNome: item.clienteNome,
              itensResumo: item.itensResumo,
              total: item.total,
              tempoDesde: item.tempoDesde,
              animatePulse: item.animatePulse,
            ))
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final recebidos = _buildCards(KanbanStatus.recebido);
    final preparo = _buildCards(KanbanStatus.preparo);
    final pronto = _buildCards(KanbanStatus.pronto);
    final entrega = _buildCards(KanbanStatus.entrega);

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
            count: recebidos.length,
            statusType: KanbanStatus.recebido,
            isEmpty: recebidos.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.recebido),
            children: recebidos,
          ),

          // Em Preparo
          KanbanColumn(
            title: 'Em Preparo',
            count: preparo.length,
            statusType: KanbanStatus.preparo,
            isEmpty: preparo.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.preparo),
            children: preparo,
          ),

          // Pronto
          KanbanColumn(
            title: 'Pronto',
            count: pronto.length,
            statusType: KanbanStatus.pronto,
            isEmpty: pronto.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.pronto),
            children: pronto,
          ),

          // Saiu para Entrega
          KanbanColumn(
            title: 'Saiu para Entrega',
            count: entrega.length,
            statusType: KanbanStatus.entrega,
            isEmpty: entrega.isEmpty,
            onAccept: (id) => _onItemDropped(id, KanbanStatus.entrega),
            children: entrega,
          ),
        ],
      ),
    );
  }
}
