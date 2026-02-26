import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/cliente/componentes/home_header.dart';

import 'package:padoca_express/features/estabelecimento/controllers/estabelecimento_controller.dart';
import 'package:padoca_express/features/estabelecimento/componentes/estabelecimento_header.dart';
import 'package:padoca_express/features/estabelecimento/componentes/pesquisa_filtro_bar.dart';
import 'package:padoca_express/features/estabelecimento/componentes/produto_card.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/carrinho_resumo_botom_bar.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/componentes/cart_conflict_dialog.dart';
import 'package:padoca_express/features/cliente/componentes/produto_simples_dialog.dart';
import 'package:padoca_express/features/cliente/componentes/produto_variavel_dialog.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class EstabelecimentoScreen extends ConsumerWidget {
  final EstabelecimentoModel estabelecimento;

  const EstabelecimentoScreen({
    super.key,
    required this.estabelecimento,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    // Assistir ao estado do controller
    final state =
        ref.watch(estabelecimentoControllerProvider(estabelecimento.id));
    final controller = ref
        .read(estabelecimentoControllerProvider(estabelecimento.id).notifier);

    // O header e filtro devem usar as informações que temos
    // Se o controller carregou os detalhes atualizados, podemos usá-los, senão usamos o original
    final modelAtualizado = state.estabelecimento ?? estabelecimento;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: ClienteAppBar(
          isDark: isDark,
          showBackButton: true), // Mantendo a barra do app requisitada
      bottomNavigationBar: const CarrinhoResumoBottomBar(),
      body: CustomScrollView(
        slivers: [
          // 1. Cabeçalho do Estabelecimento (Hero, Banner, Logo, Infos)
          EstabelecimentoHeader(
            estabelecimento: modelAtualizado,
            isDark: isDark,
          ),

          // 2. Barra de Pesquisa e Filtros (Sticky)
          if (!state.isLoading || state.categorias.isNotEmpty)
            PesquisaFiltroBar(
              isDark: isDark,
              searchQuery: state.searchQuery,
              onSearchChanged: controller.setSearchQuery,
              categorias: state.categorias,
              selectedCategoriaId: state.selectedCategoriaId,
              onCategoriaSelected: controller.selectCategoria,
            ),

          // 3. Status de Carregamento / Erro / Lista de Produtos
          if (state.isLoading)
            const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(color: Color(0xFFFF7034)),
              ),
            )
          else if (state.errorMessage != null)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(24.0),
                  child: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.error_outline_rounded,
                            size: 48, color: Colors.grey[500]),
                        const SizedBox(height: 16),
                        Flexible(
                          child: Text(
                            state.errorMessage!,
                            textAlign: TextAlign.center,
                            style: GoogleFonts.outfit(color: Colors.grey[600]),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            )
          else if (state.produtosFiltrados.isEmpty)
            SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.search_off_rounded,
                          size: 64,
                          color: isDark ? Colors.grey[700] : Colors.grey[300]),
                      const SizedBox(height: 16),
                      Text(
                        state.searchQuery.isNotEmpty
                            ? 'Nenhum produto encontrado na pesquisa.'
                            : 'Nenhum produto cadastrado.',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 40),
              sliver: MediaQuery.of(context).size.width >= 768
                  ? SliverGrid(
                      gridDelegate:
                          const SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 5,
                        mainAxisSpacing: 16,
                        crossAxisSpacing: 16,
                        childAspectRatio: 0.85,
                      ),
                      delegate: _buildChildDelegate(state.produtosFiltrados,
                          modelAtualizado, isDark, true),
                    )
                  : SliverList(
                      delegate: _buildChildDelegate(state.produtosFiltrados,
                          modelAtualizado, isDark, false),
                    ),
            ),
        ],
      ),
    );
  }

  SliverChildBuilderDelegate _buildChildDelegate(List<ProdutoModel> produtos,
      EstabelecimentoModel modelAtualizado, bool isDark, bool isGrid) {
    return SliverChildBuilderDelegate(
      (context, index) {
        final produto = produtos[index];
        return Padding(
          padding: EdgeInsets.only(bottom: isGrid ? 0 : 16),
          child: Consumer(
            builder: (context, ref, child) {
              void processAddLogic() {
                if (produto.tipoProduto == 'variavel') {
                  showDialog(
                    context: context,
                    builder: (context) => ProdutoVariavelDialog(
                      produto: produto,
                      estabelecimento: modelAtualizado,
                      onAddTap: (qtd, obs, selecoes) {
                        String formatObs = obs;
                        double adicionais = 0;
                        if (selecoes.isNotEmpty) {
                          final opts = selecoes
                              .map((s) => '${s['grupo']}: ${s['nome']}')
                              .join(', ');
                          formatObs = formatObs.isEmpty
                              ? opts
                              : '$opts\nObs: $formatObs';
                          for (var s in selecoes) {
                            adicionais +=
                                (s['preco_adicional'] as double? ?? 0);
                          }
                        }

                        final modProd = ProdutoModel(
                          id: produto.id,
                          estabelecimentoId: produto.estabelecimentoId,
                          nome: produto.nome,
                          descricao: produto.descricao,
                          preco: produto.preco + adicionais,
                          precoPromocional: produto.precoPromocional != null
                              ? produto.precoPromocional! + adicionais
                              : null,
                          imagemUrl: produto.imagemUrl,
                          isAtivo: produto.isAtivo,
                          permiteObservacoes: produto.permiteObservacoes,
                          categoriaCardapioId: produto.categoriaCardapioId,
                          tipoProduto: produto.tipoProduto,
                          opcoes: produto.opcoes,
                        );

                        ref
                            .read(carrinhoControllerProvider.notifier)
                            .adicionarProduto(
                              modProd,
                              qtd,
                              observacao: formatObs,
                              estabelecimento: modelAtualizado,
                            );
                      },
                    ),
                  );
                } else {
                  showDialog(
                    context: context,
                    builder: (context) => ProdutoSimplesDialog(
                      produto: produto,
                      estabelecimento: modelAtualizado,
                      onAddTap: (qtd, obs) {
                        ref
                            .read(carrinhoControllerProvider.notifier)
                            .adicionarProduto(
                              produto,
                              qtd,
                              observacao: obs,
                              estabelecimento: modelAtualizado,
                            );
                      },
                    ),
                  );
                }
              }

              void handleAddToCart() {
                final carrinhoAtual = ref.read(carrinhoControllerProvider);
                if (carrinhoAtual.estabelecimento != null &&
                    carrinhoAtual.estabelecimento!.id != modelAtualizado.id &&
                    carrinhoAtual.itens.isNotEmpty) {
                  showDialog(
                    context: context,
                    builder: (context) => CartConflictDialog(
                      newEstabelecimento: modelAtualizado,
                      onConfirm: () {
                        ref
                            .read(carrinhoControllerProvider.notifier)
                            .limparCarrinho();
                        processAddLogic();
                      },
                    ),
                  );
                } else {
                  processAddLogic();
                }
              }

              return ProdutoCard(
                produto: produto,
                isDark: isDark,
                isGrid: isGrid,
                onTap: () {
                  // TODO: Screen de detalhes do produto standalone, por enquanto usamos o mesmo dialog visualmente para exibir, ou ignoramos e exigimos tap no +?
                  // Deixarei chamando a mesma action de handleAddToCart temporariamente.
                  handleAddToCart();
                },
                onAddTap: handleAddToCart,
              );
            },
          ),
        );
      },
      childCount: produtos.length,
    );
  }
}
