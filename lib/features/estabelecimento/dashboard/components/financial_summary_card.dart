import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class FinancialSummaryCard extends StatelessWidget {
  final double bruto;
  final double taxas;
  final double liquido;
  final String periodoLabel;

  const FinancialSummaryCard({
    super.key,
    required this.bruto,
    required this.taxas,
    required this.liquido,
    required this.periodoLabel,
  });

  @override
  Widget build(BuildContext context) {
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
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      'Resumo Financeiro',
                      style: GoogleFonts.publicSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A0910),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F2EF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'GESTÃO',
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
                Text(
                  periodoLabel,
                  style: GoogleFonts.publicSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                Row(
                  children: [
                    _buildKpiBox('BRUTO', bruto, const Color(0xFF1A0910)),
                    const SizedBox(width: 8),
                    _buildKpiBox('TAXAS', taxas, const Color(0xFFEF4444),
                        prefix: '− '),
                    const SizedBox(width: 8),
                    _buildKpiBox('LÍQUIDO', liquido, const Color(0xFF10B981)),
                  ],
                ),
                const SizedBox(height: 14),

                // MOCK Bar showing percentages
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Composição',
                        style: GoogleFonts.publicSans(
                            fontSize: 11, color: const Color(0xFF9CA3AF))),
                    Text('90% líquido',
                        style: GoogleFonts.publicSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF10B981))),
                  ],
                ),
                const SizedBox(height: 5),
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EF),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                          flex: 90,
                          child: Container(
                              decoration: const BoxDecoration(
                                  color: Color(0xFF10B981),
                                  borderRadius: BorderRadius.horizontal(
                                      left: Radius.circular(6))))),
                      Expanded(
                          flex: 5,
                          child: Container(color: const Color(0xFFF97316))),
                      Expanded(
                          flex: 5,
                          child: Container(
                              decoration: const BoxDecoration(
                                  color: Color(0xFFFED7AA),
                                  borderRadius: BorderRadius.horizontal(
                                      right: Radius.circular(6))))),
                    ],
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    _buildLegendItem('Loja 90%', const Color(0xFF10B981)),
                    const SizedBox(width: 12),
                    _buildLegendItem('App 5%', const Color(0xFFF97316)),
                    const SizedBox(width: 12),
                    _buildLegendItem('Entrega 5%', const Color(0xFFFED7AA)),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildKpiBox(String title, double value, Color color,
      {String prefix = ''}) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFFF9F8F7),
          border: Border.all(color: const Color(0xFFEAE8E4)),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.publicSans(
                fontSize: 9.5,
                fontWeight: FontWeight.w700,
                letterSpacing: 0.5,
                color: const Color(0xFF9CA3AF),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '$prefix R\$ ${value.toStringAsFixed(2)}',
              style: GoogleFonts.publicSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildLegendItem(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
                color: color, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 4),
        Text(label,
            style: GoogleFonts.publicSans(
                fontSize: 10, color: const Color(0xFF9CA3AF))),
      ],
    );
  }
}
