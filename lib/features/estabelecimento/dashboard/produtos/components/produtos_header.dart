import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'produto_form_modal.dart';

class ProdutosHeader extends StatelessWidget {
  const ProdutosHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final isNarrow = MediaQuery.of(context).size.width < 768;

    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Hamburger (mobile) OR Title (desktop)
          if (isNarrow)
            Builder(
              builder: (ctx) => InkWell(
                onTap: () => Scaffold.of(ctx).openDrawer(),
                borderRadius: BorderRadius.circular(9),
                child: Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border:
                        Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                    borderRadius: BorderRadius.circular(9),
                  ),
                  child: const Icon(Icons.menu,
                      color: Color(0xFF6B7280), size: 20),
                ),
              ),
            )
          else
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Produtos',
                  style: GoogleFonts.publicSans(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Gerencie produtos, categorias e estoque',
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: Colors.grey.shade500,
                  ),
                ),
              ],
            ),

          // Botões de Ação Dinâmicos
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              OutlinedButton.icon(
                onPressed: () {
                  // TODO: Abrir Modal de Categorias (próxima feature)
                },
                icon: const Icon(Icons.category, size: 18),
                label: isNarrow
                    ? const SizedBox.shrink()
                    : const Text('Categorias'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.grey.shade800,
                  side: BorderSide(color: Colors.grey.shade300),
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 16,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                onPressed: () {
                  showProdutoFormModal(context);
                },
                icon: const Icon(Icons.add, size: 18),
                label: isNarrow
                    ? const SizedBox.shrink()
                    : const Text('Novo Produto'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFFec5b13),
                  foregroundColor: Colors.white,
                  elevation: 4,
                  padding: EdgeInsets.symmetric(
                    horizontal: isNarrow ? 12 : 20,
                    vertical: 14,
                  ),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                  textStyle:
                      GoogleFonts.publicSans(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
