import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../controllers/dashboard_controller.dart';
import 'widgets/dashboard_widgets.dart';

class EntregadorDashboardScreen extends ConsumerWidget {
  const EntregadorDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final controller = ref.read(dashboardControllerProvider.notifier);

    return Scaffold(
      backgroundColor: bg0,
      extendBody: true,
      body: SafeArea(
        bottom: false,
        child: state.isLoading
            ? const Center(child: CircularProgressIndicator(color: orangeColor))
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.only(bottom: 100),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Se houver erro de carregamento (não impeditivo)
                    if (state.error != null)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        child: Text(
                          state.error!,
                          style: const TextStyle(color: redColor, fontSize: 13),
                        ),
                      ),

                    // ── Header ──────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                      child: DashboardHeader(
                        nome: state.driverName,
                        tipoVeiculo: state.vehicleType,
                        online: state.isOnline,
                      ),
                    ),

                    // ── Toggle Card ──────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: DashboardToggleCard(
                        online: state.isOnline,
                        loading: state.isTogglingStatus,
                        onToggle: () => controller.toggleOnlineStatus(),
                      ),
                    ),

                    // ── Stats Row ────────────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: DashboardStatsRow(
                        ganhoHoje: state.todaysEarnings,
                        entregasHoje: state.todaysDeliveries,
                        avaliacao: state.rating,
                      ),
                    ),

                    // ── Quando online: ganho + meta ──────────────────────────
                    if (state.isOnline) ...[
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: DashboardEarningsBanner(
                          ganhoHoje: state.todaysEarnings,
                          entregasHoje: state.todaysDeliveries,
                          raioBusca: state.searchRadius,
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.fromLTRB(20, 0, 20, 14),
                        child: DashboardMetaCard(
                          ganhoSemana: state.weeklyEarnings,
                          metaSemana: state.weeklyGoal,
                        ),
                      ),
                    ],

                    // ── Mapa / região ────────────────────────────────────────
                    DashboardSectionHeader(
                      titulo: 'Sua região',
                      linkLabel: 'Ajustar raio',
                      onLink: () => context.push('/configuracoes/raio'),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 16),
                      child: DashboardMapPlaceholder(),
                    ),

                    // ── Histórico ────────────────────────────────────────────
                    DashboardSectionHeader(
                      titulo: 'Últimas entregas',
                      linkLabel: 'Ver todas',
                      onLink: () => context.push('/historico'),
                    ),
                    const Padding(
                      padding: EdgeInsets.fromLTRB(20, 0, 20, 0),
                      child: Center(
                        child: Text(
                          'Nenhuma entrega recente finalizada.',
                          style: TextStyle(color: text3, fontSize: 13),
                        ),
                      ),
                      // Na implementação final você colocaria um list view aqui buscando do historico state
                    ),
                  ],
                ),
              ),
      ),
    );
  }
}
