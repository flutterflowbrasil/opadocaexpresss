import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── Constantes de cor (alinhadas com o design system do app cliente) ──────────
const kOrange  = Color(0xFFFF7034);
const kVinho   = Color(0xFF7D2D35);
const kBgLight = Color(0xFFF9F5F0);

// ─────────────────────────────────────────────────────────────────────────────
// _LblWidget — label de campo de formulário
// ─────────────────────────────────────────────────────────────────────────────
class LblWidget extends StatelessWidget {
  final String text;
  const LblWidget(this.text, {super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 5),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: isDark ? Colors.grey[400] : Colors.grey[600],
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// CampoTextoEndereco — TextFormField estilizado para o modal
// ─────────────────────────────────────────────────────────────────────────────
class CampoTextoEndereco extends StatelessWidget {
  final TextEditingController controller;
  final String hint;
  final IconData icon;
  final bool required;
  final bool readOnly;
  final bool autofocus;
  final int maxLines;
  final TextInputType? keyboardType;
  final List<TextInputFormatter>? inputFormatters;
  final String? errorText;
  final ValueChanged<String>? onSubmitted;

  const CampoTextoEndereco({
    super.key,
    required this.controller,
    required this.hint,
    required this.icon,
    this.required = false,
    this.readOnly = false,
    this.autofocus = false,
    this.maxLines = 1,
    this.keyboardType,
    this.inputFormatters,
    this.errorText,
    this.onSubmitted,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final fillReadOnly =
        isDark ? const Color(0xFF3A3A3A) : const Color(0xFFEEEEEE);
    final fillNormal =
        isDark ? const Color(0xFF2A2A2A) : kBgLight;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      maxLines: maxLines,
      keyboardType: keyboardType,
      autofocus: autofocus,
      inputFormatters: inputFormatters,
      onFieldSubmitted: onSubmitted,
      style: GoogleFonts.outfit(
        fontSize: 14,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        hintText: hint,
        errorText: errorText,
        hintStyle: GoogleFonts.outfit(
          color: Colors.grey[400],
          fontSize: 13,
        ),
        prefixIcon: Icon(icon, color: kOrange, size: 18),
        filled: true,
        fillColor: readOnly ? fillReadOnly : fillNormal,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 14),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: kOrange, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
      ),
      validator: required
          ? (v) => (v == null || v.trim().isEmpty) ? 'Campo obrigatório' : null
          : null,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BotaoMapaFlutuante — botão circular branco com ícone (ex: voltar, GPS)
// ─────────────────────────────────────────────────────────────────────────────
class BotaoMapaFlutuante extends StatelessWidget {
  final IconData icon;
  final VoidCallback onTap;
  final bool isLoading;

  const BotaoMapaFlutuante({
    super.key,
    required this.icon,
    required this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        width: 42,
        height: 42,
        decoration: BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.15),
              blurRadius: 8,
            ),
          ],
        ),
        child: isLoading
            ? const Padding(
                padding: EdgeInsets.all(10),
                child: CircularProgressIndicator(
                  color: kOrange,
                  strokeWidth: 2,
                ),
              )
            : Icon(icon, size: 20, color: kVinho),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BotaoPrimario — botão de ação principal (laranja) do modal
// ─────────────────────────────────────────────────────────────────────────────
class BotaoPrimarioModal extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;

  const BotaoPrimarioModal({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isLoading ? null : onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: kOrange,
          disabledBackgroundColor: Colors.grey[300],
          padding: const EdgeInsets.symmetric(vertical: 17),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  color: Colors.white,
                  strokeWidth: 2.5,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.outfit(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// BotaoGpsCard — card de "usar minha localização" da etapa CEP
// ─────────────────────────────────────────────────────────────────────────────
class BotaoGpsCard extends StatelessWidget {
  final bool isLoading;
  final VoidCallback? onTap;

  const BotaoGpsCard({super.key, required this.isLoading, this.onTap});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final cardBg = isDark
        ? kOrange.withValues(alpha: 0.08)
        : kOrange.withValues(alpha: 0.05);

    return GestureDetector(
      onTap: isLoading ? null : onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: cardBg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: kOrange.withValues(alpha: 0.25)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(9),
              decoration: BoxDecoration(
                color: kOrange,
                borderRadius: BorderRadius.circular(9),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                  : const Icon(Icons.my_location, color: Colors.white, size: 18),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Usar minha localização atual',
                    style: GoogleFonts.outfit(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: isDark ? Colors.white : kVinho,
                    ),
                  ),
                  Text(
                    isLoading
                        ? 'Obtendo localização...'
                        : 'Detectar automaticamente via GPS',
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.grey[500],
                    ),
                  ),
                ],
              ),
            ),
            if (!isLoading)
              Icon(Icons.chevron_right, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// PinMapaWidget — pin animado centralizado no mapa fullscreen
// ─────────────────────────────────────────────────────────────────────────────
class PinMapaWidget extends StatelessWidget {
  const PinMapaWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          decoration: BoxDecoration(
            color: kOrange,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: kOrange.withValues(alpha: 0.4),
                blurRadius: 14,
                spreadRadius: 3,
              ),
            ],
          ),
          padding: const EdgeInsets.all(10),
          child: const Icon(Icons.location_on, color: Colors.white, size: 26),
        ),
        Container(width: 2, height: 18, color: kOrange),
        Container(
          width: 8,
          height: 4,
          decoration: BoxDecoration(
            color: kOrange.withValues(alpha: 0.3),
            borderRadius: BorderRadius.circular(4),
          ),
        ),
      ],
    );
  }
}
