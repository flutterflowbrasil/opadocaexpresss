import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'dashboard_colors.dart';

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
    return Container(
      width: 256, // 64rem equivalent in tailwind
      color: DashboardColors.burgundy,
      child: Column(
        children: [
          const SizedBox(height: 24),
          // Logo Area
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: DashboardColors.primary,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(Icons.bakery_dining,
                      color: Colors.white, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: RichText(
                    text: TextSpan(
                      style: GoogleFonts.publicSans(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      children: const [
                        TextSpan(text: 'Ôpadoca\n'),
                        TextSpan(
                          text: 'Express',
                          style: TextStyle(color: DashboardColors.primary),
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
              padding: const EdgeInsets.symmetric(horizontal: 16),
              children: [
                _buildMenuItem(
                  context: context,
                  icon: Icons.dashboard, // filled icon style per HTML
                  title: 'Painel Inicial',
                  index: 0,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.receipt_long,
                  title: 'Pedidos',
                  index: 1,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.inventory_2,
                  title: 'Produtos',
                  index: 2,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.bar_chart, // closest to monitoring
                  title: 'Status',
                  index: 3,
                ),
                const SizedBox(height: 8),
                _buildMenuItem(
                  context: context,
                  icon: Icons.settings,
                  title: 'Configurações',
                  index: 4,
                ),
              ],
            ),
          ),

          // User Profile Area at Bottom
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                  top: BorderSide(color: Colors.white.withValues(alpha: 0.1))),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border:
                        Border.all(color: Colors.white.withValues(alpha: 0.2)),
                    image: const DecorationImage(
                      image: AssetImage(
                          'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png'), // placeholder
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Carlos Padoca',
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.ellipsis,
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
                ),
                IconButton(
                  onPressed: () async {
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
  }) {
    final isSelected = selectedIndex == index;

    return SidebarMenuItem(
      title: title,
      icon: icon,
      isSelected: isSelected,
      onTap: () {
        if (!isSelected) {
          if (index == 0) {
            context.go('/dashboard_estabelecimento');
          } else if (index == 1) {
            context.go('/dashboard_estabelecimento/pedidos');
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
  final VoidCallback onTap;

  const SidebarMenuItem({
    super.key,
    required this.title,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  State<SidebarMenuItem> createState() => _SidebarMenuItemState();
}

class _SidebarMenuItemState extends State<SidebarMenuItem> {
  bool _isHovering = false;

  @override
  Widget build(BuildContext context) {
    // Determine styles based on selection and hover state
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
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: border,
            color: backgroundColor,
          ),
          child: Row(
            children: [
              Icon(
                widget.icon,
                color: iconAndTextColor,
                size: 24,
              ),
              const SizedBox(width: 12),
              Text(
                widget.title,
                style: GoogleFonts.publicSans(
                  fontSize: 16,
                  fontWeight:
                      widget.isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: iconAndTextColor,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
