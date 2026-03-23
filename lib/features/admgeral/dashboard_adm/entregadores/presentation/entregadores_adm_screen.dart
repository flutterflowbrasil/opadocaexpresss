import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/entregadores_adm_controller.dart';
import '../models/entregador_adm_model.dart';
import 'widgets/entregadores_kpi_strip.dart';
import 'widgets/entregadores_filter_bar.dart';
import 'widgets/entregador_list_item.dart';
import 'dialogs/entregador_detalhes_modal.dart';
import 'dialogs/entregador_confirm_modal.dart';
import 'dialogs/entregador_selfie_modal.dart';

class EntregadoresAdmScreen extends ConsumerStatefulWidget {
  const EntregadoresAdmScreen({super.key});

  @override
  ConsumerState<EntregadoresAdmScreen> createState() =>
      _EntregadoresAdmScreenState();
}

class _EntregadoresAdmScreenState
    extends ConsumerState<EntregadoresAdmScreen> {
  String? _selecionadoId;
  _AcaoPendente? _acaoPendente;
  String? _selfieEntregadorId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(entregadoresAdmControllerProvider);
    final ctrl = ref.read(entregadoresAdmControllerProvider.notifier);
    final filtered = state.filtered;

    final selecionado = _selecionadoId != null
        ? state.entregadores.where((e) => e.id == _selecionadoId).firstOrNull
        : null;
    final selfieEntregador = _selfieEntregadorId != null
        ? state.entregadores
            .where((e) => e.id == _selfieEntregadorId)
            .firstOrNull
        : null;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
              child: Row(
                children: [
                  Flexible(
                    child: Row(children: [
                      Text('Entregadores',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF1A0910))),
                      const SizedBox(width: 10),
                      Text('·',
                          style: GoogleFonts.dmSans(
                              fontSize: 14,
                              color: const Color(0xFF9CA3AF))),
                      const SizedBox(width: 10),
                      Flexible(
                        child: Text('Gestão de cadastros',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFFF97316))),
                      ),
                    ]),
                  ),
                  _refreshBtn(ctrl.fetch),
                ],
              ),
            ),

            // ── KPIs ─────────────────────────────────────────
            const EntregadoresKpiStrip(),
            const SizedBox(height: 14),

            // ── Filtros ──────────────────────────────────────
            const EntregadoresFilterBar(),
            const SizedBox(height: 14),

            // ── Erro inline ──────────────────────────────────
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.fromLTRB(22, 0, 22, 14),
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(state.errorMessage!,
                      style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFDC2626))),
                ),
              ),

            // ── Lista ────────────────────────────────────────
            Expanded(
              child: Container(
                margin:
                    const EdgeInsets.symmetric(horizontal: 22),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: const Color(0xFFEAE8E4)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: state.isLoading
                      ? _buildShimmer()
                      : filtered.isEmpty
                          ? _buildEmptyState()
                          : ListView.separated(
                              itemCount: filtered.length,
                              separatorBuilder: (_, __) => const Divider(
                                  height: 1, color: Color(0xFFF3F1EE)),
                              itemBuilder: (context, i) {
                                final e = filtered[i];
                                return EntregadorListItem(
                                  entregador: e,
                                  onTap: () => setState(
                                      () => _selecionadoId = e.id),
                                );
                              },
                            ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),

        // ── Modal de detalhes ────────────────────────────────
        if (selecionado != null)
          _backdrop(
            onTap: () => setState(() => _selecionadoId = null),
            child: EntregadorDetalhesModal(
              entregador: selecionado,
              isSubmitting: state.isSubmitting,
              onClose: () => setState(() => _selecionadoId = null),
              onAcao: (acao, e) {
                setState(() {
                  _selecionadoId = null;
                  _acaoPendente = _AcaoPendente(acao: acao, entregador: e);
                });
              },
              onAbrirSelfie: (e) {
                setState(() {
                  _selecionadoId = null;
                  _selfieEntregadorId = e.id;
                });
              },
            ),
          ),

        // ── Modal de confirmação ─────────────────────────────
        if (_acaoPendente != null)
          _backdrop(
            onTap: () => setState(() => _acaoPendente = null),
            child: EntregadorConfirmModal(
              acao: _acaoPendente!.acao,
              entregador: _acaoPendente!.entregador,
              isSubmitting: state.isSubmitting,
              onClose: () => setState(() => _acaoPendente = null),
              onConfirm: (acao, id, motivo) async {
                await ctrl.executarAcao(acao, id, motivo: motivo);
                if (!mounted) return;
                if (ref
                    .read(entregadoresAdmControllerProvider)
                    .errorMessage ==
                    null) {
                  setState(() => _acaoPendente = null);
                }
              },
            ),
          ),

        // ── Modal de selfie ──────────────────────────────────
        if (selfieEntregador != null)
          _backdrop(
            onTap: () => setState(() => _selfieEntregadorId = null),
            child: EntregadorSelfieModal(
              entregador: selfieEntregador,
              isSubmitting: state.isSubmitting,
              onClose: () => setState(() => _selfieEntregadorId = null),
              onRevisar: (status, obs) async {
                await ctrl.revisarSelfie(selfieEntregador.id, status,
                    observacao: obs);
                if (!mounted) return;
                setState(() => _selfieEntregadorId = null);
              },
            ),
          ),
      ],
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _backdrop({required Widget child, required VoidCallback onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        color: Colors.black.withValues(alpha: 0.48),
        child: child,
      ),
    );
  }

  Widget _refreshBtn(VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: const Color(0xFFEAE8E4)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.refresh, size: 14, color: Color(0xFF6B7280)),
            const SizedBox(width: 5),
            Text('Atualizar',
                style: GoogleFonts.dmSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280))),
          ],
        ),
      ),
    );
  }

  Widget _buildShimmer() {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFE5E7EB),
      highlightColor: const Color(0xFFF3F4F6),
      child: ListView.separated(
        itemCount: 8,
        separatorBuilder: (_, __) =>
            const Divider(height: 1, color: Color(0xFFF3F1EE)),
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                        height: 12,
                        width: 150,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                    const SizedBox(height: 6),
                    Container(
                        height: 10,
                        width: 220,
                        decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6))),
                  ],
                ),
              ),
              Container(
                  height: 24,
                  width: 72,
                  decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(20))),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.motorcycle_outlined,
              size: 40, color: Color(0xFFD1D5DB)),
          const SizedBox(height: 10),
          Text('Nenhum entregador encontrado',
              style: GoogleFonts.dmSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF6B7280))),
          const SizedBox(height: 4),
          Text('Tente ajustar os filtros ou a busca.',
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: const Color(0xFF9CA3AF))),
        ],
      ),
    );
  }
}

// ── Helper data class ─────────────────────────────────────────────────────────

class _AcaoPendente {
  final String acao;
  final EntregadorAdmModel entregador;
  const _AcaoPendente({required this.acao, required this.entregador});
}
