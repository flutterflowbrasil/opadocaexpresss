import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../componentes_dash/dashboard_colors.dart';

enum KanbanStatus { recebido, preparo, pronto, entrega }

class KanbanCard extends StatelessWidget {
  final KanbanStatus status;
  final String idPedido;
  final String clienteNome;
  final String itensResumo;
  final double total;
  final String tempoDesde;
  final bool animatePulse;

  const KanbanCard({
    super.key,
    required this.status,
    required this.idPedido,
    required this.clienteNome,
    required this.itensResumo,
    required this.total,
    required this.tempoDesde,
    this.animatePulse = false,
  });

  Color _getStatusColor() {
    switch (status) {
      case KanbanStatus.recebido:
        return DashboardColors.burgundy;
      case KanbanStatus.preparo:
        return DashboardColors.primary;
      case KanbanStatus.pronto:
        return Colors.green;
      case KanbanStatus.entrega:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor();
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final card = Container(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Left color border indicator
            Container(width: 4, color: statusColor),
            // Card Content
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          idPedido,
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: statusColor,
                          ),
                        ),
                        if (animatePulse && status == KanbanStatus.preparo)
                          Row(
                            children: [
                              Icon(Icons.sync, color: statusColor, size: 12),
                              const SizedBox(width: 4),
                              Text(
                                tempoDesde.toUpperCase(),
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.bold,
                                  color: statusColor,
                                ),
                              ),
                            ],
                          )
                        else
                          Text(
                            tempoDesde.toUpperCase(),
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: status == KanbanStatus.pronto
                                  ? statusColor
                                  : Colors.grey[500],
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      clienteNome,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.grey[800],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      itensResumo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Divider(
                        height: 1,
                        color: isDark ? Colors.grey[800] : Colors.grey[100]),
                    const SizedBox(height: 12),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                              .format(total),
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: isDark ? Colors.white : Colors.grey[800],
                          ),
                        ),
                        Icon(Icons.drag_indicator, color: Colors.grey[300]),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );

    return Draggable<String>(
      data: idPedido,
      feedback: Material(
        color: Colors.transparent,
        child: SizedBox(
          width: 300, // Fixed width for dragging feedback
          child: Opacity(
            opacity: 0.8,
            child: card,
          ),
        ),
      ),
      childWhenDragging: Opacity(
        opacity: 0.3,
        child: card,
      ),
      child: card,
    );
  }
}
