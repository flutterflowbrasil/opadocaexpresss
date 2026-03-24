import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';

class FinanceiroKpiStrip extends ConsumerWidget {
  const FinanceiroKpiStrip({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );

    if (isLoading) return const _KpiStripShimmer();

    final totalBruto = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.totalBruto),
    );
    final receitaPlataforma = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.receitaPlataforma),
    );
    final splitsPendentes = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.splitsPendentes),
    );
    final totalSaques = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.totalSaquesConcluidos),
    );

    return Wrap(
      spacing: 12,
      runSpacing: 12,
      children: [
        _KpiCard(
          label: 'Total Bruto',
          value: _fmtBrl(totalBruto),
          icon: Icons.monetization_on_outlined,
          iconColor: const Color(0xFFF97316),
          iconBg: const Color(0xFFFFF7ED),
        ),
        _KpiCard(
          label: 'Receita Plataforma',
          value: _fmtBrl(receitaPlataforma),
          icon: Icons.account_balance_outlined,
          iconColor: const Color(0xFF10B981),
          iconBg: const Color(0xFFECFDF5),
        ),
        _KpiCard(
          label: 'Splits Pendentes',
          value: splitsPendentes.toString(),
          icon: Icons.call_split_rounded,
          iconColor: const Color(0xFFF59E0B),
          iconBg: const Color(0xFFFFFBEB),
        ),
        _KpiCard(
          label: 'Saques Concluídos',
          value: _fmtBrl(totalSaques),
          icon: Icons.pix_outlined,
          iconColor: const Color(0xFF3B82F6),
          iconBg: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color iconColor;
  final Color iconBg;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.iconColor,
    required this.iconBg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
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
              color: iconBg,
              borderRadius: BorderRadius.circular(9),
            ),
            child: Icon(icon, color: iconColor, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.dmSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
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

class _KpiStripShimmer extends StatelessWidget {
  const _KpiStripShimmer();

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
            width: 200,
            height: 68,
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

String _fmtBrl(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+,)'), (m) => '${m[1]}.')}';
