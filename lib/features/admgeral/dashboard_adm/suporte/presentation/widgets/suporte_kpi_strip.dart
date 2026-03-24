import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/suporte_adm_controller.dart';

// ── KPI Strip ─────────────────────────────────────────────────────────────────

class SuporteKpiStrip extends ConsumerWidget {
  const SuporteKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isLoading),
    );

    if (isLoading) return const _KpiStripShimmer();

    final state = ref.watch(suporteAdmControllerProvider);

    final cards = [
      _KpiData(
        label: 'Total Chamados',
        value: state.totalChamados.toString(),
        icon: Icons.support_agent_outlined,
        color: const Color(0xFF6B7280),
        bg: const Color(0xFFF9FAFB),
      ),
      _KpiData(
        label: 'Abertos',
        value: state.chamadosAbertos.toString(),
        icon: Icons.mark_email_unread_outlined,
        color: const Color(0xFFEF4444),
        bg: const Color(0xFFFEF2F2),
      ),
      _KpiData(
        label: 'Em Atendimento',
        value: state.chamadosEmAtendimento.toString(),
        icon: Icons.headset_mic_outlined,
        color: const Color(0xFFF59E0B),
        bg: const Color(0xFFFFFBEB),
      ),
      _KpiData(
        label: 'Urgentes',
        value: state.chamadosUrgentes.toString(),
        icon: Icons.warning_amber_rounded,
        color: const Color(0xFFDC2626),
        bg: const Color(0xFFFEF2F2),
      ),
      _KpiData(
        label: 'Notifs. c/ Erro',
        value: state.notifsErro.toString(),
        icon: Icons.notifications_off_outlined,
        color: const Color(0xFF8B5CF6),
        bg: const Color(0xFFF5F3FF),
      ),
      _KpiData(
        label: 'Aval. Negativas',
        value: state.avalNegativas.toString(),
        icon: Icons.star_half_outlined,
        color: const Color(0xFFF97316),
        bg: const Color(0xFFFFF7ED),
      ),
    ];

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: cards.map((d) => _KpiCard(data: d)).toList(),
    );
  }
}

// ── Card individual ───────────────────────────────────────────────────────────

class _KpiData {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final Color bg;

  const _KpiData({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.bg,
  });
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  const _KpiCard({required this.data});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 170,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: data.bg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(data.icon, size: 18, color: data.color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  data.value,
                  style: GoogleFonts.dmSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A0910),
                    height: 1,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  data.label,
                  style: GoogleFonts.dmSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Shimmer ───────────────────────────────────────────────────────────────────

class _KpiStripShimmer extends StatelessWidget {
  const _KpiStripShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: List.generate(
          6,
          (_) => Container(
            width: 170,
            height: 62,
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
