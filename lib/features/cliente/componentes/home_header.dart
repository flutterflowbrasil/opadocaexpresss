import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class HomeHeader extends StatelessWidget {
  final bool isDark;
  final Color primaryColor;
  final Color secondaryColor;
  final Color cardColor;

  const HomeHeader({
    super.key,
    required this.isDark,
    required this.primaryColor,
    required this.secondaryColor,
    required this.cardColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Icon(Icons.location_on_outlined, color: primaryColor),
                  const SizedBox(width: 8),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'ENTREGAR EM',
                        style: GoogleFonts.outfit(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.2,
                        ),
                      ),
                      Row(
                        children: [
                          Text(
                            'Rua das Flores, 123',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : secondaryColor,
                            ),
                          ),
                          const Icon(Icons.keyboard_arrow_down, size: 16),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                children: [
                  _buildCircleButton(Icons.notifications_outlined, isDark),
                  const SizedBox(width: 12),
                  _buildCircleButton(Icons.shopping_bag_outlined, isDark),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),
          // Search Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Buscar padarias, doces, salgados...',
                hintStyle: GoogleFonts.outfit(color: Colors.grey, fontSize: 14),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircleButton(IconData icon, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Icon(
        icon,
        size: 20,
        color: isDark ? Colors.white : const Color(0xFF7D2D35),
      ),
    );
  }
}
