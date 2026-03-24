import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';

// Paleta de cores para o PieChart
const _kMetodoCores = {
  'pix': Color(0xFF10B981),
  'cartao_credito': Color(0xFF3B82F6),
  'cartao_debito': Color(0xFF8B5CF6),
  'dinheiro': Color(0xFFF59E0B),
  'boleto': Color(0xFF6B7280),
};
const _kMetodoLabels = {
  'pix': 'PIX',
  'cartao_credito': 'Crédito',
  'cartao_debito': 'Débito',
  'dinheiro': 'Dinheiro',
  'boleto': 'Boleto',
};

class FinanceiroVisaoGeral extends ConsumerWidget {
  const FinanceiroVisaoGeral({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );

    if (isLoading) return const _VisaoGeralShimmer();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Row: BarChart + PieChart ──────────────────────────────────────────
        LayoutBuilder(builder: (_, constraints) {
          final isWide = constraints.maxWidth > 700;
          if (isWide) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(flex: 3, child: _ReceitaBarChart()),
                const SizedBox(width: 12),
                Expanded(flex: 2, child: _MetodoPieChart()),
              ],
            );
          }
          return Column(
            children: [
              _ReceitaBarChart(),
              const SizedBox(height: 12),
              _MetodoPieChart(),
            ],
          );
        }),
        const SizedBox(height: 12),
        // ── Card modelo de split ──────────────────────────────────────────────
        _SplitModelCard(),
      ],
    );
  }
}

// ── Gráfico de barras: receita semanal ────────────────────────────────────────

class _ReceitaBarChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dados = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.receitaSemanal),
    );

    final maxY = dados
            .map((d) => d['receita'] as double)
            .fold(0.0, (a, b) => a > b ? a : b) *
        1.2;

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Receita — Últimos 7 dias',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A0910),
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 180,
            child: maxY == 0
                ? Center(
                    child: Text(
                      'Sem pedidos entregues nos últimos 7 dias',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        color: const Color(0xFF9CA3AF),
                      ),
                      textAlign: TextAlign.center,
                    ),
                  )
                : BarChart(
                    BarChartData(
                      maxY: maxY,
                      gridData: FlGridData(
                        show: true,
                        drawVerticalLine: false,
                        getDrawingHorizontalLine: (_) => FlLine(
                          color: const Color(0xFFEAE8E4),
                          strokeWidth: 1,
                        ),
                      ),
                      borderData: FlBorderData(show: false),
                      titlesData: FlTitlesData(
                        leftTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            reservedSize: 40,
                            getTitlesWidget: (value, _) => Text(
                              'R\$${value.toStringAsFixed(0)}',
                              style: GoogleFonts.dmSans(
                                fontSize: 9,
                                color: const Color(0xFF9CA3AF),
                              ),
                            ),
                          ),
                        ),
                        rightTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        topTitles: const AxisTitles(
                          sideTitles: SideTitles(showTitles: false),
                        ),
                        bottomTitles: AxisTitles(
                          sideTitles: SideTitles(
                            showTitles: true,
                            getTitlesWidget: (value, _) {
                              final idx = value.toInt();
                              if (idx < 0 || idx >= dados.length) {
                                return const SizedBox.shrink();
                              }
                              return Text(
                                dados[idx]['dia'] as String,
                                style: GoogleFonts.dmSans(
                                  fontSize: 10,
                                  color: const Color(0xFF6B7280),
                                ),
                              );
                            },
                          ),
                        ),
                      ),
                      barGroups: List.generate(dados.length, (i) {
                        final receita = dados[i]['receita'] as double;
                        final plataforma = dados[i]['plataforma'] as double;
                        return BarChartGroupData(
                          x: i,
                          barRods: [
                            BarChartRodData(
                              toY: receita,
                              width: 14,
                              borderRadius: BorderRadius.circular(4),
                              rodStackItems: receita > 0
                                  ? [
                                      BarChartRodStackItem(
                                        0,
                                        receita - plataforma,
                                        const Color(0xFFFED7AA),
                                      ),
                                      BarChartRodStackItem(
                                        receita - plataforma,
                                        receita,
                                        const Color(0xFFF97316),
                                      ),
                                    ]
                                  : [],
                            ),
                          ],
                        );
                      }),
                    ),
                  ),
          ),
          if (maxY > 0) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                _LegendaDot(color: const Color(0xFFF97316), label: 'Plataforma'),
                const SizedBox(width: 14),
                _LegendaDot(color: const Color(0xFFFED7AA), label: 'Estabelecimento + Entregador'),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ── Gráfico de pizza: distribuição por método ─────────────────────────────────

