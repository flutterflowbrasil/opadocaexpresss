// ignore_for_file: unused_element, unused_field

// ============================================================
// carteira_screen.dart — Carteira do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/financeiro
// Tabelas: entregador_saldos, splits_pagamento, entregador_bonificacoes
// Saques e movimentacao real acontecem diretamente no Asaas.
// ============================================================

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
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

  double _saqueMinimo = 10.0;
  double _saqueTarifa = 0.0;
  int _saqueLimiteDiario = 3;

  List<_Movimentacao> _movimentacoes = [];

  // Status da conta Asaas -- sincronizado em background ao abrir a tela
  String _asaasStatus = 'pending';
  String _asaasMensagem = 'Verificando sua conta Asaas...';

  RealtimeChannel? _saldoChannel;
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 1, vsync: this);
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

      final conf = await Supabase.instance.client
          .from('v_plataforma_config_publica')
          .select('chave, valor')
          .inFilter('chave', ['saque_valor_minimo', 'saque_tarifa_fixa', 'saque_limite_diario']);

      if (mounted && conf.isNotEmpty) {
        final configMap = {for (var item in conf) item['chave']: item['valor']};
        setState(() {
          _saqueMinimo = double.tryParse(configMap['saque_valor_minimo']?.toString() ?? '10.0') ?? 10.0;
          _saqueTarifa = double.tryParse(configMap['saque_tarifa_fixa']?.toString() ?? '0.0') ?? 0.0;
          _saqueLimiteDiario = int.tryParse(configMap['saque_limite_diario']?.toString() ?? '3') ?? 3;
        });
      }

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
    showModalBottomSheet(
      context: context,
      backgroundColor: _bg2,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (_) => const _AsaasAcessoSheet(),
    );
  }

  /// Chama a Edge Function para sincronizar o status da subconta Asaas.
  /// Executado em background — não bloqueia a UI.
  Future<void> _sincronizarStatusAsaas() async {
    if (_entregadorId == null) return;
    try {
      final resp = await Supabase.instance.client.functions.invoke(
        'asaas-sincronizar-subconta',
        body: {'entidade_tipo': 'entregador', 'entidade_id': _entregadorId},
      );
      if (!mounted) return;
      if (resp.status < 400 && resp.data is Map) {
        final data = (resp.data as Map).cast<String, dynamic>();
        setState(() {
          _asaasStatus = (data['status'] as String?) ?? 'pending';
          _asaasMensagem = (data['mensagem'] as String?) ?? '';
        });
      }
    } catch (e) {
      debugPrint('[Carteira] sincronizar Asaas: $e');
    }
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
                          saqueMinimo: _saqueMinimo,
                          onSacar: _abrirSaque,
                          asaasStatus: _asaasStatus,
                          asaasMensagem: _asaasMensagem,
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
                                label: 'Recebido Asaas',
                                valor: _totalGanho,
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
                            tabs: const [Tab(text: 'Movimentacoes')],
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
  final double saldoDisponivel, saldoBloqueado, saqueMinimo;
  final VoidCallback onSacar;
  final String asaasStatus;
  final String asaasMensagem;

  const _SaldoCard({
    required this.saldoDisponivel,
    required this.saldoBloqueado,
    required this.saqueMinimo,
    required this.onSacar,
    this.asaasStatus = 'pending',
    this.asaasMensagem = '',
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
          // Badge de status Asaas
          _AsaasStatusBadge(status: asaasStatus, mensagem: asaasMensagem),
          const SizedBox(height: 12),
          Text(
            'PREVISTO NO ASAAS',
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
                            'Acessar Asaas',
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
              'Saques e movimentacao sao feitos diretamente no Asaas',
              style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
            ),
          ),
        ],
      ),
    );
  }
}



// ─── Asaas Status Badge ─────────────────────────────────────────────────────────────

class _AsaasStatusBadge extends StatelessWidget {

  final String status;

  final String mensagem;

  const _AsaasStatusBadge({required this.status, required this.mensagem});



  @override

