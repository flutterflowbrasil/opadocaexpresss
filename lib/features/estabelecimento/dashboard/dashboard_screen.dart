import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import 'dashboard_controller.dart';
import 'componentes_dash/sidebar_menu.dart';

// Novos componentes
import 'components/dashboard_topbar.dart';
import 'components/period_filter_bar.dart';
import 'components/dashboard_kpis_row.dart';
import 'components/dashboard_charts_cards.dart';
import 'components/dashboard_ranking_cards.dart';
import 'components/financial_summary_card.dart';

class DashboardScreen extends ConsumerStatefulWidget {
  const DashboardScreen({super.key});

  @override
  ConsumerState<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends ConsumerState<DashboardScreen> {
  String _formatCurrency(double value) {
    return NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$').format(value);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardControllerProvider);
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    Widget bodyContent;

    // Topbar variables
    final topbarDate =
        DateFormat("d 'de' MMMM 'de' yyyy", "pt_BR").format(DateTime.now());

    if (state.isLoading && state.estabelecimentoId == null) {
      bodyContent = const Center(
          child: CircularProgressIndicator(color: Color(0xFFF97316)));
    } else if (state.error != null) {
      bodyContent = Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text('Erro ao carregar os dados:\n${state.error}',
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.black87)),
            TextButton(
              onPressed: () =>
                  ref.read(dashboardControllerProvider.notifier).recarregar(),
              child: const Text('Tentar Novamente',
                  style: TextStyle(color: Color(0xFFF97316))),
            )
          ],
        ),
      );
    } else {
      // Data mapping

      // Mapear Map<String, double> para List<ChartDataPoint>
      final chartData = state.vendasPorDia.entries
          .map((e) => ChartDataPoint(e.key, e.value))
          .toList();

      // Se vazio, adiciona mock para o gráfico não morrer
      if (chartData.isEmpty) {
        chartData.add(ChartDataPoint("10h", 0));
      }

      // Mapear Produtos do Ranking Real
      final rankingList = state.ranking.map((p) {
        final totalVendidos =
            p['vendidos'] as int? ?? (p['total_vendidos'] as int? ?? 0);
        final receita = p['receita'] as num? ?? 0.0;
        final foto = p['foto'] as String? ?? '📦';

        return RankingProduto(
          nome: p['nome'] ?? 'Desconhecido',
          vendidos: totalVendidos,
          foto: foto,
          receita: receita.toDouble(),
        );
      }).toList();

      bodyContent = RefreshIndicator(
        color: const Color(0xFFF97316),
        onRefresh: () async {
          await ref.read(dashboardControllerProvider.notifier).recarregar();
        },
        child: Column(
          children: [
            // TOPBAR (Fixed at top inside screen body)
            DashboardTopbar(
              estabelecimentoNome:
                  state.estabelecimentoNome ?? 'Estabelecimento',
              isLojaAberta: state.isLojaAberta,
              dateText: topbarDate,
            ),

            // SCROLLABLE CONTENT
            Expanded(
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                padding:
                    const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // FILTER BAR
                    PeriodFilterBar(
                      periodoSelecionado: state.periodoAtual,
                      customDate: state.dataCustomizada,
                      onPeriodoChanged: (periodo, date) {
                        ref
                            .read(dashboardControllerProvider.notifier)
                            .mudarPeriodo(periodo, date);
                      },
                    ),
                    const SizedBox(height: 16),

                    if (state.isLoading)
                      const LinearProgressIndicator(color: Color(0xFFF97316)),

                    // KPIs
                    DashboardKpisRow(
                      kpis: [
                        DashboardKpi(
                          title: 'VENDAS',
                          value: _formatCurrency(state.vendasTotal),
                          delta:
                              '${state.deltaVendas >= 0 ? '+' : ''}${state.deltaVendas}%',
                          isUp: state.deltaVendas >= 0,
                        ),
                        DashboardKpi(
                          title: 'PEDIDOS',
                          value: state.totalPedidos.toString(),
                          delta:
                              '${state.deltaPedidos >= 0 ? '+' : ''}${state.deltaPedidos}',
                          isUp: state.deltaPedidos >= 0,
                        ),
                        DashboardKpi(
                          title: 'TICKET MÉDIO',
                          value: _formatCurrency(state.ticketMedio),
                          delta:
                              '${state.deltaTicket >= 0 ? '+' : ''}${state.deltaTicket}%',
                          isUp: state.deltaTicket >= 0,
                        ),
                        DashboardKpi(
                          title: 'AVALIAÇÃO',
                          value: '${state.avaliacaoMedia.toStringAsFixed(1)} ★',
                          delta:
                              '${state.deltaAvaliacao >= 0 ? '+' : ''}${state.deltaAvaliacao}',
                          isUp: state.deltaAvaliacao >= 0,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // CHARTS (Vendas e Donut)
                    DashboardChartsCards(
                      salesData: chartData,
                      totalVendas: _formatCurrency(state.vendasTotal),
                      deltaVendas:
                          '${state.deltaVendas >= 0 ? '+' : ''}${state.deltaVendas}%',
                      isVendasUp: state.deltaVendas >= 0,
                      periodoLabel: state.periodoAtual == DashboardPeriodo.hoje
                          ? 'Hoje'
                          : 'Período',
                      recorrentesPct: state.clientesUnicos > 0
                          ? ((state.clientesRecorrentes /
                                      state.clientesUnicos) *
                                  100)
                              .round()
                          : 0,
                      clientesRecorrentes: state.clientesRecorrentes,
                      clientesNovos: state.clientesNovos,
                      indicacoesAtivas: 0, // Mock
                    ),
                    const SizedBox(height: 16),

                    // RANKING & FUNIL
                    DashboardRankingCards(
                      produtos: rankingList,
                      totalPedidos: state.totalPedidos,
                      periodoLabel: 'No período',
                      pendentes: state.pendentes,
                      confirmados: state.confirmados,
                      preparando: state.preparando,
                      prontos: state.prontos,
                      emEntrega: state.emEntrega,
                      entregues: state.entregues,
                    ),
                    const SizedBox(height: 16),

                    // FINANCIAL SUMMARY
                    FinancialSummaryCard(
                      bruto: state.vendasTotal,
                      taxas: state.vendasTotal * 0.1, // Mock 10% tax rate
                      liquido: state.vendasTotal * 0.9,
                      periodoLabel: 'No período',
                    ),

                    SizedBox(height: isWideScreen ? 48 : 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      );
    }

    return Scaffold(
      backgroundColor: const Color(0xFFF4F2EF),
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                activeId: 'dashboard',
                onItemSelected: (id) {
                  Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              activeId: 'dashboard',
              onItemSelected: (_) {},
            ),
          Expanded(child: bodyContent),
        ],
      ),
      bottomNavigationBar: null,
    );
  }
}
