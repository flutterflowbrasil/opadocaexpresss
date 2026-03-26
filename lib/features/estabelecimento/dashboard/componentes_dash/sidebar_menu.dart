import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/auth/data/auth_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/pedidos/controllers/pedidos_kanban_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/perfil/profile_controller.dart';
import 'dashboard_colors.dart';
import 'store_status_modals.dart';

final sidebarCollapsedProvider = StateProvider<bool>((ref) => false);

// ─── Modelo de item de menu ──────────────────────────────────────────────────

class _MenuItem {
  final String id;
  final String label;
  final IconData icon;
  final String? route;

  const _MenuItem({
    required this.id,
    required this.label,
    required this.icon,
    this.route,
  });
}

class _MenuSection {
  final String label;
  final List<_MenuItem> items;
  const _MenuSection({required this.label, required this.items});
}

// ─── Definição das seções ────────────────────────────────────────────────────

const _sections = [
  _MenuSection(
    label: 'OPERAÇÃO',
    items: [
      _MenuItem(
        id: 'dashboard',
        label: 'Painel Inicial',
        icon: Icons.dashboard_rounded,
        route: '/dashboard_estabelecimento',
      ),
      _MenuItem(
        id: 'orders',
        label: 'Pedidos',
        icon: Icons.receipt_long_rounded,
        route: '/dashboard_estabelecimento/pedidos',
      ),
    ],
  ),
  _MenuSection(
    label: 'CARDÁPIO',
    items: [
      _MenuItem(
        id: 'products',
        label: 'Produtos',
        icon: Icons.inventory_2_rounded,
        route: '/dashboard_estabelecimento/produtos',
      ),
      _MenuItem(
        id: 'coupons',
        label: 'Cupons & Ofertas',
        icon: Icons.local_offer_rounded,
        route: '/dashboard_estabelecimento/cupons',
      ),
    ],
  ),
  _MenuSection(
    label: 'CRESCIMENTO',
    items: [
      _MenuItem(
        id: 'reviews',
        label: 'Avaliações',
        icon: Icons.star_rounded,
      ),
    ],
  ),
  _MenuSection(
    label: 'GESTÃO',
    items: [
      _MenuItem(
        id: 'finance',
        label: 'Financeiro',
        icon: Icons.attach_money_rounded,
        route: '/dashboard_estabelecimento/financeiro',
      ),
      _MenuItem(
        id: 'team',
        label: 'Equipe & Acessos',
        icon: Icons.shield_rounded,
      ),
      _MenuItem(
        id: 'reports',
        label: 'Relatórios',
        icon: Icons.bar_chart_rounded,
        route: '/dashboard_estabelecimento/relatorios',
      ),
    ],
  ),
];

const _bottomItems = [
  _MenuItem(
    id: 'settings',
    label: 'Configurações',
    icon: Icons.settings_rounded,
    route: '/dashboard_estabelecimento/configuracoes',
  ),
];

// ─── Widget principal ────────────────────────────────────────────────────────

class SidebarMenu extends ConsumerStatefulWidget {
  final String activeId;
  final Function(String) onItemSelected;

  const SidebarMenu({
    super.key,
    required this.activeId,
    required this.onItemSelected,
  });

  @override
  ConsumerState<SidebarMenu> createState() => _SidebarMenuState();
}

class _SidebarMenuState extends ConsumerState<SidebarMenu> {
  // Seções abertas por padrão
  final Set<String> _openSections = {
    'OPERAÇÃO',
    'CARDÁPIO',
    'CRESCIMENTO',
    'GESTÃO'
  };

