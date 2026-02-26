import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/item_carrinho_card.dart';

class CarrinhoScreen extends ConsumerWidget {
  const CarrinhoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final estadoCarrinho = ref.watch(carrinhoControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final _primaryColor = const Color(0xFFFF7034);

    if (estadoCarrinho.itens.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : Colors.black87, size: 20),
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Meu Carrinho',
            style: GoogleFonts.outfit(
                color: isDark ? Colors.white : Colors.black87,
                fontWeight: FontWeight.bold),
          ),
        ),
        body: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.shopping_bag_outlined,
                  size: 80, color: Colors.grey[400]),
              const SizedBox(height: 16),
              Text(
                'Seu carrinho está vazio',
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bateu uma fome? Adicione itens!',
                style: GoogleFonts.outfit(color: Colors.grey[500]),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: () {
                  context.go('/home');
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
                child: Text('Explorar outros locais',
                    style: GoogleFonts.outfit(
                        color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      );
    }

    final estabelecimento = estadoCarrinho.estabelecimento!;
    final taxaEntrega =
        estabelecimento.configEntrega?['taxa_entrega_fixa'] ?? 0.0;
    final subtotal = estadoCarrinho.valorTotalProdutos;
    final total = estadoCarrinho.valorTotal;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : Colors.black87, size: 20),
          onPressed: () {
            context.go('/estabelecimento/${estabelecimento.id}',
                extra: estabelecimento);
          },
        ),
        title: Text(
          'Meu Carrinho',
          style: GoogleFonts.outfit(
              color: isDark ? Colors.white : Colors.black87,
              fontWeight: FontWeight.bold),
        ),
        actions: [
          TextButton(
            onPressed: () {
              ref.read(carrinhoControllerProvider.notifier).limparCarrinho();
            },
            child: Text(
              'Limpar',
              style: GoogleFonts.outfit(
                  color: Colors.red[400], fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Seu pedido em',
                    style: GoogleFonts.outfit(
                        fontSize: 14, color: Colors.grey[500]),
                  ),
                  Text(
                    estabelecimento.nome,
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
              ),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  return ItemCarrinhoCard(
                    item: estadoCarrinho.itens[index],
                    isDark: isDark,
                  );
                },
                childCount: estadoCarrinho.itens.length,
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  const Divider(),
                  const SizedBox(height: 16),
                  _buildResumoRow('Subtotal', subtotal, isDark: isDark),
                  const SizedBox(height: 8),
                  _buildResumoRow('Taxa de entrega', taxaEntrega,
                      isDark: isDark),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Total',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                      Text(
                        'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                        style: GoogleFonts.outfit(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: _primaryColor,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 100), // Espaço pro BottomBar
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF27272A) : Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: ElevatedButton(
            onPressed: estabelecimento.statusAberto
                ? () async {
                    // Validar no DB antes de seguir (Anti-fraude de horarios)
                    try {
                      final isOpenResponse =
                          await ref.read(supabaseClientProvider).rpc(
                        'verificar_estabelecimento_aberto',
                        params: {'estab_id': estabelecimento.id},
                      );

                      // Se a function retornar true, ou der erro e precisarmos seguir
                      if (isOpenResponse == true) {
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Fluxo de pagamento em diante aberto e verificado!'),
                              backgroundColor: Color(0xFFFF7034),
                            ),
                          );
                        }
                      } else {
                        // Estabelecimento fechou no meio do caminho
                        if (context.mounted) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text(
                                  'Me perdoe, o estabelecimento acabou de fechar :('),
                              backgroundColor: Colors.red,
                            ),
                          );
                        }
                      }
                    } catch (e) {
                      // Fallback: mostrar erro, mas para debug prosseguimos placeholder
                      debugPrint('Erro validando loja fechada: $e');
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                                'Falha na conexão: Fluxo de pagamento em breve!'),
                            backgroundColor: Colors.grey[700],
                          ),
                        );
                      }
                    }
                  }
                : null,
            style: ElevatedButton.styleFrom(
              backgroundColor: estabelecimento.statusAberto
                  ? _primaryColor
                  : Colors.grey[400],
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              estabelecimento.statusAberto
                  ? 'Ir para pagamento'
                  : 'Estabelecimento Fechado',
              style: GoogleFonts.outfit(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildResumoRow(String title, double valor, {required bool isDark}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 15,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        Text(
          valor == 0
              ? 'Grátis'
              : 'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: GoogleFonts.outfit(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: isDark ? Colors.white : Colors.black87,
          ),
        ),
      ],
    );
  }
}
