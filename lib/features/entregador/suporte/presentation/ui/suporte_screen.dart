// ============================================================
// suporte_screen.dart — Suporte do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/suporte
// Tabelas: suporte_chamados
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
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

class SuporteScreen extends StatefulWidget {
  const SuporteScreen({super.key});

  @override
  State<SuporteScreen> createState() => _SuporteScreenState();
}

class _SuporteScreenState extends State<SuporteScreen>
    with SingleTickerProviderStateMixin {
  bool _loading = true;
  List<Map<String, dynamic>> _chamados = [];
  String? _entregadorId;
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
      final r = await Supabase.instance.client
          .from('suporte_chamados')
          .select()
          .eq('entregador_id', _entregadorId!)
          .order('created_at', ascending: false);
      if (!mounted) return;
      setState(() {
        _chamados = List<Map<String, dynamic>>.from(r);
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _abrirNovoChamado() {
    final descCtrl = TextEditingController();
    String categoria = 'pagamento';
    String prioridade = 'normal';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _card,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModal) => Padding(
          padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 20, 24, 36),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 36,
                  height: 4,
                  decoration: BoxDecoration(
                    color: _border,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Abrir Chamado',
                  style: GoogleFonts.outfit(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    color: _text1,
                  ),
                ),
                const SizedBox(height: 20),
                DropdownButtonFormField<String>(
                  value: categoria,
                  dropdownColor: _bg3,
                  style: GoogleFonts.dmSans(color: _text1),
                  decoration: InputDecoration(
                    labelText: 'Categoria',
                    labelStyle: GoogleFonts.dmSans(color: _text3),
                    filled: true,
                    fillColor: _bg3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'pagamento', child: Text('Pagamento')),
                    DropdownMenuItem(value: 'entrega', child: Text('Entrega')),
                    DropdownMenuItem(value: 'cliente', child: Text('Cliente')),
                    DropdownMenuItem(value: 'tecnico', child: Text('Técnico')),
                    DropdownMenuItem(value: 'outro', child: Text('Outro')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => categoria = v);
                  },
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: prioridade,
                  dropdownColor: _bg3,
                  style: GoogleFonts.dmSans(color: _text1),
                  decoration: InputDecoration(
                    labelText: 'Prioridade',
                    labelStyle: GoogleFonts.dmSans(color: _text3),
                    filled: true,
                    fillColor: _bg3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _border),
                    ),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'baixa', child: Text('Baixa')),
                    DropdownMenuItem(value: 'normal', child: Text('Normal')),
                    DropdownMenuItem(value: 'alta', child: Text('Alta')),
                    DropdownMenuItem(value: 'urgente', child: Text('Urgente')),
                  ],
                  onChanged: (v) {
                    if (v != null) setModal(() => prioridade = v);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: descCtrl,
                  maxLines: 4,
                  style: GoogleFonts.dmSans(color: _text1),
                  decoration: InputDecoration(
                    hintText: 'Descreva o problema...',
                    hintStyle: GoogleFonts.dmSans(color: _text3),
                    filled: true,
                    fillColor: _bg3,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide(color: _border),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: const BorderSide(color: _orange, width: 2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _orange,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      elevation: 0,
                    ),
                    onPressed: () async {
                      if (descCtrl.text.trim().isEmpty) return;
                      Navigator.pop(ctx);
                      try {
                        final uid = Supabase.instance.client.auth.currentUser?.id;
                        await Supabase.instance.client.from('suporte_chamados').insert({
                          'entregador_id': _entregadorId,
                          'usuario_id': uid,
                          'tipo_solicitante': 'entregador',
                          'categoria': categoria,
                          'prioridade': prioridade,
                          'descricao': descCtrl.text.trim(),
                          'status': 'aberto',
                        });
                        _carregar();
                      } catch (_) {}
                    },
                    child: Text(
                      'Enviar Chamado',
                      style: GoogleFonts.outfit(
                        fontSize: 15,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _fmtData(String? iso) {
    if (iso == null) return '';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return '';
    return '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
  }

  Color _corStatus(String s) =>
      s == 'resolvido' || s == 'fechado' ? _green : s == 'em_atendimento' ? _orange : _yellow;

  Color _corPrioridade(String s) =>
      s == 'urgente' ? _red : s == 'alta' ? _orange : s == 'normal' ? _yellow : _text3;

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final abertos =
        _chamados.where((c) => !['resolvido', 'fechado'].contains(c['status'])).toList();
    final resolvidos =
        _chamados.where((c) => ['resolvido', 'fechado'].contains(c['status'])).toList();

    return Scaffold(
      backgroundColor: _bg0,
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _abrirNovoChamado,
        backgroundColor: _orange,
        label: Text(
          'Novo Chamado',
          style: GoogleFonts.outfit(fontWeight: FontWeight.w800, color: Colors.white),
        ),
        icon: const Icon(Icons.add_rounded, color: Colors.white),
      ),
      body: SafeArea(
        child: Column(
          children: [
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
                    'Suporte',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _text1,
                    ),
                  ),
                ],
              ),
            ),
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
                  labelStyle: GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w800),
                  unselectedLabelStyle:
                      GoogleFonts.outfit(fontSize: 13, fontWeight: FontWeight.w600),
                  labelColor: Colors.white,
                  unselectedLabelColor: _text3,
                  tabs: [
                    Tab(text: 'Abertos (${abertos.length})'),
                    Tab(text: 'Resolvidos (${resolvidos.length})'),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (_loading)
              const Expanded(
                child: Center(child: CircularProgressIndicator(color: _orange, strokeWidth: 2.5)),
              )
            else
              Expanded(
                child: TabBarView(
                  controller: _tabCtrl,
                  children: [
                    _ListaChamados(
                      chamados: abertos,
                      fmtData: _fmtData,
                      corStatus: _corStatus,
                      corPrioridade: _corPrioridade,
                    ),
                    _ListaChamados(
                      chamados: resolvidos,
                      fmtData: _fmtData,
                      corStatus: _corStatus,
                      corPrioridade: _corPrioridade,
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _ListaChamados extends StatelessWidget {
  final List<Map<String, dynamic>> chamados;
  final String Function(String?) fmtData;
  final Color Function(String) corStatus, corPrioridade;

  const _ListaChamados({
    required this.chamados,
    required this.fmtData,
    required this.corStatus,
    required this.corPrioridade,
  });

  String _labelCat(String c) =>
      const {
        'pagamento': 'Pagamento',
        'entrega': 'Entrega',
        'cliente': 'Cliente',
        'tecnico': 'Técnico',
        'outro': 'Outro',
      }[c] ??
      c;

  @override
  Widget build(BuildContext context) {
    if (chamados.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('💬', style: TextStyle(fontSize: 36)),
            const SizedBox(height: 8),
            Text(
              'Nenhum chamado',
              style: GoogleFonts.outfit(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: const Color(0xA6FAFAF9),
              ),
            ),
          ],
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 80),
      physics: const BouncingScrollPhysics(),
      itemCount: chamados.length,
      itemBuilder: (_, i) {
        final c = chamados[i];
        final status = c['status'] ?? 'aberto';
        final prioridade = c['prioridade'] ?? 'normal';
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
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: corStatus(status).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      status.replaceAll('_', ' '),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: corStatus(status),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: corPrioridade(prioridade).withValues(alpha: .1),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      prioridade,
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: corPrioridade(prioridade),
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fmtData(c['created_at']),
                    style: GoogleFonts.dmSans(fontSize: 9, color: _text3),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF251C14),
                      borderRadius: BorderRadius.circular(5),
                    ),
                    child: Text(
                      _labelCat(c['categoria'] ?? ''),
                      style: GoogleFonts.dmSans(
                        fontSize: 10,
                        color: const Color(0xA6FAFAF9),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                c['descricao'] ?? '',
                style: GoogleFonts.dmSans(fontSize: 12, color: const Color(0xA6FAFAF9)),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
              if (c['resposta_suporte'] != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: _green.withValues(alpha: .06),
                    border: Border.all(color: _green.withValues(alpha: .15)),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '💬 Resposta do suporte',
                        style: GoogleFonts.dmSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: _green.withValues(alpha: .7),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        c['resposta_suporte'],
                        style: GoogleFonts.dmSans(
                          fontSize: 12,
                          color: const Color(0xFFFAFAF9),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }
}
