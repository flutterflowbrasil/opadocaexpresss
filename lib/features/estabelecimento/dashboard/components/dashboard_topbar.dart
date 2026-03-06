import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../dashboard_controller.dart';

class DashboardTopbar extends ConsumerWidget {
  final String estabelecimentoNome;
  final bool isLojaAberta;
  final String dateText;

  const DashboardTopbar({
    super.key,
    required this.estabelecimentoNome,
    required this.isLojaAberta,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    return Container(
      color: Colors.white,
      padding: EdgeInsets.symmetric(horizontal: isWideScreen ? 24 : 12),
      height: 64,
      child: Builder(
        builder: (ctx) => Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // Hamburger icon (mobile only)
            if (!isWideScreen)
              InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.menu,
                      color: Color(0xFF6B7280), size: 20),
                ),
              ),

            if (!isWideScreen) const SizedBox(width: 10),

            // Greeting & Info
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bom dia, $estabelecimentoNome 👋',
                    style: GoogleFonts.publicSans(
                      fontSize: isWideScreen ? 16 : 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '$dateText · ${isLojaAberta ? "Loja aberta" : "Loja fechada"}',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: const Color(0xFF9CA3AF),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 8),

            // Actions Area
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Refresh Button
                InkWell(
                  onTap: () => ref
                      .read(dashboardControllerProvider.notifier)
                      .recarregar(),
                  borderRadius: BorderRadius.circular(9),
                  child: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      border: Border.all(
                          color: const Color(0xFFEAE8E4), width: 1.5),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.refresh,
                        color: Color(0xFF6B7280), size: 18),
                  ),
                ),
                const SizedBox(width: 10),

                // Notification Bell
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      const Icon(Icons.notifications_none,
                          color: Color(0xFF6B7280), size: 18),
                      Positioned(
                        top: 8,
                        right: 8,
                        child: Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Avatar
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFF9B2C2C)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  alignment: Alignment.center,
                  child: Text(
                    estabelecimentoNome.isNotEmpty
                        ? estabelecimentoNome[0].toUpperCase()
                        : 'L',
                    style: GoogleFonts.publicSans(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
