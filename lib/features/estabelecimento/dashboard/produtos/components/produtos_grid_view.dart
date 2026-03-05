import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../controllers/produtos_controller.dart';
import '../models/produto_model.dart';
import 'produto_form_modal.dart';
import 'package:intl/intl.dart';

class ProdutosGridView extends ConsumerWidget {
  final List<ProdutoModel> produtos;

  const ProdutosGridView({super.key, required this.produtos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Agrupando por categoria para exibir os Headers
    final Map<String, List<ProdutoModel>> mapCategorias = {};
    for (var p in produtos) {
      final key = p.categoriaCardapioNome ?? 'Sem Categoria';
      mapCategorias.putIfAbsent(key, () => []).add(p);
    }

    // Usaremos slivers iterados para injetar Section Titles + Grids de forma performática
    final slivers = <Widget>[];

    mapCategorias.forEach((catName, listProd) {
      slivers.add(
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.only(top: 16, bottom: 12),
            child: Row(
              children: [
                Text(
                  catName,
                  style: GoogleFonts.publicSans(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  '${listProd.length} produto${listProd.length != 1 ? 's' : ''}',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.grey.shade400,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Divider(color: Colors.grey.shade300, thickness: 1),
                ),
              ],
            ),
          ),
        ),
      );

      slivers.add(
        SliverGrid(
          gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
            maxCrossAxisExtent:
                380, // Largura ideal de um Card para Desktop/Mobile
            mainAxisExtent: 290, // Altura fixa do Card
            crossAxisSpacing: 16,
            mainAxisSpacing: 16,
          ),
          delegate: SliverChildBuilderDelegate(
            (context, index) {
              final prod = listProd[index];
              return _ProductGridCard(produto: prod, index: index);
            },
            childCount: listProd.length,
          ),
        ),
      );
    });

    // CustomScrollView porque não podemos misturar Listas (Header Categoria) e Grids isoladamente
    return CustomScrollView(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      slivers: slivers,
    );
  }
}

class _ProductGridCard extends ConsumerWidget {
  final ProdutoModel produto;
  final int index;

  const _ProductGridCard({required this.produto, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');
    final pLabelAtivo = !produto.ativo;
    final pEstoqueBaixo = produto.controleEstoque &&
        (produto.quantidadeEstoque != null && produto.quantidadeEstoque! <= 5);

    // Gradientes baseados no índice (mock visual como no html)
    const gradients = [
      [Color(0xFFFDE68A), Color(0xFFFCD34D)],
      [Color(0xFFFEF08A), Color(0xFFFDE047)],
      [Color(0xFFFED7AA), Color(0xFFFCA5A5)],
      [Color(0xFFD9F99D), Color(0xFF86EFAC)],
      [Color(0xFFBAE6FD), Color(0xFF93C5FD)],
    ];
    final grad = gradients[index % gradients.length];

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Área Superior - Imagem e Badges Flutuantes
          Expanded(
            flex: 4,
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Fundo / Imagem
                produto.fotoPrincipalUrl != null &&
                        produto.fotoPrincipalUrl!.isNotEmpty
                    ? Image.network(produto.fotoPrincipalUrl!,
                        fit: BoxFit.cover)
                    : Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: grad,
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                        ),
                        child: const Center(
                          child: Icon(Icons.restaurant,
                              size: 48, color: Colors.white60),
                        ),
                      ),

                // Badges Superiores Esquerdos
                Positioned(
                  top: 8,
                  left: 8,
                  child: Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: [
                      if (pLabelAtivo)
                        _Badge(
                            text: 'Inativo',
                            bgColor:
                                Colors.grey.shade800.withValues(alpha: 0.8),
                            textColor: Colors.grey.shade300),
                      if (produto.destaque)
                        _Badge(
                            text: '⭐ Destaque',
                            bgColor: Colors.yellow.shade100,
                            textColor: Colors.yellow.shade800),
                      if (produto.precoPromocional != null &&
                          produto.precoPromocional! > 0)
                        _Badge(
                            text: '🏷️ Promo',
                            bgColor: Colors.pink.shade50,
                            textColor: Colors.pink.shade600),
                      if (pEstoqueBaixo)
                        _Badge(
                            text: '⚠️ ${produto.quantidadeEstoque}',
                            bgColor: Colors.amber.shade100,
                            textColor: Colors.amber.shade800),
                    ],
                  ),
                ),

