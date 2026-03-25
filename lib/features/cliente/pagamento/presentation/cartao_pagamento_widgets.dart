import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Preview animado do cartão
// ─────────────────────────────────────────────────────────────────────────────
class CartaoPreviewWidget extends StatelessWidget {
  final String numero; // dígitos digitados (sem máscara)
  final String nome;
  final String vencimento; // "MM/AA"
  final bool isCredito;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const CartaoPreviewWidget({
    super.key,
    required this.numero,
    required this.nome,
    required this.vencimento,
    required this.isCredito,
  });

  String get _numeroMascarado {
    final d = numero.replaceAll(RegExp(r'\D'), '');
    if (d.isEmpty) return '•••• •••• •••• ••••';
    final padded = d.padRight(16, '•');
    final groups = [
      padded.substring(0, 4),
      padded.substring(4, 8),
      padded.substring(8, 12),
      padded.substring(12, 16),
    ];
    // Mostra apenas o último grupo real; os demais ficam mascarados
    return '•••• •••• •••• ${groups[3].replaceAll('•', '•')}';
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 340),
        child: AspectRatio(
          aspectRatio: 16 / 10,
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [_primaryColor, _secondaryColor],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: _primaryColor.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Linha topo: logo + badge tipo
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'ÔPadoca',
                      style: GoogleFonts.outfit(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        letterSpacing: 1,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        isCredito ? 'CRÉDITO' : 'DÉBITO',
                        style: GoogleFonts.outfit(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 10,
                          letterSpacing: 1,
                        ),
                      ),
                    ),
                  ],
                ),
                const Spacer(),
                // Número
                Text(
                  _numeroMascarado,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 3,
                  ),
                ),
                const SizedBox(height: 16),
                // Nome + Validade
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'TITULAR',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          nome.isEmpty ? 'NOME IMPRESSO' : nome.toUpperCase(),
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'VALIDADE',
                          style: GoogleFonts.outfit(
                            color: Colors.white54,
                            fontSize: 9,
                            letterSpacing: 1,
                          ),
                        ),
                        Text(
                          vencimento.isEmpty ? 'MM/AA' : vencimento,
                          style: GoogleFonts.outfit(
                            color: Colors.white,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Campo de texto estilizado para o modal de cartão
// ─────────────────────────────────────────────────────────────────────────────
class CampoCartao extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final TextInputFormatter? formatter;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final bool obscureText;
  final int? maxLength;
  final String? hint;
  final TextCapitalization textCapitalization;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const CampoCartao({
    super.key,
    required this.label,
    required this.controller,
    this.formatter,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.obscureText = false,
    this.maxLength,
    this.hint,
    this.textCapitalization = TextCapitalization.none,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      textCapitalization: textCapitalization,
      inputFormatters: formatter != null ? [formatter!] : [],
      validator: validator,
      style: GoogleFonts.outfit(
        fontSize: 15,
        color: isDark ? Colors.white : Colors.black87,
      ),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        counterText: '',
        labelStyle: GoogleFonts.outfit(
          color: isDark
              ? Colors.grey[400]
              : _secondaryColor.withValues(alpha: 0.7),
          fontSize: 14,
        ),
        hintStyle: GoogleFonts.outfit(
          color: Colors.grey[400],
          fontSize: 14,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : Colors.grey.withValues(alpha: 0.3),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _primaryColor, width: 1.5),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.red[400]!, width: 1.5),
        ),
        filled: true,
        fillColor: isDark
            ? Colors.white.withValues(alpha: 0.05)
            : Colors.grey.withValues(alpha: 0.04),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      ),
    );
  }
}
