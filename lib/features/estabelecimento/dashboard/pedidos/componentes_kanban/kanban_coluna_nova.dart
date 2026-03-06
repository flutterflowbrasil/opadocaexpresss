import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pedido_kanban_model.dart';
import 'kanban_ui_constants.dart';
import 'kanban_card_novo.dart';

class KanbanColunaNova extends StatelessWidget {
  final String statusKey;
  final List<PedidoKanbanModel> pedidos;
  final Function(String) onAvancar;
  final Function(String) onRejeitar;
  final Function(PedidoKanbanModel) onImprimir;
  final Function(PedidoKanbanModel) onOpen;

  const KanbanColunaNova({
    super.key,
    required this.statusKey,
    required this.pedidos,
    required this.onAvancar,
    required this.onRejeitar,
    required this.onImprimir,
    required this.onOpen,
  });

  @override
  Widget build(BuildContext context) {
    final st = StatusMeta.fromStatus(statusKey);
    final count = pedidos.length;

    int criticos = 0;
    for (var p in pedidos) {
      final mins = DateTime.now().difference(p.at).inMinutes;
      if ((statusKey == 'pendente' && mins > 5) ||
          (statusKey == 'preparando' && mins > 20)) {
        criticos++;
      }
    }

    return Container(
      width: 310,
      margin: const EdgeInsets.only(right: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 13, vertical: 10),
            decoration: BoxDecoration(
              color: st.bg,
              border: Border.all(color: st.border),
              borderRadius:
                  const BorderRadius.vertical(top: Radius.circular(10)),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration:
                      BoxDecoration(color: st.color, shape: BoxShape.circle),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    st.label,
                    style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: st.dark),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                      color: st.color, borderRadius: BorderRadius.circular(20)),
                  child: Text('$count', // Changed from '\$count'
                      style: GoogleFonts.publicSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                ),
                if (criticos > 0) ...[
                  const SizedBox(width: 6),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                        color: const Color(0xFFEF4444),
                        borderRadius: BorderRadius.circular(20)),
                    child: Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded,
                            color: Colors.white, size: 10),
                        const SizedBox(width: 2),
                        Text('$criticos', // Changed from '\$criticos'
                            style: GoogleFonts.publicSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: Colors.white)),
                      ],
                    ),
                  )
                ]
              ],
            ),
          ),

          // Body
          Expanded(
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.black.withAlpha(5),
                border: Border(
                  left: BorderSide(color: st.border),
                  right: BorderSide(color: st.border),
                  bottom: BorderSide(color: st.border),
                ),
                borderRadius:
                    const BorderRadius.vertical(bottom: Radius.circular(10)),
              ),
              child: count == 0
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 28),
                        child: Text(
                          'Nenhum pedido',
                          style: GoogleFonts.publicSans(
                              fontSize: 12, color: const Color(0xFFC4C1BC)),
                        ),
                      ),
                    )
                  : ListView.builder(
                      itemCount: count,
                      itemBuilder: (context, i) {
                        return KanbanCardNovo(
                          pedido: pedidos[i],
                          onAvancar: () => onAvancar(pedidos[i].id),
                          onRejeitar: () => onRejeitar(pedidos[i].id),
                          onImprimir: () => onImprimir(pedidos[i]),
                          onOpen: () => onOpen(pedidos[i]),
                        );
                      },
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