  void _toggleSection(String label) {
    setState(() {
      if (_openSections.contains(label)) {
        _openSections.remove(label);
      } else {
        _openSections.add(label);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final isCollapsed = ref.watch(sidebarCollapsedProvider);

    void toggleSidebar() {
      ref.read(sidebarCollapsedProvider.notifier).state = !isCollapsed;
    }

    return AnimatedContainer(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeInOut,
      width: isCollapsed ? 68 : 252,
      color: const Color(0xFF1E0A14),
      child: Column(
        children: [
          // ── Logo / Toggle ─────────────────────────────────────
          _buildHeader(isCollapsed, toggleSidebar),

          // ── Pill "Loja Aberta" ────────────────────────────────
          if (!isCollapsed) _buildStorePill(),

          // ── Itens de navegação ────────────────────────────────
          Expanded(
            child: ScrollConfiguration(
              behavior:
                  ScrollConfiguration.of(context).copyWith(scrollbars: false),
              child: ListView(
                padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
                children: [
                  for (final section in _sections)
                    _buildSection(section, isCollapsed),
                ],
              ),
            ),
          ),

          // ── Itens inferiores (Settings, Help) ─────────────────
          _buildBottomItems(isCollapsed),

          // ── Perfil / Logout ───────────────────────────────────
          _buildUserRow(isCollapsed),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────

  Widget _buildHeader(bool isCollapsed, VoidCallback onToggle) {
    return Container(
      height: 64,
      clipBehavior: Clip.hardEdge,
      padding: EdgeInsets.symmetric(horizontal: isCollapsed ? 15 : 16),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Row(
        mainAxisAlignment:
            isCollapsed ? MainAxisAlignment.center : MainAxisAlignment.start,
        children: [
          // Quando expandido: mostra logo; quando colapsado: só o botão de menu
          if (!isCollapsed) ...[
            // Ícone de padoca
            Flexible(
              flex: 0,
              child: Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: DashboardColors.primary,
                  borderRadius: BorderRadius.circular(6),
                  boxShadow: [
                    BoxShadow(
                      color: DashboardColors.primary.withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Center(
                  child: Text('🥐', style: TextStyle(fontSize: 12)),
                ),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Ôpadoca',
                    style: GoogleFonts.dmSans(
                      fontSize: 12, // Diminuindo ainda mais a font do logo
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'EXPRESS',
                    style: GoogleFonts.dmSans(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      color: DashboardColors.primary,
                      letterSpacing: 0.8,
                    ),
                  ),
                ],
              ),
            ),
          ],
          // Botão de toggle — sempre visível
          _ToggleButton(isCollapsed: isCollapsed, onTap: onToggle),
        ],
      ),
    );
  }

  // ── Seção agrupada ────────────────────────────────────────────────────────
  Widget _buildStorePill() {
    final dashState = ref.watch(dashboardControllerProvider);
    final dashNotifier = ref.read(dashboardControllerProvider.notifier);
    final isStoreOpen = dashState.isLojaAberta;

    return Container(
      margin: const EdgeInsets.fromLTRB(12, 10, 12, 0),
      padding: const EdgeInsets.fromLTRB(10, 4, 4, 4),
      decoration: BoxDecoration(
        color: isStoreOpen
            ? const Color(0xFF10B981).withValues(alpha: 0.1)
            : Colors.redAccent.withValues(alpha: 0.1),
        border: Border.all(
          color: isStoreOpen
              ? const Color(0xFF10B981).withValues(alpha: 0.18)
              : Colors.redAccent.withValues(alpha: 0.18),
        ),
        borderRadius: BorderRadius.circular(7),
      ),
      child: ClipRect(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          physics: const NeverScrollableScrollPhysics(),
          child: SizedBox(
            width: 214,
            child: Row(
              mainAxisSize: MainAxisSize.max,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (isStoreOpen)
                      _BlinkingDot()
                    else
                      Container(
                        width: 6,
                        height: 6,
                        decoration: const BoxDecoration(
                          shape: BoxShape.circle,
                          color: Colors.redAccent,
                        ),
                      ),
                    const SizedBox(width: 7),
                    Text(
                      isStoreOpen ? 'Loja Aberta' : 'Loja Fechada',
                      style: GoogleFonts.dmSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: isStoreOpen
                            ? const Color(0xFF10B981)
                            : Colors.redAccent,
                      ),
                    ),
                  ],
                ),
                SizedBox(
                  height: 24,
                  child: FittedBox(
                    fit: BoxFit.fill,
                    child: Switch(
                      value: isStoreOpen,
                      activeThumbColor: const Color(0xFF10B981),
                      inactiveThumbColor: Colors.redAccent,
                      inactiveTrackColor:
                          Colors.redAccent.withValues(alpha: 0.3),
                      onChanged: dashState.isLoading
                          ? null
                          : (value) async {
                              if (isStoreOpen && !value) {
                                // Closing store flow
                                final motivo =
                                    await StoreStatusModals.showCloseModal(
                                        context);
                                if (motivo == null) return; // User canceled
                                await dashNotifier.toggleStoreStatus(false,
                                    motivo: motivo);
                              } else if (!isStoreOpen && value) {
                                // Opening store flow
                                final confirm =
                                    await StoreStatusModals.showOpenModal(
                                        context);
                                if (confirm != true) return; // User canceled
                                await dashNotifier.toggleStoreStatus(true);
                              }
                            },
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Seção agrupada ────────────────────────────────────────────────────────

  Widget _buildSection(_MenuSection section, bool isCollapsed) {
    final isOpen = _openSections.contains(section.label);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label da seção (só quando expandido)
        if (!isCollapsed)
          _SectionLabel(
            label: section.label,
            isOpen: isOpen,
            onTap: () => _toggleSection(section.label),
          ),

        // Itens
        if (isOpen || isCollapsed)
          for (final item in section.items)
            _buildNavItem(item, isCollapsed),

        // Divisor no modo colapsado
        if (isCollapsed)
          Container(
            height: 1,
            margin: const EdgeInsets.symmetric(vertical: 4),
            color: Colors.white.withValues(alpha: 0.06),
          ),
      ],
    );
  }

  Widget _buildNavItem(_MenuItem item, bool isCollapsed) {
    String? badge;
    Color? badgeColor;

    if (item.id == 'orders') {
      final count = ref.watch(pedidosKanbanControllerProvider).totalAtivos;
      if (count > 0) {
        badge = '$count';
        badgeColor = const Color(0xFFF97316);
      }
    }

    return _NavItem(
      item: item,
      isActive: widget.activeId == item.id,
      isCollapsed: isCollapsed,
      badge: badge,
      badgeColor: badgeColor,
      onTap: () {
        widget.onItemSelected(item.id);
        if (item.route != null) context.go(item.route!);
      },
    );
  }

  // ── Itens do rodapé ───────────────────────────────────────────────────────

  Widget _buildBottomItems(bool isCollapsed) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 6, 10, 0),
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(color: Colors.white.withValues(alpha: 0.06)),
        ),
      ),
      child: Column(
        children: [
          for (final item in _bottomItems)
            _NavItem(
              item: item,
              isActive: widget.activeId == item.id,
              isCollapsed: isCollapsed,
              onTap: () {
                widget.onItemSelected(item.id);
                if (item.route != null) {
                  context.go(item.route!);
                }
              },
            ),
        ],
      ),
    );
  }

  // ── Perfil / Logout ───────────────────────────────────────────────────────

  Widget _buildUserRow(bool isCollapsed) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      child: Container(
        padding: EdgeInsets.symmetric(
          horizontal: isCollapsed ? 15 : 9,
          vertical: 10,
        ),
        child: isCollapsed
            ? Center(
                child: Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [Color(0xFFF97316), Color(0xFFdc2626)],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: const Center(
                    child: Text(
                      'CP',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              )
            : ClipRect(
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const NeverScrollableScrollPhysics(),
                  child: SizedBox(
                    width: 234,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        // Avatar
                        Container(
                          width: 30,
                          height: 30,
                          decoration: const BoxDecoration(
                            shape: BoxShape.circle,
                            gradient: LinearGradient(
                              colors: [Color(0xFFF97316), Color(0xFFdc2626)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight,
                            ),
                          ),
                          child: const Center(
                            child: Text(
                              'CP',
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w700,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Carlos Padoca',
                                style: GoogleFonts.dmSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'proprietario',
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: Colors.white.withValues(alpha: 0.32),
                                ),
                              ),
                            ],
                          ),
                        ),
                        _LogoutButton(
                          onPressed: () async {
                            ref.invalidate(dashboardControllerProvider);
                            ref.invalidate(carrinhoControllerProvider);
                            ref.invalidate(profileControllerProvider);
                            await ref.read(authRepositoryProvider).signOut();
                            if (mounted) context.go('/login');
                          },
                        ),
                      ],
                    ),
                  ),
                ),
              ),
      ),
    );
  }
}

// ─── Subwidgets ──────────────────────────────────────────────────────────────

/// Botão de toggle do sidebar
class _ToggleButton extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback onTap;
  const _ToggleButton({required this.isCollapsed, required this.onTap});

