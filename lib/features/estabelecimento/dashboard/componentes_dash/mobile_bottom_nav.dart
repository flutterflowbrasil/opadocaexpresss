import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_colors.dart';

class MobileBottomNav extends StatelessWidget {
  const MobileBottomNav({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: DashboardColors.burgundy,
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
        ),
      ),
      padding: const EdgeInsets.only(bottom: 16, top: 4),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _buildNavItem(Icons.dashboard, 'Painel', true),
            _buildNavItem(Icons.receipt_long, 'Vendas', false),

            // Central Add Button
            Transform.translate(
              offset: const Offset(0, -16),
              child: Container(
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: DashboardColors.burgundy, width: 4),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.4),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Material(
                  color: DashboardColors.primary,
                  shape: const CircleBorder(),
                  child: InkWell(
                    onTap: () {},
                    customBorder: const CircleBorder(),
                    child: const Padding(
                      padding: EdgeInsets.all(16),
                      child: Icon(Icons.add, color: Colors.white, size: 32),
                    ),
                  ),
                ),
              ),
            ),

            _buildNavItem(Icons.inventory_2, 'Estoque', false),
            _buildNavItem(Icons.menu, 'Menu', false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isSelected) {
    return InkWell(
      onTap: () {},
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            color: isSelected
                ? DashboardColors.primary
                : Colors.white.withValues(alpha: 0.6),
          ),
          const SizedBox(height: 4),
          Text(
            label.toUpperCase(),
            style: GoogleFonts.publicSans(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: isSelected
                  ? DashboardColors.primary
                  : Colors.white.withValues(alpha: 0.6),
            ),
          )
        ],
      ),
    );
  }
}
