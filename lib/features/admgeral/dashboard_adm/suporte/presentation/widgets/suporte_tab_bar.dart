import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Configuração das abas ─────────────────────────────────────────────────────

typedef SuporteAba = ({String id, String label, IconData icon});

const List<SuporteAba> kSuporteAbas = [
  (id: 'chamados',      label: 'Chamados',      icon: Icons.support_agent_outlined),
  (id: 'notificacoes',  label: 'Notificações',  icon: Icons.notifications_outlined),
  (id: 'avaliacoes',    label: 'Avaliações',    icon: Icons.star_outline_rounded),
];

// ── Tab Bar ───────────────────────────────────────────────────────────────────

class SuporteTabBar extends StatelessWidget {
  final String abaAtiva;
  final void Function(String) onAbaChanged;
  final int chamadosAbertos;
  final int notifsErro;
  final int avalNegativas;

  const SuporteTabBar({
    super.key,
    required this.abaAtiva,
    required this.onAbaChanged,
    this.chamadosAbertos = 0,
    this.notifsErro = 0,
    this.avalNegativas = 0,
  });

  int? _badge(String id) {
    return switch (id) {
      'chamados'     => chamadosAbertos > 0 ? chamadosAbertos : null,
      'notificacoes' => notifsErro > 0 ? notifsErro : null,
      'avaliacoes'   => avalNegativas > 0 ? avalNegativas : null,
      _              => null,
    };
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F1EE),
        borderRadius: BorderRadius.circular(10),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: kSuporteAbas.map((aba) {
            final isActive = abaAtiva == aba.id;
            final badge = _badge(aba.id);
            return GestureDetector(
              onTap: () => onAbaChanged(aba.id),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 150),
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
                decoration: BoxDecoration(
                  color: isActive ? Colors.white : Colors.transparent,
                  borderRadius: BorderRadius.circular(7),
                  boxShadow: isActive
                      ? [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.06),
                            blurRadius: 6,
                            offset: const Offset(0, 2),
                          ),
                        ]
                      : null,
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      aba.icon,
                      size: 14,
                      color: isActive
                          ? const Color(0xFFF97316)
                          : const Color(0xFF9CA3AF),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      aba.label,
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: isActive
                            ? FontWeight.w700
                            : FontWeight.w500,
                        color: isActive
                            ? const Color(0xFF1A0910)
                            : const Color(0xFF9CA3AF),
                      ),
                    ),
                    if (badge != null) ...[
                      const SizedBox(width: 5),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 5, vertical: 1),
                        decoration: BoxDecoration(
                          color: isActive
                              ? const Color(0xFFFFF7ED)
                              : const Color(0xFFEF4444),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          badge.toString(),
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            color: isActive
                                ? const Color(0xFFF97316)
                                : Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}
