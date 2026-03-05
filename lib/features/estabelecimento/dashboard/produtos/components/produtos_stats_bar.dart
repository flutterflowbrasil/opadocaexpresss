import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/produtos_controller.dart';

class ProdutosStatsBar extends ConsumerWidget {
  const ProdutosStatsBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta a lista completa de produtos (não a filtrada), pois as stats são globais
    final produtos =
        ref.watch(produtosControllerProvider.select((s) => s.produtos));

    if (produtos.isEmpty) return const SizedBox.shrink();

    final total = produtos.length;
    final ativos = produtos.where((p) => p.ativo).length;
    final disponiveis = produtos.where((p) => p.ativo && p.disponivel).length;
    final estoqueBaixo = produtos
        .where((p) =>
            p.controleEstoque &&
            (p.quantidadeEstoque != null && p.quantidadeEstoque! <= 5))
        .length;

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final isSmallMobile = constraints.maxWidth < 400;

        // Em mobile pequeno ficaria exprimido em Row, no Grid é mais seguro
        if (isMobile) {
          return GridView.count(
            crossAxisCount: isSmallMobile ? 2 : 2,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 2.5,
            padding: EdgeInsets.zero,
            children: [
              _StatItem(
                icon: Icons.restaurant_menu,
                label: 'Total de Produtos',
                value: total.toString(),
                color: Colors.grey.shade700,
                bgColor: Colors.white,
              ),
              _StatItem(
                icon: Icons.check_circle,
                label: 'Ativos',
                value: ativos.toString(),
                color: Colors.green.shade600,
                bgColor: Colors.green.shade50,
              ),
              _StatItem(
                icon: Icons.shopping_bag,
                label: 'Disponíveis',
                value: disponiveis.toString(),
                color: const Color(0xFFec5b13),
                bgColor: const Color(0xFFfef0e8),
              ),
              _StatItem(
                icon: Icons.warning,
                label: 'Estoque Baixo',
                value: estoqueBaixo.toString(),
                color: Colors.amber.shade700,
                bgColor: Colors.amber.shade50,
              ),
            ],
          );
        }

        return Row(
          children: [
            Expanded(
              child: _StatItem(
                icon: Icons.restaurant_menu,
                label: 'Total de Produtos',
                value: total.toString(),
                color: Colors.grey.shade700,
                bgColor: Colors.white,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.check_circle,
                label: 'Ativos',
                value: ativos.toString(),
                color: Colors.green.shade600,
                bgColor: Colors.green.shade50,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.shopping_bag,
                label: 'Disponíveis',
                value: disponiveis.toString(),
                color: const Color(0xFFec5b13),
                bgColor: const Color(0xFFfef0e8),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _StatItem(
                icon: Icons.warning,
                label: 'Estoque Baixo',
                value: estoqueBaixo.toString(),
                color: Colors.amber.shade700,
                bgColor: Colors.amber.shade50,
              ),
            ),
          ],
        );
      },
    );
  }
}

class _StatItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final Color bgColor;

  const _StatItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.bgColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  value,
                  style: GoogleFonts.publicSans(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                    height: 1.1,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
