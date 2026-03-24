import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Dropdown de filtro padrão da tela financeiro.
class FinanceiroDropdown extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const FinanceiroDropdown({
    super.key,
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 34,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isDense: true,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF374151),
          ),
          icon: const Icon(Icons.expand_more, size: 16, color: Color(0xFF9CA3AF)),
          items: items.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
          onChanged: (v) {
            if (v != null) onChanged(v);
          },
        ),
      ),
    );
  }
}

/// Estado vazio padrão para abas financeiras.
class FinanceiroEmptyState extends StatelessWidget {
  final IconData icon;
  final String mensagem;
  final VoidCallback? onRetry;

  const FinanceiroEmptyState({
    super.key,
    required this.icon,
    required this.mensagem,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 40, color: const Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            mensagem,
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
          if (onRetry != null) ...[
            const SizedBox(height: 14),
            TextButton(
              onPressed: onRetry,
              child: Text(
                'Tentar novamente',
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFFF97316),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Banner de aviso para abas que aguardam Edge Functions.
class FinanceiroEdgeFunctionBanner extends StatelessWidget {
  final String mensagem;

  const FinanceiroEdgeFunctionBanner({super.key, required this.mensagem});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_outline, size: 15, color: Color(0xFFF59E0B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Badge de status reutilizável.
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}
