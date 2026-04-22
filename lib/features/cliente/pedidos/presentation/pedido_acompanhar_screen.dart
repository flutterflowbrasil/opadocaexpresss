// ============================================================
// pedido_acompanhar_screen.dart — Acompanhar Pedido
// Rota: /cliente/pedido/:pedidoId
// Escuta realtime na tabela `pedidos` para atualizar o status.
// ============================================================

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

// ─── Paleta ──────────────────────────────────────────────────────────────────
const _primary = Color(0xFFEC5B13);
const _secondary = Color(0xFF7D2D35);
const _green = Color(0xFF22C55E);

// ─── Passos do status (DB → label) ───────────────────────────────────────────
enum _Passo {
  confirmado,
  preparando,
  pronto,
  aCaminho,
  entregue;

  String get label {
    switch (this) {
      case _Passo.confirmado:
        return 'Pedido confirmado';
      case _Passo.preparando:
        return 'Preparando';
      case _Passo.pronto:
        return 'Pronto';
      case _Passo.aCaminho:
        return 'A caminho';
      case _Passo.entregue:
        return 'Entregue';
    }
  }

  String get sublabel {
    switch (this) {
      case _Passo.confirmado:
        return 'Pedido recebido pelo estabelecimento';
      case _Passo.preparando:
        return 'Seu pedido está sendo preparado com carinho';
      case _Passo.pronto:
        return 'Pedido pronto, aguardando entregador';
      case _Passo.aCaminho:
        return 'Entregador a caminho do seu endereço';
      case _Passo.entregue:
        return '🎉 Bom apetite!';
    }
  }

  IconData get icon {
    switch (this) {
      case _Passo.confirmado:
        return Icons.check_circle_outline_rounded;
      case _Passo.preparando:
        return Icons.restaurant_rounded;
      case _Passo.pronto:
        return Icons.inventory_2_outlined;
      case _Passo.aCaminho:
        return Icons.delivery_dining_rounded;
      case _Passo.entregue:
        return Icons.celebration_rounded;
    }
  }
}

_Passo _statusToStep(String status) {
  switch (status) {
    case 'pendente':
      return _Passo.confirmado; // aguardando confirmação do estab
    case 'confirmado':
      return _Passo.confirmado;
    case 'preparando':
      return _Passo.preparando;
    case 'pronto':
      return _Passo.pronto;
    case 'em_entrega':
      return _Passo.aCaminho;
    case 'entregue':
      return _Passo.entregue;
    default:
      return _Passo.confirmado;
  }
}

// ─── Screen ───────────────────────────────────────────────────────────────────
class PedidoAcompanharScreen extends StatefulWidget {
  final String pedidoId;
  const PedidoAcompanharScreen({super.key, required this.pedidoId});

  @override
  State<PedidoAcompanharScreen> createState() => _PedidoAcompanharScreenState();
}

class _PedidoAcompanharScreenState extends State<PedidoAcompanharScreen> {
  bool _loading = true;
  String? _error;

  // Dados do pedido
  int? _numeroPedido;
  String _status = 'confirmado';
  String _pagamentoStatus = 'pendente';
  String _pagamentoMetodo = '';
  double _subtotal = 0;
  double _taxaEntrega = 0;
  double _total = 0;
  String _estabelecimentoNome = '';
  String? _estabelecimentoLogo;
  String _enderecoFormatado = '';
  List<dynamic> _itens = [];
  DateTime? _criadoEm;

  RealtimeChannel? _channel;

  @override
  void initState() {
    super.initState();
    _carregarPedido();
  }

  @override
  void dispose() {
    _channel?.unsubscribe();
    super.dispose();
  }

