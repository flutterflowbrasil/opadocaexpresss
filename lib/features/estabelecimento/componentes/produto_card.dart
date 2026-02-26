import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class ProdutoCard extends StatelessWidget {
  final ProdutoModel produto;
  final bool isDark;
  final VoidCallback onTap;
  final VoidCallback onAddTap;
  final bool isGrid;

  const ProdutoCard({
    super.key,
    required this.produto,
    required this.isDark,
    required this.onTap,
    required this.onAddTap,
    this.isGrid = false,
  });

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  Widget build(BuildContext context) {
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final textColor = isDark ? Colors.white : _secondaryColor;
    final Color mutedTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
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
        child: isGrid
            ? _buildGridContent(textColor, mutedTextColor)
            : _buildListContent(textColor, mutedTextColor),
      ),
    );
  }

  Widget _buildListContent(Color textColor, Color mutedTextColor) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Text Info
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                produto.nome,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: textColor,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 4),
              if (produto.descricao != null && produto.descricao!.isNotEmpty)
                Text(
                  produto.descricao!,
                  style: GoogleFonts.outfit(
                    fontSize: 12,
                    color: mutedTextColor,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    'R\$ ${produto.precoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: _primaryColor,
                    ),
                  ),
                  if (produto.precoPromocional != null) ...[
                    const SizedBox(width: 6),
                    Text(
                      'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: mutedTextColor,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                  ],
                ],
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        // Image
        if (produto.imagemUrl != null)
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.network(
              produto.imagemUrl!,
              width: 90,
              height: 90,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
            ),
          )
        else
          _buildPlaceholder(isDark),

        const SizedBox(width: 8),

        // Action
        Align(
          alignment: Alignment.center,
          child: IconButton(
            icon: const Icon(Icons.add_circle_rounded),
            color: _primaryColor,
            iconSize: 32,
            onPressed: onAddTap,
          ),
        ),
      ],
    );
  }

  Widget _buildGridContent(Color textColor, Color mutedTextColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Image Top
        if (produto.imagemUrl != null)
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.network(
                produto.imagemUrl!,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => _buildPlaceholder(isDark),
              ),
            ),
          )
        else
          Expanded(child: _buildPlaceholder(isDark)),

        const SizedBox(height: 12),

        // Text Info
        Text(
          produto.nome,
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        if (produto.descricao != null && produto.descricao!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(
            produto.descricao!,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: mutedTextColor,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Text(
                  'R\$ ${produto.precoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                  style: GoogleFonts.outfit(
                    fontSize: 15,
                    fontWeight: FontWeight.bold,
                    color: _primaryColor,
                  ),
                ),
                if (produto.precoPromocional != null) ...[
                  const SizedBox(width: 4),
                  Text(
                    'R\$ ${produto.preco.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: mutedTextColor,
                      decoration: TextDecoration.lineThrough,
                    ),
                  ),
                ],
              ],
            ),
            InkWell(
              onTap: onAddTap,
              borderRadius: BorderRadius.circular(20),
              child: const Icon(
                Icons.add_circle_rounded,
                color: _primaryColor,
                size: 32,
              ),
            )
          ],
        ),
      ],
    );
  }

  Widget _buildPlaceholder(bool isDark) {
    return Container(
      width: 90,
      height: 90,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF3A3A3A) : const Color(0xFFF0F0F0),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        Icons.fastfood_rounded,
        color: isDark ? Colors.grey[600] : Colors.grey[400],
        size: 32,
      ),
    );
  }
}
