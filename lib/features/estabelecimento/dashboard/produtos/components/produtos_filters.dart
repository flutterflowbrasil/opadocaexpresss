import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/produtos_controller.dart';

class ProdutosFilters extends ConsumerWidget {
  const ProdutosFilters({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Escuta categorias e modos
    final categorias =
        ref.watch(produtosControllerProvider.select((s) => s.categorias));
    final filterMode =
        ref.watch(produtosControllerProvider.select((s) => s.filterMode));
    final selectedCatId = ref
        .watch(produtosControllerProvider.select((s) => s.selectedCategoriaId));
    final hasActiveFilter = selectedCatId != null ||
        ref.watch(produtosControllerProvider.select((s) => s.searchQuery)) !=
            null ||
        ref.watch(produtosControllerProvider
                .select((s) => s.selectedStatusFilter)) !=
            null;

    final controller = ref.read(produtosControllerProvider.notifier);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // 1. Linha Superior: Search, Comboboxes e Modos de Visão
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: [
                // Input Busca (Debounce manual sugerido para uso de APIs futuramente, aqui local e rapido)
                Expanded(
                  flex: 2,
                  child: Container(
                    height: 44,
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Row(
                      children: [
                        Icon(Icons.search,
                            color: Colors.grey.shade400, size: 20),
                        const SizedBox(width: 8),
                        Expanded(
                          child: TextFormField(
                            style: GoogleFonts.publicSans(fontSize: 14),
                            decoration: InputDecoration(
                              hintText: 'Buscar produto...',
                              hintStyle: GoogleFonts.publicSans(
                                  color: Colors.grey.shade400, fontSize: 14),
                              border: InputBorder.none,
                              isDense: true,
                              contentPadding: EdgeInsets.zero,
                            ),
                            initialValue: ref
                                .read(produtosControllerProvider)
                                .searchQuery,
                            onChanged: (val) {
                              controller.aplicarFiltros(
                                  query: val.isEmpty ? null : val);
                            },
                          ),
                        ),
                        if (hasActiveFilter)
                          InkWell(
                            onTap: () {
                              controller.limparFiltros();
                            },
                            child: Icon(Icons.close,
                                color: Colors.grey.shade400, size: 20),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Dropdown Simples de Status
                Expanded(
                  flex: 1,
                  child: Container(
                    height: 44,
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        value: ref
                            .watch(produtosControllerProvider)
                            .selectedStatusFilter,
                        isExpanded: true,
                        hint: Text('Status',
                            style: GoogleFonts.publicSans(fontSize: 14)),
                        style: GoogleFonts.publicSans(
                            color: Colors.black87,
                            fontSize: 13,
                            fontWeight: FontWeight.w600),
                        icon: Icon(Icons.keyboard_arrow_down,
                            color: Colors.grey.shade500),
                        items: const [
                          DropdownMenuItem(
                              value: null, child: Text('Todos os status')),
                          DropdownMenuItem(
                              value: 'disponivel', child: Text('Disponível')),
                          DropdownMenuItem(
                              value: 'indisponivel',
                              child: Text('Indisponível')),
                          DropdownMenuItem(
                              value: 'destaque', child: Text('Destaque')),
                          DropdownMenuItem(
                              value: 'promo', child: Text('Em Promoção')),
                          DropdownMenuItem(
                              value: 'estoque_baixo',
                              child: Text('Estoque Baixo')),
                        ],
                        onChanged: (val) {
                          controller.aplicarFiltros(
                              status: val, setStatus: true);
                        },
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),

                // Alternar Modos de Gride/Lista
                Container(
                  height: 44,
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      _ViewModeButton(
                        icon: Icons.grid_view,
                        isActive: filterMode == 'grid',
                        onTap: () => controller.toggleFilterMode('grid'),
                      ),
                      const SizedBox(width: 4),
                      _ViewModeButton(
                        icon: Icons.view_list,
                        isActive: filterMode == 'list',
                        onTap: () => controller.toggleFilterMode('list'),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),

          // 2. Tabs das Categorias
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _CategoryTabButton(
                  title: 'Todos',
                  isActive: selectedCatId == null,
                  count: ref.read(produtosControllerProvider).produtos.length,
                  onTap: () => controller.aplicarFiltros(
                      categoriaId: null, setCategoriaId: true),
                ),
                ...categorias.where((c) => c.ativa).map((cat) {
                  // Count total the produtos sem filtro textual para cada tab
                  final badgeCount = ref
                      .read(produtosControllerProvider)
                      .produtos
                      .where((p) => p.categoriaCardapioId == cat.id)
                      .length;
                  return Padding(
                    padding: const EdgeInsets.only(left: 8),
                    child: _CategoryTabButton(
                      title: cat.nome,
                      isActive: selectedCatId == cat.id,
                      count: badgeCount,
                      onTap: () => controller.aplicarFiltros(
                          categoriaId: cat.id, setCategoriaId: true),
                    ),
                  );
                }),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ViewModeButton extends StatelessWidget {
  final IconData icon;
  final bool isActive;
  final VoidCallback onTap;

  const _ViewModeButton({
    required this.icon,
    required this.isActive,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFec5b13) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Icon(
          icon,
          size: 20,
          color: isActive ? Colors.white : Colors.grey.shade600,
        ),
      ),
    );
  }
}

class _CategoryTabButton extends StatelessWidget {
  final String title;
  final bool isActive;
  final int count;
  final VoidCallback onTap;

  const _CategoryTabButton({
    required this.title,
    required this.isActive,
    required this.count,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFec5b13) : Colors.white,
          border: Border.all(
            color: isActive ? const Color(0xFFec5b13) : Colors.grey.shade300,
          ),
          borderRadius: BorderRadius.circular(12),
          boxShadow: isActive
              ? [
                  BoxShadow(
                      color: const Color(0xFFec5b13).withValues(alpha: 0.3),
                      blurRadius: 8,
                      offset: const Offset(0, 4))
                ]
              : [],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              title,
              style: GoogleFonts.publicSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : Colors.grey.shade700,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: isActive
                    ? Colors.white.withValues(alpha: 0.2)
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                count.toString(),
                style: GoogleFonts.publicSans(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: isActive ? Colors.white : Colors.grey.shade600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
