// ============================================================
// historico_screen.dart — Histórico de Entregas
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/historico
// Tabelas: splits_pagamento, pedidos
// ============================================================

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

const _bg0 = Color(0xFF0A0704);
const _bg2 = Color(0xFF1C1510);
const _card = Color(0xFF1A1510);
const _orange = Color(0xFFF97316);
const _green = Color(0xFF22C55E);
const _red = Color(0xFFEF4444);
const _text1 = Color(0xFFFAFAF9);
const _text2 = Color(0xA6FAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

class HistoricoScreen extends StatefulWidget {
  const HistoricoScreen({super.key});

  @override
  State<HistoricoScreen> createState() => _HistoricoScreenState();
}

class _HistoricoScreenState extends State<HistoricoScreen> {
  bool _loading = true;
  String _filtro = 'todos'; // todos | concluidas | canceladas
  List<Map<String, dynamic>> _pedidos = [];
  String? _entregadorId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() => _loading = true);
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final ent = await Supabase.instance.client
        .from('entregadores')
        .select('id')
        .eq('usuario_id', uid)
        .maybeSingle();

    _entregadorId = ent?['id'];
    if (_entregadorId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      var q = Supabase.instance.client
          .from('splits_pagamento')
          .select('''
            entregador_taxa_entrega_valor, entregador_valor_extra, created_at, status,
            pedidos ( id, numero_pedido, status, distancia_km,
              estabelecimentos ( nome_fantasia ) )
          ''')
          .eq('entregador_id', _entregadorId!);

      if (_filtro == 'concluidas') {
        q = q.eq('status', 'concluido');
      } else if (_filtro == 'canceladas') {
        q = q.neq('status', 'concluido');
      }

      final r = await q.order('created_at', ascending: false).limit(50);
      if (!mounted) return;
      setState(() {
        _pedidos = List<Map<String, dynamic>>.from(r);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _fmtData(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} às ${d.hour.toString().padLeft(2, '0')}h${d.minute.toString().padLeft(2, '0')}';
  }

  double _totalPeriodo() => _pedidos
      .where((p) => (p['status'] ?? '') == 'concluido')
      .fold(
        0.0,
        (s, p) =>
            s +
            ((p['entregador_taxa_entrega_valor'] as num?)?.toDouble() ?? 0) +
            ((p['entregador_valor_extra'] as num?)?.toDouble() ?? 0),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
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
                    'Histórico',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: _text1),
                  ),
                ],
              ),
            ),
            // Filtros
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Row(
                children: ['todos', 'concluidas', 'canceladas']
                    .map(
                      (f) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () {
                            setState(() => _filtro = f);
                            _carregar();
                          },
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: _filtro == f ? _orange : _card,
                              border: Border.all(color: _filtro == f ? _orange : _border),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Text(
                              f == 'todos'
                                  ? 'Todos'
                                  : f == 'concluidas'
                                      ? 'Concluídas'
                                      : 'Canceladas',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: _filtro == f ? Colors.white : _text3,
                              ),
                            ),
                          ),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            // Resumo
            if (!_loading && _pedidos.isNotEmpty)
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: _card,
                    border: Border.all(color: _border),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        '${_pedidos.length} entregas',
                        style: GoogleFonts.dmSans(fontSize: 12, color: _text3),
                      ),
                      Text(
                        'R\$ ${_totalPeriodo().toStringAsFixed(2)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: _green,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            const SizedBox(height: 12),
            // Lista
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5)),
              )
            else if (_pedidos.isEmpty)
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('📦', style: TextStyle(fontSize: 40)),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhuma entrega encontrada',
                        style: GoogleFonts.outfit(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: _text2,
                        ),
                      ),
                    ],
                  ),
                ),
              )
            else
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  physics: const BouncingScrollPhysics(),
                  itemCount: _pedidos.length,
                  itemBuilder: (_, i) {
                    final p = _pedidos[i];
                    final pedido = (p['pedidos'] as Map?) ?? {};
                    final concluida = (pedido['status'] ?? '') == 'entregue';
                    final ganho =
                        ((p['entregador_taxa_entrega_valor'] as num?)?.toDouble() ?? 0) +
                        ((p['entregador_valor_extra'] as num?)?.toDouble() ?? 0);
                    final estab =
                        pedido['estabelecimentos']?['nome_fantasia'] ?? 'Estabelecimento';
                    final dist =
                        (pedido['distancia_km'] as num?)?.toStringAsFixed(1) ?? '?';
                    final numero = pedido['numero_pedido'];

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
                              color: concluida ? _green.withOpacity(.1) : _red.withOpacity(.1),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                concluida ? '✅' : '❌',
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
                                  estab,
                                  style: GoogleFonts.outfit(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: _text1,
                                  ),
                                ),
                                Text(
                                  '#${numero ?? '?'} · $dist km · ${_fmtData(p['created_at'])}',
                                  style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            '${concluida ? '+' : ''}R\$ ${ganho.toStringAsFixed(2)}',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                              color: concluida ? _green : _red,
                            ),
                          ),
                          const SizedBox(width: 4),
                          const Icon(Icons.chevron_right_rounded, color: _text3, size: 16),
                        ],
                      ),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}
