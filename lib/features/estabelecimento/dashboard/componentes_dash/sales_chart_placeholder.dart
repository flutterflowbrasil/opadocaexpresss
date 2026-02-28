import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_colors.dart';

class SalesChartPlaceholder extends StatelessWidget {
  const SalesChartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Fluxo de Vendas (24h)',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[900] : Colors.grey[50],
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Hoje',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
              )
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            height: 250,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildBar(0.4, '08h',
                    DashboardColors.burgundy.withValues(alpha: 0.1)),
                _buildBar(0.6, '10h',
                    DashboardColors.burgundy.withValues(alpha: 0.1)),
                _buildBar(0.95, '12h', DashboardColors.primary),
                _buildBar(0.75, '14h',
                    DashboardColors.burgundy.withValues(alpha: 0.1)),
                _buildBar(0.55, '16h',
                    DashboardColors.burgundy.withValues(alpha: 0.1)),
                _buildBar(0.85, '18h',
                    DashboardColors.primary.withValues(alpha: 0.6)),
                _buildBar(0.45, '20h',
                    DashboardColors.burgundy.withValues(alpha: 0.1)),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Container(
                  width: 12,
                  height: 12,
                  decoration: const BoxDecoration(
                      shape: BoxShape.circle, color: DashboardColors.primary)),
              const SizedBox(width: 4),
              Text('Pico de Vendas',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey[500])),
              const SizedBox(width: 16),
              Container(
                  width: 12,
                  height: 12,
                  decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: DashboardColors.burgundy.withValues(alpha: 0.2))),
              const SizedBox(width: 4),
              Text('Fluxo Médio',
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: Colors.grey[500])),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildBar(double heightFactor, String label, Color color) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Align(
                alignment: Alignment.bottomCenter,
                child: FractionallySizedBox(
                  heightFactor: heightFactor,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius:
                          const BorderRadius.vertical(top: Radius.circular(8)),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              label,
              style: GoogleFonts.publicSans(
                fontSize: 10,
                color: Colors.grey[400],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
