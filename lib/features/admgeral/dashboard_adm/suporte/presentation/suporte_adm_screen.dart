import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/suporte_adm_controller.dart';
import 'widgets/suporte_kpi_strip.dart';
import 'widgets/suporte_tab_bar.dart';
import 'widgets/suporte_chamados_tab.dart';
import 'widgets/suporte_notificacoes_tab.dart';
import 'widgets/suporte_avaliacoes_tab.dart';

// ── Tela Suporte ──────────────────────────────────────────────────────────────

class SuporteAdmScreen extends ConsumerWidget {
  const SuporteAdmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // SnackBar para erros
    ref.listen(
      suporteAdmControllerProvider.select((s) => s.errorMessage),
      (_, next) {
        if (next != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(next, style: GoogleFonts.dmSans(fontSize: 13)),
              backgroundColor: const Color(0xFFEF4444),
              action: SnackBarAction(
                label: 'Tentar novamente',
                textColor: Colors.white,
                onPressed: () =>
                    ref.read(suporteAdmControllerProvider.notifier).fetch(),
              ),
            ),
          );
        }
      },
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // ── Header ──────────────────────────────────────────────────────
          const _SuporteHeader(),
          const SizedBox(height: 20),

          // ── KPI Strip ───────────────────────────────────────────────────
          const SuporteKpiStrip(),
          const SizedBox(height: 16),

          // ── Tab Bar + Conteúdo ───────────────────────────────────────────
          const _SuporteTabContent(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _SuporteHeader extends ConsumerWidget {
  const _SuporteHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSync = ref.watch(
      suporteAdmControllerProvider.select((s) => s.lastSync),
    );
    final isLoading = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isLoading),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Text(
                'Suporte',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A0910),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '·',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Chamados, notificações e avaliações',
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFFF97316),
                  ),
                ),
              ),
            ],
          ),
        ),
        Row(
          children: [
            if (lastSync != null)
              Text(
                'Atualizado às ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}',
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            const SizedBox(width: 8),
            Tooltip(
              message: 'Atualizar',
              child: InkWell(
                onTap: isLoading
                    ? null
                    : () => ref
                        .read(suporteAdmControllerProvider.notifier)
                        .fetch(),
                borderRadius: BorderRadius.circular(8),
                child: Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEAE8E4)),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Color(0xFF9CA3AF),
                          ),
                        )
                      : const Icon(
                          Icons.refresh_rounded,
                          size: 14,
                          color: Color(0xFF6B7280),
                        ),
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Tab Bar + Conteúdo ────────────────────────────────────────────────────────

class _SuporteTabContent extends ConsumerWidget {
  const _SuporteTabContent();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(suporteAdmControllerProvider);
    final notifier = ref.read(suporteAdmControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        SuporteTabBar(
          abaAtiva: state.abaAtiva,
          onAbaChanged: notifier.setAba,
          chamadosAbertos: state.chamadosAbertos,
          notifsErro: state.notifsErro,
          avalNegativas: state.avalNegativas,
        ),
        const SizedBox(height: 16),
        _buildTabContent(state.abaAtiva),
      ],
    );
  }

  Widget _buildTabContent(String aba) {
    return switch (aba) {
      'notificacoes' => const SuporteNotificacoesTab(),
      'avaliacoes'   => const SuporteAvaliacoesTab(),
      _              => const SuporteChamadosTab(),
    };
  }
}
