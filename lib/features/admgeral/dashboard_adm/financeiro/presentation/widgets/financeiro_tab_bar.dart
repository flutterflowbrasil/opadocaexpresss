import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

const kFinanceiroAbas = [
  ('visao_geral', 'Visão Geral'),
  ('pedidos', 'Pedidos & Pagamentos'),
  ('splits', 'Splits'),
  ('saques', 'Saques PIX'),
  ('subcontas', 'Subcontas Asaas'),
];

class FinanceiroTabBar extends StatelessWidget {
  final String abaAtiva;
  final ValueChanged<String> onAbaChanged;

  const FinanceiroTabBar({
    super.key,
    required this.abaAtiva,
    required this.onAbaChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: kFinanceiroAbas.map((aba) {
          final id = aba.$1;
          final label = aba.$2;
          final isActive = id == abaAtiva;
          return GestureDetector(
            onTap: () => onAbaChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              margin: const EdgeInsets.only(right: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              decoration: BoxDecoration(
                color: isActive ? const Color(0xFFFFF7ED) : Colors.white,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isActive
                      ? const Color(0xFFF97316)
                      : const Color(0xFFEAE8E4),
                  width: 1.5,
                ),
              ),
              child: Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: isActive
                      ? const Color(0xFFF97316)
                      : const Color(0xFF6B7280),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
