import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:padoca_express/features/estabelecimento/dashboard/components/dashboard_topbar.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_controller.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/componentes_dash/sidebar_menu.dart';

import 'cupons_controller.dart';
import 'componentes_cupons/cupom_card.dart';
import 'componentes_cupons/cupom_form_modal.dart';
import 'componentes_cupons/cupom_delete_modal.dart';
import 'models/cupom_model.dart';

class CuponsScreen extends ConsumerWidget {
  const CuponsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(cuponsControllerProvider);
    // unused theme removed
    final isDesktop = MediaQuery.of(context).size.width >= 1100;
    final isTablet = MediaQuery.of(context).size.width >= 768 &&
        MediaQuery.of(context).size.width < 1100;
    final isMobile = MediaQuery.of(context).size.width < 768;
    final dashState = ref.watch(dashboardControllerProvider);
    final isLojaAberta = dashState.isLojaAberta;
    final estabelecimentoNome =
        dashState.estabelecimentoNome ?? 'Estabelecimento';

    // Formatador de Data Base igual no Dashboard Principal
    final dateText = 'Hoje';

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      drawer: !isDesktop
          ? SidebarMenu(activeId: 'coupons', onItemSelected: (_) {})
          : null, // Sidebar em modo Drawer no mobile
      body: Row(
        children: [
          if (isDesktop)
            SidebarMenu(
                activeId: 'coupons',
                onItemSelected: (_) {}), // Fixo na esquerda no Desktop

          Expanded(
            child: Column(
              children: [
                // Header (Usando DashboardTopbar compartilhado para consistência de MenuHambúrguer, Notificações etc)
                DashboardTopbar(
                  estabelecimentoNome: estabelecimentoNome,
                  isLojaAberta: isLojaAberta,
                  dateText: dateText,
                ),

                // Content
                Expanded(
                  child: state.isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : RefreshIndicator(
                          onRefresh: () => ref
                              .read(cuponsControllerProvider.notifier)
                              .carregarCupons(),
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(24),
                            physics: const AlwaysScrollableScrollPhysics(),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _buildResumoBanner(context, state),
                                const SizedBox(height: 32),
                                _buildFilterBar(context, ref, state, isMobile),
                                const SizedBox(height: 24),
                                if (state.filtrados.isEmpty)
                                  _buildEmptyState(context,
                                      isPesquisa:
                                          state.searchQuery.isNotEmpty ||
                                              state.statusFilter != 'todos')
                                else
                                  _buildCuponsGrid(context, ref,
                                      state.filtrados, isDesktop, isTablet),
                              ],
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoBanner(BuildContext context, CuponsState state) {
    int totalAtivos = 0;
    int totalExpirados = 0;
    int totalEsgotados = 0;
    int totalUsos = 0;

    final now = DateTime.now();

    for (final c in state.cupons) {
      totalUsos += c.usosAtuais;

      bool isExpirado = c.dataFim != null && c.dataFim!.isBefore(now);
      bool isEsgotado = c.limiteUsos != null && c.usosAtuais >= c.limiteUsos!;

      if (!c.ativo || isExpirado || isEsgotado) {
        if (isExpirado) totalExpirados++;
        if (isEsgotado) totalEsgotados++;
      } else {
        totalAtivos++;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header Text & Action Button
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Cupons e Ofertas',
                    style: GoogleFonts.publicSans(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Crie e gerencie descontos para atrair e fidelizar clientes',
                    style: GoogleFonts.publicSans(
                      fontSize: 15,
                      color: const Color(0xFF6B7280),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF97316),
                foregroundColor: Colors.white,
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              icon: const Icon(Icons.add, size: 20),
              label: Text('Criar Cupom',
                  style: GoogleFonts.publicSans(
                      fontWeight: FontWeight.bold, fontSize: 14)),
              onPressed: () {
                showDialog(
                  context: context,
                  builder: (ctx) => const FormCupomModal(),
                );
              },
            ),
          ],
        ),
        const SizedBox(height: 32),
        // Metrics Grid
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobileLayout = constraints.maxWidth < 650;
            return Wrap(
              spacing: 20,
              runSpacing: 20,
              children: [
                _buildNovoKpiCard(
                  constraints,
                  isMobileLayout,
                  label: 'Usos de Cupons',
                  value: totalUsos.toString(),
                  sub: '$totalUsos nesta semana',
                  icon: Icons.people_outline,
                  color: const Color(0xFF8B5CF6),
                  bgColor: const Color(0xFFF5F3FF),
                ),
                _buildNovoKpiCard(
                  constraints,
                  isMobileLayout,
                  label: 'Cupons Ativos',
                  value: totalAtivos.toString(),
                  sub: 'Rodando agora',
                  icon: Icons.local_offer_outlined,
                  color: const Color(0xFF10B981),
                  bgColor: const Color(0xFFECFDF5),
                ),
                _buildNovoKpiCard(
                  constraints,
                  isMobileLayout,
                  label: 'Expirados/Esgot.',
                  value: (totalExpirados + totalEsgotados).toString(),
                  sub: 'Encerrados',
                  icon: Icons.timer_off_outlined,
                  color: const Color(0xFFEF4444),
                  bgColor: const Color(0xFFFEF2F2),
                ),
              ],
            );
          },
        ),
      ],
    );
  }

  Widget _buildNovoKpiCard(
    BoxConstraints constraints,
    bool isMobile, {
    required String label,
    required String value,
    required String sub,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    final cardWidth =
        isMobile ? constraints.maxWidth : (constraints.maxWidth - 40) / 3;

    return Container(
      width: cardWidth,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF3F4F6)),
        boxShadow: const [
          BoxShadow(
            color: Color.fromRGBO(0, 0, 0, 0.02),
            blurRadius: 10,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label.toUpperCase(),
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: GoogleFonts.publicSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF111827),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  sub,
                  style: GoogleFonts.publicSans(
                    fontSize: 13,
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

  Widget _buildFilterBar(
      BuildContext context, WidgetRef ref, CuponsState state, bool isMobile) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          // Search Box
          SizedBox(
            width: isMobile ? 180 : 300,
            child: TextField(
              onChanged: (val) =>
                  ref.read(cuponsControllerProvider.notifier).setPesquisa(val),
              decoration: InputDecoration(
                hintText: 'Buscar código...',
                hintStyle: GoogleFonts.publicSans(fontSize: 14),
                prefixIcon: const Icon(Icons.search, size: 20),
                filled: true,
                fillColor: Colors.white,
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 0),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(30),
                  borderSide: BorderSide(color: Colors.grey.shade300),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),

          // Status Filter
          _buildFilterChip(context,
              label: 'Todos',
              isSelected: state.statusFilter == 'todos',
              onSelected: (_) => ref
                  .read(cuponsControllerProvider.notifier)
                  .setFiltroStatus('todos')),
          const SizedBox(width: 8),
          _buildFilterChip(context,
              label: 'Ativos',
              isSelected: state.statusFilter == 'ativo',
              onSelected: (_) => ref
                  .read(cuponsControllerProvider.notifier)
                  .setFiltroStatus('ativo')),
          const SizedBox(width: 8),
          _buildFilterChip(context,
              label: 'Expirados/Inativos',
              isSelected: state.statusFilter == 'expirado' ||
                  state.statusFilter == 'inativo',
              onSelected: (_) => ref
                  .read(cuponsControllerProvider.notifier)
                  .setFiltroStatus('inativo') // simplificado ou inativo
              ),
        ],
      ),
    );
  }

  Widget _buildFilterChip(BuildContext context,
      {required String label,
      required bool isSelected,
      required Function(bool) onSelected}) {
    return ChoiceChip(
      label: Text(label,
          style: GoogleFonts.publicSans(
              color: isSelected ? Colors.white : Colors.grey.shade800,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal)),
      selected: isSelected,
      onSelected: onSelected,
      selectedColor: Theme.of(context).primaryColor,
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
              color: isSelected
                  ? Theme.of(context).primaryColor
                  : Colors.grey.shade300)),
    );
  }

