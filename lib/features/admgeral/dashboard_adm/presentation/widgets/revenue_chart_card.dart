import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../../data/admin_dashboard_repository.dart';
import '../controllers/admin_dashboard_controller.dart';

// ── Provider isolado para o gráfico (autoDispose — libera ao sair da tela) ──

final revenueChartProvider =
    FutureProvider.autoDispose.family<List<ChartDataPoint>, int>((ref, days) {
  final repo = ref.watch(adminDashboardRepositoryProvider);
  return repo.fetchChartData(days: days);
});

// ── Widget público ────────────────────────────────────────────────────────────

class RevenueChartCard extends ConsumerStatefulWidget {
  const RevenueChartCard({super.key});

  @override
  ConsumerState<RevenueChartCard> createState() => _RevenueChartCardState();
}

class _RevenueChartCardState extends ConsumerState<RevenueChartCard> {
  // Opções de período para o gráfico (independente dos filtros do dashboard)
  static const _options = [
    _PeriodOption('7D', 7),
    _PeriodOption('14D', 14),
    _PeriodOption('30D', 30),
  ];
  int _selectedDays = 7;
  int? _touchedIndex;

  @override
  Widget build(BuildContext context) {
    final chartAsync = ref.watch(revenueChartProvider(_selectedDays));
    final currencyFmt =
        NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final compactFmt =
        NumberFormat.compactCurrency(locale: 'pt_BR', symbol: 'R\$');

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: chartAsync.when(
          data: (points) => _buildChart(points, currencyFmt, compactFmt),
          loading: () => _buildLoading(),
          error: (_, __) => _buildEmpty(),
        ),
      ),
    );
  }

  Widget _buildChart(
    List<ChartDataPoint> points,
    NumberFormat currencyFmt,
    NumberFormat compactFmt,
  ) {
    final bool isEmpty = points.every((p) => p.receitaPlataforma == 0);
    final totalPlataforma = points.fold(0.0, (s, p) => s + p.receitaPlataforma);
    final totalBruto = points.fold(0.0, (s, p) => s + p.faturamentoBruto);

    // Calcula taxa média
    final taxaMedia = totalBruto > 0
        ? (totalPlataforma / totalBruto * 100).toStringAsFixed(1)
        : '—';

    // Valor máximo do eixo Y para escala
    final maxY = isEmpty
        ? 1000.0
        : points.map((p) => p.receitaPlataforma).reduce((a, b) => a > b ? a : b) * 1.2;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── Cabeçalho ──────────────────────────────────────────────────────
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Receita da plataforma',
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                  const SizedBox(height: 4),
                  // Seletor de período
                  Row(
                    children: _options.map((opt) {
                      final isActive = opt.days == _selectedDays;
                      return GestureDetector(
                        onTap: () => setState(() {
                          _selectedDays = opt.days;
                          _touchedIndex = null;
                        }),
                        child: Container(
                          margin: const EdgeInsets.only(right: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: isActive
                                ? const Color(0xFFF4F2EF)
                                : Colors.transparent,
                            borderRadius: BorderRadius.circular(6),
                            border: Border.all(
                              color: isActive
                                  ? const Color(0xFFEAE8E4)
                                  : Colors.transparent,
                            ),
                          ),
                          child: Text(
                            opt.label,
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: isActive
                                  ? const Color(0xFF1A0910)
                                  : const Color(0xFF9CA3AF),
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  isEmpty
                      ? 'R\$ 0,00'
                      : currencyFmt.format(totalPlataforma),
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981),
                  ),
                ),
              ],
            ),
          ],
        ),

        const SizedBox(height: 20),

        // ── Gráfico de barras ───────────────────────────────────────────────
        SizedBox(
          height: 140,
          child: isEmpty
              ? _buildEmptyChart()
              : BarChart(
                  BarChartData(
                    maxY: maxY,
                    minY: 0,
                    barTouchData: BarTouchData(
                      enabled: true,
                      touchCallback: (event, response) {
                        if (event is FlTapUpEvent ||
                            event is FlPointerHoverEvent) {
                          setState(() {
                            _touchedIndex =
                                response?.spot?.touchedBarGroupIndex;
                          });
                        }
                        if (event is FlPointerExitEvent) {
                          setState(() => _touchedIndex = null);
                        }
                      },
                      touchTooltipData: BarTouchTooltipData(
                        getTooltipItem: (group, groupIndex, rod, rodIndex) {
                          final pt = points[group.x];
                          return BarTooltipItem(
                            '${_dayLabel(pt.date, _selectedDays)}\n',
                            GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: Colors.white70,
                            ),
                            children: [
                              TextSpan(
                                text: compactFmt.format(pt.receitaPlataforma),
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ],
                          );
                        },
                      ),
                    ),
                    titlesData: FlTitlesData(
                      leftTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false)),
                      bottomTitles: AxisTitles(
                        sideTitles: SideTitles(
                          showTitles: true,
                          reservedSize: 22,
                          getTitlesWidget: (value, meta) {
                            final idx = value.toInt();
                            if (idx < 0 || idx >= points.length) {
                              return const SizedBox.shrink();
                            }
                            final pt = points[idx];
                            final isActive = idx == _touchedIndex;
                            return Padding(
                              padding: const EdgeInsets.only(top: 4),
                              child: Text(
                                _dayLabel(pt.date, _selectedDays),
                                style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                  fontWeight: isActive
                                      ? FontWeight.w700
                                      : FontWeight.w500,
                                  color: isActive
                                      ? const Color(0xFF10B981)
                                      : const Color(0xFF9CA3AF),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    gridData: FlGridData(
                      show: true,
                      drawVerticalLine: false,
                      horizontalInterval: maxY / 3,
                      getDrawingHorizontalLine: (value) => FlLine(
                        color: const Color(0xFFF4F2EF),
                        strokeWidth: 1,
                      ),
                    ),
                    borderData: FlBorderData(show: false),
                    barGroups: List.generate(points.length, (idx) {
                      final pt = points[idx];
                      final isActive = idx == _touchedIndex;
                      return BarChartGroupData(
                        x: idx,
                        barRods: [
                          BarChartRodData(
                            toY: pt.receitaPlataforma == 0
                                ? maxY * 0.04 // stub mínimo para mostrar shape
                                : pt.receitaPlataforma,
                            width: _selectedDays <= 7 ? 22 : _selectedDays <= 14 ? 14 : 8,
                            borderRadius: const BorderRadius.vertical(
                                top: Radius.circular(6)),
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: isActive
                                  ? [
                                      const Color(0xFF10B981),
                                      const Color(0xFF059669),
                                    ]
                                  : [
                                      const Color(0xFFD1FAE5),
                                      const Color(0xFFA7F3D0),
                                    ],
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                ),
        ),

        const SizedBox(height: 16),

        // ── Rodapé com métricas resumidas ───────────────────────────────────
        const Divider(height: 1, color: Color(0xFFF4F2EF)),
        const SizedBox(height: 12),
        Row(
          children: [
            _MetricItem(
              label: 'BRUTO',
              value: compactFmt.format(totalBruto),
              valueColor: const Color(0xFF1A0910),
            ),
            const _DividerV(),
            _MetricItem(
              label: 'PLATAFORMA',
              value: compactFmt.format(totalPlataforma),
              valueColor: const Color(0xFF10B981),
            ),
            const _DividerV(),
            _MetricItem(
              label: 'TAXA MÉDIA',
              value: totalBruto > 0 ? '$taxaMedia%' : '—',
              valueColor: const Color(0xFF6B7280),
            ),
          ],
        ),
      ],
    );
  }

  String _dayLabel(DateTime date, int days) {
    if (days <= 7) {
      // S1, S2 … S7
      return 'S${date.weekday}';
    } else if (days <= 14) {
      // dia/mês abreviado
      return '${date.day}/${date.month}';
    } else {
      // apenas dia
      return '${date.day}';
    }
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(height: 20, width: 180, color: Colors.white),
          const SizedBox(height: 12),
          Container(height: 140, decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(8),
          )),
        ],
      ),
    );
  }

  Widget _buildEmpty() {
    return SizedBox(
      height: 220,
      child: Center(
        child: Text(
          'Sem dados de receita ainda.',
          style: GoogleFonts.publicSans(
              fontSize: 13, color: const Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _buildEmptyChart() {
    return BarChart(
      BarChartData(
        maxY: 1000,
        minY: 0,
        barTouchData: BarTouchData(enabled: false),
        titlesData: FlTitlesData(
          leftTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              getTitlesWidget: (value, meta) {
                return Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(
                    'S${(value.toInt() + 1)}',
                    style: GoogleFonts.publicSans(
                        fontSize: 10, color: const Color(0xFFD1D5DB)),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 333,
          getDrawingHorizontalLine: (_) =>
              FlLine(color: const Color(0xFFF4F2EF), strokeWidth: 1),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(7, (idx) {
          return BarChartGroupData(
            x: idx,
            barRods: [
              BarChartRodData(
                toY: 40.0,
                width: 22,
                borderRadius:
                    const BorderRadius.vertical(top: Radius.circular(6)),
                color: const Color(0xFFF4F2EF),
              ),
            ],
          );
        }),
      ),
    );
  }
}

// ── Helpers internos ──────────────────────────────────────────────────────────

class _PeriodOption {
  final String label;
  final int days;
  const _PeriodOption(this.label, this.days);
}

class _MetricItem extends StatelessWidget {
  final String label, value;
  final Color valueColor;

  const _MetricItem(
      {required this.label,
      required this.value,
      required this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: GoogleFonts.publicSans(
                  fontSize: 9,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.8,
                  color: const Color(0xFF9CA3AF))),
          const SizedBox(height: 4),
          Text(value,
              style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: valueColor)),
        ],
      ),
    );
  }
}

class _DividerV extends StatelessWidget {
  const _DividerV();

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      width: 1,
      margin: const EdgeInsets.symmetric(horizontal: 12),
      color: const Color(0xFFEAE8E4),
    );
  }
}
