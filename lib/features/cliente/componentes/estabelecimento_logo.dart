import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class EstabelecimentoLogo extends StatelessWidget {
  final String nome;
  final String? logoUrl;
  final double size;
  final double borderRadius;
  final bool circle;
  final BoxBorder? border;
  final List<BoxShadow>? boxShadow;

  static const _primaryColor = Color(0xFFFFB13B);

  const EstabelecimentoLogo({
    super.key,
    required this.nome,
    required this.logoUrl,
    required this.size,
    this.borderRadius = 16,
    this.circle = false,
    this.border,
    this.boxShadow,
  });

  @override
  Widget build(BuildContext context) {
    final url = logoUrl?.trim();
    final hasLogo = url != null && url.isNotEmpty;
    final radius = circle ? size / 2 : borderRadius;

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: _primaryColor,
        shape: circle ? BoxShape.circle : BoxShape.rectangle,
        borderRadius: circle ? null : BorderRadius.circular(radius),
        border: border,
        boxShadow: boxShadow,
      ),
      clipBehavior: Clip.antiAlias,
      child: hasLogo
          ? Image.network(
              url,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => _InitialsFallback(
                nome: nome,
                fontSize: size * 0.32,
              ),
            )
          : _InitialsFallback(
              nome: nome,
              fontSize: size * 0.32,
            ),
    );
  }
}

class _InitialsFallback extends StatelessWidget {
  final String nome;
  final double fontSize;

  const _InitialsFallback({
    required this.nome,
    required this.fontSize,
  });

  @override
  Widget build(BuildContext context) {
    return ColoredBox(
      color: EstabelecimentoLogo._primaryColor,
      child: Center(
        child: Text(
          _initials(nome),
          style: GoogleFonts.outfit(
            fontSize: fontSize,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
          maxLines: 1,
        ),
      ),
    );
  }

  static String _initials(String value) {
    final words = value
        .trim()
        .split(RegExp(r'\s+'))
        .where((word) => word.isNotEmpty)
        .toList();

    if (words.isEmpty) return 'PD';
    if (words.length == 1) return _takeChars(words.first, 3).toUpperCase();

    return words
        .take(3)
        .map((word) => _takeChars(word, 1))
        .join()
        .toUpperCase();
  }

  static String _takeChars(String value, int count) {
    return String.fromCharCodes(value.runes.take(count));
  }
}
