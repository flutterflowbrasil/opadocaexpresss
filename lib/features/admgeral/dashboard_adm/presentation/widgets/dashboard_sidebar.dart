import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class DashboardSidebar extends StatefulWidget {
  final bool isCollapsed;
  final VoidCallback? onToggle;
  final String activeScreen;
  final ValueChanged<String>? onNavigate;

  const DashboardSidebar({
    super.key,
    required this.isCollapsed,
    this.onToggle,
    this.activeScreen = 'dashboard',
    this.onNavigate,
  });

  @override
  State<DashboardSidebar> createState() => _DashboardSidebarState();
}

class _DashboardSidebarState extends State<DashboardSidebar> {
  final Set<String> _openSections = {'PLATAFORMA', 'CADASTROS', 'FINANCEIRO & OPS'};

  final List<Map<String, dynamic>> menuSections = [
    {
      'label': 'PLATAFORMA',
      'items': [
        {'id': 'dashboard', 'label': 'Dashboard', 'icon': Icons.dashboard, 'badge': null},
        // oculto até implementação: pedidos_live e mapa
        // {'id': 'pedidos_live', 'label': 'Pedidos ao Vivo', 'icon': Icons.list_alt, 'badge': 'ao vivo', 'badgeColor': Color(0xFFEF4444)},
        // {'id': 'mapa', 'label': 'Mapa de Entregas', 'icon': Icons.map, 'badge': null},
      ],
    },
    {
      'label': 'CADASTROS',
      'items': [
        {'id': 'estabelecimentos', 'label': 'Estabelecimentos', 'icon': Icons.storefront, 'badge': null},
        {'id': 'entregadores', 'label': 'Entregadores', 'icon': Icons.two_wheeler, 'badge': null},
        {'id': 'usuarios', 'label': 'Usuários', 'icon': Icons.people_outline, 'badge': null},
      ],
    },
    {
      'label': 'FINANCEIRO & OPS',
      'items': [
        {'id': 'financeiro', 'label': 'Financeiro', 'icon': Icons.attach_money, 'badge': null},
        {'id': 'suporte', 'label': 'Suporte', 'icon': Icons.support_agent, 'badge': null},
        {'id': 'relatorios', 'label': 'Relatórios', 'icon': Icons.insert_chart_outlined, 'badge': null},
      ],
    },
  ];

  final List<Map<String, dynamic>> bottomItems = [
    {'id': 'configuracoes', 'label': 'Configurações', 'icon': Icons.settings},
  ];

  void _toggleSection(String section) {
    setState(() {
      if (_openSections.contains(section)) {
        _openSections.remove(section);
      } else {
        _openSections.add(section);
      }
    });
  }

  void _navigate(String id) {
    widget.onNavigate?.call(id);
  }

