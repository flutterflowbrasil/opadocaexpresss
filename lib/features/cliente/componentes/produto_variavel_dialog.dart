import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class ProdutoVariavelDialog extends StatefulWidget {
  final ProdutoModel produto;
  final EstabelecimentoModel estabelecimento;
  final Function(int quantidade, String observacao,
      List<Map<String, dynamic>> selecoes) onAddTap;

  const ProdutoVariavelDialog({
    super.key,
    required this.produto,
    required this.estabelecimento,
    required this.onAddTap,
  });

  @override
  State<ProdutoVariavelDialog> createState() => _ProdutoVariavelDialogState();
}

class _ProdutoVariavelDialogState extends State<ProdutoVariavelDialog> {
  int _quantidade = 1;
  final TextEditingController _obsController = TextEditingController();
  final int maxObsLength = 140;

  // Estado das seleções: Map<NomeDaOpcao, List<ProdutoOpcaoItemModel>>
  final Map<String, List<ProdutoOpcaoItemModel>> _selecoes = {};

  @override
  void initState() {
    super.initState();
    for (final opcao in widget.produto.opcoes) {
      _selecoes[_grupoKey(opcao)] = [];
    }
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  bool _isSelectionValid() {
    for (final opcao in widget.produto.opcoes) {
      final totalSelecionado = _selecoes[_grupoKey(opcao)]?.length ?? 0;
      if (totalSelecionado < opcao.minimo) return false;
      if (opcao.obrigatorio && totalSelecionado < 1) return false;
      if (totalSelecionado > opcao.maximo) return false;
    }
    return true;
  }

  double _getAdicionaisTotal() {
    double total = 0;
    _selecoes.forEach((key, itens) {
      for (var item in itens) {
        total += (item.precoAdicional ?? 0);
      }
    });
    return total;
  }

  void _atualizarRadio(ProdutoOpcaoModel opcao, ProdutoOpcaoItemModel item) {
    setState(() {
      _selecoes[_grupoKey(opcao)] = [item];
    });
  }

  void _toggleCheckbox(
      ProdutoOpcaoModel opcao, ProdutoOpcaoItemModel item, bool checked) {
    setState(() {
      final key = _grupoKey(opcao);
      final list = List<ProdutoOpcaoItemModel>.from(_selecoes[key] ?? []);
      if (checked) {
        if (list.length < opcao.maximo &&
            !list.any((i) => _itemKey(i) == _itemKey(item))) {
          list.add(item);
        }
      } else {
        list.removeWhere((i) => _itemKey(i) == _itemKey(item));
      }
      _selecoes[key] = list;
    });
  }

  String _grupoKey(ProdutoOpcaoModel opcao) => opcao.id ?? opcao.nome;

  String _itemKey(ProdutoOpcaoItemModel item) => item.id ?? item.nome;

  String _formatMoney(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  String _precoLabel(double preco) {
    if (preco <= 0) return 'Gratis';
    return '+ ${_formatMoney(preco)}';
  }

  List<Map<String, dynamic>> _buildOpcoesSelecionadas() {
    final result = <Map<String, dynamic>>[];
    for (final grupo in widget.produto.opcoes) {
      final itensSelecionados = _selecoes[_grupoKey(grupo)] ?? [];
      if (itensSelecionados.isEmpty) continue;
      result.add({
        'grupo_id': grupo.id ?? grupo.nome,
        'grupo_nome': grupo.nome,
        'tipo': grupo.tipo,
        'itens': itensSelecionados
            .map((item) => {
                  'item_id': item.id ?? item.nome,
                  'nome': item.nome,
                  'preco': item.precoAdicional ?? 0,
                })
            .toList(),
      });
    }
    return result;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFF7034);
    final bgColor = isDark ? const Color(0xFF1f1f1f) : const Color(0xFFFFFBF2);
    final surfaceColor = isDark ? const Color(0xFF2d2d2d) : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF4a4a4a);
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[300]!;

    final double precoBase = widget.produto.precoAtual;
    final double adicionais = _getAdicionaisTotal();
    final double precoTotal = (precoBase + adicionais) * _quantidade;
    final bool canSubmit = _isSelectionValid();

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
                    backgroundColor:
                        isDark ? Colors.grey[800] : Colors.grey[200]),
              ),
            ),

            // Content Area
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
                                  borderRadius: BorderRadius.circular(16)),
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
                              color: textColor),
                        ),
                        if (widget.produto.descricao != null &&
                            widget.produto.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 8),
                          Text(widget.produto.descricao!,
                              style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : Colors.grey[600])),
                        ],
                        const SizedBox(height: 12),
                        Text(
                            'R\$ ${widget.produto.precoAtual.toStringAsFixed(2).replaceAll('.', ',')}',
                            style: GoogleFonts.outfit(
                                fontSize: 20,
                                fontWeight: FontWeight.bold,
                                color: primaryColor)),
                        const SizedBox(height: 24),

                        // Store Info
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: surfaceColor,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                                color: borderColor, style: BorderStyle.none),
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
                                          : Colors.grey[700]),
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
                                      color: textColor)),
                            ],
                          ),
                        ),
                        const SizedBox(height: 24),

                        // Variações do Produto
                        ...widget.produto.opcoes.map((opcao) {
                          final isRadio = opcao.isEscolhaUnica;
                          final selecionados =
                              _selecoes[_grupoKey(opcao)]?.length ?? 0;

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                      color: isDark
                                          ? Colors.grey[800]
                                          : Colors.grey[200],
                                      borderRadius: BorderRadius.circular(8)),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(opcao.nome,
                                          style: GoogleFonts.outfit(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                              color: textColor)),
                                      Container(
                                        padding: const EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: opcao.obrigatorio
                                              ? Colors.grey[700]
                                              : Colors.grey[400],
                                          borderRadius:
                                              BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          opcao.obrigatorio
                                              ? 'OBRIGATÓRIO'
                                              : 'OPCIONAL',
                                          style: GoogleFonts.outfit(
                                              color: Colors.white,
                                              fontSize: 10,
                                              fontWeight: FontWeight.bold),
                                        ),
                                      )
                                    ],
                                  ),
                                ),
                                if (opcao.maximo > 0)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Text(
                                      isRadio
                                          ? 'Escolha 1 opcao'
                                          : 'Escolha de ${opcao.minimo} ate ${opcao.maximo}',
                                      style: GoogleFonts.outfit(
                                        fontSize: 12,
                                        color: isDark
                                            ? Colors.grey[400]
                                            : Colors.grey[600],
                                      ),
                                    ),
                                  ),
                                const SizedBox(height: 12),
                                Column(
                                  children: opcao.itens.map((item) {
                                    final listSelecionada =
                                        _selecoes[_grupoKey(opcao)] ?? [];
                                    final isSelected = listSelecionada.any(
                                        (i) => _itemKey(i) == _itemKey(item));
                                    final maxAtingido = !isRadio &&
                                        !isSelected &&
                                        selecionados >= opcao.maximo;
                                    final itemPreco = item.precoAdicional ?? 0;

                                    return GestureDetector(
                                      onTap: () {
                                        if (isRadio) {
                                          _atualizarRadio(opcao, item);
                                        } else if (!maxAtingido) {
                                          _toggleCheckbox(
                                              opcao, item, !isSelected);
                                        } else {
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                'Limite de ${opcao.maximo} selecoes atingido.',
                                              ),
                                            ),
                                          );
                                        }
                                      },
                                      child: Container(
                                        margin:
                                            const EdgeInsets.only(bottom: 8),
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: surfaceColor,
                                          border: Border.all(
                                              color: isSelected
                                                  ? primaryColor
                                                  : borderColor),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Row(
                                          children: [
                                            isRadio
                                                ? Radio<String>(
                                                    value: item.nome,
                                                    groupValue: isSelected
                                                        ? item.nome
                                                        : null,
                                                    onChanged: (val) =>
                                                        _atualizarRadio(
                                                            opcao, item),
                                                    activeColor: primaryColor,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  )
                                                : Checkbox(
                                                    value: isSelected,
                                                    onChanged: maxAtingido
                                                        ? null
                                                        : (val) =>
                                                            _toggleCheckbox(
                                                              opcao,
                                                              item,
                                                              val ?? false,
                                                            ),
                                                    activeColor: primaryColor,
                                                    visualDensity:
                                                        VisualDensity.compact,
                                                  ),
                                            Expanded(
                                              child: Column(
                                                crossAxisAlignment:
                                                    CrossAxisAlignment.start,
                                                children: [
                                                  Text(item.nome,
                                                      style: GoogleFonts.outfit(
                                                          fontWeight:
                                                              FontWeight.w500,
                                                          color: textColor,
                                                          fontSize: 14)),
                                                  if (item.descricao != null &&
                                                      item.descricao!
                                                          .trim()
                                                          .isNotEmpty)
                                                    Text(
                                                      item.descricao!,
                                                      style: GoogleFonts.outfit(
                                                        color: isDark
                                                            ? Colors.grey[400]
                                                            : Colors.grey[500],
                                                        fontSize: 12,
                                                      ),
                                                    ),
                                                ],
                                              ),
                                            ),
                                            Text(
                                              _precoLabel(itemPreco),
                                              style: GoogleFonts.outfit(
                                                  color: isSelected
                                                      ? primaryColor
                                                      : Colors.grey[500],
                                                  fontSize: 14,
                                                  fontWeight: isSelected
                                                      ? FontWeight.bold
                                                      : FontWeight.w500),
                                            ),
                                          ],
                                        ),
                                      ),
                                    );
                                  }).toList(),
                                )
                              ],
                            ),
                          );
                        }),

                        // Observation removida para ir para o carrinho
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
                          color:
                              isDark ? Colors.grey[800]! : Colors.grey[200]!))),
              child: SafeArea(
                child: Row(
                  children: [
                    Container(
                      height: 48,
                      decoration: BoxDecoration(
                          border: Border.all(
                              color: isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!),
                          borderRadius: BorderRadius.circular(12)),
                      child: Row(
                        children: [
                          IconButton(
                              icon: const Icon(Icons.remove_rounded),
                              color: primaryColor,
                              onPressed: _quantidade > 1
                                  ? () => setState(() => _quantidade--)
                                  : null),
                          SizedBox(
                              width: 32,
                              child: Text(_quantidade.toString(),
                                  textAlign: TextAlign.center,
                                  style: GoogleFonts.outfit(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                      color: textColor))),
                          IconButton(
                              icon: const Icon(Icons.add_rounded),
                              color: primaryColor,
                              onPressed: () => setState(() => _quantidade++)),
                        ],
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: canSubmit
                            ? () {
                                widget.onAddTap(
                                  _quantidade,
                                  _obsController.text,
                                  _buildOpcoesSelecionadas(),
                                );
                                Navigator.of(context).pop();
                              }
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor:
                              canSubmit ? primaryColor : Colors.grey[500],
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(
                              horizontal: 24, vertical: 14),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('Adicionar',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
                            Text(
                                'R\$ ${precoTotal.toStringAsFixed(2).replaceAll('.', ',')}',
                                style: GoogleFonts.outfit(
                                    fontWeight: FontWeight.bold, fontSize: 16)),
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
