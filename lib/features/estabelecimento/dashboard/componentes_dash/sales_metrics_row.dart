import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dashboard_colors.dart';

class SalesMetricsRow extends StatelessWidget {
  final double vendasHoje;
  final int pedidosAtivos;
  final double ticketMedio;
  final double avaliacaoMedia;

  const SalesMetricsRow({
    super.key,
    required this.vendasHoje,
    required this.pedidosAtivos,
    required this.ticketMedio,
    required this.avaliacaoMedia,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1024
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 1);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 3.0,
          children: [
            _buildMetricCard(
              context,
              title: 'Vendas Hoje',
              value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(vendasHoje),
              extraText: '12%',
              extraIcon: Icons.trending_up,
              extraColor: Colors.green,
            ),
            _buildMetricCard(
              context,
              title: 'Pedidos Ativos',
              value: pedidosAtivos.toString(),
              extraText: 'Pendentes',
              extraColor: DashboardColors.primary,
            ),
            _buildMetricCard(
              context,
              title: 'Ticket Médio',
              value: NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                  .format(ticketMedio),
              extraText: 'Estável',
              extraColor: Colors.grey[400]!,
            ),
            _buildMetricCard(
              context,
              title: 'Avaliação',
              value:
                  '$avaliacaoMedia', // Using string format because star is appended
              extraText: '92 reviews',
              extraIcon: Icons.star,
              extraIconColor: Colors.yellow[600],
              extraColor: Colors.grey[400]!,
            ),
          ],
        );
      },
    );
  }

  Widget _buildMetricCard(
    BuildContext context, {
    required String title,
    required String value,
    required String extraText,
    required Color extraColor,
    IconData? extraIcon,
    Color? extraIconColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: GoogleFonts.publicSans(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: Colors.grey[500],
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.baseline,
                textBaseline: TextBaseline.alphabetic,
                children: [
                  Text(
                    value,
                    style: GoogleFonts.publicSans(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: isDark
                          ? DashboardColors.cream
                          : DashboardColors.burgundy,
                    ),
                  ),
                  if (extraIcon != null && title == 'Avaliação') ...[
                    const SizedBox(width: 4),
                    Icon(extraIcon,
                        color: extraIconColor ?? extraColor, size: 20),
                  ]
                ],
              ),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  if (extraIcon != null && title != 'Avaliação') ...[
                    Icon(extraIcon, color: extraColor, size: 14),
                    const SizedBox(width: 4),
                  ],
                  Text(
                    extraText,
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight:
                          title == 'Ticket Médio' || title == 'Avaliação'
                              ? FontWeight.normal
                              : FontWeight.bold,
                      color: extraColor,
                    ),
                  ),
                ],
              )
            ],
          ),
        ],
      ),
    );
  }
}
