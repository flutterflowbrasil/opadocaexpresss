import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../componentes_dash/sidebar_menu.dart';
import 'controllers/pedidos_kanban_controller.dart';
import 'componentes_kanban/kanban_coluna_nova.dart';
import 'models/pedido_kanban_model.dart';

class PedidosScreen extends ConsumerStatefulWidget {
  const PedidosScreen({super.key});

  @override
  ConsumerState<PedidosScreen> createState() => _PedidosScreenState();
}

class _PedidosScreenState extends ConsumerState<PedidosScreen> {
  String _search = '';
  String _filterPgto = 'todos';
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen = MediaQuery.of(context).size.width >= 1100;
    final state = ref.watch(pedidosKanbanControllerProvider);
    final notifier = ref.read(pedidosKanbanControllerProvider.notifier);

    // Filters
    final filtrados = state.pedidos.where((p) {
      final matchSearch = _search.isEmpty ||
          p.cliente.toLowerCase().contains(_search.toLowerCase()) ||
          p.numero.toString().contains(_search);
      final matchPgto = _filterPgto == 'todos' || p.pgto == _filterPgto;
      return matchSearch && matchPgto;
    }).toList();

    List<PedidoKanbanModel> porColuna(String status) =>
        filtrados.where((p) => p.status == status).toList();

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF1E1E1E) : const Color(0xFFF4F2EF),
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                  activeId: 'orders',
                  onItemSelected: (id) => Navigator.pop(context))),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(activeId: 'orders', onItemSelected: (_) {}),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // TOPBAR Custom
                Container(
                  height: 58,
                  padding: const EdgeInsets.symmetric(horizontal: 22),
                  decoration: const BoxDecoration(
                      color: Colors.white,
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFEAE8E4)))),
                  child: Builder(
                    builder: (ctx) => Row(
                      children: [
                        // Hamburger (mobile only)
                        if (!isWideScreen) ...[
                          InkWell(
                            onTap: () => Scaffold.of(ctx).openDrawer(),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                border: Border.all(
                                    color: const Color(0xFFEAE8E4), width: 1.5),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: const Icon(Icons.menu,
                                  color: Color(0xFF6B7280), size: 20),
                            ),
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: Row(
                            children: [
                              Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Pedidos',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 15,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A0910))),
                                  Text('Gestão de fluxo e despacho',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 11,
                                          color: const Color(0xFF9CA3AF))),
                                ],
                              ),
                              if (isWideScreen) ...[
                                const SizedBox(width: 14),
                                _buildStatBadge(
                                    'Ativos',
                                    '${state.totalAtivos}',
                                    const Color(0xFFF97316)),
                                const SizedBox(width: 7),
                                _buildStatBadge(
                                    'Hoje',
                                    '${state.pedidos.length}',
                                    const Color(0xFF6B7280)),
                                const SizedBox(width: 7),
                                _buildStatBadge(
                                    'Receita',
                                    'R\$ ${state.receitaHoje.toStringAsFixed(0)}',
                                    const Color(0xFF10B981)),
                              ]
                            ],
                          ),
                        ),

                        // Right Side Actions
                        Row(
                          children: [
                            if (isWideScreen) ...[
                              Container(
                                width: 200,
                                height: 36,
                                padding:
                                    const EdgeInsets.symmetric(horizontal: 12),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF4F2EF),
                                    borderRadius: BorderRadius.circular(9)),
                                child: Row(
                                  children: [
                                    const Icon(Icons.search,
                                        size: 15, color: Color(0xFF6B7280)),
                                    const SizedBox(width: 7),
                                    Expanded(
                                      child: TextField(
                                        onChanged: (v) =>
                                            setState(() => _search = v),
                                        style: GoogleFonts.publicSans(
                                            fontSize: 12,
                                            color: const Color(0xFF1A0910)),
                                        decoration: const InputDecoration(
                                            hintText: 'Buscar...',
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _buildFilterPopup(),
                              const SizedBox(width: 8),
                            ],
                            InkWell(
                              onTap: () =>
                                  notifier.recarregar(), // Refresh button
                              borderRadius: BorderRadius.circular(9),
                              child: Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                    border: Border.all(
                                        color: const Color(0xFFEAE8E4),
                                        width: 1.5),
                                    borderRadius: BorderRadius.circular(9)),
                                child: const Icon(Icons.refresh,
                                    size: 16, color: Color(0xFF6B7280)),
                              ),
                            ),
                          ],
                        )
                      ],
                    ), // Row
                  ), // Builder
                ), // Container

                // KANBAN AREA
                Expanded(
                  child: state.isLoading && state.pedidos.isEmpty
                      ? const Center(child: CircularProgressIndicator())
                      : ScrollConfiguration(
                          behavior: ScrollConfiguration.of(context).copyWith(
                            dragDevices: {
                              PointerDeviceKind.touch,
                              PointerDeviceKind.mouse,
                              PointerDeviceKind.trackpad,
                            },
                          ),
                          child: Scrollbar(
                            controller: _scrollController,
                            thumbVisibility: true,
                            trackVisibility: true,
                            thickness: 8,
                            radius: const Radius.circular(8),
                            child: SingleChildScrollView(
                              controller: _scrollController,
                              scrollDirection: Axis.horizontal,
                              physics: const BouncingScrollPhysics(),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 18, vertical: 16),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  ...[
                                    'pendente',
                                    'confirmado',
                                    'preparando',
                                    'pronto',
                                    'em_entrega'
                                  ].map((status) {
                                    return KanbanColunaNova(
                                      statusKey: status,
                                      pedidos: porColuna(status),
                                      onAvancar: (id) =>
                                          notifier.alterarStatusPedido(
                                              id, _getNextStatus(status)),
                                      onRejeitar: (id) =>
                                          notifier.rejeitarPedido(id),
                                      onImprimir: (_) {},
                                      onOpen: (_) {},
                                    );
                                  }),

                                  // Entregues Column
                                  Container(
                                    width: 260,
                                    margin: const EdgeInsets.only(right: 12),
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        Container(
                                          padding: const EdgeInsets.symmetric(
                                              horizontal: 12, vertical: 10),
                                          decoration: BoxDecoration(
                                              color: const Color(0xFFF9FAFB),
                                              border: Border.all(
                                                  color:
                                                      const Color(0xFFE5E7EB)),
                                              borderRadius:
                                                  const BorderRadius.vertical(
                                                      top:
                                                          Radius.circular(10))),
                                          child: Row(
                                            children: [
                                              Container(
                                                  width: 8,
                                                  height: 8,
                                                  decoration:
                                                      const BoxDecoration(
                                                          color:
                                                              Color(0xFF6B7280),
                                                          shape:
                                                              BoxShape.circle)),
                                              const SizedBox(width: 8),
                                              Expanded(
                                                  child: Text('Entregues hoje',
                                                      style: GoogleFonts
                                                          .publicSans(
                                                              fontSize: 12,
                                                              fontWeight:
                                                                  FontWeight
                                                                      .w700,
                                                              color: const Color(
                                                                  0xFF4B5563)))),
                                              Container(
                                                padding:
                                                    const EdgeInsets.symmetric(
                                                        horizontal: 8,
                                                        vertical: 2),
                                                decoration: BoxDecoration(
                                                    color:
                                                        const Color(0xFF6B7280),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            20)),
                                                child: Text(
                                                    '${state.countEntreguesHoje}',
                                                    style:
                                                        GoogleFonts.publicSans(
                                                            fontSize: 11,
                                                            fontWeight:
                                                                FontWeight.w800,
                                                            color:
                                                                Colors.white)),
                                              ),
                                            ],
                                          ),
                                        ),
                                        Expanded(
                                          child: Container(
                                            padding: const EdgeInsets.all(8),
                                            decoration: BoxDecoration(
                                                color:
                                                    Colors.black.withAlpha(5),
                                                border: const Border(
                                                    left: BorderSide(
                                                        color:
                                                            Color(0xFFE5E7EB)),
                                                    right: BorderSide(
                                                        color:
                                                            Color(0xFFE5E7EB)),
                                                    bottom: BorderSide(
                                                        color:
                                                            Color(0xFFE5E7EB))),
                                                borderRadius:
                                                    const BorderRadius.vertical(
                                                        bottom: Radius.circular(
                                                            10))),
                                            child: ListView.builder(
                                              itemCount:
                                                  state.pedidosEntregues.length,
                                              itemBuilder: (context, i) {
                                                final p =
                                                    state.pedidosEntregues[i];
                                                return Container(
                                                  padding: const EdgeInsets
                                                      .symmetric(
                                                      horizontal: 10,
                                                      vertical: 8),
                                                  margin: const EdgeInsets.only(
                                                      bottom: 6),
                                                  decoration: BoxDecoration(
                                                      color: Colors.white,
                                                      border: Border.all(
                                                          color: const Color(
                                                              0xFFF3F4F6)),
                                                      borderRadius:
                                                          BorderRadius.circular(
                                                              9)),
                                                  child: Row(
                                                    children: [
                                                      Container(
                                                          width: 6,
                                                          height: 6,
                                                          decoration:
                                                              const BoxDecoration(
                                                                  color: Color(
                                                                      0xFF10B981),
                                                                  shape: BoxShape
                                                                      .circle)),
                                                      const SizedBox(width: 8),
                                                      Expanded(
                                                        child: Column(
                                                          crossAxisAlignment:
                                                              CrossAxisAlignment
                                                                  .start,
                                                          children: [
                                                            Text(
                                                                '#${p.numero} · ${p.cliente}',
                                                                style: GoogleFonts.publicSans(
                                                                    fontSize:
                                                                        12,
                                                                    fontWeight:
                                                                        FontWeight
                                                                            .w600,
                                                                    color: const Color(
                                                                        0xFF6B7280)),
                                                                maxLines: 1,
                                                                overflow:
                                                                    TextOverflow
                                                                        .ellipsis),
                                                            Text(
                                                                'Receita: R\$ ${p.total.toStringAsFixed(2)}',
                                                                style: GoogleFonts
                                                                    .publicSans(
                                                                        fontSize:
                                                                            10,
                                                                        color: const Color(
                                                                            0xFF9CA3AF))),
                                                          ],
                                                        ),
                                                      ),
                                                    ],
                                                  ),
                                                );
                                              },
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  )
                                ],
                              ),
                            ),
                          ),
                        ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  String _getNextStatus(String current) {
    switch (current) {
      case 'pendente':
        return 'confirmado';
      case 'confirmado':
        return 'preparando';
      case 'preparando':
        return 'pronto';
      case 'pronto':
        return 'em_entrega';
      case 'em_entrega':
        return 'entregue'; // Optional, might want manual action
      default:
        return current;
    }
  }

  Widget _buildStatBadge(String lbl, String val, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 4),
      decoration: BoxDecoration(
          color: const Color(0xFFF4F2EF),
          borderRadius: BorderRadius.circular(8)),
      child: Row(
        children: [
          Text(lbl,
              style: GoogleFonts.publicSans(
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                  fontWeight: FontWeight.w600)),
          const SizedBox(width: 5),
          Text(val,
              style: GoogleFonts.publicSans(
                  fontSize: 13, color: color, fontWeight: FontWeight.w800)),
        ],
      ),
    );
  }

  Widget _buildFilterPopup() {
    final Map<String, String> filterOptions = {
      'todos': 'Todos',
      'pix': 'Pix',
      'credito': 'Crédito',
      'debito': 'Débito',
      'dinheiro': 'Dinheiro',
      'credito_maquina': 'Crédito Maquin.',
      'debito_maquina': 'Débito Maquin.',
    };

    final isFiltered = _filterPgto != 'todos';
    final currentLabel = filterOptions[_filterPgto] ?? 'Filtros';

    return PopupMenuButton<String>(
      tooltip: 'Filtrar por pagamento',
      offset: const Offset(0, 40),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onSelected: (value) => setState(() => _filterPgto = value),
      itemBuilder: (context) => filterOptions.entries.map((e) {
        final sel = _filterPgto == e.key;
        return PopupMenuItem<String>(
          value: e.key,
          height: 36,
          child: Row(
            children: [
              Icon(
                sel ? Icons.radio_button_checked : Icons.radio_button_off,
                size: 16,
                color: sel ? const Color(0xFFF97316) : const Color(0xFF9CA3AF),
              ),
              const SizedBox(width: 8),
              Text(
                e.value,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                  color:
                      sel ? const Color(0xFFF97316) : const Color(0xFF4B5563),
                ),
              ),
            ],
          ),
        );
      }).toList(),
      child: Container(
        height: 36,
        padding: const EdgeInsets.symmetric(horizontal: 12),
        margin: const EdgeInsets.only(right: 8),
        decoration: BoxDecoration(
          color: isFiltered ? const Color(0xFFFFF7ED) : Colors.white,
          border: Border.all(
              color: isFiltered
                  ? const Color(0xFFF97316)
                  : const Color(0xFFEAE8E4),
              width: 1.5),
          borderRadius: BorderRadius.circular(9),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_list,
                size: 15,
                color: isFiltered
                    ? const Color(0xFFF97316)
                    : const Color(0xFF6B7280)),
            const SizedBox(width: 6),
            Text(isFiltered ? currentLabel : 'Filtros',
                style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isFiltered
                        ? const Color(0xFFF97316)
                        : const Color(0xFF6B7280))),
            if (isFiltered) ...[
              const SizedBox(width: 6),
              GestureDetector(
                onTap: () => setState(() => _filterPgto = 'todos'),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF97316).withOpacity(0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close,
                      size: 10, color: Color(0xFFEA580C)),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
