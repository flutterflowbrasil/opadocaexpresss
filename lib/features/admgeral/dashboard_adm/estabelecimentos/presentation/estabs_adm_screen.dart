import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../controllers/estabs_adm_controller.dart';
import 'widgets/estabs_kpi_strip.dart';
import 'widgets/estabs_filter_bar.dart';
import 'widgets/estab_list_item.dart';
import 'dialogs/estab_detalhes_modal.dart';

class EstabsAdmScreen extends ConsumerStatefulWidget {
  const EstabsAdmScreen({super.key});

  @override
  ConsumerState<EstabsAdmScreen> createState() => _EstabsAdmScreenState();
}

class _EstabsAdmScreenState extends ConsumerState<EstabsAdmScreen> {
  String? _estabSelecionadoId;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(estabsAdmControllerProvider);
    final controller = ref.read(estabsAdmControllerProvider.notifier);
    final filtered = state.filtered;

    // Estabelecimento selecionado para o modal
    final estabSelecionado = _estabSelecionadoId != null
        ? state.estabelecimentos
            .where((e) => e.id == _estabSelecionadoId)
            .firstOrNull
        : null;

    return Stack(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Header ─────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(22, 22, 22, 14),
              child: Row(
                children: [
                  Flexible(
                    child: Row(
                      children: [
                        Text(
                          'Estabelecimentos',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1A0910),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          '·',
                          style: GoogleFonts.publicSans(
                            fontSize: 14,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Flexible(
                          child: Text(
                            'Gestão de cadastros',
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFFF97316),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  GestureDetector(
                    onTap: controller.fetch,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: const Color(0xFFEAE8E4)),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.refresh,
                            size: 14,
                            color: Color(0xFF6B7280),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            'Atualizar',
                            style: GoogleFonts.publicSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // ── KPIs ───────────────────────────────────────
            const EstabsKpiStrip(),
            const SizedBox(height: 14),

            // ── Filtros ─────────────────────────────────────
            const EstabsFilterBar(),
            const SizedBox(height: 14),

            // ── Erro ────────────────────────────────────────
            if (state.errorMessage != null)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 22),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFEF2F2),
                    borderRadius: BorderRadius.circular(9),
                    border: Border.all(color: const Color(0xFFFCA5A5)),
                  ),
                  child: Text(
                    state.errorMessage!,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: const Color(0xFFDC2626),
                    ),
                  ),
                ),
              ),

            // ── Lista ───────────────────────────────────────
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 22),
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
                                height: 1,
                                color: Color(0xFFF3F1EE),
                              ),
                              itemBuilder: (context, i) {
                                final estab = filtered[i];
                                return EstabListItem(
                                  estab: estab,
                                  onTap: () => setState(
                                    () => _estabSelecionadoId = estab.id,
                                  ),
                                );
                              },
                            ),
                ),
              ),
            ),
            const SizedBox(height: 22),
          ],
        ),

        // ── Modal de detalhes ───────────────────────────────
        if (estabSelecionado != null)
          GestureDetector(
            onTap: () => setState(() => _estabSelecionadoId = null),
            child: Container(
              color: Colors.black.withValues(alpha: 0.48),
              child: EstabDetalhesModal(
                estab: estabSelecionado,
                isSubmitting: state.isSubmitting,
                onClose: () => setState(() => _estabSelecionadoId = null),
                onAcao: (acao, estabId, motivo) async {
                  await controller.executarAcao(acao, estabId, motivo: motivo);
                  // Fecha o modal só se não houve erro
                  if (ref.read(estabsAdmControllerProvider).errorMessage == null) {
                    setState(() => _estabSelecionadoId = null);
                  }
                },
              ),
            ),
          ),
      ],
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
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      height: 12,
                      width: 160,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Container(
                      height: 10,
                      width: 220,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                height: 24,
                width: 72,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
              ),
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
          const Icon(
            Icons.store_outlined,
            size: 40,
            color: Color(0xFFD1D5DB),
          ),
          const SizedBox(height: 10),
          Text(
            'Nenhum estabelecimento encontrado',
            style: GoogleFonts.publicSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF6B7280),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Tente ajustar os filtros ou a busca.',
            style: GoogleFonts.publicSans(
              fontSize: 12,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}