  @override
  State<_ToggleButton> createState() => _ToggleButtonState();
}

class _ToggleButtonState extends State<_ToggleButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 140),
          width: 26,
          height: 26,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hover
                ? Colors.white.withValues(alpha: 0.12)
                : Colors.white.withValues(alpha: 0.06),
          ),
          child: Icon(
            Icons.menu_rounded,
            size: 16,
            color: _hover ? Colors.white : Colors.white.withValues(alpha: 0.4),
          ),
        ),
      ),
    );
  }
}

/// Label de seção recolhível
class _SectionLabel extends StatefulWidget {
  final String label;
  final bool isOpen;
  final VoidCallback onTap;

  const _SectionLabel({
    required this.label,
    required this.isOpen,
    required this.onTap,
  });

  @override
  State<_SectionLabel> createState() => _SectionLabelState();
}

class _SectionLabelState extends State<_SectionLabel> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(8, 15, 8, 4),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  widget.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.4,
                    color: _hover
                        ? Colors.white.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.22),
                  ),
                ),
              ),
              AnimatedRotation(
                turns: widget.isOpen ? 0.25 : 0,
                duration: const Duration(milliseconds: 200),
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 13,
                  color: _hover
                      ? Colors.white.withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.22),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Item de navegação individual
class _NavItem extends StatefulWidget {
  final _MenuItem item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;
  final String? badge;
  final Color? badgeColor;

  const _NavItem({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
    this.badge,
    this.badgeColor,
  });

  @override
  State<_NavItem> createState() => _NavItemState();
}

