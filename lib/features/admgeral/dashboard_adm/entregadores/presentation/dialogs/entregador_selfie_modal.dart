import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../models/entregador_adm_model.dart';

class EntregadorSelfieModal extends StatefulWidget {
  final EntregadorAdmModel entregador;
  final bool isSubmitting;
  final Future<void> Function(String status, String? observacao) onRevisar;
  final VoidCallback onClose;

  const EntregadorSelfieModal({
    super.key,
    required this.entregador,
    required this.isSubmitting,
    required this.onRevisar,
    required this.onClose,
  });

  @override
  State<EntregadorSelfieModal> createState() => _EntregadorSelfieModalState();
}

class _EntregadorSelfieModalState extends State<EntregadorSelfieModal> {
  final _obsCtrl = TextEditingController();

  @override
  void dispose() {
    _obsCtrl.dispose();
    super.dispose();
  }

  EntregadorAdmModel get e => widget.entregador;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Material(
        color: Colors.transparent,
        child: Container(
          width: 480,
          constraints: const BoxConstraints(maxHeight: 680),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                  color: Colors.black.withValues(alpha: 0.25), blurRadius: 64)
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildHeader(),
              Flexible(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(22, 18, 22, 22),
                  child: _buildBody(),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 18, 22, 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F1EE))),
      ),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: const Color(0xFFEFF6FF),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Center(child: Text('🤳', style: TextStyle(fontSize: 18))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Revisão de Selfie',
                    style: GoogleFonts.dmSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: const Color(0xFF1A0910))),
                Text('${e.nome} — verificação manual',
                    style: GoogleFonts.dmSans(
                        fontSize: 11, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          GestureDetector(
            onTap: widget.onClose,
            child: Container(
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(7),
                  border: Border.all(
                      color: const Color(0xFFEAE8E4), width: 1.5)),
              child: const Icon(Icons.close, size: 14, color: Color(0xFF6B7280)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBody() {
    final selfieUrl = e.selfieRevisao?.fotoSelfieUrl;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // ── Área da selfie ──────────────────────────────────
        Container(
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFFF4F2EF),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color(0xFFEAE8E4)),
          ),
          clipBehavior: Clip.hardEdge,
          child: selfieUrl != null
              ? Image.network(selfieUrl, fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => _selfieStoragePlaceholder())
              : _selfieStoragePlaceholder(),
        ),
        const SizedBox(height: 14),

        // ── Checklist ────────────────────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFF9F8F7),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFEAE8E4)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Verificar na selfie:',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF6B7280))),
              const SizedBox(height: 8),
              ..._checklistItems.map((item) => Padding(
                    padding: const EdgeInsets.only(bottom: 5),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Padding(
                          padding: EdgeInsets.only(top: 2),
                          child: Icon(Icons.circle,
                              size: 5, color: Color(0xFF3B82F6)),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(item,
                              style: GoogleFonts.dmSans(
                                  fontSize: 11,
                                  color: const Color(0xFF374151))),
                        ),
                      ],
                    ),
                  )),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Como acessar no Storage ─────────────────────────
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: const Color(0xFFFFFBEB),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: const Color(0xFFFDE68A)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('📂 Como visualizar a selfie',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF92400E))),
              const SizedBox(height: 6),
              Text(
                'Supabase Dashboard → Storage → documentos-entregador\n'
                '→ pasta ${e.id}/ → selfie.*',
                style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFFB45309),
                    height: 1.6),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),

        // ── Observação ───────────────────────────────────────
        Text('OBSERVAÇÃO (opcional)',
            style: GoogleFonts.dmSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF6B7280),
                letterSpacing: 0.5)),
        const SizedBox(height: 6),
        TextField(
          controller: _obsCtrl,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: 'Ex: Selfie aprovada — rosto visível e nítido.',
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
        const SizedBox(height: 16),

        // ── Botões ────────────────────────────────────────────
        Row(
          children: [
            Expanded(
              child: _actionBtn(
                label: '❌  Reprovar selfie',
                color: const Color(0xFFDC2626),
                bgColor: const Color(0xFFFEF2F2),
                borderColor: const Color(0xFFFCA5A5),
                onTap: () => _revisar('reprovado'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _actionBtn(
                label: '✅  Aprovar selfie',
                color: const Color(0xFF065F46),
                bgColor: const Color(0xFFECFDF5),
                borderColor: const Color(0xFFA7F3D0),
                onTap: () => _revisar('aprovado'),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Future<void> _revisar(String status) async {
    if (widget.isSubmitting) return;
    final obs = _obsCtrl.text.trim();
    await widget.onRevisar(status, obs.isEmpty ? null : obs);
    widget.onClose();
  }

  Widget _actionBtn({
    required String label,
    required Color color,
    required Color bgColor,
    required Color borderColor,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: widget.isSubmitting ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(11),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: borderColor, width: 2),
        ),
        child: widget.isSubmitting
            ? const Center(
                child: SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2)))
            : Center(
                child: Text(label,
                    style: GoogleFonts.dmSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: color)),
              ),
      ),
    );
  }

  Widget _selfieStoragePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Icon(Icons.camera_alt_outlined,
            size: 48, color: Color(0xFFD1D5DB)),
        const SizedBox(height: 8),
        Text('Selfie enviada pelo app',
            style: GoogleFonts.dmSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF6B7280))),
        const SizedBox(height: 4),
        Text('Acesse o Supabase Storage para visualizar',
            style: GoogleFonts.dmSans(
                fontSize: 11, color: const Color(0xFF9CA3AF))),
      ],
    );
  }
}

const _checklistItems = [
  'Rosto completamente visível e sem obstruções',
  'Sem óculos escuros ou máscara cobrindo o rosto',
  'Iluminação adequada — foto não está escura ou estourada',
  'A pessoa está olhando para a câmera',
  'Não é foto de foto (tela de celular ou impresso)',
];