  Future<void> _handleLogout() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final double width = widget.isCollapsed ? 68 : 248;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeOutCubic,
      width: width,
      height: double.infinity,
      color: const Color(0xFF1A0910),
      child: ClipRect(
        child: LayoutBuilder(
          builder: (context, constraints) {
            // Usa largura real para evitar RenderFlex durante a animação
            final c = constraints.maxWidth < 120;
            return Column(
              children: [
                // ── Header ────────────────────────────────────────────────
                Container(
                  padding: EdgeInsets.fromLTRB(c ? 0 : 15, 16, c ? 0 : 14, 16),
                  decoration: const BoxDecoration(
                    border: Border(bottom: BorderSide(color: Colors.white10)),
                  ),
                  child: c
                      ? Center(
                          child: GestureDetector(
                            onTap: widget.onToggle,
                            child: Container(
                              width: 36,
                              height: 36,
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.07),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(Icons.menu, color: Colors.white60, size: 18),
                            ),
                          ),
                        )
                      : Row(
                          children: [
                            Container(
                              width: 32,
                              height: 32,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                borderRadius: BorderRadius.circular(8),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFFF97316).withValues(alpha: 0.35),
                                    blurRadius: 10,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Text('🛡️', style: TextStyle(fontSize: 15)),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Padoca Express',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white,
                                    ),
                                  ),
                                  Text(
                                    'ADMIN GERAL',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFF97316),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            if (widget.onToggle != null)
                              GestureDetector(
                                onTap: widget.onToggle,
                                child: Container(
                                  width: 26,
                                  height: 26,
                                  decoration: BoxDecoration(
                                    color: Colors.white.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Icon(Icons.menu, color: Colors.white54, size: 16),
                                ),
                              ),
                          ],
                        ),
                ),

                // ── Badge "Administrador Geral" ────────────────────────────
                if (!c)
                  Container(
                    margin: const EdgeInsets.only(top: 10, left: 12, right: 12, bottom: 2),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF97316).withValues(alpha: 0.08),
                      border: Border.all(color: const Color(0xFFF97316).withValues(alpha: 0.18)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.shield, color: Color(0xFFF97316), size: 14),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            'Administrador Geral',
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                // ── Itens de navegação ────────────────────────────────────
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.only(top: 4, left: 9, right: 9),
                    children: menuSections.map((sec) {
                      final isOpen = _openSections.contains(sec['label'] as String);
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!c)
                            GestureDetector(
                              onTap: () => _toggleSection(sec['label'] as String),
                              child: Padding(
                                padding: const EdgeInsets.only(top: 14, left: 7, right: 7, bottom: 4),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        sec['label'] as String,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.publicSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          letterSpacing: 1.4,
                                          color: Colors.white24,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      isOpen ? Icons.keyboard_arrow_down : Icons.keyboard_arrow_right,
                                      size: 14,
                                      color: Colors.white24,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          if (isOpen || c)
                            ...(sec['items'] as List<Map<String, dynamic>>).map((item) {
                              final isAct = widget.activeScreen == item['id'];
                              return _SidebarItem(
                                item: item,
                                isActive: isAct,
                                isCollapsed: widget.isCollapsed,
                                onTap: () => _navigate(item['id'] as String),
                              );
                            }),
                        ],
                      );
                    }).toList(),
                  ),
                ),

                // ── Itens inferiores ──────────────────────────────────────
                Container(
                  padding: const EdgeInsets.only(top: 6, left: 9, right: 9),
                  decoration: const BoxDecoration(border: Border(top: BorderSide(color: Colors.white10))),
                  child: Column(
                    children: bottomItems.map((item) {
                      final isAct = widget.activeScreen == item['id'];
                      return _SidebarItem(
                        item: item,
                        isActive: isAct,
                        isCollapsed: widget.isCollapsed,
                        onTap: () => _navigate(item['id'] as String),
                      );
                    }).toList(),
                  ),
                ),

                // ── Avatar do usuário ─────────────────────────────────────
                Container(
                  padding: const EdgeInsets.fromLTRB(8, 10, 8, 14),
                  child: Row(
                    mainAxisAlignment: c ? MainAxisAlignment.center : MainAxisAlignment.start,
                    children: [
                      Container(
                        width: 30,
                        height: 30,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            colors: [Color(0xFFF97316), Color(0xFF9B2C2C)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          shape: BoxShape.circle,
                        ),
                        child: const Center(
                          child: Text(
                            'A',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                        ),
                      ),
                      if (!c) ...[
                        const SizedBox(width: 9),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Admin',
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                'admin geral',
                                style: GoogleFonts.publicSans(fontSize: 10, color: Colors.white30),
                              ),
                            ],
                          ),
                        ),
                        _AdmLogoutButton(onPressed: _handleLogout),
                      ],
                    ],
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Item de menu com hover state e cursor pointer.
class _SidebarItem extends StatefulWidget {
  final Map<String, dynamic> item;
  final bool isActive;
  final bool isCollapsed;
  final VoidCallback onTap;

