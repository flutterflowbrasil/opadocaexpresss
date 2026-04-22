import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/notificacoes/controllers/notificacoes_controller.dart';

/// AppBar reutilizável do cliente.
/// - Mobile: endereço | busca compacta | ícones
/// - Desktop: endereço | busca expandida | ícones (estilo iFood)
class ClienteAppBar extends ConsumerWidget implements PreferredSizeWidget {
  final bool isDark;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onCartTap;
  final VoidCallback? onAddressTap;
  final bool showBackButton;
  final bool showSearch;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const ClienteAppBar({
    super.key,
    required this.isDark,
    this.onNotificationTap,
    this.onCartTap,
    this.onAddressTap,
    this.showBackButton = false,
    this.showSearch = true,
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
            ? _buildDesktopBar(context, cardBg, cartCount, ref)
            : _buildMobileBar(context, cardBg, cartCount, ref),
      ),
    );
  }

  // ─── Mobile ───────────────────────────────────────────────────────────────
  Widget _buildMobileBar(BuildContext context, Color cardBg, int cartCount, WidgetRef ref) {
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
        const Spacer(),

        // Ícone de busca compacto
        if (showSearch)
          _ActionButton(
            icon: Icons.search_rounded,
            isDark: isDark,
            onTap: () => context.push('/busca'),
          ),

        const SizedBox(width: 8),

        // Ícones de ação
        _buildNotificationButton(context, ref),
        const SizedBox(width: 8),
        _buildCartButton(context, cartCount),
      ],
    );
  }

  // ─── Desktop / Tablet ─────────────────────────────────────────────────────
  Widget _buildDesktopBar(BuildContext context, Color cardBg, int cartCount, WidgetRef ref) {
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

        // Busca expandida (centro)
        if (showSearch)
          Expanded(
            child: GestureDetector(
              onTap: () => context.push('/busca'),
              child: Container(
                height: 42,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF3A3A3A) : cardBg,
                  borderRadius: BorderRadius.circular(12),
                  border:
                      Border.all(color: Colors.grey.withValues(alpha: 0.15)),
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
                    Icon(Icons.search_rounded,
                        color: Colors.grey[400], size: 20),
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
          )
        else
          const Spacer(),

        const SizedBox(width: 16),

        // Ícones
        _buildNotificationButton(context, ref),
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

  Widget _buildNotificationButton(BuildContext context, WidgetRef ref) {
    final notificacoes = ref.watch(notificacoesControllerProvider);
    final unreadCount = notificacoes.length;
    
    final btn = _ActionButton(
      icon: Icons.notifications_outlined,
      isDark: isDark,
      onTap: () {
        if (onNotificationTap != null) {
          onNotificationTap!();
        } else {
          _showNotificationsModal(context, ref, notificacoes);
        }
      },
    );

    if (unreadCount == 0) return btn;

    return Badge(
      label: Text(unreadCount > 9 ? '9+' : unreadCount.toString()),
      backgroundColor: Colors.redAccent,
      textColor: Colors.white,
      offset: const Offset(-4, 4),
      child: btn,
    );
  }

  void _showNotificationsModal(BuildContext context, WidgetRef ref, List<AppNotificationModel> notificacoes) {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: isDark ? const Color(0xFF27272A) : Colors.white,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Notificações',
                style: GoogleFonts.outfit(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : const Color(0xFF7D2D35),
                ),
              ),
              IconButton(
                icon: Icon(Icons.close, color: isDark ? Colors.white70 : Colors.black54),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ],
          ),
          content: SizedBox(
            width: double.maxFinite,
            child: notificacoes.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Text(
                      'Você não tem novas notificações no momento.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.white70 : Colors.black54,
                        fontSize: 16,
                      ),
                    ),
                  )
                : ListView.separated(
                    shrinkWrap: true,
                    itemCount: notificacoes.length,
                    separatorBuilder: (_, __) => const Divider(),
                    itemBuilder: (ctx, index) {
                      final notif = notificacoes[index];
                      return ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFFFF7034).withValues(alpha: 0.2),
                          child: Icon(
                            notif.status == 'pronto' ? Icons.check_circle_outline : Icons.delivery_dining,
                            color: const Color(0xFFFF7034),
                          ),
                        ),
                        title: Text(
                          notif.title,
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        subtitle: Text(
                          notif.body,
                          style: GoogleFonts.outfit(
                            fontSize: 13,
                            color: isDark ? Colors.white70 : Colors.black54,
                          ),
                        ),
                        onTap: () {
                          // Remove a notificação lida e fecha modal
                          ref.read(notificacoesControllerProvider.notifier).removeNotification(notif.pedidoId);
                          Navigator.of(ctx).pop();
                          // Direciona
                          context.push('/cliente/pedido/${notif.pedidoId}');
                        },
                      );
                    },
                  ),
          ),
          actions: notificacoes.isEmpty ? null : [
             TextButton(
               onPressed: () {
                 ref.read(notificacoesControllerProvider.notifier).clearAll();
                 Navigator.of(ctx).pop();
               },
               child: Text('Limpar Todas', style: GoogleFonts.outfit(color: const Color(0xFFFF7034))),
             )
          ],
        );
      },
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
