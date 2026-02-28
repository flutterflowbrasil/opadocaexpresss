import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'dashboard_controller.dart';
import 'componentes_dash/dashboard_colors.dart';
import 'componentes_dash/sidebar_menu.dart';
import 'componentes_dash/dashboard_header.dart';
import 'componentes_dash/quick_actions_row.dart';
import 'componentes_dash/sales_metrics_row.dart';
import 'componentes_dash/sales_chart_placeholder.dart';
import 'componentes_dash/top_products_list.dart';
import 'componentes_dash/recent_orders_table.dart';
import 'componentes_dash/mobile_bottom_nav.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final isWideScreen =
        MediaQuery.of(context).size.width >= 768; // 'md' breakpoint in tailwind

    Widget bodyContent;
    if (state.isLoading) {
      bodyContent = const Center(
          child: CircularProgressIndicator(color: DashboardColors.primary));
    } else if (state.error != null) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro ao carregar os dados: ${state.error}',
                style:
                    TextStyle(color: isDark ? Colors.white : Colors.black87)),
            TextButton(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).recarregar(),
              child: const Text('Tentar Novamente'),
            )
          ],
        ),
      );
    } else {
      bodyContent = RefreshIndicator(
        color: DashboardColors.primary,
        onRefresh: () async {
          await ref.read(dashboardControllerProvider.notifier).recarregar();
        },
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DashboardHeader(
                  estabelecimentoNome:
                      state.estabelecimentoNome ?? 'Estabelecimento'),
              const SizedBox(height: 24),

              const QuickActionsRow(),
              const SizedBox(height: 16),

              SalesMetricsRow(
                vendasHoje: state.vendasHoje,
                pedidosAtivos: state.pedidosAtivos,
                ticketMedio: state.ticketMedio,
                avaliacaoMedia: state.avaliacaoMedia,
              ),
              const SizedBox(height: 16),

              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    if (constraints.maxWidth > 1024) {
                      // lg breakpoint
                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Expanded(
                            flex: 2,
                            child: SalesChartPlaceholder(),
                          ),
                          const SizedBox(width: 24),
                          Expanded(
                            flex: 1,
                            child:
                                TopProductsList(produtos: state.maisVendidos),
                          ),
                        ],
                      );
                    } else {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SalesChartPlaceholder(),
                          const SizedBox(height: 24),
                          TopProductsList(produtos: state.maisVendidos),
                        ],
                      );
                    }
                  },
                ),
              ),

              const SizedBox(height: 24),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: RecentOrdersTable(pedidos: state.pedidosRecentes),
              ),

              // Extra padding at bottom for mobile nav overlap so content isn't hidden
              SizedBox(height: isWideScreen ? 48 : 100),
            ],
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: isDark
          ? DashboardColors.backgroundDark
          : DashboardColors.backgroundLight,
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                selectedIndex: 0,
                onItemSelected: (index) {
                  if (index != 0) Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              selectedIndex: 0,
              onItemSelected: (index) {},
            ),
          Expanded(child: bodyContent),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : const MobileBottomNav(),
    );
  }
}