  const _SidebarItem({
    required this.item,
    required this.isActive,
    required this.isCollapsed,
    required this.onTap,
  });

  @override
  State<_SidebarItem> createState() => _SidebarItemState();
}

class _SidebarItemState extends State<_SidebarItem> {
  bool _hover = false;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final actuallyCollapsed = constraints.maxWidth < 120;

        final iconColor = widget.isActive
            ? const Color(0xFFF97316)
            : _hover
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.42);

        final textColor = widget.isActive
            ? const Color(0xFFF97316)
            : _hover
                ? Colors.white.withValues(alpha: 0.85)
                : Colors.white.withValues(alpha: 0.42);

        return MouseRegion(
          cursor: SystemMouseCursors.click,
          onEnter: (_) => setState(() => _hover = true),
          onExit: (_) => setState(() => _hover = false),
          child: Tooltip(
            message: actuallyCollapsed ? (widget.item['label'] as String) : '',
            preferBelow: false,
            decoration: BoxDecoration(
              color: const Color(0xFF1A0910),
              borderRadius: BorderRadius.circular(7),
              border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
              boxShadow: const [BoxShadow(color: Colors.black54, blurRadius: 14)],
            ),
            textStyle: GoogleFonts.publicSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w500,
              color: Colors.white,
            ),
            child: GestureDetector(
              onTap: widget.onTap,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 130),
                margin: const EdgeInsets.only(bottom: 1),
                padding: EdgeInsets.symmetric(
                  vertical: 7.5,
                  horizontal: actuallyCollapsed ? 0 : 8,
                ),
                decoration: BoxDecoration(
                  gradient: widget.isActive
                      ? LinearGradient(colors: [
                          const Color(0xFFF97316).withValues(alpha: 0.22),
                          const Color(0xFFF97316).withValues(alpha: 0.08),
                        ])
                      : null,
                  color: !widget.isActive && _hover
                      ? Colors.white.withValues(alpha: 0.06)
                      : null,
                  borderRadius: BorderRadius.circular(8),
                  border: widget.isActive
                      ? const Border(left: BorderSide(color: Color(0xFFF97316), width: 2))
                      : null,
                ),
                child: Row(
                  mainAxisAlignment: actuallyCollapsed
                      ? MainAxisAlignment.center
                      : MainAxisAlignment.start,
                  children: [
                    if (widget.isActive && !actuallyCollapsed) const SizedBox(width: 6),
                    Icon(
                      widget.item['icon'] as IconData,
                      size: 18,
                      color: iconColor,
                    ),
                    if (!actuallyCollapsed) ...[
                      const SizedBox(width: 9),
                      Expanded(
                        child: Text(
                          widget.item['label'] as String,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.publicSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: textColor,
                          ),
                        ),
                      ),
                      if (widget.item['badge'] != null)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 1),
                          decoration: BoxDecoration(
                            color: widget.isActive
                                ? const Color(0xFFF97316).withValues(alpha: 0.25)
                                : (widget.item['badgeColor'] as Color).withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            widget.item['badge'] as String,
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: widget.isActive
                                  ? const Color(0xFFF97316)
                                  : widget.item['badgeColor'] as Color,
                            ),
                          ),
                        ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Botão de logout do Admin Geral com hover state
class _AdmLogoutButton extends StatefulWidget {
  final VoidCallback onPressed;
  const _AdmLogoutButton({required this.onPressed});

  @override
  State<_AdmLogoutButton> createState() => _AdmLogoutButtonState();
}

class _AdmLogoutButtonState extends State<_AdmLogoutButton> {
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
                ? const Color(0xFFF97316).withValues(alpha: 0.12)
                : Colors.transparent,
          ),
          child: Icon(
            Icons.logout_rounded,
            size: 16,
            color: _hover
                ? const Color(0xFFF97316)
                : Colors.white24,
          ),
        ),
      ),
    );
  }
}
