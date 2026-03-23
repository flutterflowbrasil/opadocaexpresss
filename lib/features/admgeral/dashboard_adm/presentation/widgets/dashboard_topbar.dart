import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/admin_dashboard_controller.dart';

// IDs de telas que exibem a barra de pesquisa no topbar
// 'entregadores' foi removido — tem campo de busca próprio na tela
const _screensWithSearch = {'usuarios', 'relatorios'};

class DashboardTopbar extends ConsumerWidget {
  final bool isMobile;
  final VoidCallback? onMenuTapped;
  final String activeScreen;
  final VoidCallback? onRefresh;

  const DashboardTopbar({
    super.key,
    this.isMobile = false,
    this.onMenuTapped,
    this.activeScreen = 'dashboard',
    this.onRefresh,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSync = ref.watch(
      adminDashboardControllerProvider.select((s) => s.lastSync),
    );

    final showSearch = !isMobile && _screensWithSearch.contains(activeScreen);

    final syncLabel = lastSync != null
        ? 'Atualizado às ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
        : 'Carregando...';

    return Container(
      height: 58,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Esquerda: hamburger (mobile) + título
          Row(
            children: [
              if (isMobile) ...[
                IconButton(
                  icon: const Icon(Icons.menu, color: Color(0xFF1A0910)),
                  onPressed: onMenuTapped,
                ),
                const SizedBox(width: 8),
              ],
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Painel Administrativo',
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                  Text(
                    syncLabel,
                    style: GoogleFonts.publicSans(fontSize: 11, color: const Color(0xFF9CA3AF)),
                  ),
                ],
              ),
            ],
          ),

          // Direita: pesquisa (condicional) + refresh + notificação + avatar
          Row(
            children: [
              if (showSearch)
                Container(
                  width: 200,
                  height: 36,
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EF),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.search, size: 16, color: Color(0xFF9CA3AF)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: TextField(
                          decoration: InputDecoration(
                            hintText: 'Buscar...',
                            hintStyle: GoogleFonts.publicSans(
                              fontSize: 12,
                              color: const Color(0xFF9CA3AF),
                            ),
                            border: InputBorder.none,
                            isDense: true,
                            contentPadding: EdgeInsets.zero,
                          ),
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: const Color(0xFF1A0910),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (showSearch) const SizedBox(width: 10),

              // Botão Refresh (oculto em telas com refresh próprio)
              if (activeScreen != 'estabelecimentos' &&
                  activeScreen != 'entregadores')
                GestureDetector(
                  onTap: onRefresh ??
                      () => ref.read(adminDashboardControllerProvider.notifier).fetchData(),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(9),
                      border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                    ),
                    child: const Icon(Icons.refresh, size: 18, color: Color(0xFF6B7280)),
                  ),
                ),
              if (activeScreen != 'estabelecimentos' &&
                  activeScreen != 'entregadores')
                const SizedBox(width: 10),

              // Notificações
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                ),
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    const Icon(Icons.notifications_none, size: 18, color: Color(0xFF6B7280)),
                    Positioned(
                      top: 6,
                      right: 6,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: const Color(0xFFEF4444),
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
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [Color(0xFFF97316), Color(0xFF9B2C2C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Center(
                  child: Text(
                    'A',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
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
