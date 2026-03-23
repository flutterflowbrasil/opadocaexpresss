import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/responsive_layout.dart';
import 'controllers/admin_dashboard_controller.dart';
import '../data/admin_dashboard_repository.dart';
import 'widgets/dashboard_sidebar.dart';
import 'widgets/dashboard_topbar.dart';
import 'widgets/kpi_cards.dart';
import 'widgets/pending_approvals_section.dart';
import 'widgets/revenue_chart_card.dart';
import '../estabelecimentos/presentation/estabs_adm_screen.dart';
import '../entregadores/presentation/entregadores_adm_screen.dart';

// ── Tela principal ────────────────────────────────────────────────────────────

class AdminDashboardScreen extends ConsumerStatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  ConsumerState<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends ConsumerState<AdminDashboardScreen> {
  bool _isSidebarCollapsed = false;
  String _activeScreen = 'dashboard';

  /// ID do item selecionado para abrir detalhe na tela de destino (nulo = lista geral).
  String? _selectedItemId;

  void _toggleSidebar() {
    setState(() => _isSidebarCollapsed = !_isSidebarCollapsed);
  }

  /// Navega para [screen] e opcionalmente destaca o item [itemId].
  void _navigate(String screen, {String? itemId}) {
    setState(() {
      _activeScreen = screen;
      _selectedItemId = itemId;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      body: ResponsiveLayout(
        mobile: (context) => _buildMobileLayout(context),
        desktop: (context) => _buildDesktopLayout(),
        tablet: (context) => _buildDesktopLayout(forceCollapse: true),
      ),
    );
  }

  Widget _buildDesktopLayout({bool forceCollapse = false}) {
    final collapsed = forceCollapse || _isSidebarCollapsed;
    return Row(
      children: [
        DashboardSidebar(
          isCollapsed: collapsed,
          onToggle: _toggleSidebar,
          activeScreen: _activeScreen,
          onNavigate: (s) => _navigate(s),
        ),
        Expanded(
          child: Column(
            children: [
              DashboardTopbar(activeScreen: _activeScreen),
              Expanded(child: _buildContent()),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMobileLayout(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      drawer: Drawer(
        child: DashboardSidebar(
          isCollapsed: false,
          onToggle: () => Navigator.of(context).pop(),
          activeScreen: _activeScreen,
          onNavigate: (s) {
            Navigator.of(context).pop();
            _navigate(s);
          },
        ),
      ),
      body: Column(
        children: [
          DashboardTopbar(
            isMobile: true,
            onMenuTapped: () => Scaffold.of(context).openDrawer(),
            activeScreen: _activeScreen,
          ),
          Expanded(child: _buildContent()),
        ],
      ),
    );
  }

  Widget _buildContent() {
    if (_activeScreen == 'estabelecimentos') {
      return const EstabsAdmScreen();
    }
    if (_activeScreen == 'entregadores') {
      return const EntregadoresAdmScreen();
    }
    return _DashboardContent(
      activeScreen: _activeScreen,
      selectedItemId: _selectedItemId,
      onNavigate: _navigate,
    );
  }
}

// ── Conteúdo do dashboard ────────────────────────────────────────────────────

class _DashboardContent extends ConsumerStatefulWidget {
  final String activeScreen;
  final String? selectedItemId;
  final void Function(String screen, {String? itemId}) onNavigate;

  const _DashboardContent({
    required this.activeScreen,
    required this.onNavigate,
    this.selectedItemId,
  });

  @override
  ConsumerState<_DashboardContent> createState() => _DashboardContentState();
}

class _DashboardContentState extends ConsumerState<_DashboardContent> {
  void _changePeriod(DashboardPeriod period) {
    ref.read(adminDashboardControllerProvider.notifier).changePeriod(period);
  }

  @override
  Widget build(BuildContext context) {
    final selectedPeriod = ref.watch(
      adminDashboardControllerProvider.select((s) => s.selectedPeriod),
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header com filtros de período ────────────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Row(
                  children: [
                    Text(
                      'Dashboard',
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0910),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text('·',
                        style: GoogleFonts.publicSans(
                            fontSize: 14, color: const Color(0xFF9CA3AF))),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        'Visão geral da plataforma',
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFFF97316),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Wrap(
                spacing: 6,
                children: DashboardPeriod.values.map((period) {
                  final isActive = period == selectedPeriod;
                  return GestureDetector(
                    onTap: () => _changePeriod(period),
                    child: Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color:
                            isActive ? const Color(0xFFFFF7ED) : Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: isActive
                              ? const Color(0xFFF97316)
                              : const Color(0xFFEAE8E4),
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        period.label,
                        style: GoogleFonts.publicSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isActive
                              ? const Color(0xFFF97316)
                              : const Color(0xFF6B7280),
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Alertas ─────────────────────────────────────────────────────
          AlertsSection(onNavigate: widget.onNavigate),
          const SizedBox(height: 16),

          // ── KPI cards ───────────────────────────────────────────────────
          const KpiCardsSection(),
          const SizedBox(height: 16),

          // ── Gráfico de receita da plataforma ────────────────────────────
          const RevenueChartCard(),
          const SizedBox(height: 16),

          // ── Tabelas de aprovações pendentes ─────────────────────────────
          PendingApprovalsSection(onNavigate: widget.onNavigate),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Seção de alertas ─────────────────────────────────────────────────────────

class AlertsSection extends ConsumerWidget {
  final void Function(String screen, {String? itemId}) onNavigate;

  const AlertsSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);

    if (state.isLoading ||
        (state.estabPendentesCount == 0 &&
            state.entregPendentesCount == 0 &&
            state.chamadosAbertosCount == 0)) {
      return const SizedBox.shrink();
    }

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        if (state.estabPendentesCount > 0)
          _AlertBanner(
            icon: Icons.store,
            color: const Color(0xFFF97316),
            bgColor: const Color(0xFFFFF7ED),
            borderColor: const Color(0xFFFED7AA),
            textColor: const Color(0xFF92400E),
            text: '${state.estabPendentesCount} estabelecimentos aguardando aprovação',
            actionText: 'Revisar',
            onAction: () => onNavigate('estabelecimentos'),
          ),
        if (state.entregPendentesCount > 0)
          _AlertBanner(
            icon: Icons.motorcycle,
            color: const Color(0xFF3B82F6),
            bgColor: const Color(0xFFEFF6FF),
            borderColor: const Color(0xFFBFDBFE),
            textColor: const Color(0xFF1E40AF),
            text: '${state.entregPendentesCount} entregadores aguardando KYC',
            actionText: 'Revisar',
            onAction: () => onNavigate('entregadores'),
          ),
        if (state.chamadosAbertosCount > 0)
          _AlertBanner(
            icon: Icons.support_agent,
            color: const Color(0xFFDC2626),
            bgColor: const Color(0xFFFEF2F2),
            borderColor: const Color(0xFFFCA5A5),
            textColor: const Color(0xFF991B1B),
            text: '${state.chamadosAbertosCount} chamados de suporte abertos',
            actionText: 'Ver',
            onAction: () => onNavigate('suporte'),
          ),
      ],
    );
  }
}

class _AlertBanner extends StatelessWidget {
  final IconData icon;
  final Color color, bgColor, borderColor, textColor;
  final String text, actionText;
  final VoidCallback onAction;

  const _AlertBanner({
    required this.icon,
    required this.color,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
    required this.text,
    required this.actionText,
    required this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 300,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: borderColor),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 16),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.publicSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: textColor,
              ),
            ),
          ),
          GestureDetector(
            onTap: onAction,
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: const Color(0xFFEAE8E4)),
              ),
              child: Text(
                actionText,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: color,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