  Future<void> _carregarPedido() async {
    try {
      final row = await Supabase.instance.client
          .from('pedidos')
          .select('''
            numero_pedido, status, pagamento_status, pagamento_metodo,
            subtotal_produtos, taxa_entrega, total,
            created_at, itens,
            endereco_entrega_snapshot,
            estabelecimentos(nome_fantasia, logo_url)
          ''')
          .eq('id', widget.pedidoId)
          .maybeSingle();

      if (row == null || !mounted) return;

      final estab = (row['estabelecimentos'] as Map?) ?? {};
      final snap = (row['endereco_entrega_snapshot'] as Map?) ?? {};

      setState(() {
        _numeroPedido = row['numero_pedido'] as int?;
        _status = row['status'] as String? ?? 'confirmado';
        _pagamentoStatus = row['pagamento_status'] as String? ?? 'pendente';
        _pagamentoMetodo = row['pagamento_metodo'] as String? ?? '';
        _subtotal = (row['subtotal_produtos'] as num?)?.toDouble() ?? 0;
        _taxaEntrega = (row['taxa_entrega'] as num?)?.toDouble() ?? 0;
        _total = (row['total'] as num?)?.toDouble() ?? 0;
        _estabelecimentoNome =
            estab['nome_fantasia'] as String? ?? 'Estabelecimento';
        _estabelecimentoLogo = estab['logo_url'] as String?;
        _itens = (row['itens'] as List?) ?? [];
        _criadoEm = row['created_at'] != null
            ? DateTime.tryParse(row['created_at'] as String)
            : null;
        _enderecoFormatado = _fmtEndereco(snap);
        _loading = false;
      });

      _assinarRealtime();
    } catch (e) {
      if (mounted) {
        setState(() {
          _loading = false;
          _error = 'Erro ao carregar pedido';
        });
      }
    }
  }

  String _fmtEndereco(Map<dynamic, dynamic> m) {
    final l = m['logradouro'] ?? '';
    final n = m['numero'] ?? '';
    final b = m['bairro'] ?? '';
    final c = m['cidade'] ?? '';
    return '$l${n.toString().isNotEmpty ? ", $n" : ""}'
        '${b.toString().isNotEmpty ? " — $b" : ""}'
        '${c.toString().isNotEmpty ? ", $c" : ""}';
  }

