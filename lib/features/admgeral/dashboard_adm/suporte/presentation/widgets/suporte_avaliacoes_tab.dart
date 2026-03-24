import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/suporte_adm_controller.dart';
import '../../models/suporte_adm_models.dart';

// ── Aba Avaliações ────────────────────────────────────────────────────────────

class SuporteAvaliacoesTab extends ConsumerWidget {
  const SuporteAvaliacoesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isLoading),
    );
    final avaliacoes = ref.watch(
      suporteAdmControllerProvider.select((s) => s.avaliacoes),
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
          if (isLoading)
            const _AvaliacoesShimmer()
          else if (avaliacoes.isEmpty)
            _AvaliacoesEmptyState()
          else
            LayoutBuilder(
              builder: (context, constraints) {
                final crossAxisCount =
                    constraints.maxWidth > 700 ? 2 : 1;
                return _AvaliacoesGrid(
                  avaliacoes: avaliacoes,
                  crossAxisCount: crossAxisCount,
                );
              },
            ),
        ],
      ),
    );
  }
}

// ── Grid de cards ─────────────────────────────────────────────────────────────

class _AvaliacoesGrid extends StatelessWidget {
  final List<Avaliacao> avaliacoes;
  final int crossAxisCount;

  const _AvaliacoesGrid({
    required this.avaliacoes,
    required this.crossAxisCount,
  });

  @override
  Widget build(BuildContext context) {
    // Wrap em vez de GridView para evitar constraints de altura
    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: avaliacoes
          .map((a) => FractionallySizedBox(
                widthFactor: crossAxisCount == 2 ? 0.49 : 1.0,
                child: _AvaliacaoCard(avaliacao: a),
              ))
          .toList(),
    );
  }
}

// ── Card ──────────────────────────────────────────────────────────────────────

class _AvaliacaoCard extends StatelessWidget {
  final Avaliacao avaliacao;
  const _AvaliacaoCard({required this.avaliacao});

  bool get _isNegativa =>
      (avaliacao.notaEstabelecimento ?? 5) <= 3 ||
      (avaliacao.notaEntregador ?? 5) <= 3;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: _isNegativa
              ? const Color(0xFFFCA5A5)
              : const Color(0xFFEAE8E4),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.person_outline,
                            size: 13, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            avaliacao.clienteNome ?? 'Cliente',
                            style: GoogleFonts.dmSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A0910),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Row(
                      children: [
                        const Icon(Icons.store_outlined,
                            size: 12, color: Color(0xFF9CA3AF)),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            avaliacao.estabNome ?? 'Estabelecimento',
                            style: GoogleFonts.dmSans(
                              fontSize: 11,
                              color: const Color(0xFF9CA3AF),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              if (_isNegativa)
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 7, vertical: 3),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Negativa',
                    style: GoogleFonts.dmSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFEF4444),
                    ),
                  ),
                ),
              const SizedBox(width: 6),
              Text(
                _fmtDate(avaliacao.createdAt),
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(height: 1, color: Color(0xFFF3F1EE)),
          const SizedBox(height: 10),

          // Notas
          if (avaliacao.notaEstabelecimento != null) ...[
            _NotaRow(
              label: 'Estabelecimento',
              nota: avaliacao.notaEstabelecimento!,
              comentario: avaliacao.comentarioEstabelecimento,
            ),
          ],
          if (avaliacao.notaEntregador != null) ...[
            const SizedBox(height: 8),
            _NotaRow(
              label: 'Entregador',
              nota: avaliacao.notaEntregador!,
              comentario: avaliacao.comentarioEntregador,
            ),
          ],
        ],
      ),
    );
  }
}

class _NotaRow extends StatelessWidget {
  final String label;
  final double nota;
  final String? comentario;

  const _NotaRow({
    required this.label,
    required this.nota,
    this.comentario,
  });

  @override
  Widget build(BuildContext context) {
    final intNota = nota.round();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280),
              ),
            ),
            const SizedBox(width: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: List.generate(5, (i) {
                return Icon(
                  i < intNota ? Icons.star_rounded : Icons.star_outline_rounded,
                  size: 13,
                  color: i < intNota
                      ? const Color(0xFFF59E0B)
                      : const Color(0xFFE5E7EB),
                );
              }),
            ),
            const SizedBox(width: 5),
            Text(
              nota.toStringAsFixed(0),
              style: GoogleFonts.dmSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: intNota <= 3
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
              ),
            ),
          ],
        ),
        if (comentario != null && comentario!.isNotEmpty) ...[
          const SizedBox(height: 3),
          Text(
            '"$comentario"',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF6B7280),
              fontStyle: FontStyle.italic,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }
}

// ── Empty & shimmer ───────────────────────────────────────────────────────────

class _AvaliacoesEmptyState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.star_outline_rounded,
              size: 40, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 12),
          Text(
            'Nenhuma avaliação registrada ainda.\nAs avaliações aparecem após a entrega dos pedidos.',
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

class _AvaliacoesShimmer extends StatelessWidget {
  const _AvaliacoesShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Wrap(
        spacing: 12,
        runSpacing: 12,
        children: List.generate(
          4,
          (_) => Container(
            height: 110,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
