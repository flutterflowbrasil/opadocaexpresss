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
import 'package:padoca_express/features/cliente/pagamento/models/dados_cartao_model.dart';
import 'package:intl/intl.dart';

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
    final metodo = _metodoPagamentoSelecionado!;

    DadosCartaoModel? dadosCartao;
    if (metodo == 'cartao_site') {
      // 1. Coleta dados do cartão
      if (!mounted) return;
      dadosCartao = await CartaoPagamentoModal.show(context);
      if (dadosCartao == null || !mounted) return;
    }

    // 2. Exibe modal de confirmação com endereço + método antes de processar
    final confirmed = await _mostrarConfirmacaoPedido(dadosCartao: dadosCartao);
    if (!confirmed || !mounted) return;

    // 3. Processa pagamento
    final carrinho = ref.read(carrinhoControllerProvider);
    final endereco = _enderecoSelecionado!;

    if (metodo == 'pix_site') {
      await ref.read(pagamentoControllerProvider.notifier).finalizarPedido(
            carrinho: carrinho,
            endereco: endereco,
            metodoPagamento: 'pix',
          );
    } else {
      await ref.read(pagamentoControllerProvider.notifier).finalizarPedido(
            carrinho: carrinho,
            endereco: endereco,
            metodoPagamento:
                dadosCartao!.isCredito ? 'cartao_credito' : 'cartao_debito',
            dadosCartao: dadosCartao,
          );
    }
  }

  Future<bool> _mostrarConfirmacaoPedido(
      {DadosCartaoModel? dadosCartao}) async {
    final carrinho = ref.read(carrinhoControllerProvider);
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => _ConfirmacaoPedidoSheet(
        endereco: _enderecoSelecionado!,
        metodo: _metodoPagamentoSelecionado!,
        dadosCartao: dadosCartao,
        subtotal: carrinho.valorTotalProdutos,
        taxaEntrega: carrinho.estabelecimento?.taxaEntregaValor ?? 0,
        total: carrinho.valorTotal,
      ),
    );
    return result == true;
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
        final pid = next.pedidoCriadoId ?? '';
        if (pid.isNotEmpty) {
          context.go('/cliente/pedido/$pid');
        } else {
          context.go('/cliente/pedidos');
        }
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

// ─────────────────────────────────────────────────────────────────────────────
// Modal de confirmação do pedido
// ─────────────────────────────────────────────────────────────────────────────
class _ConfirmacaoPedidoSheet extends StatelessWidget {
  final EnderecoCliente endereco;
  final String metodo;
  final DadosCartaoModel? dadosCartao;
  final double subtotal;
  final double taxaEntrega;
  final double total;

  static const _primary = Color(0xFFFF7034);
  static const _secondary = Color(0xFF7D2D35);

  const _ConfirmacaoPedidoSheet({
    required this.endereco,
    required this.metodo,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
    this.dadosCartao,
  });

  String get _labelMetodo {
    if (metodo == 'pix_site') return 'Pix';
    if (dadosCartao != null) {
      final tipo = dadosCartao!.isCredito ? 'Crédito' : 'Débito';
      return 'Cartão de $tipo';
    }
    return 'Cartão';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1917) : Colors.white;
    final fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24, 20, 24, MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: .3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Confirmar Pedido',
            style: GoogleFonts.outfit(
              fontSize: 20, fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : _secondary,
            ),
          ),
          const SizedBox(height: 20),

          // Endereço
          _SectionRow(
            icon: Icons.location_on_outlined,
            label: 'Entrega em',
            value: '${endereco.logradouro}, ${endereco.numero} — ${endereco.bairro}',
            isDark: isDark,
          ),
          const SizedBox(height: 14),

          // Pagamento
          _SectionRow(
            icon: metodo == 'pix_site'
                ? Icons.pix_outlined
                : Icons.credit_card_outlined,
            label: 'Pagamento',
            value: _labelMetodo,
            isDark: isDark,
          ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: .15)),
          const SizedBox(height: 12),

          // Valores
          _ValorRow('Subtotal', fmt.format(subtotal), isDark: isDark),
          const SizedBox(height: 8),
          _ValorRow('Taxa de entrega', fmt.format(taxaEntrega), isDark: isDark),
          const SizedBox(height: 8),
          _ValorRow(
            'Total',
            fmt.format(total),
            isDark: isDark,
            isBold: true,
            color: _primary,
          ),
          const SizedBox(height: 24),

          // Botão confirmar
          SizedBox(
            width: double.infinity,
            height: 54,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 4,
                shadowColor: _primary.withValues(alpha: .35),
              ),
              child: Text(
                'Confirmar Pedido',
                style: GoogleFonts.outfit(
                  fontSize: 16, fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: Text(
                'Cancelar',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool isDark;

  const _SectionRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20,
            color: isDark ? Colors.grey[400] : Colors.grey[600]),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label,
                  style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[500])),
              const SizedBox(height: 2),
              Text(value,
                  style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF7D2D35))),
            ],
          ),
        ),
      ],
    );
  }
}

class _ValorRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isBold;
  final Color? color;

  const _ValorRow(this.label, this.value,
      {required this.isDark, this.isBold = false, this.color});

  @override
  Widget build(BuildContext context) {
    final textColor = color ??
        (isDark
            ? (isBold ? Colors.white : Colors.grey[300])
            : (isBold ? const Color(0xFF7D2D35) : Colors.grey[700]));
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: GoogleFonts.outfit(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor)),
        Text(value,
            style: GoogleFonts.outfit(
                fontSize: isBold ? 15 : 13,
                fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
                color: textColor)),
      ],
    );
  }
}
