import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/entregador_adm_model.dart';

// ── Configurações de status ────────────────────────────────────────────────────

const _statusConfig = {
  'pendente':  _StatusCfg('Pendente',  Color(0xFFF59E0B), Color(0xFFFFFBEB), Color(0xFFFDE68A)),
  'aprovado':  _StatusCfg('Aprovado',  Color(0xFF10B981), Color(0xFFECFDF5), Color(0xFFA7F3D0)),
  'suspenso':  _StatusCfg('Suspenso',  Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFFCA5A5)),
  'rejeitado': _StatusCfg('Rejeitado', Color(0xFF6B7280), Color(0xFFF9FAFB), Color(0xFFE5E7EB)),
};

const _selfieConfig = {
  'revisao_manual': _StatusCfg('Selfie ✋', Color(0xFFF59E0B), Color(0xFFFFFBEB), Color(0xFFFDE68A)),
  'aprovado':       _StatusCfg('Selfie ✅', Color(0xFF10B981), Color(0xFFECFDF5), Color(0xFFA7F3D0)),
  'reprovado':      _StatusCfg('Selfie ❌', Color(0xFFEF4444), Color(0xFFFEF2F2), Color(0xFFFCA5A5)),
};

const _veiculoIcon = {
  'moto':      '🏍️',
  'carro':     '🚗',
  'bicicleta': '🚲',
  'van':       '🚐',
};

class _StatusCfg {
  final String label;
  final Color color, bg, border;
  const _StatusCfg(this.label, this.color, this.bg, this.border);
}

// ── Widget ────────────────────────────────────────────────────────────────────

class EntregadorListItem extends StatelessWidget {
  final EntregadorAdmModel entregador;
  final VoidCallback onTap;

  const EntregadorListItem({
    super.key,
    required this.entregador,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final e = entregador;
    final st = _statusConfig[e.statusCadastro] ?? _statusConfig['pendente']!;
    final selfie = e.selfieRevisao;
    final selfieConf = selfie != null ? _selfieConfig[selfie.status] : null;
    final docPct = EntregadorAdmModel.docTotal > 0
        ? e.docCount / EntregadorAdmModel.docTotal
        : 0.0;

    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // ── Avatar com ícone veículo ─────────────────────
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: const Color(0xFFEFF6FF),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: const Color(0xFFBFDBFE)),
              ),
              child: Center(
                child: Text(
                  _veiculoIcon[e.tipoVeiculo] ?? '🏍️',
                  style: const TextStyle(fontSize: 18),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // ── Nome / e-mail ─────────────────────────────────
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          e.nome,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A0910),
                          ),
                        ),
                      ),
                      if (e.statusOnline) ...[
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: const BoxDecoration(
                            color: Color(0xFF10B981),
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                  Text(
                    e.email ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // ── Veículo ──────────────────────────────────────
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    e.veiculoModelo ?? '—',
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF374151),
                    ),
                  ),
                  if (e.veiculoPlaca != null)
                    Text(
                      e.veiculoPlaca!,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 1,
                      ),
                    ),
                ],
              ),
            ),

            // ── Estatísticas ──────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.totalEntregas}',
                    style: GoogleFonts.dmSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                  Text(
                    'entregas',
                    style: GoogleFonts.dmSans(
                      fontSize: 10,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ),
            ),

            // ── Docs progress ─────────────────────────────────
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${e.docCount}/${EntregadorAdmModel.docTotal}',
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: e.docCount == EntregadorAdmModel.docTotal
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                  const SizedBox(height: 3),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(3),
                    child: LinearProgressIndicator(
                      value: docPct,
                      minHeight: 4,
                      backgroundColor: const Color(0xFFE5E7EB),
                      color: e.docCount == EntregadorAdmModel.docTotal
                          ? const Color(0xFF10B981)
                          : const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(width: 10),

            // ── Status badge ──────────────────────────────────
            _Badge(label: st.label, color: st.color, bg: st.bg, border: st.border),

            // ── Selfie badge (se existir) ─────────────────────
            if (selfieConf != null) ...[
              const SizedBox(width: 6),
              _Badge(
                label: selfieConf.label,
                color: selfieConf.color,
                bg: selfieConf.bg,
                border: selfieConf.border,
              ),
            ] else if (e.docEnviado('selfie')) ...[
              const SizedBox(width: 6),
              _Badge(
                label: 'Selfie ⏳',
                color: const Color(0xFF8B5CF6),
                bg: const Color(0xFFF5F3FF),
                border: const Color(0xFFDDD6FE),
              ),
            ],

            const SizedBox(width: 10),

            // ── Botão ver ─────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(7),
                border: Border.all(color: const Color(0xFFEAE8E4)),
              ),
              child: Text(
                'Ver',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color, bg, border;

  const _Badge({
    required this.label,
    required this.color,
    required this.bg,
    required this.border,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: border),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}