  void _assinarRealtime() {
    _channel = Supabase.instance.client
        .channel('pedido_status_${widget.pedidoId}')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'pedidos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'id',
            value: widget.pedidoId,
          ),
          callback: (payload) {
            if (!mounted) return;
            final novo = payload.newRecord;
            setState(() {
              _status = novo['status'] as String? ?? _status;
              _pagamentoStatus =
                  novo['pagamento_status'] as String? ?? _pagamentoStatus;
            });
          },
        )
        .subscribe();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1917) : const Color(0xFFF8F6F6);

    if (_loading) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _appBar(isDark),
        body: const Center(
          child: CircularProgressIndicator(color: _primary),
        ),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: bg,
        appBar: _appBar(isDark),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 48, color: Colors.red),
              const SizedBox(height: 12),
              Text(_error!, style: GoogleFonts.outfit(fontSize: 15)),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  setState(() {
                    _loading = true;
                    _error = null;
                  });
                  _carregarPedido();
                },
                child: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    final fmt = NumberFormat.simpleCurrency(locale: 'pt_BR');
    final step = _statusToStep(_status);
    final entregue = _status == 'entregue';

    return Scaffold(
      backgroundColor: bg,
      appBar: _appBar(isDark),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header estabelecimento ────────────────────────────────
            _EstabelecimentoHeader(
              nome: _estabelecimentoNome,
              logoUrl: _estabelecimentoLogo,
              numeroPedido: _numeroPedido,
              criadoEm: _criadoEm,
              isDark: isDark,
              entregue: entregue,
            ),
            const SizedBox(height: 20),

            // ── Stepper de status ─────────────────────────────────────
            _buildStepper(step, isDark),
            const SizedBox(height: 20),


            // ── Itens do pedido ───────────────────────────────────────
            _SectionCard(
              title: 'Itens do pedido',
              isDark: isDark,
              child: Column(
                children: [
                  ..._itens.map((item) {
                    final nome =
                        item['produto_nome'] ?? item['nome'] ?? 'Item';
                    final qtd = item['quantidade'] ?? 1;
                    final sub = (item['subtotal'] as num?)?.toDouble() ?? 0;
                    return Padding(
                      padding: const EdgeInsets.symmetric(vertical: 6),
                      child: Row(
                        children: [
                          Text(
                            '${qtd}x',
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: _primary,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              nome,
                              style: GoogleFonts.outfit(
                                fontSize: 13,
                                color: isDark
                                    ? Colors.grey[300]
                                    : Colors.grey[800],
                              ),
                            ),
                          ),
                          Text(
                            fmt.format(sub),
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : _secondary,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                  const Divider(height: 20),
                  _TotalRow('Subtotal', fmt.format(_subtotal),
                      isDark: isDark),
                  const SizedBox(height: 4),
                  _TotalRow(
                      'Taxa de entrega', fmt.format(_taxaEntrega),
                      isDark: isDark),
                  const SizedBox(height: 8),
                  _TotalRow('Total', fmt.format(_total),
                      isDark: isDark, isBold: true),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Endereço de entrega ───────────────────────────────────
            _SectionCard(
              title: 'Endereço de entrega',
              isDark: isDark,
              child: Row(
                children: [
                  const Icon(Icons.location_on_outlined,
                      color: _primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _enderecoFormatado.isEmpty
                          ? 'Endereço não disponível'
                          : _enderecoFormatado,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        color:
                            isDark ? Colors.grey[300] : Colors.grey[700],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),

            // ── Pagamento ─────────────────────────────────────────────
            _SectionCard(
              title: 'Pagamento',
              isDark: isDark,
              child: Row(
                children: [
                  Icon(
                    _pagamentoMetodo == 'pix'
                        ? Icons.pix_outlined
                        : Icons.credit_card_outlined,
                    color: _primary,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    _labelPagamento(_pagamentoMetodo),
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                  ),
                  const Spacer(),
                  _StatusChip(
                    label: _labelPagStatus(_pagamentoStatus),
                    color: _pagamentoStatus == 'confirmado'
                        ? _green
                        : _pagamentoStatus == 'pendente'
                            ? Colors.orange
                            : Colors.red,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            if (entregue)
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/home'),
                  icon: const Icon(Icons.home_outlined, color: Colors.white),
                  label: Text(
                    'Voltar ao início',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primary,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }

  AppBar _appBar(bool isDark) => AppBar(
        backgroundColor:
            isDark ? const Color(0xFF1C1917) : const Color(0xFFF8F6F6),
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new,
              color: isDark ? Colors.white : _secondary, size: 20),
          onPressed: () =>
              context.canPop() ? context.pop() : context.go('/home'),
        ),
        title: Text(
          'Acompanhar Pedido',
          style: GoogleFonts.outfit(
            color: isDark ? Colors.white : _secondary,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
      );

  Widget _buildStepper(_Passo stepAtual, bool isDark) {
    final passos = _Passo.values;
    final indexAtual = passos.indexOf(stepAtual);

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27201A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primary.withValues(alpha: .12),
        ),
      ),
      child: Column(
        children: List.generate(passos.length, (i) {
          final passo = passos[i];
          final done = i < indexAtual;
          final active = i == indexAtual;
          final isLast = i == passos.length - 1;

          final color = done || active
              ? (i == passos.length - 1 && active ? _green : _primary)
              : (isDark ? Colors.grey[700]! : Colors.grey[300]!);

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Linha + Círculo
              Column(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: (done || active)
                          ? color.withValues(alpha: .15)
                          : Colors.transparent,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color,
                        width: active ? 2.5 : 1.5,
                      ),
                    ),
                    child: Icon(
                      done ? Icons.check_rounded : passo.icon,
                      size: 18,
                      color: color,
                    ),
                  ),
                  if (!isLast)
                    Container(
                      width: 2,
                      height: 32,
                      color: done ? _primary : (isDark ? Colors.grey[800]! : Colors.grey[200]!),
                    ),
                ],
              ),
              const SizedBox(width: 14),
              // Texto
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(top: 6, bottom: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        passo.label,
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: active
                              ? FontWeight.bold
                              : FontWeight.w500,
                          color: active
                              ? (isDark ? Colors.white : _secondary)
                              : (done
                                  ? _primary
                                  : (isDark
                                      ? Colors.grey[600]
                                      : Colors.grey[400])),
                        ),
                      ),
                      if (active) ...[
                        const SizedBox(height: 2),
                        Text(
                          passo.sublabel,
                          style: GoogleFonts.outfit(
                            fontSize: 12,
                            color: isDark
                                ? Colors.grey[400]
                                : Colors.grey[600],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  String _labelPagamento(String metodo) {
    switch (metodo) {
      case 'pix':
        return 'Pix';
      case 'cartao_credito':
        return 'Cartão de Crédito';
      case 'cartao_debito':
        return 'Cartão de Débito';
      default:
        return metodo;
    }
  }

  String _labelPagStatus(String status) {
    switch (status) {
      case 'confirmado':
        return 'Pago';
      case 'pendente':
        return 'Aguardando';
      case 'falhou':
        return 'Falhou';
      case 'vencido':
        return 'Vencido';
      default:
        return status;
    }
  }
}

// ─── Widgets auxiliares ──────────────────────────────────────────────────────

class _EstabelecimentoHeader extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final int? numeroPedido;
  final DateTime? criadoEm;
  final bool isDark;
  final bool entregue;

  const _EstabelecimentoHeader({
    required this.nome,
    required this.logoUrl,
    required this.numeroPedido,
    required this.criadoEm,
    required this.isDark,
    required this.entregue,
  });

  @override
  Widget build(BuildContext context) {
    final bg = isDark ? const Color(0xFF27201A) : Colors.white;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(16),
        border:
            Border.all(color: _primary.withValues(alpha: .12)),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Container(
              width: 56,
              height: 56,
              color: Colors.grey[200],
              child: logoUrl != null
                  ? Image.network(logoUrl!, fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          const Icon(Icons.storefront, color: Colors.grey))
                  : const Icon(Icons.storefront, color: Colors.grey),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nome,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : _secondary,
                  ),
                ),
                if (numeroPedido != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Pedido #$numeroPedido',
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      color: _primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                if (criadoEm != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    DateFormat("dd/MM 'às' HH:mm").format(criadoEm!),
                    style: GoogleFonts.outfit(
                      fontSize: 11,
                      color: isDark ? Colors.grey[500] : Colors.grey[500],
                    ),
                  ),
                ],
              ],
            ),
          ),
          if (entregue)
            const Icon(Icons.check_circle_rounded,
                color: _green, size: 28),
        ],
      ),
    );
  }
}

class _SectionCard extends StatelessWidget {
  final String title;
  final Widget child;
  final bool isDark;

  const _SectionCard(
      {required this.title, required this.child, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27201A) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _primary.withValues(alpha: .1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title.toUpperCase(),
            style: GoogleFonts.outfit(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              letterSpacing: 1.2,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 12),
          child,
        ],
      ),
    );
  }
}

class _TotalRow extends StatelessWidget {
  final String label;
  final String value;
  final bool isDark;
  final bool isBold;

  const _TotalRow(this.label, this.value,
      {required this.isDark, this.isBold = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isDark ? Colors.grey[300] : Colors.grey[700],
          ),
        ),
        Text(
          value,
          style: GoogleFonts.outfit(
            fontSize: isBold ? 14 : 12,
            fontWeight: isBold ? FontWeight.bold : FontWeight.normal,
            color: isBold
                ? (isDark ? Colors.white : _secondary)
                : (isDark ? Colors.grey[300] : Colors.grey[700]),
          ),
        ),
      ],
    );
  }
}

class _StatusChip extends StatelessWidget {
  final String label;
  final Color color;

  const _StatusChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: .12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: .4)),
      ),
      child: Text(
        label,
        style: GoogleFonts.outfit(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
