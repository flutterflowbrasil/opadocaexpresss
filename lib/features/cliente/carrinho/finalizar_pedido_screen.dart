import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/resumo_pedido_card.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/metodo_pagamento_card.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/endereco_entrega_card.dart';
import 'package:padoca_express/features/cliente/carrinho/models/endereco_model.dart';

class FinalizarPedidoScreen extends ConsumerStatefulWidget {
  const FinalizarPedidoScreen({super.key});

  @override
  ConsumerState<FinalizarPedidoScreen> createState() =>
      _FinalizarPedidoScreenState();
}

class _FinalizarPedidoScreenState extends ConsumerState<FinalizarPedidoScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  int _selectedTabIndex = 0;
  String? _metodoPagamentoSelecionado; // Site ou Entrega
  EnderecoClienteModel? _enderecoSelecionado;
  bool _carregandoEndereco = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _selectedTabIndex = _tabController.index;
        _metodoPagamentoSelecionado = null; // Reseta seleção ao mudar a aba
      });
    });
    _buscarEnderecoPrimario();
  }

  Future<void> _buscarEnderecoPrimario() async {
    try {
      final user = Supabase.instance.client.auth.currentUser;
      if (user != null) {
        final clientesData = await Supabase.instance.client
            .from('clientes')
            .select('id')
            .eq('usuario_id', user.id)
            .maybeSingle();

        if (clientesData != null) {
          final clienteId = clientesData['id'];
          final enderecosData = await Supabase.instance.client
              .from('enderecos_clientes')
              .select('*')
              .eq('cliente_id', clienteId)
              .order('is_padrao', ascending: false)
              .limit(1)
              .maybeSingle();

          if (enderecosData != null) {
            setState(() {
              _enderecoSelecionado =
                  EnderecoClienteModel.fromJson(enderecosData);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar endereço: \$e");
    } finally {
      if (mounted) {
        setState(() {
          _carregandoEndereco = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final estadoCarrinho = ref.watch(carrinhoControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final bgSecColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF);

    final estabelecimento = estadoCarrinho.estabelecimento;

    if (estabelecimento == null || estadoCarrinho.itens.isEmpty) {
      return Scaffold(
        backgroundColor: bgColor,
        body: const Center(
          child: Text('Carrinho vazio ou sem estabelecimento'),
        ),
      );
    }

    final subtotal = estadoCarrinho.valorTotalProdutos;
    final taxaEntrega =
        estabelecimento.configEntrega?['taxa_entrega_fixa'] ?? 0.0;
    final total = estadoCarrinho.valorTotal;
    // O botão está ativo apenas se endereço foi carregado e não for nulo e o pagamento foi escolhido
    final isValid =
        _enderecoSelecionado != null && _metodoPagamentoSelecionado != null;

    final isDesktop = MediaQuery.of(context).size.width >= 900;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : _secondaryColor, size: 20),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Finalizar Pedido',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : _secondaryColor,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.0),
          child: Container(
            color: _primaryColor.withValues(alpha: 0.1),
            height: 1.0,
          ),
        ),
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          if (isDesktop) {
            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 6,
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildLeftColumn(isDark, bgSecColor),
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: SingleChildScrollView(
                    padding:
                        const EdgeInsets.only(top: 24, right: 24, bottom: 120),
                    child: ResumoPedidoCard(
                      estadoCarrinho: estadoCarrinho,
                      isDark: isDark,
                      subtotal: subtotal,
                      taxaEntrega: taxaEntrega,
                      total: total,
                    ),
                  ),
                ),
              ],
            );
          }

          // Mobile View
          return SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: _buildLeftColumn(isDark, bgSecColor),
                ),
                ResumoPedidoCard(
                  estadoCarrinho: estadoCarrinho,
                  isDark: isDark,
                  subtotal: subtotal,
                  taxaEntrega: taxaEntrega,
                  total: total,
                ),
              ],
            ),
          );
        },
      ),
      bottomSheet: _buildBottomConfirmBar(isDark, total, isValid),
    );
  }

  Widget _buildLeftColumn(bool isDark, Color bgSecColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionTitle('ENDEREÇO DE ENTREGA', isDark),
        const SizedBox(height: 12),
        if (_carregandoEndereco)
          const Center(child: CircularProgressIndicator())
        else
          EnderecoEntregaCard(
            isDark: isDark,
            bgSecColor: bgSecColor,
            endereco: _enderecoSelecionado,
            onAdicionar: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text(
                        'Ação: Adicionar Endereço via Google Maps/Formulário')),
              );
            },
            onTrocar: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                    content: Text('Ação: Trocar Endereço Selecionado')),
              );
            },
          ),
        const SizedBox(height: 24),
        _buildSectionTitle('FORMA DE PAGAMENTO', isDark),
        const SizedBox(height: 12),
        _buildTabsToggle(isDark),
        const SizedBox(height: 16),
        _selectedTabIndex == 0
            ? _buildTabPeloSite(isDark, bgSecColor)
            : _buildTabNaEntrega(isDark, bgSecColor),
      ],
    );
  }

  Widget _buildSectionTitle(String title, bool isDark) {
    return Text(
      title,
      style: GoogleFonts.outfit(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: isDark ? _primaryColor : _secondaryColor,
        letterSpacing: 1.0,
      ),
    );
  }

  Widget _buildTabsToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark
            ? _secondaryColor.withValues(alpha: 0.2)
            : _secondaryColor.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          color: isDark ? _primaryColor : Colors.white,
          borderRadius: BorderRadius.circular(8),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 4,
                offset: const Offset(0, 2),
              ),
          ],
        ),
        dividerColor: Colors.transparent,
        labelColor: isDark ? Colors.white : _secondaryColor,
        unselectedLabelColor:
            isDark ? Colors.grey[400] : _secondaryColor.withValues(alpha: 0.6),
        labelStyle:
            GoogleFonts.outfit(fontWeight: FontWeight.bold, fontSize: 14),
        tabs: const [
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.language, size: 18),
                SizedBox(width: 8),
                Text('Pelo site'),
              ],
            ),
          ),
          Tab(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.delivery_dining, size: 18),
                SizedBox(width: 8),
                Text('Na entrega'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabPeloSite(bool isDark, Color bgSecColor) {
    return Column(
      children: [
        MetodoPagamentoSiteCard(
          id: 'cartao_credito_site',
          isDark: isDark,
          bgSecColor: bgSecColor,
          selected: _metodoPagamentoSelecionado == 'cartao_credito_site',
          icon: const Icon(Icons.credit_card, color: _primaryColor),
          title: 'Cartão de Crédito',
          subtitle: '•••• •••• •••• 4242',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
        const SizedBox(height: 12),
        MetodoPagamentoSiteCard(
          id: 'pix_site',
          isDark: isDark,
          bgSecColor: bgSecColor,
          selected: _metodoPagamentoSelecionado == 'pix_site',
          icon: Image.asset(
            'assets/imagens/99478349-ff1b1280-2932-11eb-8776-1942bbe1a52a.png',
            width: 24,
            height: 24,
            errorBuilder: (_, __, ___) =>
                const Icon(Icons.pix_outlined, color: _primaryColor),
          ),
          title: 'Pix',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
      ],
    );
  }

  Widget _buildTabNaEntrega(bool isDark, Color bgSecColor) {
    // Agora utilizamos Column / Wrap ao inves de GridView pra ter cards mais finos (altura controlada em MetodoPagamentoCard = 56)
    return Column(
      children: [
        MetodoPagamentoCard(
          id: 'dinheiro_entrega',
          isDark: isDark,
          bgSecColor: bgSecColor,
          icon: const Icon(Icons.payments, color: Colors.green),
          title: 'Dinheiro',
          selected: _metodoPagamentoSelecionado == 'dinheiro_entrega',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
        const SizedBox(height: 12),
        MetodoPagamentoCard(
          id: 'master_debito_entrega',
          isDark: isDark,
          bgSecColor: bgSecColor,
          icon: const Icon(Icons.credit_card, color: Colors.redAccent),
          title: 'Mastercard - Débito',
          selected: _metodoPagamentoSelecionado == 'master_debito_entrega',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
        const SizedBox(height: 12),
        MetodoPagamentoCard(
          id: 'visa_debito_entrega',
          isDark: isDark,
          bgSecColor: bgSecColor,
          icon: const Icon(Icons.credit_card, color: Colors.blueAccent),
          title: 'Visa - Débito',
          selected: _metodoPagamentoSelecionado == 'visa_debito_entrega',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
        const SizedBox(height: 12),
        MetodoPagamentoCard(
          id: 'elo_debito_entrega',
          isDark: isDark,
          bgSecColor: bgSecColor,
          icon: const Icon(Icons.credit_card, color: Colors.grey),
          title: 'Elo - Débito',
          selected: _metodoPagamentoSelecionado == 'elo_debito_entrega',
          onSelected: (id) => setState(() => _metodoPagamentoSelecionado = id),
        ),
      ],
    );
  }

  Widget _buildBottomConfirmBar(bool isDark, double total, bool isValid) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF1C1917).withValues(alpha: 0.9)
            : Colors.white.withValues(alpha: 0.9),
        border: Border(
            top: BorderSide(color: _primaryColor.withValues(alpha: 0.1))),
      ),
      child: SafeArea(
        child: ElevatedButton(
          onPressed: isValid
              ? () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Processando Pedido...')),
                  );
                }
              : null, // Desabilita o botão
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            disabledBackgroundColor:
                Colors.grey[400], // Cor quando desabilitado
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isValid ? 8 : 0,
            shadowColor: _primaryColor.withValues(alpha: 0.4),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Finalizar Pedido',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 8),
              const Icon(Icons.chevron_right, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }
}
