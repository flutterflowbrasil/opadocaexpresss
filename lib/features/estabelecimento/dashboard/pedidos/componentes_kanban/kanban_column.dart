import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'kanban_card.dart';

class KanbanColumn extends StatelessWidget {
  final String title;
  final int count;
  final KanbanStatus statusType;
  final List<Widget> children;
  final bool isEmpty;
  final Function(String idPedido)? onAccept;

  const KanbanColumn({
    super.key,
    required this.title,
    required this.count,
    required this.statusType,
    required this.children,
    this.isEmpty = false,
    this.onAccept,
  });

  Color _getBadgeColor() {
    switch (statusType) {
      case KanbanStatus.recebido:
        return Colors.grey[200]!;
      case KanbanStatus.preparo:
        return const Color(0xFFEC5B13); // Primary
      case KanbanStatus.pronto:
        return Colors.green;
      case KanbanStatus.entrega:
        return Colors.blue;
    }
  }

  Color _getBadgeTextColor() {
    switch (statusType) {
      case KanbanStatus.recebido:
        return Colors.grey[700]!;
      case KanbanStatus.preparo:
      case KanbanStatus.pronto:
      case KanbanStatus.entrega:
        return Colors.white;
    }
  }

  Color _getBgColor(bool isDark) {
    switch (statusType) {
      case KanbanStatus.recebido:
        return isDark
            ? Colors.grey[900]!.withValues(alpha: 0.3)
            : Colors.grey[100]!.withValues(alpha: 0.5);
      case KanbanStatus.preparo:
        return const Color(0xFFEC5B13).withValues(alpha: isDark ? 0.1 : 0.05);
      case KanbanStatus.pronto:
        return Colors.green.withValues(alpha: isDark ? 0.1 : 0.05);
      case KanbanStatus.entrega:
        return Colors.blue.withValues(alpha: isDark ? 0.1 : 0.05);
    }
  }

  Color _getBorderColor() {
    switch (statusType) {
      case KanbanStatus.recebido:
        return Colors.grey[300]!;
      case KanbanStatus.preparo:
        return const Color(0xFFEC5B13).withValues(alpha: 0.2);
      case KanbanStatus.pronto:
        return Colors.green.withValues(alpha: 0.2);
      case KanbanStatus.entrega:
        return Colors.blue.withValues(alpha: 0.2);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      width: 320,
      margin: const EdgeInsets.only(right: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Column Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[200] : Colors.grey[700],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: _getBadgeColor(),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        count.toString(),
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                          color: _getBadgeTextColor(),
                        ),
                      ),
                    ),
                  ],
                ),
                Icon(Icons.more_horiz, color: Colors.grey[400]),
              ],
            ),
          ),

          // Column Body
          Expanded(
            child: DragTarget<String>(
              onAcceptWithDetails: (details) {
                if (onAccept != null) {
                  onAccept!(details.data);
                }
              },
              builder: (context, candidateData, rejectedData) {
                return Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _getBgColor(isDark),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _getBorderColor(),
                      // dash pattern not natively supported on simple border, falling back to solid light border
                    ),
                  ),
                  child: isEmpty
                      ? Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.delivery_dining,
                                  size: 48, color: Colors.grey[400]),
                              const SizedBox(height: 8),
                              Text(
                                'Nenhuma entrega em curso',
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: Colors.grey[500],
                                ),
                              ),
                            ],
                          ),
                        )
                      : ListView(
                          children: children,
                        ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
