import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/estab_adm_model.dart';

class EstabConfirmModal extends StatefulWidget {
  final String acao;
  final EstabAdmModel estab;
  final void Function(String acao, String motivo) onConfirm;
  final VoidCallback onClose;

  const EstabConfirmModal({
    super.key,
    required this.acao,
    required this.estab,
    required this.onConfirm,
    required this.onClose,
  });

  @override
  State<EstabConfirmModal> createState() => _EstabConfirmModalState();
}

class _EstabConfirmModalState extends State<EstabConfirmModal> {
  final _motivoController = TextEditingController();

  @override
  void dispose() {
    _motivoController.dispose();
    super.dispose();
  }

  bool get _precisaMotivo =>
      widget.acao == 'suspender' || widget.acao == 'rejeitar';

  bool get _podeConfirmar =>
      !_precisaMotivo || _motivoController.text.trim().isNotEmpty;

  static const _cfg = {
    'aprovar': (
      title: 'Aprovar estabelecimento',
      color: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
      btn: 'Confirmar aprovação',
      emoji: '✅',
    ),
    'rejeitar': (
      title: 'Rejeitar cadastro',
      color: Color(0xFFEF4444),
      bg: Color(0xFFFEF2F2),
      btn: 'Confirmar rejeição',
      emoji: '❌',
    ),
    'suspender': (
      title: 'Suspender estabelecimento',
      color: Color(0xFFF59E0B),
      bg: Color(0xFFFFFBEB),
      btn: 'Confirmar suspensão',
      emoji: '⚠️',
    ),
    'reativar': (
      title: 'Reativar estabelecimento',
      color: Color(0xFF10B981),
      bg: Color(0xFFECFDF5),
      btn: 'Confirmar reativação',
      emoji: '🔓',
    ),
  };

  @override
  Widget build(BuildContext context) {
    final cfg = _cfg[widget.acao] ?? _cfg['aprovar']!;

    return Dialog(
      backgroundColor: Colors.transparent,
      child: GestureDetector(
        onTap: widget.onClose,
        child: Container(
          color: Colors.transparent,
          child: Center(
            child: GestureDetector(
              onTap: () {},
              child: Container(
                width: 420,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.18),
                      blurRadius: 40,
                      offset: const Offset(0, 12),
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 14),
                      decoration: const BoxDecoration(
                        border: Border(
                          bottom: BorderSide(color: Color(0xFFF3F1EE)),
                        ),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 40,
                            height: 40,
                            decoration: BoxDecoration(
                              color: cfg.bg,
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: Center(
                              child: Text(
                                cfg.emoji,
                                style: const TextStyle(fontSize: 18),
                              ),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  cfg.title,
                                  style: GoogleFonts.publicSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF1A0910),
                                  ),
                                ),
                                Text(
                                  widget.estab.nomeFantasia,
                                  style: GoogleFonts.publicSans(
                                    fontSize: 11,
                                    color: const Color(0xFF9CA3AF),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          GestureDetector(
                            onTap: widget.onClose,
                            child: Container(
                              width: 28,
                              height: 28,
                              decoration: BoxDecoration(
                                border: Border.all(color: const Color(0xFFEAE8E4)),
                                borderRadius: BorderRadius.circular(7),
                              ),
                              child: const Icon(
                                Icons.close,
                                size: 14,
                                color: Color(0xFF6B7280),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Body
                    Padding(
                      padding: const EdgeInsets.fromLTRB(18, 16, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (_precisaMotivo) ...[
                            Text(
                              'Motivo ${widget.acao == 'suspender' ? 'da suspensão' : 'da rejeição'} *',
                              style: GoogleFonts.publicSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF6B7280),
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(height: 6),
                            TextField(
                              controller: _motivoController,
                              maxLines: 3,
                              onChanged: (_) => setState(() {}),
                              style: GoogleFonts.publicSans(
                                fontSize: 12,
                                color: const Color(0xFF1A0910),
                              ),
                              decoration: InputDecoration(
                                hintText:
                                    'Descreva o motivo ${widget.acao == 'suspender' ? 'da suspensão' : 'da rejeição'}…',
                                hintStyle: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF),
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                                filled: true,
                                fillColor: const Color(0xFFF9F8F7),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFEAE8E4)),
                                ),
                                enabledBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide:
                                      const BorderSide(color: Color(0xFFEAE8E4)),
                                ),
                                focusedBorder: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(9),
                                  borderSide: const BorderSide(
                                    color: Color(0xFFF97316),
                                    width: 1.5,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 14),
                          ],
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              GestureDetector(
                                onTap: widget.onClose,
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 9,
                                  ),
                                  decoration: BoxDecoration(
                                    color: Colors.white,
                                    border: Border.all(
                                        color: const Color(0xFFEAE8E4)),
                                    borderRadius: BorderRadius.circular(9),
                                  ),
                                  child: Text(
                                    'Cancelar',
                                    style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF6B7280),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              GestureDetector(
                                onTap: _podeConfirmar
                                    ? () => widget.onConfirm(
                                          widget.acao,
                                          _motivoController.text.trim(),
                                        )
                                    : null,
                                child: Opacity(
                                  opacity: _podeConfirmar ? 1.0 : 0.4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 16,
                                      vertical: 9,
                                    ),
                                    decoration: BoxDecoration(
                                      color: cfg.color,
                                      borderRadius: BorderRadius.circular(9),
                                    ),
                                    child: Text(
                                      cfg.btn,
                                      style: GoogleFonts.publicSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
