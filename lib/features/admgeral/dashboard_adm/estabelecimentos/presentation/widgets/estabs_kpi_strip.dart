import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/estabs_adm_controller.dart';

class EstabsKpiStrip extends ConsumerWidget {
  const EstabsKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(estabsAdmControllerProvider);

    final kpis = [
      _KpiItem('Total', '${state.totalCount}', const Color(0xFF6B7280), const Color(0xFFF9F8F7), Icons.store_outlined),
      _KpiItem('Aprovados', '${state.aprovadosCount}', const Color(0xFF10B981), const Color(0xFFECFDF5), Icons.check_circle_outline),
      _KpiItem('Pendentes', '${state.pendentesCount}', const Color(0xFFF59E0B), const Color(0xFFFFFBEB), Icons.access_time),
      _KpiItem('Suspensos', '${state.suspensosCount}', const Color(0xFFEF4444), const Color(0xFFFEF2F2), Icons.block_outlined),
      _KpiItem('Rejeitados', '${state.rejeitadosCount}', const Color(0xFF9CA3AF), const Color(0xFFF3F4F6), Icons.cancel_outlined),
      _KpiItem('Abertos agora', '${state.abertosCount}', const Color(0xFF3B82F6), const Color(0xFFEFF6FF), Icons.storefront),
      _KpiItem(
        'Faturamento total',
        _fmt(state.faturamentoTotal),
        const Color(0xFF10B981),
        const Color(0xFFECFDF5),
        Icons.attach_money,
      ),
    ];

    return SizedBox(
      height: 80,
      child: ScrollConfiguration(
        behavior: ScrollConfiguration.of(context).copyWith(
          dragDevices: {
            PointerDeviceKind.touch,
            PointerDeviceKind.mouse,
            PointerDeviceKind.trackpad,
          },
        ),
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: 22),
          itemCount: kpis.length,
          separatorBuilder: (_, __) => const SizedBox(width: 10),
          itemBuilder: (context, i) {
            final kpi = kpis[i];
            if (state.isLoading) {
              return Shimmer.fromColors(
                baseColor: const Color(0xFFE5E7EB),
                highlightColor: const Color(0xFFF3F4F6),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              );
            }
            return _KpiCard(kpi: kpi);
          },
        ),
      ),
    );
  }

  String _fmt(double v) {
    if (v >= 1000000) return 'R\$ ${(v / 1000000).toStringAsFixed(1)}M';
    if (v >= 1000) return 'R\$ ${(v / 1000).toStringAsFixed(1)}K';
    return 'R\$ ${v.toStringAsFixed(0)}';
  }
}

class _KpiItem {
  final String label;
  final String value;
  final Color color;
  final Color bg;
  final IconData icon;
  const _KpiItem(this.label, this.value, this.color, this.bg, this.icon);
}

class _KpiCard extends StatelessWidget {
  final _KpiItem kpi;
  const _KpiCard({required this.kpi});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 140,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: kpi.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(kpi.icon, size: 16, color: kpi.color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  kpi.value,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: kpi.color,
                  ),
                ),
                Text(
                  kpi.label,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.publicSans(
                    fontSize: 10,
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