  Widget _buildEmptyState(BuildContext context, {required bool isPesquisa}) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 60),
        child: Column(
          children: [
            Icon(Icons.discount_outlined,
                size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              isPesquisa
                  ? 'Nenhum cupom encontrado para o filtro atual.'
                  : 'Você ainda não possui cupons criados.',
              style: GoogleFonts.publicSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.grey.shade800,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isPesquisa
                  ? 'Tente limpar a barra de pesquisa ou mudar as abas.'
                  : 'Crie um cupom atrativo para aumentar as vendas do seu estabelecimento.',
              style: GoogleFonts.publicSans(
                fontSize: 14,
                color: Colors.grey.shade600,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCuponsGrid(BuildContext context, WidgetRef ref,
      List<CupomModel> cupons, bool isDesktop, bool isTablet) {
    int crossAxisCount = 1;
    if (isDesktop) {
      crossAxisCount = 3; // 3 columns on large screens
    } else if (isTablet) {
      crossAxisCount = 2; // 2 columns on tablets
    }

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        crossAxisSpacing: 24,
        mainAxisSpacing: 24,
        childAspectRatio: isDesktop
            ? 1.6
            : (isTablet ? 1.5 : 1.4), // Ajustando ratio para não cortar textos
      ),
      itemCount: cupons.length,
      itemBuilder: (context, index) {
        final cupom = cupons[index];
        return CupomCard(
          cupom: cupom,
          onEdit: () {
            showDialog(
              context: context,
              builder: (ctx) => FormCupomModal(cupomExistente: cupom),
            );
          },
          onDelete: () {
            showDialog(
              context: context,
              builder: (ctx) => CupomDeleteModal(cupom: cupom),
            );
          },
          onToggleStatus: (val) async {
            final sucess = await ref
                .read(cuponsControllerProvider.notifier)
                .alternarStatus(cupom);
            if (sucess && context.mounted) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(val ? 'Cupom Ativado' : 'Cupom Pausado')),
              );
            }
          },
        );
      },
    );
  }
}
