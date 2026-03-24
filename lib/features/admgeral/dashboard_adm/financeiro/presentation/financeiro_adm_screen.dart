import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/financeiro_adm_controller.dart';
import 'widgets/financeiro_kpi_strip.dart';
import 'widgets/financeiro_tab_bar.dart';
import 'widgets/financeiro_visao_geral.dart';
import 'widgets/financeiro_pedidos_tab.dart';
import 'widgets/financeiro_splits_tab.dart';
import 'widgets/financeiro_saques_tab.dart';
import 'widgets/financeiro_subcontas_tab.dart';

class FinanceiroAdmScreen extends ConsumerWidget {
  const FinanceiroAdmScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Exibe SnackBar para erros transitórios
    ref.listen(
      financeiroAdmControllerProvider.select((s) => s.errorMessage),
      (_, next) {
        if (next != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                next,
                style: GoogleFonts.dmSans(fontSize: 13),
              ),
              backgroundColor: const Color(0xFFEF4444),
              action: SnackBarAction(
                label: 'Tentar novamente',
                textColor: Colors.white,
                onPressed: () =>
                    ref.read(financeiroAdmControllerProvider.notifier).fetch(),
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
          // ── Header ──────────────────────────────────────────────────────────
          _FinanceiroHeader(),
          const SizedBox(height: 20),

          // ── KPI Strip ───────────────────────────────────────────────────────
          const FinanceiroKpiStrip(),
          const SizedBox(height: 16),

          // ── Tab Bar + Conteúdo ───────────────────────────────────────────────
          _FinanceiroTabContent(),
          const SizedBox(height: 30),
        ],
      ),
    );
  }
}

// ── Header ────────────────────────────────────────────────────────────────────

class _FinanceiroHeader extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSync = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.lastSync),
    );
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Flexible(
          child: Row(
            children: [
              Text(
                'Financeiro',
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF1A0910),
                ),
              ),
              const SizedBox(width: 10),
              Text('·',
                  style: GoogleFonts.dmSans(
                    fontSize: 14,
                    color: const Color(0xFF9CA3AF),
                  )),
              const SizedBox(width: 10),
              Flexible(
                child: Text(
                  'Receitas, splits e saques',
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
                        .read(financeiroAdmControllerProvider.notifier)
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

class _FinanceiroTabContent extends ConsumerWidget {
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abaAtiva = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.abaAtiva),
    );
    final notifier = ref.read(financeiroAdmControllerProvider.notifier);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        FinanceiroTabBar(
          abaAtiva: abaAtiva,
          onAbaChanged: notifier.setAba,
        ),
        const SizedBox(height: 16),
        _buildTabContent(abaAtiva),
      ],
    );
  }

  Widget _buildTabContent(String aba) {
    return switch (aba) {
      'pedidos'    => const FinanceiroPedidosTab(),
      'splits'     => const FinanceiroSplitsTab(),
      'saques'     => const FinanceiroSaquesTab(),
      'subcontas'  => const FinanceiroSubcontasTab(),
      _            => const FinanceiroVisaoGeral(),
    };
  }
}
