import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/dashboard_controller.dart';
import '../controllers/dashboard_state.dart';
import 'widgets/dashboard_widgets.dart';

import 'package:padoca_express/features/entregador/avaliacoes/presentation/ui/avaliacoes_screen.dart';
import 'package:padoca_express/features/entregador/perfil/presentation/ui/perfil_screen.dart';

// ─── Cores locais (mesmas do widgets file) ────────────────────────────────────
const _bg0 = Color(0xFF0A0704);
const _bg2 = Color(0xFF1C1510);
const _orange = Color(0xFFF97316);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x18FFFFFF);

class EntregadorDashboardScreen extends ConsumerStatefulWidget {
  const EntregadorDashboardScreen({super.key});

  @override
  ConsumerState<EntregadorDashboardScreen> createState() =>
      _EntregadorDashboardScreenState();
}

class _EntregadorDashboardScreenState
    extends ConsumerState<EntregadorDashboardScreen> {
  int _currentIndex = 0;
  bool _despachoDialogOpen = false;

  static const _tabs = [
    _TabItem(icon: Icons.home_rounded, label: 'Início'),
    _TabItem(icon: Icons.star_rounded, label: 'Avaliações'),
    _TabItem(icon: Icons.person_rounded, label: 'Perfil'),
  ];

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);

    ref.listen<DashboardState>(dashboardControllerProvider, (previous, next) {
      // Erros
      if (next.error != null && previous?.error != next.error) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: redColor,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }

      // Novo despacho recebido → abre modal em qualquer aba
      if (next.despachoRecebido != null &&
          previous?.despachoRecebido == null &&
          !_despachoDialogOpen) {
        _despachoDialogOpen = true;
        showDialog<void>(
          context: context,
          barrierDismissible: false,
          barrierColor: Colors.black.withValues(alpha: .75),
          builder: (_) => Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 40),
            child: DespachoRecebidoCard(
              despacho: next.despachoRecebido!,
              isResponding: next.isRespondingDespacho,
              onAceitar: () {
                Navigator.of(context, rootNavigator: true).pop();
                _despachoDialogOpen = false;
                ref.read(dashboardControllerProvider.notifier).aceitarDespacho();
              },
              onRejeitar: () {
                Navigator.of(context, rootNavigator: true).pop();
                _despachoDialogOpen = false;
                ref.read(dashboardControllerProvider.notifier).rejeitarDespacho();
              },
            ),
          ),
        ).then((_) => _despachoDialogOpen = false);
      }

      // Despacho foi limpo externamente (ex: expirou no servidor) → fecha modal
      if (next.despachoRecebido == null &&
          previous?.despachoRecebido != null &&
          _despachoDialogOpen) {
        Navigator.of(context, rootNavigator: true).maybePop();
        _despachoDialogOpen = false;
      }

      // Despacho aceito com sucesso → navegar para tela de entrega
      if (previous?.statusDespacho != 'em_pedido' &&
          next.statusDespacho == 'em_pedido' &&
          next.pedidoAtualId != null) {
        context.push('/dashboard_entregador/entrega/${next.pedidoAtualId}');
      }
    });

    return Scaffold(
      backgroundColor: _bg0,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: [
          // ── Tab 0: Home / Dashboard ─────────────────────────────────────
          _DashboardHome(state: state, ref: ref),

          // ── Tab 1: Avaliações ───────────────────────────────────────────
          const AvaliacoesScreen(),

          // ── Tab 2: Perfil ───────────────────────────────────────────────
          const PerfilScreen(),
        ],
      ),
      bottomNavigationBar: _EntregadorNavBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        tabs: _tabs,
      ),
    );
  }
}

// ─── Dashboard Home content ──────────────────────────────────────────────────

class _DashboardHome extends ConsumerWidget {
  final DashboardState state;
  final WidgetRef ref;

