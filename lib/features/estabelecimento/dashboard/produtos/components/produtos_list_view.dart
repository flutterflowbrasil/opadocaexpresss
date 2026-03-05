import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:cached_network_image/cached_network_image.dart';

import '../controllers/produtos_controller.dart';
import '../models/produto_model.dart';
import 'produto_form_modal.dart';

class ProdutosListView extends ConsumerWidget {
  final List<ProdutoModel> produtos;

  const ProdutosListView({super.key, required this.produtos});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final currencyFmt = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$');

    // Agrupando por categoria
    final Map<String, List<ProdutoModel>> mapCategorias = {};
    for (var p in produtos) {
      final key = p.categoriaCardapioNome ?? 'Sem Categoria';
      mapCategorias.putIfAbsent(key, () => []).add(p);
    }

    return CustomScrollView(
      // B3: Removido shrinkWrap:true e NeverScrollableScrollPhysics
      // O scroll é controlado pelo CustomScrollView pai em produtos_screen.dart
      shrinkWrap: false,
      slivers: [
        for (final entry in mapCategorias.entries) ...[
          // Cabeçalho da Categoria
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 12, top: 16),
              child: Row(
                children: [
                  Text(
                    entry.key,
                    style: GoogleFonts.publicSans(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${entry.value.length} produto${entry.value.length != 1 ? 's' : ''}',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: Colors.grey.shade400,
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(child: Divider(color: Colors.grey.shade300)),
                ],
              ),
            ),
          ),

          // Lista de Produtos da Categoria
          SliverList(
            delegate: SliverChildBuilderDelegate(
              (context, index) {
                final prod = entry.value[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _ProductListTile(
                      produto: prod, currencyFmt: currencyFmt, ref: ref),
                );
              },
              childCount: entry.value.length,
            ),
          ),
        ],
      ],
    );
  }
}

class _ProductListTile extends StatelessWidget {
  final ProdutoModel produto;
  final NumberFormat currencyFmt;
  final WidgetRef ref;

  const _ProductListTile({
    required this.produto,
    required this.currencyFmt,
    required this.ref,
  });

  @override
  Widget build(BuildContext context) {
    final bool pEstoqueBaixo = produto.controleEstoque &&
        (produto.quantidadeEstoque != null && produto.quantidadeEstoque! <= 5);
    final bool pDisponivel = produto.disponivel && produto.ativo;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Imagem / Placeholder
            Container(
              width: 72,
              height: 72,
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                gradient: produto.fotoPrincipalUrl == null ||
                        produto.fotoPrincipalUrl!.isEmpty
                    ? const LinearGradient(
                        colors: [Color(0xFFFDE68A), Color(0xFFFCD34D)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      )
                    : null,
              ),
              child: produto.fotoPrincipalUrl != null &&
                      produto.fotoPrincipalUrl!.isNotEmpty
                  // M5: CachedNetworkImage evita re-download a cada rebuild da lista
                  ? CachedNetworkImage(
                      imageUrl: produto.fotoPrincipalUrl!,
                      fit: BoxFit.cover,
                      placeholder: (ctx, url) => const Center(
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                      errorWidget: (ctx, url, error) => const Icon(
                        Icons.restaurant,
                        color: Colors.white60,
                        size: 32,
                      ),
                    )
                  : const Center(
                      child: Icon(Icons.restaurant,
                          color: Colors.white60, size: 32),
                    ),
            ),
            const SizedBox(width: 16),

            // Info Central
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          produto.nome,
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      // Badge de Status
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: pDisponivel
                              ? Colors.green.shade50
                              : Colors.red.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          pDisponivel ? 'Disponível' : 'Indisponível',
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: pDisponivel
                                ? Colors.green.shade600
                                : Colors.red.shade600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  if (produto.descricao?.isNotEmpty == true) ...[
                    const SizedBox(height: 4),
                    Text(
                      produto.descricao!,
                      style: GoogleFonts.publicSans(
                          fontSize: 12, color: Colors.grey.shade500),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      // Preço
                      if (produto.precoPromocional != null &&
                          produto.precoPromocional! > 0) ...[
                        Text(
                          currencyFmt.format(produto.preco),
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            decoration: TextDecoration.lineThrough,
                            color: Colors.grey.shade400,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          currencyFmt.format(produto.precoPromocional),
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: Colors.pink.shade600,
                          ),
                        ),
                      ] else
                        Text(
                          currencyFmt.format(produto.preco),
                          style: GoogleFonts.publicSans(
                            fontSize: 15,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFFec5b13),
                          ),
                        ),

                      const SizedBox(width: 12),

                      // Badges adicionais
                      if (produto.destaque) ...[
                        _SmallBadge(
                            text: '⭐ Destaque',
                            bg: Colors.yellow.shade100,
                            fg: Colors.yellow.shade800),
                        const SizedBox(width: 4),
                      ],
                      if (pEstoqueBaixo) ...[
                        _SmallBadge(
                            text: '⚠️ ${produto.quantidadeEstoque} un.',
                            bg: Colors.amber.shade100,
                            fg: Colors.amber.shade800),
                      ],
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),

            // Ações
            Column(
              children: [
                // Toggle Disponibilidade
                Switch.adaptive(
                  value: pDisponivel,
                  activeTrackColor: const Color(0xFFec5b13),
                  inactiveTrackColor: Colors.grey.shade200,
                  onChanged: (val) {
                    ref
                        .read(produtosControllerProvider.notifier)
                        .toggleDisponibilidade(produto.id, produto.disponivel);
                  },
                ),
                const SizedBox(height: 4),
                // Botão Editar
                InkWell(
                  onTap: () {
                    // Abre o modal de edição com os dados do produto
                    showProdutoFormModal(context, produto: produto);
                  },
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      border: Border.all(color: Colors.grey.shade200),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child:
                        Icon(Icons.edit, size: 18, color: Colors.grey.shade600),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _SmallBadge extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const _SmallBadge({required this.text, required this.bg, required this.fg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: GoogleFonts.publicSans(
            fontSize: 10, fontWeight: FontWeight.bold, color: fg),
      ),
    );
  }
}
