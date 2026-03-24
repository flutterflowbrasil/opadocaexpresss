import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/suporte_adm_controller.dart';
import '../../models/suporte_adm_models.dart';

// ── Aba Notificações ──────────────────────────────────────────────────────────

class SuporteNotificacoesTab extends ConsumerWidget {
  const SuporteNotificacoesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isLoading),
    );
    final notificacoes = ref.watch(
      suporteAdmControllerProvider.select((s) => s.notificacoes),
    );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner informativo
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            padding:
                const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFFFFBEB),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: const Color(0xFFFDE68A)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    size: 15, color: Color(0xFFF59E0B)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Notificações são enviadas via Edge Function pelo worker FCM. '
                    'Erros persistentes indicam tokens inválidos ou limite de quota atingido.',
                    style: GoogleFonts.dmSans(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),

          if (isLoading)
            const _NotifsShimmer()
          else if (notificacoes.isEmpty)
            _NotifsEmptyState()
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _NotifsTable(notificacoes: notificacoes),
            ),
        ],
      ),
    );
  }
}

// ── Tabela ────────────────────────────────────────────────────────────────────

class _NotifsTable extends StatelessWidget {
  final List<NotificacaoFila> notificacoes;
  const _NotifsTable({required this.notificacoes});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(150),
        1: FixedColumnWidth(160),
        2: FixedColumnWidth(100),
        3: FixedColumnWidth(80),
        4: FixedColumnWidth(180),
        5: FixedColumnWidth(110),
      },
      children: [
        _header(),
        ...notificacoes.map(_row),
      ],
    );
  }

  TableRow _header() {
    const cols = [
      'Evento',
      'Título',
      'Status',
      'Tentativas',
      'Erro',
      'Criado em',
    ];
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      children: cols
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Text(
                c,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _row(NotificacaoFila n) {
    const statusCfg = {
      'pendente':    (l: 'Pendente',    c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
      'processando': (l: 'Processando', c: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF)),
      'enviado':     (l: 'Enviado',     c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'falhou':      (l: 'Falhou',      c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
      'ignorado':    (l: 'Ignorado',    c: Color(0xFF9CA3AF), bg: Color(0xFFF9FAFB)),
    };
    final cfg = statusCfg[n.status];
    final esgotado = n.tentativas >= n.maxTentativas;

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      children: [
        _cell(_eventoLabel(n.evento)),
        _cell(n.titulo),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: cfg == null
              ? Text(n.status,
                  style: GoogleFonts.dmSans(fontSize: 11))
              : _StatusBadge(
                  label: cfg.l, color: cfg.c, bg: cfg.bg),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '${n.tentativas}/${n.maxTentativas}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: esgotado
                      ? const Color(0xFFEF4444)
                      : const Color(0xFF374151),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 4),
          child: n.erroCodigo != null
              ? Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        borderRadius: BorderRadius.circular(5),
                      ),
                      child: Text(
                        n.erroCodigo!,
                        style: GoogleFonts.dmSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFFEF4444),
                        ),
                      ),
                    ),
                    if (n.erroDetalhe != null) ...[
                      const SizedBox(height: 2),
                      Text(
                        n.erroDetalhe!,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          color: const Color(0xFF9CA3AF),
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ],
                )
              : Text('—',
                  style: GoogleFonts.dmSans(
                      fontSize: 11, color: const Color(0xFF9CA3AF))),
        ),
        _cell(_fmtDate(n.createdAt)),
      ],
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 2),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: const Color(0xFF374151),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  String _eventoLabel(String evento) {
    return evento.replaceAll('_', ' ');
  }
}

class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _StatusBadge(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
          color: bg, borderRadius: BorderRadius.circular(6)),
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

// ── Empty & shimmer ───────────────────────────────────────────────────────────

class _NotifsEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.notifications_active_outlined,
              size: 40, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma notificação na fila.\nTodos os envios foram processados.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifsShimmer extends StatelessWidget {
  const _NotifsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: List.generate(
          4,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