  const _DashboardHome({required this.state, required this.ref});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return SafeArea(
      bottom: false,
      child: state.isLoading
          ? const DashboardShimmer()
          : RefreshIndicator(
              color: orangeColor,
              backgroundColor: bg2,
              onRefresh: () =>
                  ref.read(dashboardControllerProvider.notifier).loadDashboard(),
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.only(bottom: 110),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Header ─────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
                      child: DashboardHeader(
                        nome: state.driverName,
                        tipoVeiculo: state.vehicleType,
                        online: state.isOnline,
                        fotoPerfilUrl: state.fotoPerfilUrl,
                      ),
                    ),

                    // ── Saldo disponível ────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: SaldoCard(
                        saldoDisponivel: state.saldoDisponivel,
                        saldoBloqueado: state.saldoBloqueado,
                        onSaque: () =>
                            context.push('/dashboard_entregador/financeiro'),
                      ),
                    ),

                    // ── Toggle online/offline ───────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: DashboardToggleCard(
                        online: state.isOnline,
                        loading: state.isTogglingStatus,
                        onToggle: () => ref
                            .read(dashboardControllerProvider.notifier)
                            .toggleOnlineStatus(),
                      ),
                    ),

                    // ── Stats ───────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                      child: DashboardStatsRow(
                        ganhoHoje: state.todaysEarnings,
                        entregasHoje: state.todaysDeliveries,
                        avaliacao: state.rating,
                        totalEntregas: state.totalEntregas,
                      ),
                    ),

                    // ── Pedido ativo ────────────────────────────────────
                    if (state.pedidoAtivo != null)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: PedidoAtivoCard(
                          pedido: state.pedidoAtivo!,
                          onConfirmar: () => ref
                              .read(dashboardControllerProvider.notifier)
                              .confirmarEntrega(),
                        ),
                      ),

                    // ── Meta semanal (quando online) ────────────────────
                    if (state.isOnline)
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 12),
                        child: DashboardMetaCard(
                          ganhoSemana: state.weeklyEarnings,
                          metaSemana: state.weeklyGoal,
                        ),
                      ),

                    // ── Últimas entregas ────────────────────────────────
                    DashboardSectionHeader(
                      titulo: 'Últimas entregas',
                      linkLabel: 'Ver histórico',
                      onLink: () =>
                          context.push('/dashboard_entregador/historico'),
                    ),
                    if (state.isLoadingDeliveries)
                      const Padding(
                        padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: DashboardDeliveriesShimmer(),
                      )
                    else if (state.recentDeliveries.isEmpty)
                      const Padding(
                        padding:
                            EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                        child: DashboardEmptyDeliveries(),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 0),
                        child: Column(
                          children: state.recentDeliveries
                              .map((e) => Padding(
                                    padding: const EdgeInsets.only(bottom: 8),
                                    child: EntregaRecenteCard(entrega: e),
                                  ))
                              .toList(),
                        ),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

// ─── Bottom Navigation Bar ────────────────────────────────────────────────────

class _TabItem {
  final IconData icon;
  final String label;
  const _TabItem({required this.icon, required this.label});
}

class _EntregadorNavBar extends StatelessWidget {
  final int currentIndex;
  final ValueChanged<int> onTap;
  final List<_TabItem> tabs;

  const _EntregadorNavBar({
    required this.currentIndex,
    required this.onTap,
    required this.tabs,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: _bg2,
        border: const Border(top: BorderSide(color: _border, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: .4),
            blurRadius: 24,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 64,
          child: Row(
            children: List.generate(tabs.length, (i) {
              final active = i == currentIndex;
              final tab = tabs[i];
              return Expanded(
                child: GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onTap(i),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeInOut,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 4),
                          decoration: BoxDecoration(
                            color: active
                                ? _orange.withValues(alpha: .15)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Icon(
                            tab.icon,
                            size: 22,
                            color: active ? _orange : _text3,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          tab.label,
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            fontWeight: active
                                ? FontWeight.w700
                                : FontWeight.w500,
                            color: active ? _orange : _text3,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}
