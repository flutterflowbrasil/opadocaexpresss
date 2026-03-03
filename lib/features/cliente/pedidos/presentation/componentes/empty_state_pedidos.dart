import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EmptyStatePedidos extends StatelessWidget {
  final bool isAtivos;

  const EmptyStatePedidos({super.key, required this.isAtivos});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isAtivos ? Icons.shopping_bag_outlined : Icons.history,
            size: 64,
            color: isDark ? Colors.white54 : Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            isAtivos
                ? 'Nenhum pedido em andamento'
                : 'Nenhum histórico de pedidos',
            style: GoogleFonts.outfit(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : const Color(0xFF4A1010),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            isAtivos
                ? 'Quando você fizer um pedido, ele vai aparecer aqui para você acompanhar.'
                : 'Os pedidos que você já concluiu ficarão salvos aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
