import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';

import '../controllers/admin_dashboard_controller.dart';

class PendingApprovalsSection extends ConsumerWidget {
  final void Function(String screen, {String? itemId}) onNavigate;

  const PendingApprovalsSection({super.key, required this.onNavigate});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminDashboardControllerProvider);

    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 800;

        if (state.isLoading) {
          return _buildLoading();
        }

        if (isMobile) {
          return Column(
            children: [
              _buildEstabelecimentosList(state.estabPendentes),
              const SizedBox(height: 16),
              _buildEntregadoresList(state.entregPendentes),
            ],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: _buildEstabelecimentosList(state.estabPendentes)),
            const SizedBox(width: 16),
            Expanded(child: _buildEntregadoresList(state.entregPendentes)),
          ],
        );
      },
    );
  }

  Widget _buildEstabelecimentosList(List<Map<String, dynamic>> items) {
    return _BaseListCard(
      title: 'Estabelecimentos Pendentes',
      icon: Icons.storefront,
      iconColor: const Color(0xFFF97316),
      iconBgColor: const Color(0xFFFFF7ED),
      count: items.length,
      emptyMessage: 'Nenhum estabelecimento pendente.',
      onViewAll: items.length > 5
          ? () => onNavigate('estabelecimentos')
          : null,
      children: items
          .map((e) => _buildEstabelecimentoItem(e))
          .toList(),
    );
  }

  Widget _buildEntregadoresList(List<Map<String, dynamic>> items) {
    return _BaseListCard(
      title: 'Entregadores (KYC Pendente)',
      icon: Icons.two_wheeler,
      iconColor: const Color(0xFF3B82F6),
      iconBgColor: const Color(0xFFEFF6FF),
      count: items.length,
      emptyMessage: 'Nenhum entregador pendente.',
      onViewAll: items.length > 5
          ? () => onNavigate('entregadores')
          : null,
      children: items
          .map((e) => _buildEntregadorItem(e))
          .toList(),
    );
  }

  Widget _buildEstabelecimentoItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    final nome = item['nome_fantasia'] ?? item['razao_social'] ?? 'Sem Nome';
    final inicial = nome.toString().substring(0, 1).toUpperCase();

    return _ListItem(
      avatarText: inicial,
      avatarColor: const Color(0xFFF97316),
      avatarBg: const Color(0xFFFFF7ED),
      title: nome.toString(),
      subtitle: item['cnpj'] ?? 'CNPJ não informado',
      status: 'Aprovar',
      statusColor: const Color(0xFF10B981),
      statusBg: const Color(0xFFECFDF5),
      borderColor: const Color(0xFFD1FAE5),
      onTap: () => onNavigate('estabelecimentos', itemId: id),
    );
  }

  Widget _buildEntregadorItem(Map<String, dynamic> item) {
    final id = item['id']?.toString();
    final cpf = item['cpf']?.toString() ?? 'CPF não informado';
    final nome = item['nome'] ?? item['razao_social'] ?? 'Entregador Pendente';
    final inicial = cpf.substring(0, 1).toUpperCase();

    return _ListItem(
      avatarText: inicial,
      avatarColor: const Color(0xFF3B82F6),
      avatarBg: const Color(0xFFEFF6FF),
      title: nome.toString(),
      subtitle: cpf,
      status: 'Analisar KYC',
      statusColor: const Color(0xFFF59E0B),
      statusBg: const Color(0xFFFFFBEB),
      borderColor: const Color(0xFFFEF3C7),
      onTap: () => onNavigate('entregadores', itemId: id),
    );
  }

  Widget _buildLoading() {
    return Shimmer.fromColors(
      baseColor: Colors.grey[300]!,
      highlightColor: Colors.grey[100]!,
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ── Card base da lista ──────────────────────────────────────────────────────

class _BaseListCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color iconColor, iconBgColor;
  final int count;
  final String emptyMessage;
  final List<Widget> children;
  final VoidCallback? onViewAll;

  const _BaseListCard({
    required this.title,
    required this.icon,
    required this.iconColor,
    required this.iconBgColor,
    required this.count,
    required this.emptyMessage,
    required this.children,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(20),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 20),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910),
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF4F2EF),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '$count',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAE8E4)),
          if (children.isEmpty)
            Padding(
              padding: const EdgeInsets.all(30),
              child: Center(
                child: Text(
                  emptyMessage,
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: children.length > 5 ? 5 : children.length,
              separatorBuilder: (context, index) => const Divider(
                height: 1,
                color: Color(0xFFF4F2EF),
                indent: 20,
                endIndent: 20,
              ),
              itemBuilder: (context, index) => children[index],
            ),
          if (onViewAll != null)
            Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: onViewAll,
                child: Center(
                  child: Text(
                    'Ver todos ($count)',
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFF97316),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Item da lista ─────────────────────────────────────────────────────────────

class _ListItem extends StatelessWidget {
  final String avatarText, title, subtitle, status;
  final Color avatarColor, avatarBg, statusColor, statusBg, borderColor;
  final VoidCallback? onTap;

  const _ListItem({
    required this.avatarText,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.avatarColor,
    required this.avatarBg,
    required this.statusColor,
    required this.statusBg,
    required this.borderColor,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(4),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: avatarBg, shape: BoxShape.circle),
              child: Center(
                child: Text(
                  avatarText,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: avatarColor,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.publicSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A0910),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: const Color(0xFF6B7280),
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 10),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: statusBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: borderColor),
              ),
              child: Text(
                status,
                style: GoogleFonts.publicSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: statusColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