                // Ações Superiores Direitas (Edit / Eye Toggle)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Row(
                    children: [
                      _GlassButton(
                        icon: Icons.edit,
                        color: Colors.grey.shade700,
                        onTap: () {
                          showProdutoFormModal(context, produto: produto);
                        },
                      ),
                      const SizedBox(width: 4),
                      _GlassButton(
                        icon: produto.disponivel && produto.ativo
                            ? Icons.visibility
                            : Icons.visibility_off,
                        color: produto.disponivel && produto.ativo
                            ? Colors.green.shade600
                            : Colors.red.shade400,
                        onTap: () {
                          ref
                              .read(produtosControllerProvider.notifier)
                              .toggleDisponibilidade(
                                  produto.id, produto.disponivel);
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Área Base - Dados Textuais
          Expanded(
            flex: 5,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Título e Preço
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          produto.nome,
                          style: GoogleFonts.publicSans(
                              fontSize: 14,
                              fontWeight: FontWeight.bold,
                              height: 1.2),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          if (produto.precoPromocional != null &&
                              produto.precoPromocional! > 0) ...[
                            Text(currencyFmt.format(produto.preco),
                                style: GoogleFonts.publicSans(
                                    fontSize: 10,
                                    decoration: TextDecoration.lineThrough,
                                    color: Colors.grey.shade400)),
                            Text(currencyFmt.format(produto.precoPromocional),
                                style: GoogleFonts.publicSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.pink.shade600)),
                          ] else
                            Text(currencyFmt.format(produto.preco),
                                style: GoogleFonts.publicSans(
                                    fontSize: 15,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFFec5b13))),
                        ],
                      )
                    ],
                  ),
                  const SizedBox(height: 6),

                  // Descrição
                  Text(
                    produto.descricao?.isNotEmpty == true
                        ? produto.descricao!
                        : '—',
                    style: GoogleFonts.publicSans(
                        fontSize: 11, color: Colors.grey.shade500),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),

                  const Spacer(),

                  // Rodapé: Vendas, Tipo, Status Text
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.shopping_bag,
                              size: 12, color: Colors.grey.shade400),
                          const SizedBox(width: 4),
                          Text('${produto.totalVendidos} vendas',
                              style: GoogleFonts.publicSans(
                                  fontSize: 11, color: Colors.grey.shade500)),
                          if (produto.tipoProduto == 'variavel') ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                  color: Colors.blue.shade50,
                                  borderRadius: BorderRadius.circular(4)),
                              child: Text('Variável',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.blue.shade600)),
                            ),
                          ]
                        ],
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: produto.disponivel && produto.ativo
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          produto.disponivel && produto.ativo
                              ? 'Disponível'
                              : 'Indisponível',
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: produto.disponivel && produto.ativo
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                      )
                    ],
                  ),

                  // Barra de Estoque (Se Ativa)
                  if (produto.controleEstoque) ...[
                    const SizedBox(height: 8),
                    Divider(color: Colors.grey.shade100, height: 1),
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Estoque',
                            style: GoogleFonts.publicSans(
                                fontSize: 11, color: Colors.grey.shade500)),
                        Text('${produto.quantidadeEstoque} un.',
                            style: GoogleFonts.publicSans(
                                fontSize: 11,
                                fontWeight: FontWeight.bold,
                                color: pEstoqueBaixo
                                    ? Colors.amber.shade700
                                    : Colors.grey.shade700)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Container(
                      height: 6,
                      decoration: BoxDecoration(
                          color: Colors.grey.shade100,
                          borderRadius: BorderRadius.circular(4)),
                      child: FractionallySizedBox(
                        alignment: Alignment.centerLeft,
                        widthFactor:
                            (produto.quantidadeEstoque ?? 0) / 100.0 > 1.0
                                ? 1.0
                                : (produto.quantidadeEstoque ?? 0) / 100.0,
                        child: Container(
                          decoration: BoxDecoration(
                            color: pEstoqueBaixo
                                ? Colors.amber.shade400
                                : Colors.green.shade400,
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                      ),
                    ),
                  ]
                ],
              ),
            ),
          )
        ],
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String text;
  final Color bgColor;
  final Color textColor;

  const _Badge(
      {required this.text, required this.bgColor, required this.textColor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
          color: bgColor, borderRadius: BorderRadius.circular(12)),
      child: Text(text,
          style: GoogleFonts.publicSans(
              fontSize: 10, fontWeight: FontWeight.bold, color: textColor)),
    );
  }
}

class _GlassButton extends StatelessWidget {
  final IconData icon;
  final Color color;
  final VoidCallback onTap;

  const _GlassButton(
      {required this.icon, required this.color, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.9),
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 4)
          ],
        ),
        child: Icon(icon, size: 18, color: color),
      ),
    );
  }
}