class _MetodoPieChart extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final distribuicao = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.distribuicaoPorMetodo),
    );

    final total = distribuicao.values.fold(0.0, (a, b) => a + b);

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Por Método de Pagamento',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: const Color(0xFF1A0910),
            ),
          ),
          const SizedBox(height: 16),
          if (total == 0)
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 32),
                child: Text(
                  'Nenhum pedido entregue ainda',
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else ...[
            SizedBox(
              height: 140,
              child: PieChart(
                PieChartData(
                  sectionsSpace: 2,
                  centerSpaceRadius: 36,
                  sections: distribuicao.entries.map((e) {
                    final pct = total > 0 ? (e.value / total * 100) : 0;
                    return PieChartSectionData(
                      value: e.value,
                      title: '${pct.toStringAsFixed(0)}%',
                      titleStyle: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      color: _kMetodoCores[e.key] ?? const Color(0xFF6B7280),
                      radius: 50,
                    );
                  }).toList(),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 10,
              runSpacing: 6,
              children: distribuicao.keys.map((metodo) {
                return _LegendaDot(
                  color: _kMetodoCores[metodo] ?? const Color(0xFF6B7280),
                  label: _kMetodoLabels[metodo] ?? metodo,
                );
              }).toList(),
            ),
          ],
        ],
      ),
    );
  }
}

// ── Card: Modelo de Split ─────────────────────────────────────────────────────

class _SplitModelCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.call_split_rounded,
                  size: 16, color: Color(0xFFF97316)),
              const SizedBox(width: 8),
              Text(
                'Modelo de Distribuição (Split)',
                style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A0910),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: const [
              _SplitPill(
                label: 'Estabelecimento',
                value: '85%',
                descricao: 'do subtotal dos produtos',
                color: Color(0xFFF97316),
                bg: Color(0xFFFFF7ED),
              ),
              _SplitPill(
                label: 'Entregador',
                value: '100%',
                descricao: 'da taxa de entrega',
                color: Color(0xFF10B981),
                bg: Color(0xFFECFDF5),
              ),
              _SplitPill(
                label: 'Plataforma',
                value: '5%',
                descricao: 'do subtotal dos produtos',
                color: Color(0xFF3B82F6),
                bg: Color(0xFFEFF6FF),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFEAE8E4)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Exemplo — Pedido R\$ 60,00',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                const SizedBox(height: 6),
                _ExemploLinha(
                    label: 'Subtotal produtos', valor: 'R\$ 50,00'),
                _ExemploLinha(
                    label: 'Taxa de entrega', valor: 'R\$ 10,00'),
                const Divider(height: 12, color: Color(0xFFEAE8E4)),
                _ExemploLinha(
                    label: 'Estabelecimento (85% × R\$ 50)',
                    valor: 'R\$ 42,50',
                    destaque: true),
                _ExemploLinha(
                    label: 'Entregador (100% taxa)',
                    valor: 'R\$ 10,00',
                    destaque: true),
                _ExemploLinha(
                    label: 'Plataforma (5% × R\$ 50)',
                    valor: 'R\$ 2,50',
                    destaque: true),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitPill extends StatelessWidget {
  final String label, value, descricao;
  final Color color, bg;

  const _SplitPill({
    required this.label,
    required this.value,
    required this.descricao,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: GoogleFonts.dmSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
          Text(
            descricao,
            style: GoogleFonts.dmSans(
              fontSize: 10,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _ExemploLinha extends StatelessWidget {
  final String label, valor;
  final bool destaque;

  const _ExemploLinha({
    required this.label,
    required this.valor,
    this.destaque = false,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: destaque ? FontWeight.w600 : FontWeight.w400,
              color: destaque
                  ? const Color(0xFF374151)
                  : const Color(0xFF9CA3AF),
            ),
          ),
          Text(
            valor,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF1A0910),
            ),
          ),
        ],
      ),
    );
  }
}

class _LegendaDot extends StatelessWidget {
  final Color color;
  final String label;

  const _LegendaDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            color: const Color(0xFF6B7280),
          ),
        ),
      ],
    );
  }
}

class _VisaoGeralShimmer extends StatelessWidget {
  const _VisaoGeralShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                flex: 3,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: Container(
                  height: 260,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 160,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ],
      ),
    );
  }
}
