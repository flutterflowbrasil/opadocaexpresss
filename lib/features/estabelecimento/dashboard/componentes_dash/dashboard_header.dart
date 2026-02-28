import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dashboard_colors.dart';

class DashboardHeader extends StatelessWidget {
  final String estabelecimentoNome;

  const DashboardHeader({super.key, required this.estabelecimentoNome});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? DashboardColors.backgroundDark.withValues(alpha: 0.8)
            : DashboardColors.backgroundLight.withValues(alpha: 0.8),
        border: Border(
          bottom: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
          ),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              if (MediaQuery.of(context).size.width < 800)
                IconButton(
                  icon: Icon(
                    Icons.menu,
                    color: isDark ? Colors.white : DashboardColors.burgundy,
                  ),
                  onPressed: () => Scaffold.of(context).openDrawer(),
                ),
              Text(
                'Resumo do Dia',
                style: GoogleFonts.publicSans(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          Row(
            children: [
              // Loja Aberta Toggle
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[800] : Colors.grey[100],
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                  ),
                ),
                child: Row(
                  children: [
                    Text(
                      'Loja Aberta',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.grey[300] : Colors.grey[600],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Switch(
                      value: true, // TODO: Bind to state
                      onChanged: (val) {},
                      activeColor: Colors.white,
                      activeTrackColor: Colors.green,
                      inactiveThumbColor: Colors.white,
                      inactiveTrackColor: Colors.grey[400],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              // Notifications
              Stack(
                alignment: Alignment.center,
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.notifications,
                      color: isDark
                          ? DashboardColors.cream
                          : DashboardColors.burgundy,
                    ),
                    onPressed: () {},
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: DashboardColors.primary,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isDark ? Colors.grey[800]! : Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(width: 12),
              // User Info
              if (MediaQuery.of(context).size.width >= 600)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      estabelecimentoNome,
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: isDark ? Colors.white : Colors.black87,
                      ),
                    ),
                    Text(
                      'Gerente',
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                    ),
                  ],
                ),
              if (MediaQuery.of(context).size.width >= 600)
                const SizedBox(width: 12),
              Container(
                width: 40,
                height: 40,
                decoration: const BoxDecoration(
                  color: DashboardColors.burgundy,
                  shape: BoxShape.circle,
                ),
                alignment: Alignment.center,
                child: Text(
                  estabelecimentoNome.isNotEmpty
                      ? estabelecimentoNome[0].toUpperCase()
                      : 'A',
                  style: GoogleFonts.publicSans(
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
