import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/suporte_adm_controller.dart';
import '../../models/suporte_adm_models.dart';

// ── Configurações visuais ─────────────────────────────────────────────────────


const _priorCfg = {
  'urgente': (l: 'Urgente', c: Color(0xFFDC2626), bg: Color(0xFFFEF2F2)),
  'alta':    (l: 'Alta',    c: Color(0xFFEA580C), bg: Color(0xFFFFF7ED)),
  'normal':  (l: 'Normal',  c: Color(0xFF2563EB), bg: Color(0xFFEFF6FF)),
  'baixa':   (l: 'Baixa',   c: Color(0xFF6B7280), bg: Color(0xFFF9FAFB)),
};

const _tipoCfg = {
  'cliente':         (l: 'Cliente',         c: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF), icon: Icons.person_outline),
  'entregador':      (l: 'Entregador',      c: Color(0xFFF97316), bg: Color(0xFFFFF7ED), icon: Icons.directions_bike_outlined),
  'estabelecimento': (l: 'Estabelecimento', c: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF), icon: Icons.store_outlined),
  'admin':           (l: 'Admin',           c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2), icon: Icons.shield_outlined),
};

const _catCfg = {
  'pagamento': (l: 'Pagamento', c: Color(0xFF10B981)),
  'entrega':   (l: 'Entrega',   c: Color(0xFFF97316)),
  'cliente':   (l: 'Cliente',   c: Color(0xFF3B82F6)),
  'tecnico':   (l: 'Técnico',   c: Color(0xFF8B5CF6)),
  'outro':     (l: 'Outro',     c: Color(0xFF9CA3AF)),
};

const _respostasRapidas = [
  'Estamos analisando seu caso. Retornaremos em até 24h.',
  'Problema identificado e resolvido. Pedimos desculpas pelo inconveniente.',
  'Por favor, envie mais detalhes para que possamos ajudar.',
  'Seu reembolso foi processado. Prazo: 5 dias úteis.',
];

// ── Modal ─────────────────────────────────────────────────────────────────────

class SuporteModalAtender extends ConsumerStatefulWidget {
  final SupporteChamado chamado;

  const SuporteModalAtender({super.key, required this.chamado});

  @override
  ConsumerState<SuporteModalAtender> createState() =>
      _SuporteModalAtenderState();
}

class _SuporteModalAtenderState extends ConsumerState<SuporteModalAtender> {
  late String _novoStatus;
  late String _novaPrioridade;
  late TextEditingController _respostaCtrl;

  @override
  void initState() {
    super.initState();
    _novoStatus = widget.chamado.status;
    _novaPrioridade = widget.chamado.prioridade;
    _respostaCtrl = TextEditingController(
        text: widget.chamado.respostaSuporte ?? '');
  }

  @override
  void dispose() {
    _respostaCtrl.dispose();
    super.dispose();
  }

  String _elapsed(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min atrás';
    if (diff.inHours < 24) return '${diff.inHours}h atrás';
    return '${diff.inDays}d atrás';
  }

