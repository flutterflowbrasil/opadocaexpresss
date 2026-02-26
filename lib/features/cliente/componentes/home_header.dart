import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';

/// AppBar reutilizável do cliente.
/// - Mobile: endereço | busca compacta | ícones
/// - Desktop: endereço | busca expandida | ícones (estilo iFood)
class ClienteAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onAddressTap;
  final bool showBackButton;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const ClienteAppBar({
    super.key,
    required this.isDark,
    this.onNotificationTap,
    this.onCartTap,
    this.onAddressTap,
    this.showBackButton = false,
  });

  @override
  Size get preferredSize => const Size.fromHeight(64);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isDesktop = screenWidth >= 900;
    final isTablet = screenWidth >= 600 && screenWidth < 900;

    final cartCount = ref.watch(carrinhoControllerProvider).quantidadeTotal;

    final cardBg = isDark ? const Color(0xFF27272A) : Colors.white;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    return Container(
      color: bgColor,
      padding: EdgeInsets.symmetric(
        horizontal: isDesktop ? 40 : 16,
        vertical: 10,
      ),
      child: SafeArea(
        bottom: false,
        child: isDesktop || isTablet
            ? _buildDesktopBar(context, cardBg, cartCount)
            : _buildMobileBar(context, cardBg, cartCount),
      ),
    );
  }

  // ─── Mobile ───────────────────────────────────────────────────────────────
  Widget _buildMobileBar(BuildContext context, Color cardBg, int cartCount) {
    return Row(
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          const SizedBox(width: 12),
        ],
        // Endereço
        Expanded(
          child: GestureDetector(
            onTap: onAddressTap,
            child: Row(
              children: [
                Icon(Icons.location_on_outlined,
                    color: _primaryColor, size: 18),
                const SizedBox(width: 6),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'ENTREGAR EM',
                        style: GoogleFonts.outfit(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey,
                          letterSpacing: 1.0,
                        ),
                      ),
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              'Rua das Flores, 123',
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: isDark ? Colors.white : _secondaryColor,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Icon(
                            Icons.keyboard_arrow_down,
                            size: 14,
                            color: isDark ? Colors.white70 : _secondaryColor,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Campo de busca compacto (read-only → navega)
        Flexible(
          child: GestureDetector(
            onTap: () => context.push('/busca'),
            child: Container(
              height: 36,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: Colors.grey.withValues(alpha: 0.2),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(width: 8),
                  Icon(Icons.search_rounded, size: 16, color: Colors.grey[500]),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      'Buscar...',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: Colors.grey[500],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 8),

        // Ícones de ação
        _ActionButton(
          icon: Icons.notifications_outlined,
          isDark: isDark,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 8),
        _buildCartButton(context, cartCount),
      ],
    );
  }

  // ─── Desktop / Tablet ─────────────────────────────────────────────────────
  Widget _buildDesktopBar(BuildContext context, Color cardBg, int cartCount) {
    return Row(
      children: [
        if (showBackButton) ...[
          IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          const SizedBox(width: 16),
        ],
        // Logo / Brand
        MouseRegion(
          cursor: SystemMouseCursors.click,
          child: GestureDetector(
            onTap: () => context.go('/home'),
            child: Text(
              'ÔPadoca',
              style: GoogleFonts.outfit(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: _primaryColor,
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Endereço compacto
        GestureDetector(
          onTap: onAddressTap,
          child: Row(
            children: [
              Icon(Icons.location_on_outlined, color: _primaryColor, size: 16),
              const SizedBox(width: 4),
              Text(
                'Rua das Flores, 123',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : _secondaryColor,
                ),
              ),
              Icon(Icons.keyboard_arrow_down,
                  size: 14, color: isDark ? Colors.white54 : _secondaryColor),
            ],
          ),
        ),

        const SizedBox(width: 16),

        // Busca expandida (centro)
        Expanded(
          child: GestureDetector(
            onTap: () => context.push('/busca'),
            child: Container(
              height: 42,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF3A3A3A) : cardBg,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.15)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.04),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                children: [
                  const SizedBox(width: 14),
                  Icon(Icons.search_rounded, color: Colors.grey[400], size: 20),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      'Busque por produtos ou padarias...',
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: Colors.grey[400],
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(width: 16),

        // Ícones
        _ActionButton(
          icon: Icons.notifications_outlined,
          isDark: isDark,
          onTap: onNotificationTap,
        ),
        const SizedBox(width: 10),
        _buildCartButton(context, cartCount),
      ],
    );
  }

  Widget _buildCartButton(BuildContext context, int cartCount) {
    final btn = _ActionButton(
      icon: Icons.shopping_bag_outlined,
      isDark: isDark,
      onTap: onCartTap ?? () => context.push('/carrinho'),
    );

    if (cartCount == 0) return btn;

    return Badge(
      label: Text(cartCount.toString()),
      backgroundColor: _primaryColor,
      textColor: Colors.white,
      offset: const Offset(-4, 4),
      child: btn,
    );
  }
}

// ─── Botão circular de ação ───────────────────────────────────────────────────
class _ActionButton extends StatelessWidget {
  final IconData icon;
  final bool isDark;
  final VoidCallback? onTap;

  const _ActionButton({
    required this.icon,
    required this.isDark,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Icon(
          icon,
          size: 19,
          color: isDark ? Colors.white : const Color(0xFF7D2D35),
        ),
      ),
    );
  }
}
