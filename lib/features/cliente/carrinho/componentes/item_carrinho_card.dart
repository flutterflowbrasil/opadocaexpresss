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
          // Image e Botão Editar
          Column(
            children: [
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
              if (produto.opcoes.isNotEmpty && produto.aceitaObservacaoCategoria)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: InkWell(
                    onTap: () => _mostrarDialogoObservacao(context, ref, item),
                    child: Text(
                      'Editar',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFFFF7034),
                      ),
                    ),
                  ),
                ),
            ],
          ),

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
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: InkWell(
                      onTap: produto.aceitaObservacaoCategoria
                          ? () => _mostrarDialogoObservacao(context, ref, item)
                          : null,
                      borderRadius: BorderRadius.circular(4),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              'Obs: ${item.observacao}',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: mutedTextColor,
                                fontStyle: FontStyle.italic,
                              ),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (produto.aceitaObservacaoCategoria)
                            Icon(Icons.edit, size: 14, color: mutedTextColor),
                        ],
                      ),
                    ),
                  )
                else if (produto.aceitaObservacaoCategoria)
                  Padding(
                    padding: const EdgeInsets.only(top: 4, bottom: 4),
                    child: InkWell(
                      onTap: () => _mostrarDialogoObservacao(context, ref, item),
                      borderRadius: BorderRadius.circular(4),
                      child: Text(
                        '+ Adicionar observação',
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: const Color(0xFFFF7034),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
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

void _mostrarDialogoObservacao(BuildContext context, WidgetRef ref, ItemCarrinhoModel item) {
  final TextEditingController obsController = TextEditingController(text: item.observacao ?? '');
  final isDark = Theme.of(context).brightness == Brightness.dark;
  final primaryColor = const Color(0xFFFF7034);
  final surfaceColor = isDark ? const Color(0xFF2d2d2d) : Colors.white;
  final textColor = isDark ? Colors.white : const Color(0xFF4a4a4a);
  final int maxObsLength = 140;

  showDialog(
    context: context,
    builder: (context) {
      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          width: 400,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1f1f1f) : const Color(0xFFFFFBF2),
            borderRadius: BorderRadius.circular(24),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Observação',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  IconButton(
                    icon: Icon(Icons.close_rounded, color: Colors.grey[500]),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              ValueListenableBuilder<TextEditingValue>(
                valueListenable: obsController,
                builder: (context, value, child) {
                  return Text(
                    '${value.text.length} / $maxObsLength caracteres',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                    textAlign: TextAlign.right,
                  );
                },
              ),
              const SizedBox(height: 4),
              TextField(
                controller: obsController,
                maxLength: maxObsLength,
                maxLines: 4,
                style: GoogleFonts.outfit(color: textColor, fontSize: 14),
                decoration: InputDecoration(
                  counterText: '',
                  hintText: 'Ex: bem passadinho, sem muita manteiga, etc.',
                  hintStyle: GoogleFonts.outfit(color: Colors.grey[400], fontSize: 14),
                  filled: true,
                  fillColor: surfaceColor,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[300]!),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  ref.read(carrinhoControllerProvider.notifier).atualizarObservacao(
                        item.produto,
                        item.observacao,
                        obsController.text.trim(),
                      );
                  Navigator.of(context).pop();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                child: Text(
                  'Salvar Observação',
                  style: GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 16),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}