  Future<void> _salvar() async {
    await ref.read(suporteAdmControllerProvider.notifier).responderChamado(
          chamadoId: widget.chamado.id,
          status: _novoStatus,
          prioridade: _novaPrioridade,
          resposta: _respostaCtrl.text.trim(),
          usuarioId: widget.chamado.usuarioId,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  @override
  Widget build(BuildContext context) {
    final isSaving = ref.watch(
      suporteAdmControllerProvider.select((s) => s.isSaving),
    );

    final tipoCfg = _tipoCfg[widget.chamado.tipoSolicitante] ??
        _tipoCfg['cliente']!;
    final prCfg =
        _priorCfg[widget.chamado.prioridade] ?? _priorCfg['normal']!;
    final catCfg =
        _catCfg[widget.chamado.categoria] ?? _catCfg['outro']!;

    return Dialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 600, maxHeight: 700),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 18, 18, 14),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: tipoCfg.bg,
                      borderRadius: BorderRadius.circular(11),
                    ),
                    child: Icon(tipoCfg.icon,
                        size: 20, color: tipoCfg.c),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 5,
                          runSpacing: 4,
                          children: [
                            Text(
                              widget.chamado.solicitanteNome ??
                                  'Usuário',
                              style: GoogleFonts.dmSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                color: const Color(0xFF1A0910),
                              ),
                            ),
                            _MiniChip(
                                label: tipoCfg.l,
                                color: tipoCfg.c,
                                bg: tipoCfg.bg),
                            _MiniChip(
                                label: prCfg.l,
                                color: prCfg.c,
                                bg: prCfg.bg),
                            _MiniChip(
                                label: catCfg.l,
                                color: catCfg.c,
                                bg: catCfg.c.withValues(alpha: 0.1)),
                          ],
                        ),
                        const SizedBox(height: 3),
                        Text(
                          '${widget.chamado.solicitanteEmail ?? ''} · Aberto ${_elapsed(widget.chamado.createdAt)}',
                          style: GoogleFonts.dmSans(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded,
                        size: 18, color: Color(0xFF9CA3AF)),
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(7),
                          side: const BorderSide(
                              color: Color(0xFFEAE8E4))),
                      padding: const EdgeInsets.all(6),
                    ),
                  ),
                ],
              ),
            ),

            // ── Body ───────────────────────────────────────────────────────
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(22, 16, 22, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Descrição
                    Container(
                      padding: const EdgeInsets.all(14),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9F8F7),
                        borderRadius: BorderRadius.circular(11),
                        border: Border.all(
                            color: const Color(0xFFEAE8E4)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'RELATO DO USUÁRIO',
                            style: GoogleFonts.dmSans(
                              fontSize: 9,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF9CA3AF),
                              letterSpacing: 0.6,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            widget.chamado.descricao,
                            style: GoogleFonts.dmSans(
                              fontSize: 13,
                              color: const Color(0xFF1A0910),
                              height: 1.6,
                            ),
                          ),
                          if (widget.chamado.pedidoId != null) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.inventory_2_outlined,
                                    size: 13,
                                    color: Color(0xFF3B82F6)),
                                const SizedBox(width: 5),
                                Text(
                                  'Pedido vinculado: #${widget.chamado.pedidoId!.substring(widget.chamado.pedidoId!.length - 6)}',
                                  style: GoogleFonts.dmSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF3B82F6),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Controles: status + prioridade
                    Row(
                      children: [
                        Expanded(
                          child: _ModalSelect(
                            label: 'STATUS',
                            value: _novoStatus,
                            items: const {
                              'aberto': '🔴 Aberto',
                              'em_atendimento': '🟡 Em Atendimento',
                              'resolvido': '🟢 Resolvido',
                              'fechado': '⚫ Fechado',
                            },
                            onChanged: (v) =>
                                setState(() => _novoStatus = v),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _ModalSelect(
                            label: 'PRIORIDADE',
                            value: _novaPrioridade,
                            items: const {
                              'baixa': '⬇️ Baixa',
                              'normal': '➡️ Normal',
                              'alta': '⬆️ Alta',
                              'urgente': '🚨 Urgente',
                            },
                            onChanged: (v) =>
                                setState(() => _novaPrioridade = v),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Resposta
                    Text(
                      'RESPOSTA AO USUÁRIO',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF6B7280),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 5),
                    TextField(
                      controller: _respostaCtrl,
                      minLines: 3,
                      maxLines: 6,
                      style: GoogleFonts.dmSans(
                          fontSize: 12.5, color: const Color(0xFF1A0910)),
                      decoration: InputDecoration(
                        hintText:
                            'Digite a resposta que será enviada ao usuário…',
                        hintStyle: GoogleFonts.dmSans(
                            fontSize: 12.5,
                            color: const Color(0xFF9CA3AF)),
                        contentPadding: const EdgeInsets.all(12),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFEAE8E4)),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFEAE8E4)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: const BorderSide(
                              color: Color(0xFFF97316), width: 1.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Respostas rápidas
                    Text(
                      'RESPOSTAS RÁPIDAS',
                      style: GoogleFonts.dmSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF9CA3AF),
                        letterSpacing: 0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: _respostasRapidas.map((t) {
                        return GestureDetector(
                          onTap: () =>
                              _respostaCtrl.text = t,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius:
                                  BorderRadius.circular(7),
                              border: Border.all(
                                  color: const Color(0xFFEAE8E4)),
                            ),
                            child: Text(
                              t.length > 40
                                  ? '${t.substring(0, 40)}…'
                                  : t,
                              style: GoogleFonts.dmSans(
                                fontSize: 10,
                                color: const Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            // ── Footer ─────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 14),
              decoration: const BoxDecoration(
                border:
                    Border(top: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed:
                        isSaving ? null : () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 9),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(9),
                        side: const BorderSide(
                            color: Color(0xFFEAE8E4)),
                      ),
                    ),
                    child: Text(
                      'Cancelar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton.icon(
                    onPressed: isSaving ? null : _salvar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFF97316),
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 20, vertical: 9),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                      elevation: 0,
                    ),
                    icon: isSaving
                        ? const SizedBox(
                            width: 12,
                            height: 12,
                            child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white))
                        : const Icon(Icons.send_rounded, size: 14),
                    label: Text(
                      isSaving ? 'Salvando…' : 'Salvar e Notificar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
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

// ── Widgets auxiliares ────────────────────────────────────────────────────────

class _MiniChip extends StatelessWidget {
  final String label;
  final Color color;
  final Color bg;
  const _MiniChip(
      {required this.label, required this.color, required this.bg});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: GoogleFonts.dmSans(
            fontSize: 9, fontWeight: FontWeight.w700, color: color),
      ),
    );
  }
}

class _ModalSelect extends StatelessWidget {
  final String label;
  final String value;
  final Map<String, String> items;
  final ValueChanged<String> onChanged;

  const _ModalSelect({
    required this.label,
    required this.value,
    required this.items,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.dmSans(
            fontSize: 9,
            fontWeight: FontWeight.w700,
            color: const Color(0xFF6B7280),
            letterSpacing: 0.6,
          ),
        ),
        const SizedBox(height: 5),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(9),
            border: Border.all(
                color: const Color(0xFFEAE8E4), width: 1.5),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: value,
              isDense: true,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF1A0910),
              ),
              icon: const Icon(Icons.expand_more,
                  size: 16, color: Color(0xFF9CA3AF)),
              items: items.entries
                  .map((e) => DropdownMenuItem(
                      value: e.key, child: Text(e.value)))
                  .toList(),
              onChanged: (v) {
                if (v != null) onChanged(v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
