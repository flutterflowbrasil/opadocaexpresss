import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dashboard_colors.dart';

class TopProductsList extends StatelessWidget {
  final List<Map<String, dynamic>> produtos;

  const TopProductsList({super.key, required this.produtos});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Mais Vendidos',
            style: GoogleFonts.publicSans(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          if (produtos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Text(
                'Sem vendas registradas.',
                style: GoogleFonts.publicSans(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: produtos.length,
              separatorBuilder: (context, index) => const SizedBox(height: 16),
              itemBuilder: (context, index) {
                final produto = produtos[index];
                final price = (produto['preco'] as num?)?.toDouble() ?? 0.0;
                final qtd = produto['total_vendidos'] as int? ?? 0;
                final total = price * qtd;

                return Row(
                  children: [
                    Container(
                      width: 48,
                      height: 48,
                      decoration: BoxDecoration(
                        color: DashboardColors.cream,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: produto['imagem_url'] != null
                          ? Image.network(produto['imagem_url'],
                              fit: BoxFit.cover)
                          : Icon(Icons.bakery_dining,
                              color: DashboardColors.primary
                                  .withValues(alpha: 0.5)),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            produto['nome'] ?? 'Produto',
                            style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              color: isDark ? Colors.white : Colors.black87,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '$qtd unidades',
                            style: GoogleFonts.publicSans(
                              fontSize: 12,
                              color: Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                          .format(total),
                      style: GoogleFonts.publicSans(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                        color: DashboardColors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: () {},
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                side: BorderSide(
                  color: isDark
                      ? DashboardColors.cream.withValues(alpha: 0.2)
                      : DashboardColors.burgundy.withValues(alpha: 0.2),
                ),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
                foregroundColor:
                    isDark ? DashboardColors.cream : DashboardColors.burgundy,
              ),
              child: Text(
                'Ver Relatório Completo',
                style: GoogleFonts.publicSans(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
