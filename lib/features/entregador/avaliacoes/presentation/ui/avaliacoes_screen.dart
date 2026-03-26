// ============================================================
// avaliacoes_screen.dart — Avaliações do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/avaliacoes
// Tabelas: avaliacoes, entregadores
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
const _yellow = Color(0xFFFBBF24);
const _red = Color(0xFFEF4444);
const _text1 = Color(0xFFFAFAF9);
const _text2 = Color(0xA6FAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

class AvaliacoesScreen extends StatefulWidget {
  const AvaliacoesScreen({super.key});

  @override
  State<AvaliacoesScreen> createState() => _AvaliacoesScreenState();
}

class _AvaliacoesScreenState extends State<AvaliacoesScreen> {
  bool _loading = true;
  double _media = 0;
  int _total = 0;
  Map<int, int> _distribuicao = {5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
  List<Map<String, dynamic>> _avaliacoes = [];
  String? _entregadorId;

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) return;

    final ent = await Supabase.instance.client
        .from('entregadores')
        .select('id, avaliacao_media, total_avaliacoes')
        .eq('usuario_id', uid)
        .maybeSingle();

    _entregadorId = ent?['id'];
    if (_entregadorId == null) {
      if (mounted) setState(() => _loading = false);
      return;
    }

    if (mounted) {
      setState(() {
        _media = (ent?['avaliacao_media'] as num?)?.toDouble() ?? 0;
        _total = ent?['total_avaliacoes'] ?? 0;
      });
    }

    try {
      final r = await Supabase.instance.client
          .from('avaliacoes')
          .select('''
            nota_entregador, comentario_entregador, created_at,
            pedidos ( numero_pedido,
              clientes ( usuarios ( nome_completo_fantasia ) ) )
          ''')
          .eq('entregador_id', _entregadorId!)
          .not('nota_entregador', 'is', null)
          .order('created_at', ascending: false)
          .limit(30);

      final dist = <int, int>{5: 0, 4: 0, 3: 0, 2: 0, 1: 0};
      for (final a in r) {
        final nota = ((a['nota_entregador'] as num?)?.round() ?? 0).clamp(1, 5);
        dist[nota] = (dist[nota] ?? 0) + 1;
      }

      if (!mounted) return;
      setState(() {
        _avaliacoes = List<Map<String, dynamic>>.from(r);
        _distribuicao = dist;
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
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
  }

  Color _corNota(double nota) {
    if (nota >= 4.5) return _green;
    if (nota >= 3.5) return _yellow;
    return _red;
  }

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
                    'Avaliações',
                    style: GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w900, color: _text1),
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Card nota geral
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [_yellow.withOpacity(.12), _orange.withOpacity(.06)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          border: Border.all(color: _yellow.withOpacity(.2)),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'NOTA GERAL',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w800,
                                    color: _yellow.withOpacity(.6),
                                    letterSpacing: .8,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      _media.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 48,
                                        fontWeight: FontWeight.w900,
                                        color: _yellow,
                                        height: 1,
                                      ),
                                    ),
                                    Padding(
                                      padding: const EdgeInsets.only(bottom: 8, left: 6),
                                      child: Text(
                                        '/5',
                                        style: GoogleFonts.outfit(
                                          fontSize: 18,
                                          color: _text3,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                Row(
                                  children: List.generate(
                                    5,
                                    (i) => Icon(
                                      i < _media.round() ? Icons.star_rounded : Icons.star_outline_rounded,
                                      color: _yellow,
                                      size: 16,
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  '$_total avaliações',
                                  style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
                                ),
                              ],
                            ),
                            const SizedBox(width: 24),
                            Expanded(
                              child: Column(
                                children: [5, 4, 3, 2, 1].map((n) {
                                  final count = _distribuicao[n] ?? 0;
                                  final pct = _total > 0 ? count / _total : 0.0;
                                  return Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 2),
                                    child: Row(
                                      children: [
                                        Text(
                                          '$n',
                                          style: GoogleFonts.outfit(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: _text3,
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        const Icon(Icons.star_rounded, color: _yellow, size: 10),
                                        const SizedBox(width: 6),
                                        Expanded(
                                          child: ClipRRect(
                                            borderRadius: BorderRadius.circular(2),
                                            child: LinearProgressIndicator(
                                              value: pct.toDouble(),
                                              minHeight: 5,
                                              backgroundColor: _bg2,
                                              valueColor: AlwaysStoppedAnimation(_yellow),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          '$count',
                                          style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                                        ),
                                      ],
                                    ),
                                  );
                                }).toList(),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),
                      Text(
                        'AVALIAÇÕES RECENTES',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _text3,
                          letterSpacing: .8,
                        ),
                      ),
                      const SizedBox(height: 10),
                      if (_avaliacoes.isEmpty)
                        Container(
                          padding: const EdgeInsets.all(24),
                          decoration: BoxDecoration(
                            color: _card,
                            border: Border.all(color: _border),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Column(
                              children: [
                                const Text('⭐', style: TextStyle(fontSize: 32)),
                                const SizedBox(height: 8),
                                Text(
                                  'Nenhuma avaliação ainda',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _text2,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        )
                      else
                        ...(_avaliacoes.map((a) {
                          final nota = (a['nota_entregador'] as num?)?.toDouble() ?? 0;
                          final coment = a['comentario_entregador'] as String?;
                          final pedido = (a['pedidos'] as Map?) ?? {};
                          final cliente =
                              pedido['clientes']?['usuarios']?['nome_completo_fantasia'] ?? 'Cliente';
                          final numero = pedido['numero_pedido'];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: _card,
                              border: Border.all(color: _border),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Row(
                                      children: List.generate(
                                        5,
                                        (i) => Icon(
                                          i < nota.round()
                                              ? Icons.star_rounded
                                              : Icons.star_outline_rounded,
                                          color: _corNota(nota),
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      nota.toStringAsFixed(1),
                                      style: GoogleFonts.outfit(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w800,
                                        color: _corNota(nota),
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_fmtData(a['created_at'])} · #${numero ?? '?'}',
                                      style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 6),
                                Text(
                                  cliente,
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    color: _text3,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                                if (coment != null && coment.isNotEmpty) ...[
                                  const SizedBox(height: 6),
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: _bg2,
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Text(
                                      '"$coment"',
                                      style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        color: _text2,
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                          );
                        }).toList()),
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
