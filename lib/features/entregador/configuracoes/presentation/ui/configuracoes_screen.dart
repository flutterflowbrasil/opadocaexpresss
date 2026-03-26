// ============================================================
// configuracoes_screen.dart — Configurações do Entregador
// Ôpadoca Express · App do Entregador
// Rota: /dashboard_entregador/configuracoes
// Tabelas: entregador_configuracoes, entregadores
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
const _text1 = Color(0xFFFAFAF9);
const _text3 = Color(0x59FAFAF9);
const _border = Color(0x12FFFFFF);

class ConfiguracoesScreen extends StatefulWidget {
  const ConfiguracoesScreen({super.key});

  @override
  State<ConfiguracoesScreen> createState() => _ConfiguracoesScreenState();
}

class _ConfiguracoesScreenState extends State<ConfiguracoesScreen> {
  bool _loading = true;
  bool _salvando = false;
  String? _entregadorId;

  int _raioAtuacao = 10;
  bool _aceitaAuto = false;
  bool _notifPedidos = true;
  bool _notifAtualizacoes = true;
  bool _modoNoturno = false;

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
        .select('id')
        .eq('usuario_id', uid)
        .maybeSingle();

    _entregadorId = ent?['id'];
    if (_entregadorId == null) {
      setState(() => _loading = false);
      return;
    }

    try {
      final cfg = await Supabase.instance.client
          .from('entregador_configuracoes')
          .select()
          .eq('entregador_id', _entregadorId!)
          .maybeSingle();

      if (!mounted) return;
      setState(() {
        if (cfg != null) {
          _raioAtuacao = cfg['raio_atuacao_km'] ?? 10;
          _aceitaAuto = cfg['aceita_automaticamente'] ?? false;
          _notifPedidos = cfg['notif_novos_pedidos'] ?? true;
          _notifAtualizacoes = cfg['notif_atualizacoes'] ?? true;
          _modoNoturno = cfg['modo_noturno'] ?? false;
        }
        _loading = false;
      });
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _salvar() async {
    if (_entregadorId == null) return;
    setState(() => _salvando = true);
    try {
      await Supabase.instance.client.from('entregador_configuracoes').upsert({
        'entregador_id': _entregadorId,
        'raio_atuacao_km': _raioAtuacao,
        'aceita_automaticamente': _aceitaAuto,
        'notif_novos_pedidos': _notifPedidos,
        'notif_atualizacoes': _notifAtualizacoes,
        'modo_noturno': _modoNoturno,
        'updated_at': DateTime.now().toIso8601String(),
      });
      await Supabase.instance.client
          .from('entregadores')
          .update({'raio_atuacao_km': _raioAtuacao})
          .eq('id', _entregadorId!);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Configurações salvas!'),
          backgroundColor: _green,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
          margin: const EdgeInsets.all(16),
        ),
      );
    } catch (_) {
    } finally {
      if (mounted) setState(() => _salvando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg0,
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
                    'Configurações',
                    style: GoogleFonts.outfit(
                      fontSize: 20,
                      fontWeight: FontWeight.w900,
                      color: _text1,
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
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 30),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Raio de atuação
                      _SecTitulo('ÁREA DE ATUAÇÃO'),
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'Raio de atuação',
                                  style: GoogleFonts.outfit(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: _text1,
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
                                  decoration: BoxDecoration(
                                    color: _orange.withValues(alpha: .12),
                                    border: Border.all(color: _orange.withValues(alpha: .3)),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '$_raioAtuacao km',
                                    style: GoogleFonts.outfit(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: _orange,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Pedidos dentro deste raio serão oferecidos a você',
                              style: GoogleFonts.dmSans(fontSize: 11, color: _text3),
                            ),
                            SliderTheme(
                              data: SliderTheme.of(context).copyWith(
                                activeTrackColor: _orange,
                                inactiveTrackColor: _bg3,
                                thumbColor: _orange,
                                overlayColor: _orange.withValues(alpha: .2),
                                thumbShape: const RoundSliderThumbShape(enabledThumbRadius: 10),
                              ),
                              child: Slider(
                                value: _raioAtuacao.toDouble(),
                                min: 1,
                                max: 30,
                                divisions: 29,
                                onChanged: (v) => setState(() => _raioAtuacao = v.round()),
                              ),
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('1 km', style: GoogleFonts.dmSans(fontSize: 10, color: _text3)),
                                Text(
                                  '30 km',
                                  style: GoogleFonts.dmSans(fontSize: 10, color: _text3),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Pedidos
                      _SecTitulo('PEDIDOS'),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _ToggleRow(
                          label: 'Aceitar pedidos automaticamente',
                          sublabel: 'Sem precisar confirmar manualmente',
                          value: _aceitaAuto,
                          onChanged: (v) => setState(() => _aceitaAuto = v),
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Notificações
                      _SecTitulo('NOTIFICAÇÕES'),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Column(
                          children: [
                            _ToggleRow(
                              label: 'Novos pedidos',
                              sublabel: 'Push ao receber nova oferta',
                              value: _notifPedidos,
                              onChanged: (v) => setState(() => _notifPedidos = v),
                            ),
                            Divider(color: _border, height: 1, indent: 16, endIndent: 16),
                            _ToggleRow(
                              label: 'Atualizações',
                              sublabel: 'Status de pagamento e conta',
                              value: _notifAtualizacoes,
                              onChanged: (v) => setState(() => _notifAtualizacoes = v),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                      // Aparência
                      _SecTitulo('APARÊNCIA'),
                      Container(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        decoration: BoxDecoration(
                          color: _card,
                          border: Border.all(color: _border),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: _ToggleRow(
                          label: 'Modo noturno',
                          sublabel: 'Tema escuro (padrão neste app)',
                          value: _modoNoturno,
                          onChanged: (v) => setState(() => _modoNoturno = v),
                        ),
                      ),
                      const SizedBox(height: 24),
                      SizedBox(
                        width: double.infinity,
                        height: 54,
                        child: ElevatedButton(
                          onPressed: _salvando ? null : _salvar,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _orange,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            elevation: 0,
                          ),
                          child: _salvando
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(
                                  'Salvar Configurações',
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
              ),
          ],
        ),
      ),
    );
  }
}

class _SecTitulo extends StatelessWidget {
  final String texto;
  const _SecTitulo(this.texto);

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          texto,
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w800,
            color: _text3,
            letterSpacing: .8,
          ),
        ),
      );
}

class _ToggleRow extends StatelessWidget {
  final String label, sublabel;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleRow({
    required this.label,
    required this.sublabel,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: GoogleFonts.outfit(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: _text1,
                    ),
                  ),
                  Text(sublabel, style: GoogleFonts.dmSans(fontSize: 11, color: _text3)),
                ],
              ),
            ),
            Switch(
              value: value,
              onChanged: onChanged,
              activeColor: _orange,
              activeTrackColor: _orange.withValues(alpha: .3),
              inactiveTrackColor: _bg3,
              inactiveThumbColor: _text3,
            ),
          ],
        ),
      );
}
