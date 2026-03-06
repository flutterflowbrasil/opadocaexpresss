import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class RankingProduto {
  final String nome;
  final int vendidos;
  final String foto;
  final double receita;

  RankingProduto({
    required this.nome,
    required this.vendidos,
    required this.foto,
    required this.receita,
  });
}

class DashboardRankingCards extends StatelessWidget {
  final List<RankingProduto> produtos;
  final int totalPedidos;
  final String periodoLabel;

  // Funil de status
  final int pendentes;
  final int confirmados;
  final int preparando;
  final int prontos;
  final int emEntrega;
  final int entregues;

  const DashboardRankingCards({
    super.key,
    required this.produtos,
    required this.totalPedidos,
    required this.periodoLabel,
    required this.pendentes,
    required this.confirmados,
    required this.preparando,
    required this.prontos,
    required this.emEntrega,
    required this.entregues,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;
        if (isMobile) {
          return Column(
            children: [
              _buildRankingCard(),
              const SizedBox(height: 16),
              _buildFunnelCard(),
            ],
          );
        }
        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildRankingCard()),
            const SizedBox(width: 16),
            Expanded(child: _buildFunnelCard()),
          ],
        );
      },
    );
  }

  Widget _buildRankingCard() {
    int maxVendidos = produtos.isEmpty ? 1 : produtos[0].vendidos;
    if (maxVendidos == 0) maxVendidos = 1;

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
                      'Ranking de Produtos',
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
                        'CARDÁPIO',
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
                Icon(Icons.arrow_forward_ios,
                    size: 12, color: const Color(0xFF6B7280)),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: produtos.isEmpty
                ? Padding(
                    padding: const EdgeInsets.symmetric(vertical: 20),
                    child: Center(
                      child: Text('Nenhum dado',
                          style: GoogleFonts.publicSans(color: Colors.grey)),
                    ),
                  )
                : Column(
                    children: produtos.asMap().entries.map((e) {
                      int idx = e.key;
                      var p = e.value;
                      bool isTop = idx == 0;
                      double pct = p.vendidos / maxVendidos;

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 13),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 18,
                              child: Text(
                                '#${idx + 1}',
                                style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: isTop
                                      ? const Color(0xFFF97316)
                                      : const Color(0xFFD1D5DB),
                                ),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Text(p.foto, style: const TextStyle(fontSize: 18)),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Expanded(
                                        child: Text(
                                          p.nome,
                                          style: GoogleFonts.publicSans(
                                            fontSize: 12.5,
                                            fontWeight: FontWeight.w600,
                                            color: const Color(0xFF1A0910),
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Text(
                                        '${p.vendidos}×',
                                        style: GoogleFonts.publicSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w800,
                                          color: isTop
                                              ? const Color(0xFFF97316)
                                              : const Color(0xFF6B7280),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 4),
                                  Container(
                                    height: 5,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF4F2EF),
                                      borderRadius: BorderRadius.circular(3),
                                    ),
                                    child: FractionallySizedBox(
                                      alignment: Alignment.centerLeft,
                                      widthFactor: pct.clamp(0.0, 1.0),
                                      child: Container(
                                        decoration: BoxDecoration(
                                          color: isTop
                                              ? const Color(0xFFF97316)
                                              : const Color(0xFFF97316)
                                                  .withValues(alpha: 0.28),
                                          borderRadius:
                                              BorderRadius.circular(3),
                                        ),
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    'R\$ ${p.receita.toStringAsFixed(2)} gerados',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 10,
                                      color: const Color(0xFF9CA3AF),
                                    ),
                                  ),
                                ],
                              ),
                            )
                          ],
                        ),
                      );
                    }).toList(),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildFunnelCard() {
    // Finds the maximum volume to base the progress bars
    int maxFunnel = [
      pendentes,
      confirmados,
      preparando,
      prontos,
      emEntrega,
      entregues
    ].reduce((a, b) => a > b ? a : b);
    if (maxFunnel == 0) maxFunnel = 1;

    Widget buildRow(String label, int value, Color color) {
      double pct = value / maxFunnel;
      return Padding(
        padding: const EdgeInsets.only(bottom: 8.0),
        child: Row(
          children: [
            SizedBox(
              width: 74,
              child: Text(
                label,
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Container(
                height: 20,
                decoration: BoxDecoration(
                  color: const Color(0xFFF4F2EF),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: FractionallySizedBox(
                  alignment: Alignment.centerLeft,
                  widthFactor: pct > 0 ? (pct < 0.05 ? 0.05 : pct) : 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    padding: const EdgeInsets.only(left: 8),
                    alignment: Alignment.centerLeft,
                    child: value > 0
                        ? Text(
                            '$value',
                            style: GoogleFonts.publicSans(
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          )
                        : null,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 10),
            SizedBox(
              width: 28,
              child: Text(
                '$value',
                textAlign: TextAlign.right,
                style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
            )
          ],
        ),
      );
    }

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
                      'Funil de Status',
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
                        'OPERAÇÃO',
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
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '$totalPedidos',
                      style: GoogleFonts.publicSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0910),
                      ),
                    ),
                    Text(
                      'pedidos · $periodoLabel',
                      style: GoogleFonts.publicSans(
                        fontSize: 10,
                        color: const Color(0xFF9CA3AF),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                buildRow('Pendente', pendentes, const Color(0xFFF59E0B)),
                buildRow('Confirmado', confirmados, const Color(0xFF3B82F6)),
                buildRow('Preparando', preparando, const Color(0xFF8B5CF6)),
                buildRow('Pronto', prontos, const Color(0xFF10B981)),
                buildRow('Em entrega', emEntrega, const Color(0xFFF97316)),
                buildRow('Entregue', entregues, const Color(0xFF6B7280)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9F8F7),
                          border: Border.all(color: const Color(0xFFEAE8E4)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Taxa de conclusão',
                                style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    color: const Color(0xFF9CA3AF))),
                            const SizedBox(height: 2),
                            Text(
                              '${totalPedidos > 0 ? ((entregues / totalPedidos) * 100).toStringAsFixed(0) : "0"}%',
                              style: GoogleFonts.publicSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981)),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 12, vertical: 10),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF7ED),
                          border: Border.all(color: const Color(0xFFFED7AA)),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Tempo médio',
                                style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF92400E))),
                            const SizedBox(height: 2),
                            Text(
                              '-- min', // Placeholder mock logic for time
                              style: GoogleFonts.publicSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFFF97316)),
                            ),
                            Text('do pedido à entrega',
                                style: GoogleFonts.publicSans(
                                    fontSize: 9.5,
                                    color: const Color(0xFFC4C1BC))),
                          ],
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
