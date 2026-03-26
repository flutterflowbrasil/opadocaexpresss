// ============================================================
// carteira_screen.dart — Carteira do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/financeiro
// Tabelas: entregador_saldos, entregador_saques,
//          splits_pagamento, entregador_bonificacoes
// Edge Function: solicitar-saque
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg0 = Color(0xFF0A0704);
const _bg2 = Color(0xFF1C1510);
const _bg3 = Color(0xFF251C14);
const _card = Color(0xFF1A1510);
const _orange = Color(0xFFF97316);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);
const _yellow = Color(0xFFFBBF24);
const _text1 = Color(0xFFFAFAF9);
const _text2 = Color(0xA6FAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

// ─── Modelo ────────────────────────────────────────────────────────────────
class _Movimentacao {
  final String tipo; // 'credito' | 'saque'
  final double valor;
  final String descricao, data, status;

  const _Movimentacao({
    required this.tipo,
    required this.valor,
    required this.descricao,
    required this.data,
    required this.status,
  });
}

// ═══════════════════════════════════════════════════════════════════════════
// SCREEN
// ═══════════════════════════════════════════════════════════════════════════
class CarteiraScreen extends StatefulWidget {
  const CarteiraScreen({super.key});

  @override
  State<CarteiraScreen> createState() => _CarteiraScreenState();
}

class _CarteiraScreenState extends State<CarteiraScreen> with SingleTickerProviderStateMixin {
  bool _loading = true;
  double _saldoDisponivel = 0;
  double _saldoBloqueado = 0;
  double _totalGanho = 0;
  double _totalSacado = 0;
  String? _entregadorId;
  String? _pixChave;
  String _pixTipo = 'cpf';

  List<_Movimentacao> _movimentacoes = [];

  RealtimeChannel? _saldoChannel;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 2, vsync: this);
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    try {
      final ent = await Supabase.instance.client
          .from('entregadores')
          .select('id, dados_bancarios')
          .eq('usuario_id', uid)
          .maybeSingle();

      _entregadorId = ent?['id'];

      final db = (ent?['dados_bancarios'] as Map?) ?? {};
      _pixChave = db['pix_chave'];
      _pixTipo = db['pix_tipo'] ?? 'cpf';

      if (_entregadorId == null) return;

      final saldo = await Supabase.instance.client
          .from('entregador_saldos')
          .select()
          .eq('entregador_id', _entregadorId!)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        _saldoDisponivel = (saldo?['saldo_disponivel'] as num?)?.toDouble() ?? 0;
        _saldoBloqueado = (saldo?['saldo_bloqueado'] as num?)?.toDouble() ?? 0;
        _totalGanho = (saldo?['total_ganho'] as num?)?.toDouble() ?? 0;
        _totalSacado = (saldo?['total_sacado'] as num?)?.toDouble() ?? 0;
      });

      await _carregarMovimentacoes();
      _iniciarRealtime();
    } catch (e) {
      debugPrint('[Carteira] $e');
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _carregarMovimentacoes() async {
    if (_entregadorId == null) return;

    final splits = await Supabase.instance.client
        .from('splits_pagamento')
        .select(
          'entregador_taxa_entrega_valor, entregador_valor_extra, created_at, pedidos(numero_pedido)',
        )
        .eq('entregador_id', _entregadorId!)
        .order('created_at', ascending: false)
        .limit(20);

    final saques = await Supabase.instance.client
        .from('entregador_saques')
        .select()
        .eq('entregador_id', _entregadorId!)
        .order('solicitado_em', ascending: false)
        .limit(20);

    final bonifs = await Supabase.instance.client
        .from('entregador_bonificacoes')
        .select()
        .eq('entregador_id', _entregadorId!)
        .order('created_at', ascending: false)
        .limit(10);

    if (!mounted) return;

    final List<_Movimentacao> lista = [];

    for (final s in splits) {
      final v = ((s['entregador_taxa_entrega_valor'] as num?)?.toDouble() ?? 0) +
          ((s['entregador_valor_extra'] as num?)?.toDouble() ?? 0);
      final num_ = s['pedidos']?['numero_pedido'];
      lista.add(_Movimentacao(
        tipo: 'credito',
        valor: v,
        descricao: 'Entrega #${num_ ?? '?'}',
        data: _fmtData(s['created_at']),
        status: 'concluido',
      ));
    }

    for (final s in saques) {
      lista.add(_Movimentacao(
        tipo: 'saque',
        valor: (s['valor'] as num).toDouble(),
        descricao: 'Saque PIX',
        data: _fmtData(s['solicitado_em']),
        status: s['status'] ?? 'pendente',
      ));
    }

    for (final b in bonifs) {
      lista.add(_Movimentacao(
        tipo: 'credito',
        valor: (b['valor'] as num).toDouble(),
        descricao: b['descricao'] ?? 'Bonificação',
        data: _fmtData(b['created_at']),
        status: 'concluido',
      ));
    }

    lista.sort((a, b) => b.data.compareTo(a.data));
    setState(() => _movimentacoes = lista);
  }

  void _iniciarRealtime() {
    if (_entregadorId == null) return;
    _saldoChannel = Supabase.instance.client
        .channel('carteira-$_entregadorId')
        .onPostgresChanges(
          event: PostgresChangeEvent.update,
          schema: 'public',
          table: 'entregador_saldos',
          filter: PostgresChangeFilter(
            type: PostgresChangeFilterType.eq,
            column: 'entregador_id',
            value: _entregadorId!,
          ),
          callback: (p) {
            if (!mounted) return;
            setState(() {
              _saldoDisponivel =
                  (p.newRecord['saldo_disponivel'] as num?)?.toDouble() ?? _saldoDisponivel;
              _saldoBloqueado =
                  (p.newRecord['saldo_bloqueado'] as num?)?.toDouble() ?? _saldoBloqueado;
            });
          },
        )
        .subscribe();
  }

  String _fmtData(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  void _abrirSaque() {
    if (_saldoDisponivel < 10) {
      _mostrarErro('Saldo mínimo para saque é R\$ 10,00');
      return;
    }
    if (_pixChave == null || _pixChave!.isEmpty) {
      _mostrarErro('Cadastre sua chave PIX no perfil antes de sacar.');
      return;
    }
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => _SaqueSheet(
        saldoDisponivel: _saldoDisponivel,
        pixChave: _pixChave!,
        pixTipo: _pixTipo,
        entregadorId: _entregadorId!,
        onSucesso: () {
          _carregar();
          _mostrarSucesso('Saque solicitado! Será processado em instantes.');
        },
      ),
    );
  }

  void _mostrarErro(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: _red,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

  void _mostrarSucesso(String msg) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(msg),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );

  @override
  void dispose() {
    _tabCtrl.dispose();
    _saldoChannel?.unsubscribe();
    super.dispose();
  }

  // ══════════════════════════════════════════════════════════════════════════
  // BUILD
  // ══════════════════════════════════════════════════════════════════════════
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: _bg2,
                        border: Border.all(color: _border),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Center(
                        child: Icon(Icons.arrow_back_ios_new_rounded, color: _text1, size: 16),
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Text(
                    'Carteira',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _text1,
                    ),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: _green.withValues(alpha: .1),
                      border: Border.all(color: _green.withValues(alpha: .25)),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(color: _green, shape: BoxShape.circle),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'PIX Disponível',
                          style: GoogleFonts.dmSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5)),
              )
            else
              Expanded(
                child: SingleChildScrollView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.only(bottom: 30),
                  child: Column(
                    children: [
                      const SizedBox(height: 24),
                      // Card de saldo
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: _SaldoCard(
                          saldoDisponivel: _saldoDisponivel,
                          saldoBloqueado: _saldoBloqueado,
                          onSacar: _abrirSaque,
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Cards de totais
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TotalCard(
                                label: 'Total Ganho',
                                valor: _totalGanho,
                                cor: _green,
                                icon: '💰',
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: _TotalCard(
                                label: 'Total Sacado',
                                valor: _totalSacado,
                                cor: _orange,
                                icon: '⬆️',
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      // Tabs
                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        child: Container(
                          decoration: BoxDecoration(
                            color: _card,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: TabBar(
                            controller: _tabCtrl,
                            indicator: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            indicatorSize: TabBarIndicatorSize.tab,
                            dividerColor: Colors.transparent,
                            labelStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                            unselectedLabelStyle: GoogleFonts.outfit(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                            labelColor: Colors.white,
                            unselectedLabelColor: _text3,
                            tabs: const [Tab(text: 'Movimentações'), Tab(text: 'Saques')],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      SizedBox(
                        height: 420,
                        child: TabBarView(
                          controller: _tabCtrl,
                          children: [
                            _ListaMovimentacoes(
                              itens: _movimentacoes,
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                            _ListaSaques(
                              entregadorId: _entregadorId ?? '',
                              padding: const EdgeInsets.symmetric(horizontal: 20),
                            ),
                          ],
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

// ═══════════════════════════════════════════════════════════════════════════
// SALDO CARD
// ═══════════════════════════════════════════════════════════════════════════
class _SaldoCard extends StatelessWidget {
  final double saldoDisponivel, saldoBloqueado;
  final VoidCallback onSacar;

  const _SaldoCard({
    required this.saldoDisponivel,
    required this.saldoBloqueado,
    required this.onSacar,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF1A1008), Color(0xFF0F0804)],
        ),
        border: Border.all(color: _orange.withValues(alpha: .2)),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [BoxShadow(color: _orange.withValues(alpha: .08), blurRadius: 30)],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'SALDO DISPONÍVEL',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: _orange.withValues(alpha: .6),
              letterSpacing: .8,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'R\$ ${saldoDisponivel.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(
              fontSize: 36,
              fontWeight: FontWeight.w900,
              color: _orange,
              height: 1,
            ),
          ),
          if (saldoBloqueado > 0) ...[
            const SizedBox(height: 6),
            Row(
              children: [
                const Text('🔒', style: TextStyle(fontSize: 11)),
                const SizedBox(width: 4),
                Text(
                  'R\$ ${saldoBloqueado.toStringAsFixed(2)} em processamento',
                  style: GoogleFonts.dmSans(fontSize: 11, color: _yellow),
                ),
              ],
            ),
          ],
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: onSacar,
                  child: Container(
                    height: 50,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [_orange, Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(13),
                      boxShadow: [
                        BoxShadow(
                          color: _orange.withValues(alpha: .35),
                          blurRadius: 14,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text('⚡', style: TextStyle(fontSize: 16)),
                          const SizedBox(width: 8),
                          Text(
                            'Sacar via PIX',
                            style: GoogleFonts.outfit(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Center(
            child: Text(
              'Mínimo R\$ 10,00 · Instantâneo',
              style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Total Card ─────────────────────────────────────────────────────────────
class _TotalCard extends StatelessWidget {
  final String label, icon;
  final double valor;
  final Color cor;

  const _TotalCard({
    required this.label,
    required this.valor,
    required this.cor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _card,
        border: Border.all(color: _border),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(icon, style: const TextStyle(fontSize: 18)),
          const SizedBox(height: 6),
          Text(
            'R\$ ${valor.toStringAsFixed(2)}',
            style: GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w800, color: cor),
          ),
          Text(
            label,
            style: GoogleFonts.dmSans(fontSize: 10, color: _text3, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA MOVIMENTAÇÕES
// ═══════════════════════════════════════════════════════════════════════════
class _ListaMovimentacoes extends StatelessWidget {
  final List<_Movimentacao> itens;
  final EdgeInsets padding;

  const _ListaMovimentacoes({required this.itens, required this.padding});

  @override
  Widget build(BuildContext context) {
    if (itens.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💳', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Nenhuma movimentação',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _text2),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: padding.add(const EdgeInsets.only(top: 4)),
      physics: const BouncingScrollPhysics(),
      itemCount: itens.length,
      itemBuilder: (_, i) {
        final m = itens[i];
        final isCredito = m.tipo == 'credito';
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: isCredito
                      ? _green.withValues(alpha: .1)
                      : _orange.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    isCredito ? '⬇️' : '⬆️',
                    style: const TextStyle(fontSize: 14),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      m.descricao,
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text1,
                      ),
                    ),
                    Text(m.data, style: GoogleFonts.dmSans(fontSize: 10, color: _text3)),
                  ],
                ),
              ),
              Text(
                '${isCredito ? '+' : '-'} R\$ ${m.valor.toStringAsFixed(2)}',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: isCredito ? _green : _orange,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// LISTA SAQUES
// ═══════════════════════════════════════════════════════════════════════════
class _ListaSaques extends StatefulWidget {
  final String entregadorId;
  final EdgeInsets padding;

  const _ListaSaques({required this.entregadorId, required this.padding});

  @override
  State<_ListaSaques> createState() => _ListaSaquesState();
}

class _ListaSaquesState extends State<_ListaSaques> {
  List<Map<String, dynamic>> _saques = [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    if (widget.entregadorId.isEmpty) {
      setState(() => _loading = false);
      return;
    }
    try {
      final r = await Supabase.instance.client
          .from('entregador_saques')
          .select()
          .eq('entregador_id', widget.entregadorId)
          .order('solicitado_em', ascending: false)
          .limit(30);
      if (!mounted) return;
      setState(() {
        _saques = List<Map<String, dynamic>>.from(r);
        _loading = false;
      });
    } catch (_) {
      setState(() => _loading = false);
    }
  }

  String _fmtData(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2));
    }
    if (_saques.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('⚡', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 8),
            Text(
              'Nenhum saque realizado',
              style: GoogleFonts.outfit(fontSize: 14, fontWeight: FontWeight.w700, color: _text2),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: widget.padding.add(const EdgeInsets.only(top: 4)),
      physics: const BouncingScrollPhysics(),
      itemCount: _saques.length,
      itemBuilder: (_, i) {
        final s = _saques[i];
        final status = s['status'] ?? 'pendente';
        final cor = status == 'concluido'
            ? _green
            : status == 'falhou'
                ? _red
                : _yellow;
        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: _card,
            border: Border.all(color: _border),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: cor.withValues(alpha: .1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    status == 'concluido' ? '✅' : status == 'falhou' ? '❌' : '⏳',
                    style: const TextStyle(fontSize: 15),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Saque PIX',
                      style: GoogleFonts.outfit(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: _text1,
                      ),
                    ),
                    Text(
                      '${s['pix_chave'] ?? ''} · ${_fmtData(s['solicitado_em'])}',
                      style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '- R\$ ${(s['valor'] as num).toStringAsFixed(2)}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: _orange,
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cor.withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      status,
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: cor,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// SAQUE SHEET
// ═══════════════════════════════════════════════════════════════════════════
class _SaqueSheet extends StatefulWidget {
  final double saldoDisponivel;
  final String pixChave, pixTipo, entregadorId;
  final VoidCallback onSucesso;

  const _SaqueSheet({
    required this.saldoDisponivel,
    required this.pixChave,
    required this.pixTipo,
    required this.entregadorId,
    required this.onSucesso,
  });

  @override
  State<_SaqueSheet> createState() => _SaqueSheetState();
}

class _SaqueSheetState extends State<_SaqueSheet> {
  final _ctrl = TextEditingController();
  bool _enviando = false;
  String? _erro;

  @override
  void initState() {
    super.initState();
    _ctrl.text = widget.saldoDisponivel.toStringAsFixed(2);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  Future<void> _sacar() async {
    final v = double.tryParse(_ctrl.text.replaceAll(',', '.'));
    if (v == null || v < 10) {
      setState(() => _erro = 'Valor mínimo: R\$ 10,00');
      return;
    }
    if (v > widget.saldoDisponivel) {
      setState(() => _erro = 'Saldo insuficiente');
      return;
    }

    setState(() {
      _enviando = true;
      _erro = null;
    });

    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'solicitar-saque',
        body: {
          'entregador_id': widget.entregadorId,
          'valor': v,
          'pix_chave': widget.pixChave,
          'pix_tipo': widget.pixTipo,
        },
      );

      if (resp.status != 200) throw Exception(resp.data?['error'] ?? 'Erro ao sacar');

      if (mounted) {
        Navigator.pop(context);
        widget.onSucesso();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _enviando = false;
          _erro = e.toString().replaceAll('Exception: ', '');
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 20),
            Text(
              'Sacar via PIX',
              style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: _text1),
            ),
            const SizedBox(height: 4),
            Text(
              'Disponível: R\$ ${widget.saldoDisponivel.toStringAsFixed(2)}',
              style: GoogleFonts.dmSans(fontSize: 13, color: _text3),
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _bg3,
                border: Border.all(color: _border),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 18)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Chave PIX (${widget.pixTipo})',
                          style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                        ),
                        Text(
                          widget.pixChave,
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _text1,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _ctrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: GoogleFonts.outfit(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: _orange,
              ),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                prefixText: 'R\$ ',
                prefixStyle: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _text3,
                ),
                filled: true,
                fillColor: _bg3,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: BorderSide(color: _orange.withValues(alpha: .3)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                  borderSide: const BorderSide(color: _orange, width: 2),
                ),
                errorText: _erro,
              ),
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _enviando ? null : _sacar,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _orange,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _enviando
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                      )
                    : Text(
                        'Confirmar Saque',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
