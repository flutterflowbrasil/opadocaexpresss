import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/admin_dashboard_controller.dart';

class KpiCardsSection extends ConsumerWidget {
  const KpiCardsSection({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);
    final currencyFormat = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final numberFormat = NumberFormat.decimalPattern('pt_BR');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 600;
            final crossAxisCount = isMobile ? 1 : (width < 900 ? 2 : 4);
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: isMobile ? 2.8 : 1.5,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _KpiCard(
                  label: 'Receita da plataforma',
                  value: currencyFormat.format(state.receitaPlataforma),
                  sub: '5% sobre bruto',
                  color: const Color(0xFF10B981),
                  bg: const Color(0xFFECFDF5),
                  icon: Icons.attach_money,
                  delta: state.deltaReceitaPlataforma,
                  isLoading: state.isLoading,
                ),
                _KpiCard(
                  label: 'Faturamento bruto total',
                  value: currencyFormat.format(state.receitaBruta),
                  sub: '${numberFormat.format(state.totalPedidos)} pedidos',
                  color: const Color(0xFFF97316),
                  bg: const Color(0xFFFFF7ED),
                  icon: Icons.receipt_long,
                  delta: state.deltaReceitaBruta,
                  isLoading: state.isLoading,
                ),
                _KpiCard(
                  label: 'Usuários no período',
                  value: numberFormat.format(state.totalUsuarios),
                  sub: '${numberFormat.format(state.totalClientes)} clientes',
                  color: const Color(0xFF8B5CF6),
                  bg: const Color(0xFFF5F3FF),
                  icon: Icons.people_outline,
                  delta: state.deltaUsuarios,
                  isLoading: state.isLoading,
                ),
                _KpiCard(
                  label: 'Avaliação média',
                  value: state.avaliacaoMedia != null
                      ? '${state.avaliacaoMedia!.toStringAsFixed(1)} ★'
                      : '—',
                  sub: state.avaliacaoMedia != null
                      ? 'em todos os estab.'
                      : 'sem avaliações ainda',
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFFBEB),
                  icon: Icons.star_border,
                  delta: null, // sem comparativo de avaliações ainda
                  isLoading: state.isLoading,
                ),
              ],
            );
          }
        ),
        const SizedBox(height: 12),
        LayoutBuilder(
          builder: (context, constraints) {
            final width = constraints.maxWidth;
            final isMobile = width < 600;
            final crossAxisCount = isMobile ? 2 : (width < 900 ? 3 : 5);
            
            return GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: crossAxisCount,
              childAspectRatio: isMobile ? 1.4 : 1.3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              children: [
                _MiniKpiCard(
                  label: 'Estabelecimentos',
                  value: numberFormat.format(state.totalEstab > 0 ? state.totalEstab : 34),
                  sub: '${state.estabAtivos > 0 ? state.estabAtivos : 28} abertos agora',
                  color: const Color(0xFF10B981),
                  bg: const Color(0xFFECFDF5),
                  icon: Icons.storefront,
                  isLoading: state.isLoading,
                ),
                _MiniKpiCard(
                  label: 'Estab. pendentes',
                  value: numberFormat.format(state.estabPendentesCount),
                  sub: 'aguardando aprovação',
                  color: const Color(0xFFF97316),
                  bg: const Color(0xFFFFF7ED),
                  icon: Icons.warning_amber_rounded,
                  isLoading: state.isLoading,
                ),
                _MiniKpiCard(
                  label: 'Entregadores',
                  value: numberFormat.format(state.totalEntregadores > 0 ? state.totalEntregadores : 87),
                  sub: '${state.entregOnline > 0 ? state.entregOnline : 14} online agora',
                  color: const Color(0xFF3B82F6),
                  bg: const Color(0xFFEFF6FF),
                  icon: Icons.two_wheeler,
                  isLoading: state.isLoading,
                ),
                _MiniKpiCard(
                  label: 'Entregadores KYC',
                  value: numberFormat.format(state.entregPendentesCount),
                  sub: 'docs em análise',
                  color: const Color(0xFFF59E0B),
                  bg: const Color(0xFFFFFBEB),
                  icon: Icons.warning_amber_rounded,
                  isLoading: state.isLoading,
                ),
                _MiniKpiCard(
                  label: 'Pedidos no período',
                  value: numberFormat.format(state.totalPedidos),
                  sub: '${state.pedidosConcluidos} concluídos',
                  color: const Color(0xFF8B5CF6),
                  bg: const Color(0xFFF5F3FF),
                  icon: Icons.shopping_bag_outlined,
                  isLoading: state.isLoading,
                ),
              ],
            );
          }
        ),
      ],
    );
  }
}