  Widget build(BuildContext context) {

    final (icon, color, label) = switch (status) {

      'active' => ('✅', _green, 'Conta ativa'),

      'blocked' => ('🚫', _red, 'Conta bloqueada'),

      'rejected' => ('❌', _red, 'Conta reprovada'),

      _ => ('⏳', _yellow, 'Em analise'),

    };

    return Row(

      children: [

        Container(

          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),

          decoration: BoxDecoration(

            color: color.withValues(alpha: .12),

            border: Border.all(color: color.withValues(alpha: .3)),

            borderRadius: BorderRadius.circular(8),

          ),

          child: Row(

            mainAxisSize: MainAxisSize.min,

            children: [

              Text(icon, style: const TextStyle(fontSize: 11)),

              const SizedBox(width: 5),

              Text(

                label,

                style: GoogleFonts.dmSans(

                  fontSize: 10,

                  fontWeight: FontWeight.w800,

                  color: color,

                ),

              ),

            ],

          ),

        ),

        if (mensagem.isNotEmpty) ...[

          const SizedBox(width: 8),

          Expanded(

            child: Text(

              mensagem,

              style: GoogleFonts.dmSans(fontSize: 9, color: _text3),

              maxLines: 1,

              overflow: TextOverflow.ellipsis,

            ),

          ),

        ],

      ],

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

// ═══════════════════════════════════════════════════════════════════════════
// ASAAS ACESSO SHEET — Instrucoes para primeiro acesso no Asaas
// ═══════════════════════════════════════════════════════════════════════════
class _AsaasAcessoSheet extends StatelessWidget {
  const _AsaasAcessoSheet();

  static const _urlSandbox = 'https://sandbox.asaas.com';
  static const _urlProd = 'https://app.asaas.com';

  Future<void> _abrirLink(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        24,
        20,
        24,
        MediaQuery.of(context).viewInsets.bottom + 28,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Handle
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: _border,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: .12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Center(
                  child: Text('🏦', style: TextStyle(fontSize: 20)),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acessar sua conta Asaas',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: _text1,
                    ),
                  ),
                  Text(
                    'Saques e movimentacoes sao feitos diretamente no Asaas',
                    style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          // Passos
          _PassoItem(
            numero: '1',
            titulo: 'Acesse o site do Asaas',
            descricao: 'Clique no botao abaixo para abrir o Asaas',
          ),
          _PassoItem(
            numero: '2',
            titulo: 'Primeiro acesso? Clique em "Esqueci minha senha"',
            descricao: 'Use o EMAIL que voce cadastrou no Ôpadoca Express',
          ),
          _PassoItem(
            numero: '3',
            titulo: 'Crie sua senha e entre',
            descricao: 'Voce recebera um email do Asaas com o link de criacao de senha',
            isLast: true,
          ),
          const SizedBox(height: 24),
          // Botao de acesso
          SizedBox(
            width: double.infinity,
            height: 52,
            child: ElevatedButton(
              onPressed: () => _abrirLink(_urlProd),
              style: ElevatedButton.styleFrom(
                backgroundColor: _orange,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('⚡', style: TextStyle(fontSize: 16)),
                  const SizedBox(width: 8),
                  Text(
                    'Abrir Asaas (Producao)',
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
          const SizedBox(height: 10),
          // Botao sandbox (menor, secundario)
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: () => _abrirLink(_urlSandbox),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: _orange.withValues(alpha: .4)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: Text(
                'Abrir Asaas Sandbox (Testes)',
                style: GoogleFonts.outfit(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _orange,
                ),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Center(
            child: Text(
              'Nao sabe a senha? Clique em "Esqueci minha senha" no Asaas',
              style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Passo de instrucao ─────────────────────────────────────────────────────
class _PassoItem extends StatelessWidget {
  final String numero, titulo, descricao;
  final bool isLast;

  const _PassoItem({
    required this.numero,
    required this.titulo,
    required this.descricao,
    this.isLast = false,
  });

  @override
  Widget build(BuildContext context) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Column(
            children: [
              Container(
                width: 28,
                height: 28,
                decoration: BoxDecoration(
                  color: _orange.withValues(alpha: .15),
                  border: Border.all(color: _orange.withValues(alpha: .4)),
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    numero,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: _orange,
                    ),
                  ),
                ),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    color: _border,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    titulo,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text1,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    descricao,
                    style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
