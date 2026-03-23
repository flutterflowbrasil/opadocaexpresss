import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/entregadores_adm_controller.dart';

class EntregadoresKpiStrip extends ConsumerWidget {
  const EntregadoresKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = ref.watch(entregadoresAdmControllerProvider);

    final kpis = [
      _KpiData('Total', s.totalCount.toString(), const Color(0xFF1A0910), Icons.people_outline),
      _KpiData('Pendentes', s.pendentesCount.toString(), const Color(0xFFF59E0B), Icons.hourglass_empty),
      _KpiData('Aprovados', s.aprovadosCount.toString(), const Color(0xFF10B981), Icons.check_circle_outline),
      _KpiData('Suspensos', s.suspensosCount.toString(), const Color(0xFFEF4444), Icons.block),
      _KpiData('Rejeitados', s.rejeitadosCount.toString(), const Color(0xFF6B7280), Icons.cancel_outlined),
      _KpiData('Online agora', s.onlineCount.toString(), const Color(0xFF3B82F6), Icons.circle, dot: true),
      _KpiData('Selfies ✋', s.selfiePendenteCount.toString(), const Color(0xFF8B5CF6), Icons.face_retouching_natural),
    ];

    return SizedBox(
      height: 72,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 22),
        itemCount: kpis.length,
        separatorBuilder: (_, __) => const SizedBox(width: 10),
        itemBuilder: (context, i) => _KpiCard(data: kpis[i], isLoading: s.isLoading),
      ),
    );
  }
}

class _KpiData {
  final String label;
  final String value;
  final Color color;
  final IconData icon;
  final bool dot;
  const _KpiData(this.label, this.value, this.color, this.icon, {this.dot = false});
}

class _KpiCard extends StatelessWidget {
  final _KpiData data;
  final bool isLoading;

  const _KpiCard({required this.data, required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 112,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: isLoading
          ? _shimmer()
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Icon(data.icon, size: 13, color: data.color),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        data.label,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                  ],
                ),
                Text(
                  data.value,
                  style: GoogleFonts.dmSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: data.color,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _shimmer() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        Container(height: 10, width: 64, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(4))),
        Container(height: 22, width: 40, decoration: BoxDecoration(color: const Color(0xFFE5E7EB), borderRadius: BorderRadius.circular(4))),
      ],
    );
  }
}