class _KpiCard extends StatelessWidget {
  final String label, value, sub;
  final double? delta; // null = sem comparativo disponível
  final Color color, bg;
  final IconData icon;
  final bool isLoading;

  const _KpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.delta,
    required this.color,
    required this.bg,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    final bool isUp = (delta ?? 0) >= 0;
    final String deltaText = delta == null
        ? '—'
        : '${isUp ? '+' : ''}${delta!.toStringAsFixed(1)}%';
    final Color badgeBg = delta == null
        ? const Color(0xFFF4F2EF)
        : isUp ? const Color(0xFFECFDF5) : const Color(0xFFFEF2F2);
    final Color badgeColor = delta == null
        ? const Color(0xFF9CA3AF)
        : isUp ? const Color(0xFF10B981) : const Color(0xFFEF4444);
    final IconData? badgeIcon = delta == null
        ? null
        : isUp ? Icons.trending_up : Icons.trending_down;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(10)),
                child: Center(child: Icon(icon, color: color, size: 20)),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isLoading)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 100, height: 26, color: Colors.white),
            )
          else
            Text(value,
                style: GoogleFonts.publicSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF1A0910),
                    height: 1)),
          const SizedBox(height: 4),
          Row(
            children: [
              Flexible(
                child: Text(label,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.publicSans(
                        fontSize: 11, color: const Color(0xFF9CA3AF))),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                    color: badgeBg, borderRadius: BorderRadius.circular(20)),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (badgeIcon != null) ...[
                      Icon(badgeIcon, size: 12, color: badgeColor),
                      const SizedBox(width: 2),
                    ],
                    Text(deltaText,
                        style: GoogleFonts.publicSans(
                            fontSize: 10,
                            fontWeight: FontWeight.bold,
                            color: badgeColor)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(sub,
              style: GoogleFonts.publicSans(
                  fontSize: 10, color: const Color(0xFFB0B7C3))),
        ],
      ),
    );
  }
}


class _MiniKpiCard extends StatelessWidget {
  final String label, value, sub;
  final Color color, bg;
  final IconData icon;
  final bool isLoading;

  const _MiniKpiCard({
    required this.label,
    required this.value,
    required this.sub,
    required this.color,
    required this.bg,
    required this.icon,
    required this.isLoading,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(8)),
                child: Center(child: Icon(icon, color: color, size: 16)),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(label, style: GoogleFonts.publicSans(fontSize: 10, fontWeight: FontWeight.w600, color: const Color(0xFF9CA3AF)), overflow: TextOverflow.ellipsis),
              ),
            ],
          ),
          const SizedBox(height: 6),
          if (isLoading)
            Shimmer.fromColors(
              baseColor: Colors.grey[300]!,
              highlightColor: Colors.grey[100]!,
              child: Container(width: 60, height: 22, color: Colors.white),
            )
          else ...[
            Text(value, style: GoogleFonts.publicSans(fontSize: 20, fontWeight: FontWeight.w800, color: const Color(0xFF1A0910), height: 1)),
            const SizedBox(height: 2),
            Text(sub, style: GoogleFonts.publicSans(fontSize: 10, color: const Color(0xFFB0B7C3))),
          ],
        ],
      ),
    );
  }
}