class _NavItemState extends State<_NavItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color itemColor = widget.isActive
        ? Colors.white
        : (_hover
            ? Colors.white.withValues(alpha: 0.8)
            : Colors.white.withValues(alpha: 0.46));

    final Color bgColor = widget.isActive
        ? DashboardColors.primary
        : (_hover ? Colors.white.withValues(alpha: 0.055) : Colors.transparent);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: Tooltip(
        message: widget.isCollapsed ? widget.item.label : '',
        preferBelow: false,
        decoration: BoxDecoration(
          color: const Color(0xFF100510),
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
          boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14)],
        ),
        textStyle: GoogleFonts.dmSans(
          fontSize: 11.5,
          fontWeight: FontWeight.w500,
          color: Colors.white,
        ),
        child: GestureDetector(
          onTap: widget.onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 130),
            clipBehavior: Clip.hardEdge,
            margin: const EdgeInsets.only(bottom: 1),
            padding: EdgeInsets.symmetric(
              horizontal: widget.isCollapsed ? 0 : 9,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              color: bgColor,
            ),
            child: widget.isCollapsed
                ? Center(
                    child: Icon(
                      widget.item.icon,
                      size: 18,
                      color: itemColor,
                    ),
                  )
                : ClipRect(
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      physics: const NeverScrollableScrollPhysics(),
                      child: SizedBox(
                        width: 214,
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.start,
                          mainAxisSize: MainAxisSize.max,
                          children: [
                            Icon(
                              widget.item.icon,
                              size: 18,
                              color: itemColor,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                widget.item.label,
                                style: GoogleFonts.dmSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: itemColor,
                                ),
                                overflow: TextOverflow.ellipsis,
                                maxLines: 1,
                              ),
                            ),
                            if (widget.badge != null)
                              Flexible(
                                flex: 0,
                                child: Container(
                                  margin: const EdgeInsets.only(left: 4),
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 6, vertical: 1),
                                  decoration: BoxDecoration(
                                    color: widget.isActive
                                        ? Colors.white.withValues(alpha: 0.25)
                                        : (widget.badgeColor ?? const Color(0xFFF97316))
                                            .withValues(alpha: 0.13),
                                    borderRadius: BorderRadius.circular(20),
                                  ),
                                  child: Text(
                                    widget.badge!,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: widget.isActive
                                          ? Colors.white
                                          : (widget.badgeColor ?? const Color(0xFFF97316)),
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

/// Botão de Logout
class _LogoutButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _LogoutButton({required this.onPressed});

  @override
  State<_LogoutButton> createState() => _LogoutButtonState();
}

class _LogoutButtonState extends State<_LogoutButton> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onPressed,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 130),
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(6),
            color: _hover
                ? DashboardColors.primary.withValues(alpha: 0.1)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.logout_rounded,
            size: 16,
            color: _hover
                ? DashboardColors.primary
                : Colors.white.withValues(alpha: 0.22),
          ),
        ),
      ),
    );
  }
}

/// Ponto piscante de status
class _BlinkingDot extends StatefulWidget {
  @override
  State<_BlinkingDot> createState() => _BlinkingDotState();
}

class _BlinkingDotState extends State<_BlinkingDot>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double> _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);
    _anim = Tween<double>(begin: 1, end: 0.35).animate(_ctrl);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _anim,
      child: Container(
        width: 6,
        height: 6,
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          color: Color(0xFF10B981),
        ),
      ),
    );
  }
}

// ─── Compatibilidade com código existente ────────────────────────────────────

/// Mantido para compatibilidade retroativa com o widget SidebarMenuItem
/// que pode ser referenciado em outros arquivos.
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
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    final Color color = widget.isSelected
        ? DashboardColors.primary
        : (_hover ? DashboardColors.accent : Colors.white);

    return MouseRegion(
      cursor: SystemMouseCursors.click,
      onEnter: (_) => setState(() => _hover = true),
      onExit: (_) => setState(() => _hover = false),
      child: GestureDetector(
        onTap: widget.onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: EdgeInsets.symmetric(
              vertical: 12, horizontal: widget.isCollapsed ? 0 : 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: widget.isSelected
                ? DashboardColors.primary.withValues(alpha: 0.2)
                : (_hover
                    ? DashboardColors.accent.withValues(alpha: 0.1)
                    : Colors.transparent),
          ),
          child: Row(
            mainAxisAlignment: widget.isCollapsed
                ? MainAxisAlignment.center
                : MainAxisAlignment.start,
            children: [
              Icon(widget.icon,
                  color: color, size: widget.isCollapsed ? 28 : 24),
              if (!widget.isCollapsed)
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(left: 12),
                    child: Text(
                      widget.title,
                      style: GoogleFonts.publicSans(
                        fontSize: 16,
                        fontWeight: widget.isSelected
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: color,
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
