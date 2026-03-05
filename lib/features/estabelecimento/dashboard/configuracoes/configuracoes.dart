import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../componentes_dash/dashboard_colors.dart';
import '../componentes_dash/sidebar_menu.dart';
import '../componentes_dash/mobile_bottom_nav.dart';
import 'controllers/configuracoes_controller.dart';
import 'controllers/configuracoes_state.dart';
import 'componentes_config/visual_tab.dart';
import 'componentes_config/info_tab.dart';
import 'componentes_config/endereco_tab.dart';
import 'componentes_config/entrega_tab.dart';
import 'componentes_config/bancarios_tab.dart';
import 'componentes_config/horarios_tab.dart';
import 'componentes_config/avancado_tab.dart';
import 'componentes_config/responsavel_tab.dart';

class ConfiguracoesScreen extends ConsumerStatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  ConsumerState<ConfiguracoesScreen> createState() =>
      _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends ConsumerState<ConfiguracoesScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 8, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(configuracoesControllerProvider);
    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final brightness = Theme.of(context).brightness;
    final isDark = brightness == Brightness.dark;

    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    Widget bodyContent = state.isLoading
        ? const Center(child: CircularProgressIndicator())
        : state.error != null
            ? _buildErrorState(state.error!)
            : Column(
                children: [
                  _buildHeader(isDark, state, notifier),
                  _buildTabBar(isDark),
                  Expanded(
                    child: TabBarView(
                      controller: _tabController,
                      children: [
                        VisualTab(isDark: isDark),
                        InfoTab(isDark: isDark),
                        EnderecoTab(isDark: isDark),
                        HorariosTab(isDark: isDark),
                        EntregaTab(isDark: isDark),
                        AvancadoTab(isDark: isDark),
                        ResponsavelTab(isDark: isDark),
                        BancariosTab(isDark: isDark),
                      ],
                    ),
                  ),
                ],
              );

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0F0F0F) : Colors.grey[50],
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                activeId: 'settings',
                onItemSelected: (id) {
                  if (id != 'settings') Navigator.pop(context);
                },
              ),
            ),
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              activeId: 'settings',
              onItemSelected: (_) {},
            ),
          Expanded(child: bodyContent),
        ],
      ),
      bottomNavigationBar: isWideScreen ? null : const MobileBottomNav(),
    );
  }

  Widget _buildHeader(
      bool isDark, ConfiguracoesState state, ConfiguracoesController notifier) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: Row(
        children: [
          const Icon(Icons.settings, size: 32, color: DashboardColors.primary),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Configurações',
                  style: GoogleFonts.publicSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                if (state.hasChanges)
                  const Text(
                    'Você tem alterações não salvas',
                    style: TextStyle(
                        color: Colors.orange,
                        fontSize: 12,
                        fontWeight: FontWeight.bold),
                  )
                else
                  Text(
                    'Gerencie os dados e o funcionamento da sua loja.',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      color: Colors.grey[500],
                    ),
                  ),
              ],
            ),
          ),
          if (state.hasChanges) ...[
            TextButton(
              onPressed:
                  state.isSaving ? null : () => notifier.descartarAlteracoes(),
              child: const Text('Descartar'),
            ),
            const SizedBox(width: 12),
          ],
          ElevatedButton.icon(
            onPressed: (state.hasChanges && !state.isSaving)
                ? () async {
                    final success = await notifier.salvarAlteracoes();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success
                              ? 'Configurações salvas com sucesso!'
                              : 'Erro ao salvar: ${state.error ?? "Tente novamente"}'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  }
                : null,
            icon: state.isSaving
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(
                        strokeWidth: 2, color: Colors.white),
                  )
                : const Icon(Icons.save),
            label: const Text('Salvar Alterações'),
            style: ElevatedButton.styleFrom(
              backgroundColor: DashboardColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              disabledBackgroundColor:
                  isDark ? Colors.grey[800] : Colors.grey[200],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabBar(bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        border: Border(
            bottom: BorderSide(
                color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
      ),
      child: TabBar(
        controller: _tabController,
        isScrollable: true,
        tabAlignment: TabAlignment.start,
        labelColor: DashboardColors.primary,
        unselectedLabelColor: Colors.grey[500],
        indicatorColor: DashboardColors.primary,
        indicatorPadding: const EdgeInsets.symmetric(horizontal: 16),
        labelStyle: const TextStyle(fontWeight: FontWeight.bold),
        tabs: const [
          Tab(text: 'Visual'),
          Tab(text: 'Informações'),
          Tab(text: 'Endereço'),
          Tab(text: 'Horários'),
          Tab(text: 'Entrega'),
          Tab(text: 'Avançado'),
          Tab(text: 'Responsável'),
          Tab(text: 'Bancário'),
        ],
      ),
    );
  }

  Widget _buildErrorState(String message) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.error_outline, size: 64, color: Colors.red),
          const SizedBox(height: 16),
          const Text('Ocorreu um erro ao carregar os dados:',
              style: TextStyle(color: Colors.grey)),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(message,
                textAlign: TextAlign.center,
                style: const TextStyle(
                    fontWeight: FontWeight.bold, color: Colors.red)),
          ),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => ref
                .read(configuracoesControllerProvider.notifier)
                .carregarDados(),
            child: const Text('Tentar Novamente'),
          ),
        ],
      ),
    );
  }
}
