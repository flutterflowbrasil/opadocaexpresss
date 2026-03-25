import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/resumo_pedido_card.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/metodo_pagamento_card.dart';
import 'package:padoca_express/features/cliente/carrinho/componentes/endereco_entrega_card.dart';
import 'package:padoca_express/features/cliente/localizacao/endereco_model.dart';
import 'package:padoca_express/features/cliente/localizacao/selecionar_endereco_modal.dart';
import 'package:padoca_express/features/cliente/pagamento/controllers/pagamento_controller.dart';
import 'package:padoca_express/features/cliente/pagamento/state/pagamento_state.dart';
import 'package:padoca_express/features/cliente/pagamento/presentation/cartao_pagamento_modal.dart';

class FinalizarPedidoScreen extends ConsumerStatefulWidget {
  const FinalizarPedidoScreen({super.key});

  @override
  ConsumerState<FinalizarPedidoScreen> createState() =>
      _FinalizarPedidoScreenState();
}

class _FinalizarPedidoScreenState extends ConsumerState<FinalizarPedidoScreen> {
  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  String? _metodoPagamentoSelecionado;
  EnderecoCliente? _enderecoSelecionado;
  bool _carregandoEndereco = true;

  @override
  void initState() {
    super.initState();
    _buscarEnderecoPrimario();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(pagamentoControllerProvider.notifier).verificarPixPendente();
    });
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
              _enderecoSelecionado = EnderecoCliente.fromJson(enderecosData);
            });
          }
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar endereço: $e");
    } finally {
      if (mounted) {
        setState(() {
          _carregandoEndereco = false;
        });
      }
    }
  }

  Future<void> _abrirSelecaoEndereco() async {
    final selecionado = await SelecionarEnderecoModal.show(context);
    if (selecionado != null && mounted) {
      setState(() => _enderecoSelecionado = selecionado);
    }
  }

  Future<void> _finalizarPedido() async {
    final carrinho = ref.read(carrinhoControllerProvider);
    final metodo = _metodoPagamentoSelecionado!;
    final endereco = _enderecoSelecionado!;

    if (metodo == 'pix_site') {
      await ref.read(pagamentoControllerProvider.notifier).finalizarPedido(
            carrinho: carrinho,
            endereco: endereco,
            metodoPagamento: 'pix',
          );
    } else {
      // Cartão: abre modal para coletar dados
      if (!mounted) return;
      final dadosCartao = await CartaoPagamentoModal.show(context);
      if (dadosCartao == null || !mounted) return;

      await ref.read(pagamentoControllerProvider.notifier).finalizarPedido(
            carrinho: carrinho,
            endereco: endereco,
            metodoPagamento:
                dadosCartao.isCredito ? 'cartao_credito' : 'cartao_debito',
            dadosCartao: dadosCartao,
          );
    }
  }

  @override
  Widget build(BuildContext context) {
    final estadoCarrinho = ref.watch(carrinhoControllerProvider);
    final pagamentoState = ref.watch(pagamentoControllerProvider);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);
    final bgSecColor =
        isDark ? const Color(0xFF27272A) : const Color(0xFFFFFFFF);

    // Reagir a mudanças de status do pagamento
    ref.listen<PagamentoState>(pagamentoControllerProvider, (_, next) {
      if (!mounted) return;

      if (next.status == PagamentoStatus.aguardandoPix &&
          next.cobranca != null) {
        context.go('/pagamento/pix', extra: {
          'pedidoId': next.pedidoCriadoId ?? '',
          'pixCopiaECola': next.cobranca!.pixCopiaECola ?? '',
          'pixQrCode': next.cobranca!.pixQrCode,
          'segundosRestantes': next.segundosRestantes ?? 300,
        });
      } else if (next.status == PagamentoStatus.confirmado) {
        context.go('/pagamento/sucesso',
            extra: {'pedidoId': next.pedidoCriadoId ?? ''});
      } else if (next.status == PagamentoStatus.erro &&
          next.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.errorMessage!,
                style: GoogleFonts.outfit()),
            backgroundColor: Colors.red[400],
          ),
        );
        ref.read(pagamentoControllerProvider.notifier).limparErro();
      }
    });

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
    final taxaEntrega = estabelecimento.taxaEntregaValor;
    final total = estadoCarrinho.valorTotal;
    final isValid =
        _enderecoSelecionado != null && _metodoPagamentoSelecionado != null;
    final isSubmitting = pagamentoState.isSubmitting;

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
      bottomSheet:
          _buildBottomConfirmBar(isDark, total, isValid, isSubmitting),
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
            onAdicionar: _abrirSelecaoEndereco,
            onTrocar: _abrirSelecaoEndereco,
          ),
        const SizedBox(height: 24),
        _buildSectionTitle('FORMA DE PAGAMENTO', isDark),
        const SizedBox(height: 16),
        _buildPagamentoOnline(isDark, bgSecColor),
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

  Widget _buildPagamentoOnline(bool isDark, Color bgSecColor) {
    return Column(
      children: [
        MetodoPagamentoSiteCard(
          id: 'cartao_site',
          isDark: isDark,
          bgSecColor: bgSecColor,
          selected: _metodoPagamentoSelecionado == 'cartao_site',
          icon: const Icon(Icons.credit_card, color: _primaryColor),
          title: 'Cartão Crédito / Débito',
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

  Widget _buildBottomConfirmBar(
      bool isDark, double total, bool isValid, bool isSubmitting) {
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
          onPressed: isValid && !isSubmitting ? _finalizarPedido : null,
          style: ElevatedButton.styleFrom(
            backgroundColor: _primaryColor,
            disabledBackgroundColor: Colors.grey[400],
            padding: const EdgeInsets.symmetric(vertical: 16),
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            elevation: isValid ? 8 : 0,
            shadowColor: _primaryColor.withValues(alpha: 0.4),
          ),
          child: isSubmitting
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                      strokeWidth: 2, color: Colors.white),
                )
              : Row(
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
