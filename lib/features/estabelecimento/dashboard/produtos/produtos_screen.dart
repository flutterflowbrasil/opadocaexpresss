import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../shared/widgets/responsive_layout.dart';
import '../dashboard_controller.dart';
import '../componentes_dash/sidebar_menu.dart';
import '../componentes_dash/mobile_bottom_nav.dart';
import 'controllers/produtos_controller.dart';
import 'components/produtos_header.dart';
import 'components/produtos_filters.dart';
import 'components/produtos_stats_bar.dart';
import 'components/produtos_grid_view.dart';
import 'components/produtos_list_view.dart';

/// Provider derivado para expor apenas o estabelecimentoId de forma eficiente
final _estabelecimentoIdProvider = Provider<String?>((ref) {
  return ref
      .watch(dashboardControllerProvider.select((s) => s.estabelecimentoId));
});

class ProdutosScreen extends ConsumerStatefulWidget {
  const ProdutosScreen({super.key});

  @override
  ConsumerState<ProdutosScreen> createState() => _ProdutosScreenState();
}

class _ProdutosScreenState extends ConsumerState<ProdutosScreen> {
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    // Dispara o carregamento inicial após o primeiro frame,
    // pois o dashboardController pode ainda estar inicializando.
    WidgetsBinding.instance.addPostFrameCallback((_) => _tryLoad());
  }

  void _tryLoad() {
    final estabId = ref.read(_estabelecimentoIdProvider);
    if (estabId != null && !_loaded) {
      _loaded = true;
      ref.read(produtosControllerProvider.notifier).loadDados(estabId);
    }
  }

  @override
  Widget build(BuildContext context) {
    // Observa o ID para reagir quando o dashboard terminar de carregar
    ref.listen(_estabelecimentoIdProvider, (previous, next) {
      if (next != null && !_loaded) _tryLoad();
    });

    final isLoading =
        ref.watch(produtosControllerProvider.select((s) => s.isLoading));
    final error = ref.watch(produtosControllerProvider.select((s) => s.error));
    final estabId = ref.watch(_estabelecimentoIdProvider);

    return ResponsiveLayout(
      mobile: (ctx) => _buildContent(ctx,
          isMobile: true, isLoading: isLoading, error: error, estabId: estabId),
      desktop: (ctx) => _buildContent(ctx,
          isMobile: false,
          isLoading: isLoading,
          error: error,
          estabId: estabId),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isMobile,
    required bool isLoading,
    String? error,
    String? estabId,
  }) {
    final isWideScreen = MediaQuery.of(context).size.width >= 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F6F6),
      drawer: isWideScreen
          ? null
          : Drawer(
              child: SidebarMenu(
                activeId: 'products',
                onItemSelected: (id) {
                  if (id != 'products') Navigator.pop(context);
                },
              ),
            ),
      appBar: isMobile
          ? AppBar(
              title: Text('Produtos',
                  style: GoogleFonts.publicSans(fontWeight: FontWeight.bold)),
              backgroundColor: Colors.white,
              foregroundColor: Colors.black87,
              elevation: 0,
            )
          : null,
      bottomNavigationBar: isMobile ? const MobileBottomNav() : null,
      body: Row(
        children: [
          if (isWideScreen)
            SidebarMenu(
              activeId: 'products',
              onItemSelected: (_) {},
            ),
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : error != null
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.error_outline,
                                color: Colors.red, size: 48),
                            const SizedBox(height: 16),
                            Text(error, textAlign: TextAlign.center),
                            const SizedBox(height: 16),
                            ElevatedButton(
                              onPressed: () {
                                if (estabId != null) {
                                  ref
                                      .read(produtosControllerProvider.notifier)
                                      .loadDados(estabId);
                                }
                              },
                              child: const Text('Tentar Novamente'),
                            ),
                          ],
                        ),
                      )
                    : CustomScrollView(
                        slivers: [
                          const SliverToBoxAdapter(child: ProdutosHeader()),
                          SliverPersistentHeader(
                            pinned: true,
                            delegate: _StickyFiltersDelegate(
                                child: const ProdutosFilters()),
                          ),
                          const SliverToBoxAdapter(
                            child: Padding(
                              padding: EdgeInsets.fromLTRB(24, 16, 24, 12),
                              child: ProdutosStatsBar(),
                            ),
                          ),
                          const _ProdutosContentArea(),
                        ],
                      ),
          ),
        ],
      ),
    );
  }
}

class _ProdutosContentArea extends ConsumerWidget {
  const _ProdutosContentArea();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final mode =
        ref.watch(produtosControllerProvider.select((s) => s.filterMode));
    final produtosFiltrados = ref
        .watch(produtosControllerProvider.select((s) => s.produtosFiltrados));

    if (produtosFiltrados.isEmpty) {
      return SliverFillRemaining(
        hasScrollBody: false,
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.restaurant_menu,
                  size: 60, color: Colors.grey.shade300),
              const SizedBox(height: 16),
              Text(
                'Nenhum produto encontrado',
                style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey.shade600),
              ),
              const SizedBox(height: 8),
              Text(
                'Tente ajustar os filtros ou adicione um novo produto',
                style: GoogleFonts.publicSans(color: Colors.grey.shade500),
              ),
            ],
          ),
        ),
      );
    }

    return SliverToBoxAdapter(
      child: Padding(
        padding: const EdgeInsets.only(left: 24, right: 24, bottom: 90),
        child: mode == 'grid'
            ? ProdutosGridView(produtos: produtosFiltrados)
            : ProdutosListView(produtos: produtosFiltrados),
      ),
    );
  }
}

class _StickyFiltersDelegate extends SliverPersistentHeaderDelegate {
  final Widget child;

  _StickyFiltersDelegate({required this.child});

  @override
  double get minExtent => 152;
  @override
  double get maxExtent => 152;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return ClipRect(
      child: Container(
        color: const Color(0xFFF8F6F6),
        child: child,
      ),
    );
  }

  @override
  bool shouldRebuild(covariant SliverPersistentHeaderDelegate oldDelegate) =>
      true;
}
