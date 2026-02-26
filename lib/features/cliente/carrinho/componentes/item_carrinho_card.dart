import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class ItemCarrinhoCard extends ConsumerWidget {
  final ItemCarrinhoModel item;
  final bool isDark;

  const ItemCarrinhoCard({
    super.key,
    required this.item,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final produto = item.produto;
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF7D2D35);
    final mutedTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: borderColor),
        boxShadow: [
          if (!isDark)
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Image
          if (produto.imagemUrl != null)
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                produto.imagemUrl!,
                width: 70,
                height: 70,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(),
              ),
            )
          else
            _buildPlaceholder(),

          const SizedBox(width: 12),

          // Info & Controls
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        produto.nome,
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: textColor,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.delete_outline,
                          color: Colors.red[400], size: 20),
                      padding: EdgeInsets.zero,
                      constraints: const BoxConstraints(),
                      onPressed: () {
                        ref
                            .read(carrinhoControllerProvider.notifier)
                            .removerProduto(produto,
                                observacao: item.observacao);
                      },
                    ),
                  ],
                ),
                if (item.observacao != null && item.observacao!.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Text(
                      'Obs: ${item.observacao}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: mutedTextColor,
                        fontStyle: FontStyle.italic,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'R\$ ${item.subtotal.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: const Color(0xFFFF7034),
                      ),
                    ),
                    _buildQuantityControls(ref, produto),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQuantityControls(WidgetRef ref, ProdutoModel produto) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF9F5F0),
        borderRadius: BorderRadius.circular(20),
        border:
            Border.all(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          InkWell(
            onTap: () {
              ref.read(carrinhoControllerProvider.notifier).atualizarQuantidade(
                  produto, item.quantidade - 1,
                  observacao: item.observacao);
            },
            borderRadius:
                const BorderRadius.horizontal(left: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(
                  item.quantidade == 1 ? Icons.delete_outline : Icons.remove,
                  size: 16,
                  color: item.quantidade == 1
                      ? Colors.red[400]
                      : (isDark ? Colors.white : Colors.black87)),
            ),
          ),
          Text(
            item.quantidade.toString(),
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          InkWell(
            onTap: () {
              ref.read(carrinhoControllerProvider.notifier).atualizarQuantidade(
                  produto, item.quantidade + 1,
                  observacao: item.observacao);
            },
            borderRadius:
                const BorderRadius.horizontal(right: Radius.circular(20)),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              child: Icon(Icons.add, size: 16, color: const Color(0xFFFF7034)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPlaceholder() {
    return Container(
      width: 70,
      height: 70,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fastfood_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 24,
      ),
    );
  }
}
