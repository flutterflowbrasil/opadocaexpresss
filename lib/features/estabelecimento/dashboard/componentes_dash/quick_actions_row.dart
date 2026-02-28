import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_colors.dart';

class QuickActionsRow extends StatelessWidget {
  const QuickActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final crossAxisCount = constraints.maxWidth > 1024
            ? 4
            : (constraints.maxWidth > 600 ? 2 : 2);

        return GridView.count(
          crossAxisCount: crossAxisCount,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 16),
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 2.5,
          children: [
            _buildActionCard(
              context,
              icon: Icons.add_circle,
              title: 'Novo Produto',
              bgColor: DashboardColors.primary,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            _buildActionCard(
              context,
              icon: Icons.update,
              title: 'Atualizar Status',
              bgColor: DashboardColors.burgundy,
              iconColor: Colors.white,
              textColor: Colors.white,
            ),
            _buildActionCard(
              context,
              icon: Icons.campaign,
              title: 'Anunciar Oferta',
              bgColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.white,
              iconColor: DashboardColors.primary,
              textColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              border: true,
            ),
            _buildActionCard(
              context,
              icon: Icons.local_shipping,
              title: 'Entregas',
              bgColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.grey[800]!
                  : Colors.white,
              iconColor: Theme.of(context).brightness == Brightness.dark
                  ? DashboardColors.cream
                  : DashboardColors.burgundy,
              textColor: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : Colors.black87,
              border: true,
            ),
          ],
        );
      },
    );
  }

  Widget _buildActionCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color bgColor,
    required Color iconColor,
    required Color textColor,
    bool border = false,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      onTap: () {},
      borderRadius: BorderRadius.circular(12),
      child: Container(
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(12),
          border: border
              ? Border.all(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!)
              : null,
          boxShadow: [
            if (!border)
              BoxShadow(
                color: bgColor.withValues(alpha: 0.2),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: iconColor, size: 32),
            const SizedBox(height: 8),
            Text(
              title,
              textAlign: TextAlign.center,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
