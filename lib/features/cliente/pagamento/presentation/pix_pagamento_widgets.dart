import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:qr_flutter/qr_flutter.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Card do QR Code PIX
// ─────────────────────────────────────────────────────────────────────────────
class PixQrCodeCard extends StatelessWidget {
  final String pixCopiaECola;
  final String? pixQrCodeBase64;

  static const _primaryColor = Color(0xFFFF7034);

  const PixQrCodeCard({
    super.key,
    required this.pixCopiaECola,
    this.pixQrCodeBase64,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    Widget qrWidget;
    if (pixQrCodeBase64 != null && pixQrCodeBase64!.isNotEmpty) {
      try {
        qrWidget = Image.memory(
          base64Decode(pixQrCodeBase64!),
          width: 240,
          height: 240,
          fit: BoxFit.contain,
        );
      } catch (_) {
        qrWidget = _qrView();
      }
    } else if (pixCopiaECola.isNotEmpty) {
      qrWidget = _qrView();
    } else {
      qrWidget = const SizedBox(
        width: 240,
        height: 240,
        child: Center(child: CircularProgressIndicator()),
      );
    }

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _primaryColor.withValues(alpha: 0.15),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.pix, color: _primaryColor, size: 20),
              const SizedBox(width: 8),
              Text(
                'Escaneie o QR Code',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF7D2D35),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: qrWidget,
          ),
          const SizedBox(height: 12),
          Text(
            'Abra seu app de pagamentos e escaneie o código',
            textAlign: TextAlign.center,
            style: GoogleFonts.outfit(
              fontSize: 12,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _qrView() {
    return QrImageView(
      data: pixCopiaECola,
      version: QrVersions.auto,
      size: 240,
      backgroundColor: Colors.white,
      errorStateBuilder: (ctx, err) => const SizedBox(
        width: 240,
        height: 240,
        child: Center(
          child: Text('Erro ao gerar QR Code', textAlign: TextAlign.center),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Contador regressivo (MM:SS)
// ─────────────────────────────────────────────────────────────────────────────
class CountdownTimerWidget extends StatelessWidget {
  final int segundosRestantes;

  const CountdownTimerWidget({super.key, required this.segundosRestantes});

  @override
  Widget build(BuildContext context) {
    final min = (segundosRestantes ~/ 60).toString().padLeft(2, '0');
    final seg = (segundosRestantes % 60).toString().padLeft(2, '0');
    final isUrgente = segundosRestantes <= 60;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'O tempo para você pagar acaba em:',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 4),
        AnimatedDefaultTextStyle(
          duration: const Duration(milliseconds: 300),
          style: GoogleFonts.outfit(
            fontSize: 36,
            fontWeight: FontWeight.bold,
            color: isUrgente ? Colors.red[600]! : const Color(0xFFFF7034),
          ),
          child: Text('$min:$seg'),
        ),
        if (isUrgente)
          Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              'Finalize o pagamento agora!',
              style: GoogleFonts.outfit(
                fontSize: 12,
                color: Colors.red[400],
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Botão Copia e Cola
// ─────────────────────────────────────────────────────────────────────────────
class CopiaColaButton extends StatelessWidget {
  final String pixCopiaECola;

  static const _primaryColor = Color(0xFFFF7034);

  const CopiaColaButton({super.key, required this.pixCopiaECola});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      children: [
        Text(
          'Ou copie o código:',
          style: GoogleFonts.outfit(
            fontSize: 13,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          decoration: BoxDecoration(
            color: isDark
                ? Colors.white.withValues(alpha: 0.06)
                : Colors.grey.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(
              color: _primaryColor.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  pixCopiaECola,
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color:
                        isDark ? Colors.grey[300] : Colors.grey[700],
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                onTap: () async {
                  await Clipboard.setData(
                      ClipboardData(text: pixCopiaECola));
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Código copiado!',
                          style: GoogleFonts.outfit(),
                        ),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: _primaryColor,
                        duration: const Duration(seconds: 2),
                      ),
                    );
                  }
                },
                borderRadius: BorderRadius.circular(6),
                child: const Padding(
                  padding: EdgeInsets.all(4),
                  child: Icon(Icons.copy_outlined,
                      size: 18, color: _primaryColor),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
