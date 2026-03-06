import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ChartDataPoint {
  final String label;
  final double value;

  ChartDataPoint(this.label, this.value);
}

class DashboardChartsCards extends StatelessWidget {
  final List<ChartDataPoint> salesData;
  final String totalVendas;
  final String deltaVendas;
  final bool isVendasUp;
  final String periodoLabel;

  final int recorrentesPct;
  final int clientesRecorrentes;
  final int clientesNovos;
  final int indicacoesAtivas;

  const DashboardChartsCards({
    super.key,
    required this.salesData,
    required this.totalVendas,
    required this.deltaVendas,
    required this.isVendasUp,
    required this.periodoLabel,
    required this.recorrentesPct,
    required this.clientesRecorrentes,
    required this.clientesNovos,
    required this.indicacoesAtivas,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        if (isMobile) {
          return Column(
            children: [
              _buildSalesChart(),
              const SizedBox(height: 16),
              _buildCustomersDonut(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(flex: 3, child: _buildSalesChart()),
            const SizedBox(width: 16),
            Expanded(flex: 2, child: _buildCustomersDonut()),
          ],
        );
      },
    );
  }

  Widget _buildSalesChart() {
    double maxValue = salesData.isEmpty
        ? 0
        : salesData.map((e) => e.value).reduce((a, b) => a > b ? a : b);

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Vendas — $periodoLabel',
                  style: GoogleFonts.publicSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                Row(
                  children: [
                    Text(
                      totalVendas,
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0910),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVendasUp
                            ? const Color(0xFFECFDF5)
                            : const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        children: [
                          Icon(
                            isVendasUp
                                ? Icons.trending_up
                                : Icons.trending_down,
                            size: 13,
                            color: isVendasUp
                                ? const Color(0xFF059669)
                                : const Color(0xFFDC2626),
                          ),
                          const SizedBox(width: 3),
                          Text(
                            deltaVendas,
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: isVendasUp
                                  ? const Color(0xFF059669)
                                  : const Color(0xFFDC2626),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          // Chart Body
          Padding(
            padding: const EdgeInsets.all(18),
            child: SizedBox(
              height: 120, // Reduced from mockup 150 to keep compact
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: salesData.asMap().entries.map((entry) {
                  int idx = entry.key;
                  var dp = entry.value;
                  double pct = maxValue > 0 ? (dp.value / maxValue) : 0;
                  bool isLast = idx == salesData.length - 1;

                  return Expanded(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 3.0),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          if (isLast && pct > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A0910),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'R\$${dp.value.toStringAsFixed(0)}',
                                style: GoogleFonts.publicSans(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          const SizedBox(height: 4),
                          Flexible(
                            child: FractionallySizedBox(
                              heightFactor: pct > 0 ? max(0.05, pct) : 0,
                              alignment: Alignment.bottomCenter,
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 400),
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: isLast
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFFF97316)
                                          .withValues(alpha: 0.22),
                                  borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(4)),
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            dp.label,
                            style: GoogleFonts.publicSans(
                              fontSize: 9,
                              color: isLast
                                  ? const Color(0xFFF97316)
                                  : const Color(0xFF9CA3AF),
                              fontWeight:
                                  isLast ? FontWeight.w700 : FontWeight.w400,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.visible,
                          ),
                        ],
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCustomersDonut() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 15, 18, 12),
            child: Row(
              children: [
                Text(
                  'Clientes Novos vs. Recorrentes',
                  style: GoogleFonts.publicSans(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'CLIENTES',
                    style: GoogleFonts.publicSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              children: [
                // Donut mock visualization using Stack & CircularProgressIndicator
                SizedBox(
                  width: 90,
                  height: 90,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: 1.0,
                          strokeWidth: 10,
                          color:
                              const Color(0xFFFED7AA), // Light orange (Novos)
                        ),
                      ),
                      SizedBox(
                        width: 70,
                        height: 70,
                        child: CircularProgressIndicator(
                          value: recorrentesPct / 100, // ex: 0.68
                          strokeWidth: 10,
                          backgroundColor: Colors.transparent,
                          color: const Color(0xFFF97316), // Brand orange
                          strokeCap: StrokeCap.round,
                        ),
                      ),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Text(
                            '$recorrentesPct%',
                            style: GoogleFonts.publicSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFF1A0910),
                            ),
                          ),
                          Text(
                            'recorr.',
                            style: GoogleFonts.publicSans(
                              fontSize: 9,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
                const SizedBox(width: 20),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildDonutLegendItem(
                          'Recorrentes',
                          '$recorrentesPct%',
                          '$clientesRecorrentes clientes',
                          const Color(0xFFF97316)),
                      const SizedBox(height: 10),
                      _buildDonutLegendItem(
                          'Novos hoje',
                          '${100 - recorrentesPct}%',
                          '$clientesNovos clientes',
                          const Color(0xFFFED7AA)),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F8F7),
                          border: Border.all(color: const Color(0xFFEAE8E4)),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Indicações ativas',
                                style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    color: const Color(0xFF9CA3AF))),
                            const SizedBox(height: 2),
                            Text('$indicacoesAtivas clientes',
                                style: GoogleFonts.publicSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFFF97316))),
                          ],
                        ),
                      )
                    ],
                  ),
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildDonutLegendItem(
      String label, String value, String subtitle, Color color) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
                width: 10,
                height: 10,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(3))),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label,
                    style: GoogleFonts.publicSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0910)))),
            Text(value,
                style: GoogleFonts.publicSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A0910))),
          ],
        ),
        Padding(
          padding: const EdgeInsets.only(left: 18),
          child: Text(subtitle,
              style: GoogleFonts.publicSans(
                  fontSize: 11, color: const Color(0xFF9CA3AF))),
        ),
      ],
    );
  }
}
