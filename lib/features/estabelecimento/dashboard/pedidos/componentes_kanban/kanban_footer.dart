import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../componentes_dash/dashboard_colors.dart';

class KanbanFooter extends StatelessWidget {
  const KanbanFooter({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 48,
      color: DashboardColors.burgundy,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              _buildStatusDot(Colors.greenAccent),
              const SizedBox(width: 4),
              Text(
                'Servidor: Online',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              const SizedBox(width: 24),
              _buildStatusDot(DashboardColors.primary),
              const SizedBox(width: 4),
              Text(
                'Entregadores: 4 ativos',
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
          if (MediaQuery.of(context).size.width >= 768)
            RichText(
              text: TextSpan(
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
                children: const [
                  TextSpan(text: 'Tempo médio de preparo: '),
                  TextSpan(
                    text: '14 min',
                    style: TextStyle(
                      color: DashboardColors.primary,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildStatusDot(Color color) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(
        color: color,
        shape: BoxShape.circle,
      ),
    );
  }
}
