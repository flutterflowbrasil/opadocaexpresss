import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/estab_adm_model.dart';

class EstabListItem extends StatelessWidget {
  final EstabAdmModel estab;
  final VoidCallback onTap;

  const EstabListItem({super.key, required this.estab, required this.onTap});

  static const _statusCfg = {
    'aprovado': (
      label: 'Aprovado',
      color: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
      border: Color(0xFFA7F3D0),
    ),
    'pendente': (
      label: 'Pendente',
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
      border: Color(0xFFFDE68A),
    ),
    'suspenso': (
      label: 'Suspenso',
      color: Color(0xFFEF4444),
      bg: Color(0xFFFEF2F2),
      border: Color(0xFFFCA5A5),
    ),
    'rejeitado': (
      label: 'Rejeitado',
      color: Color(0xFF6B7280),
      bg: Color(0xFFF9FAFB),
      border: Color(0xFFE5E7EB),
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _statusCfg[estab.statusCadastro] ??
        _statusCfg['pendente']!;
    final inicial = estab.nomeFantasia.isNotEmpty
        ? estab.nomeFantasia[0].toUpperCase()
        : '?';

    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.white,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
        child: Row(
          children: [
            // Avatar
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFFFF7ED), Color(0xFFFED7AA)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFFED7AA)),
              ),
              child: Center(
                child: Text(
                  inicial,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Nome + CNPJ
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          estab.nomeFantasia,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.publicSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A0910),
                          ),
                        ),
                      ),
                      if (estab.destaque) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 1,
                          ),
                          decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                          ),
                          child: Text(
                            '★ Destaque',
                            style: GoogleFonts.publicSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    '${estab.razaoSocial}${estab.cnpj != null ? ' · ${estab.cnpj}' : ''}',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Métricas compactas
            _Metric(
              label: 'Pedidos',
              value: '${estab.totalPedidos ?? 0}',
              color: const Color(0xFFF97316),
            ),
            const SizedBox(width: 10),
            _Metric(
              label: 'Avaliação',
              value: estab.avaliacaoMedia > 0
                  ? '${estab.avaliacaoMedia.toStringAsFixed(1)} ★'
                  : '—',
              color: const Color(0xFFF59E0B),
            ),
            const SizedBox(width: 14),

            // Badge de status
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: cfg.bg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: cfg.border),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 5,
                    height: 5,
                    decoration: BoxDecoration(
                      color: cfg.color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 5),
                  Text(
                    cfg.label,
                    style: GoogleFonts.publicSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: cfg.color,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            const Icon(
              Icons.chevron_right,
              size: 16,
              color: Color(0xFFD1D5DB),
            ),
          ],
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Metric({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          value,
          style: GoogleFonts.publicSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 9,
            color: const Color(0xFF9CA3AF),
          ),
        ),
      ],
    );
  }
}
