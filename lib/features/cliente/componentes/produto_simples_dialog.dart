import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class ProdutoSimplesDialog extends StatefulWidget {
  final ProdutoModel produto;
  final EstabelecimentoModel estabelecimento;
  final Function(int quantidade, String observacao) onAddTap;

  const ProdutoSimplesDialog({
    super.key,
    required this.produto,
    required this.estabelecimento,
    required this.onAddTap,
  });

  @override
  State<ProdutoSimplesDialog> createState() => _ProdutoSimplesDialogState();
}

class _ProdutoSimplesDialogState extends State<ProdutoSimplesDialog> {
  int _quantidade = 1;
  final TextEditingController _obsController = TextEditingController();
  final int maxObsLength = 140;

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFF7034);
    final bgColor = isDark ? const Color(0xFF1f1f1f) : const Color(0xFFFFFBF2);
    final surfaceColor = isDark ? const Color(0xFF2d2d2d) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4a4a4a);

    final double precoTotal = widget.produto.precoAtual * _quantidade;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Container(
        width: MediaQuery.of(context).size.width > 768 ? 900 : double.infinity,
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(24),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header Top Bar
            Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              color: bgColor,
              child: IconButton(
                icon: Icon(Icons.close_rounded,
                    color: isDark ? Colors.grey[400] : Colors.grey[500]),
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: isDark ? Colors.grey[800] : Colors.grey[200],
                ),
              ),
            ),

            // Content Area (Scrollable or Row on Desktop)
            Flexible(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final isDesktop = constraints.maxWidth >= 768;

                  Widget imageSection = Container(
                    color: surfaceColor,
                    padding: const EdgeInsets.all(24),
                    child: Center(
                      child: Stack(
                        children: [
                          if (widget.produto.imagemUrl != null)
                            ClipRRect(
                              borderRadius: BorderRadius.circular(16),
                              child: Image.network(
                                widget.produto.imagemUrl!,
                                width: isDesktop ? 350 : double.infinity,
                                height: isDesktop ? 350 : 180,
                                fit: BoxFit.contain,
                              ),
                            )
                          else
                            Container(
                              width: isDesktop ? 350 : double.infinity,
                              height: isDesktop ? 350 : 180,
                              decoration: BoxDecoration(
                                color: isDark
                                    ? Colors.grey[800]
                                    : Colors.grey[200],
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Icon(Icons.fastfood,
                                  size: 64, color: Colors.grey[400]),
                            ),
                        ],
                      ),
                    ),
                  );

                  Widget detailsSection = Container(
                    padding: const EdgeInsets.all(24),
                    color: bgColor,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.produto.nome,
                          style: GoogleFonts.outfit(
                            fontSize: 24,
                            fontWeight: FontWeight.bold,
                            color: textColor,
                          ),
                        ),
                        if (widget.produto.descricao != null &&
                            widget.produto.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(
                            widget.produto.descricao!,
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                          ),
                        ],
                        const SizedBox(height: 12),
                        Text(
                          'R\$ ${widget.produto.precoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                          style: GoogleFonts.outfit(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: primaryColor,
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Store Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: isDark
                                    ? Colors.grey[800]!
                                    : Colors.grey[300]!,
                                style: BorderStyle.none),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.storefront_rounded,
                                  color: Colors.grey[400], size: 20),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(
                                  widget.estabelecimento.nome,
                                  style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.w600,
                                    color: isDark
                                        ? Colors.grey[200]
                                        : Colors.grey[700],
                                  ),
                                ),
                              ),
                              Icon(Icons.star_rounded,
                                  color: Colors.amber[500], size: 16),
                              const SizedBox(width: 4),
                              Text(
                                widget.estabelecimento.avaliacaoMedia
                                    .toStringAsFixed(1),
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 14,
                                    color: textColor),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Observation
                        if (widget.produto.permiteObservacoes) ...[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Alguma observação?',
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  fontWeight: FontWeight.bold,
                                  color: isDark
                                      ? Colors.grey[300]
                                      : Colors.grey[700],
                                ),
                              ),
                              ValueListenableBuilder<TextEditingValue>(
                                valueListenable: _obsController,
                                builder: (context, value, child) {
                                  return Text(
                                    '${value.text.length} / $maxObsLength',
                                    style: GoogleFonts.outfit(
                                      fontSize: 12,
                                      color: Colors.grey[400],
                                    ),
                                  );
                                },
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _obsController,
                            maxLength: maxObsLength,
                            maxLines: 4,
                            style: GoogleFonts.outfit(
                                color: textColor, fontSize: 14),
                            decoration: InputDecoration(
                              counterText: '',
                              hintText:
                                  'Ex: bem passadinho, sem muita manteiga, etc.',
                              hintStyle: GoogleFonts.outfit(
                                  color: Colors.grey[400], fontSize: 14),
                              filled: true,
                              fillColor: surfaceColor,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(
                                    color: isDark
                                        ? Colors.grey[700]!
                                        : Colors.grey[300]!),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(12),
                                borderSide: BorderSide(color: primaryColor),
                              ),
                            ),
                          ),
                        ]
                      ],
                    ),
                  );

                  if (isDesktop) {
                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Expanded(child: imageSection),
                        Expanded(
                            child:
                                SingleChildScrollView(child: detailsSection)),
                      ],
                    );
                  } else {
                    return SingleChildScrollView(
                      child: Column(
                        children: [
                          imageSection,
                          detailsSection,
                        ],
                      ),
                    );
                  }
                },
              ),
            ),

            // Bottom Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              decoration: BoxDecoration(
                color: surfaceColor,
                border: Border(
                    top: BorderSide(
                        color: isDark ? Colors.grey[800]! : Colors.grey[200]!)),
              ),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color:
                                isDark ? Colors.grey[700]! : Colors.grey[300]!),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        children: [
                          IconButton(
                            icon: const Icon(Icons.remove_rounded),
                            color: primaryColor,
                            onPressed: _quantidade > 1
                                ? () => setState(() => _quantidade--)
                                : null,
                          ),
                          SizedBox(
                            width: 32,
                            child: Text(
                              _quantidade.toString(),
                              textAlign: TextAlign.center,
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                  color: textColor),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.add_rounded),
                            color: primaryColor,
                            onPressed: () => setState(() => _quantidade++),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: () {
                          widget.onAddTap(_quantidade, _obsController.text);
                          Navigator.of(context).pop();
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: primaryColor,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Adicionar',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                            Text(
                              'R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
