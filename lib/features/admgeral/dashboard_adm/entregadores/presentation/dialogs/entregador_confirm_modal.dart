import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/entregador_adm_model.dart';

class EntregadorConfirmModal extends StatefulWidget {
  final String acao;
  final EntregadorAdmModel entregador;
  final bool isSubmitting;
  final Future<void> Function(String acao, String id, String? motivo) onConfirm;
  final VoidCallback onClose;

  const EntregadorConfirmModal({
    super.key,
    required this.acao,
    required this.entregador,
    required this.isSubmitting,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<EntregadorConfirmModal> createState() => _EntregadorConfirmModalState();
}

class _EntregadorConfirmModalState extends State<EntregadorConfirmModal> {
  final _motivoCtrl = TextEditingController();

  @override
  void dispose() {
    _motivoCtrl.dispose();
    super.dispose();
  }

  bool get _precisaMotivo =>
      widget.acao == 'suspender' || widget.acao == 'rejeitar';

  bool get _podeConfirmar =>
      !_precisaMotivo || _motivoCtrl.text.trim().isNotEmpty;

  _AcaoCfg get _cfg => _acaoConfigs[widget.acao]!;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 440,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.2), blurRadius: 64)],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              _buildBody(),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    final cfg = _cfg;
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 20, 22, 16),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F1EE))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: cfg.bgColor,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(child: Text(cfg.icon, style: const TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(cfg.title,
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0910))),
                Text(widget.entregador.nome,
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          _closeButton(),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final cfg = _cfg;
    return Padding(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFFF9F8F7),
              borderRadius: BorderRadius.circular(9),
            ),
            child: Text(cfg.desc,
                style: GoogleFonts.dmSans(
                    fontSize: 12, color: const Color(0xFF6B7280))),
          ),
          if (_precisaMotivo) ...[
            const SizedBox(height: 14),
            Text('MOTIVO *',
                style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF6B7280),
                    letterSpacing: 0.5)),
            const SizedBox(height: 6),
            TextField(
              controller: _motivoCtrl,
              maxLines: 3,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Descreva o motivo…',
                hintStyle: GoogleFonts.dmSans(
                    fontSize: 12, color: const Color(0xFF9CA3AF)),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide:
                      const BorderSide(color: Color(0xFF3B82F6), width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(12),
              ),
              style: GoogleFonts.dmSans(
                  fontSize: 12, color: const Color(0xFF1A0910)),
            ),
          ],
          const SizedBox(height: 18),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              _outlineBtn('Cancelar', widget.onClose),
              const SizedBox(width: 8),
              _confirmBtn(),
            ],
          ),
        ],
      ),
    );
  }

  Widget _outlineBtn(String label, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(9),
          border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
        ),
        child: Text('Cancelar',
            style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280))),
      ),
    );
  }

  Widget _confirmBtn() {
    final canConfirm = _podeConfirmar && !widget.isSubmitting;
    return GestureDetector(
      onTap: canConfirm
          ? () async {
              await widget.onConfirm(
                widget.acao,
                widget.entregador.id,
                _motivoCtrl.text.trim().isEmpty
                    ? null
                    : _motivoCtrl.text.trim(),
              );
            }
          : null,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 9),
        decoration: BoxDecoration(
          color: canConfirm ? _cfg.color : _cfg.color.withValues(alpha: 0.4),
          borderRadius: BorderRadius.circular(9),
        ),
        child: widget.isSubmitting
            ? const SizedBox(
                width: 16,
                height: 16,
                child: CircularProgressIndicator(
                    strokeWidth: 2, color: Colors.white),
              )
            : Text(_cfg.btnLabel,
                style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Colors.white)),
      ),
    );
  }

  Widget _closeButton() {
    return GestureDetector(
      onTap: widget.onClose,
      child: Container(
        width: 28,
        height: 28,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(7),
          border: Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
        ),
        child: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
      ),
    );
  }
}

// ── Configurações por ação ─────────────────────────────────────────────────────

class _AcaoCfg {
  final String title, desc, btnLabel, icon;
  final Color color, bgColor;
  const _AcaoCfg(
      {required this.title,
      required this.desc,
      required this.btnLabel,
      required this.icon,
      required this.color,
      required this.bgColor});
}

const _acaoConfigs = {
  'aprovar': _AcaoCfg(
    title: 'Aprovar entregador',
    desc: 'Libera o entregador na plataforma. Cria carteira Asaas automaticamente.',
    btnLabel: 'Confirmar aprovação',
    icon: '✅',
    color: Color(0xFF10B981),
    bgColor: Color(0xFFECFDF5),
  ),
  'rejeitar': _AcaoCfg(
    title: 'Rejeitar cadastro',
    desc: 'Notifica o entregador com o motivo. Cadastro fica arquivado.',
    btnLabel: 'Confirmar rejeição',
    icon: '❌',
    color: Color(0xFFEF4444),
    bgColor: Color(0xFFFEF2F2),
  ),
  'suspender': _AcaoCfg(
    title: 'Suspender entregador',
    desc: 'Bloqueia novas entregas imediatamente.',
    btnLabel: 'Confirmar suspensão',
    icon: '⚠️',
    color: Color(0xFFF59E0B),
    bgColor: Color(0xFFFFFBEB),
  ),
  'reativar': _AcaoCfg(
    title: 'Reativar entregador',
    desc: 'Retorna o entregador ao status aprovado.',
    btnLabel: 'Confirmar reativação',
    icon: '🔓',
    color: Color(0xFF10B981),
    bgColor: Color(0xFFECFDF5),
  ),
};
