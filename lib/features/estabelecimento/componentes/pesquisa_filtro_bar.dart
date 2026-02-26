import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';

class PesquisaFiltroBar extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final Function(String) onSearchChanged;
  final List<CategoriaCardapioModel> categorias;
  final String selectedCategoriaId;
  final Function(String) onCategoriaSelected;

  const PesquisaFiltroBar({
    super.key,
    required this.isDark,
    required this.searchQuery,
    required this.onSearchChanged,
    required this.categorias,
    required this.selectedCategoriaId,
    required this.onCategoriaSelected,
  });

  @override
  Widget build(BuildContext context) {
    final bgColor = isDark ? const Color(0xFF1C1917) : Colors.white;

    return SliverPersistentHeader(
      pinned: true,
      delegate: _SliverAppBarDelegate(
        minHeight: 120,
        maxHeight: 120,
        child: Container(
          color: bgColor,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Search Bar
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 12),
                child: _SearchBar(
                  isDark: isDark,
                  searchQuery: searchQuery,
                  onSearchChanged: onSearchChanged,
                ),
              ),
              // Categories List
              SizedBox(
                height: 40,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  itemCount: categorias.length,
                  itemBuilder: (context, index) {
                    final cat = categorias[index];
                    final isSelected = cat.id == selectedCategoriaId;
                    return Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: _CategoryChip(
                        name: cat.nome,
                        isSelected: isSelected,
                        isDark: isDark,
                        onTap: () => onCategoriaSelected(cat.id),
                      ),
                    );
                  },
                ),
              ),
              const Spacer(),
              // Divider
              Divider(
                height: 1,
                color: isDark ? Colors.grey[800] : Colors.grey[200],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final bool isDark;
  final String searchQuery;
  final Function(String) onSearchChanged;

  const _SearchBar({
    required this.isDark,
    required this.searchQuery,
    required this.onSearchChanged,
  });

  @override
  Widget build(BuildContext context) {
    final fillColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFF5F5F5);
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

    return TextField(
      onChanged: onSearchChanged, // Already passes the string directly
      style: GoogleFonts.outfit(
        color: isDark ? Colors.white : Colors.black87,
        fontSize: 15,
      ),
      decoration: InputDecoration(
        hintText: 'Buscar no cardápio...',
        hintStyle: GoogleFonts.outfit(
          color: isDark ? Colors.grey[500] : Colors.grey[400],
        ),
        prefixIcon: Icon(
          Icons.search_rounded,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
        ),
        filled: true,
        fillColor: fillColor,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: borderColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFFF7034), width: 1.5),
        ),
      ),
    );
  }
}

class _CategoryChip extends StatelessWidget {
  final String name;
  final bool isSelected;
  final bool isDark;
  final VoidCallback onTap;

  const _CategoryChip({
    required this.name,
    required this.isSelected,
    required this.isDark,
    required this.onTap,
  });

  static const _primaryColor = Color(0xFFFF7034);

  @override
  Widget build(BuildContext context) {
    final bgAtivo = _primaryColor;
    final bgInativo = isDark ? const Color(0xFF3A3A3A) : Colors.white;
    final borderColor = isSelected
        ? Colors.transparent
        : (isDark ? Colors.grey[700]! : Colors.grey[300]!);

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? bgAtivo : bgInativo,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: borderColor),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: _primaryColor.withValues(alpha: 0.3),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ]
              : [],
        ),
        child: Text(
          name,
          style: GoogleFonts.outfit(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected
                ? Colors.white
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate({
    required this.minHeight,
    required this.maxHeight,
    required this.child,
  });

  final double minHeight;
  final double maxHeight;
  final Widget child;

  @override
  double get minExtent => minHeight;

  @override
  double get maxExtent => maxHeight;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(child: child);
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return maxHeight != oldDelegate.maxHeight ||
        minHeight != oldDelegate.minHeight ||
        child != oldDelegate.child;
  }
}
