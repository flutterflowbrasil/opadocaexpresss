import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/perfil/profile_controller.dart';
import 'dashboard_colors.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

class SidebarMenu extends ConsumerWidget {
  final int selectedIndex;
  final Function(int) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.selectedIndex,
    required this.onItemSelected,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    void toggleSidebar() {
      ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 250),
      width: isCollapsed ? 80 : 256, // 64rem equivalent in tailwind
      color: DashboardColors.burgundy,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                IconButton(
                  icon: Icon(
                    isCollapsed ? Icons.menu : Icons.menu_open,
                    color: Colors.white70,
                  ),
                  tooltip: isCollapsed ? 'Expandir' : 'Minimizar',
                  onPressed: toggleSidebar,
                ),
                if (!isCollapsed)
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: DashboardColors.primary,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(Icons.bakery_dining,
                                color: Colors.white, size: 20),
                          ),
                          const SizedBox(width: 12),
                          Text.rich(
                            TextSpan(
                              style: GoogleFonts.publicSans(
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                              children: const [
                                TextSpan(text: 'Ôpadoca\n'),
                                TextSpan(
                                  text: 'Express',
                                  style:
                                      TextStyle(color: DashboardColors.primary),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          // Menu Items
          Expanded(
            child: ListView(
              padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 8 : 16),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard,
                  title: 'Painel Inicial',
                  index: 0,
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long,
                  title: 'Pedidos',
                  index: 1,
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.inventory_2,
                  title: 'Produtos',
                  index: 2,
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bar_chart,
                  title: 'Status',
                  index: 3,
                  isCollapsed: isCollapsed,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Configurações',
                  index: 4,
                  isCollapsed: isCollapsed,
                ),
              ],
            ),
          ),

          // User Profile Area at Bottom
          Container(
            padding: EdgeInsets.all(isCollapsed ? 8 : 16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              mainAxisAlignment: isCollapsed
                  ? MainAxisAlignment.center
                  : MainAxisAlignment.start,
              children: [
                if (!isCollapsed)
                  Expanded(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.2)),
                              image: const DecorationImage(
                                image: AssetImage(
                                    'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png'), // placeholder
                                fit: BoxFit.cover,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Carlos Padoca',
                                style: GoogleFonts.publicSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'Gerente',
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  color: Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                IconButton(
                  onPressed: () async {
                    ref.invalidate(dashboardControllerProvider);
                    ref.invalidate(carrinhoControllerProvider);
                    ref.invalidate(profileControllerProvider);
                    await ref.read(authRepositoryProvider).signOut();
                    if (context.mounted) {
                      context.go('/login');
                    }
                  },
                  icon: const Icon(Icons.logout, color: Colors.white70),
                  tooltip: 'Sair',
                )
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  Widget _buildMenuItem({
    required BuildContext context,
    required IconData icon,
    required String title,
    required int index,
    required bool isCollapsed,
  }) {
    final isSelected = selectedIndex == index;

    return SidebarMenuItem(
      title: title,
      icon: icon,
      isSelected: isSelected,
      isCollapsed: isCollapsed,
      onTap: () {
        if (!isSelected) {
          if (index == 0) {
            context.go('/dashboard_estabelecimento');
          } else if (index == 1) {
            context.go('/dashboard_estabelecimento/pedidos');
          } else if (index == 2) {
            context.go('/dashboard_estabelecimento/produtos');
          } else if (index == 4) {
            context.go('/dashboard_estabelecimento/configuracoes');
          }
        }
        onItemSelected(index);
      },
    );
  }
}

class SidebarMenuItem extends StatefulWidget {
  final String title;
  final IconData icon;
  final bool isSelected;
  final bool isCollapsed;
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    final Color iconAndTextColor = widget.isSelected
        ? DashboardColors.primary
        : (_isHovering ? DashboardColors.accent : Colors.white);

    final Color backgroundColor = widget.isSelected
        ? DashboardColors.primary.withValues(alpha: 0.2)
        : (_isHovering
            ? DashboardColors.accent.withValues(alpha: 0.1)
            : Colors.transparent);

    final Border? border = widget.isSelected
        ? Border.all(color: DashboardColors.primary.withValues(alpha: 0.3))
        : (_isHovering
            ? Border.all(color: DashboardColors.accent.withValues(alpha: 0.3))
            : null);

    return MouseRegion(
      onEnter: (_) => setState(() => _isHovering = true),
      onExit: (_) => setState(() => _isHovering = false),
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
            vertical: 12,
            horizontal: widget.isCollapsed ? 0 : 12,
          ),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
            color: backgroundColor,
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(
                widget.icon,
                color: iconAndTextColor,
                size: widget.isCollapsed ? 28 : 24,
              ),
              if (!widget.isCollapsed)
                Flexible(
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    physics: const NeverScrollableScrollPhysics(),
                    child: Padding(
                      padding: const EdgeInsets.only(left: 12),
                      child: Text(
                        widget.title,
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: widget.isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                          color: iconAndTextColor,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
