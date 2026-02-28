import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class MetodoPagamentoCard extends StatelessWidget {
  final String id;
  final bool isDark;
  final Color bgSecColor;
  final Widget icon;
  final String title;
  final bool selected;
  final ValueChanged<String> onSelected;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const MetodoPagamentoCard({
    super.key,
    required this.id,
    required this.isDark,
    required this.bgSecColor,
    required this.icon,
    required this.title,
    required this.selected,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(id),
      child: Container(
        height: 56, // Altura reduzida para ficar compatível com o do Pix
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: selected
              ? (isDark
                  ? Colors.green[900]!.withValues(alpha: 0.2)
                  : Colors.green[50])
              : (isDark ? _secondaryColor.withValues(alpha: 0.2) : bgSecColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: selected
                ? Colors.green[400]!
                : _primaryColor.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
          boxShadow: [
            if (!isDark && !selected)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 2,
                offset: const Offset(0, 1),
              )
          ],
        ),
        child: Row(
          children: [
            icon,
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: isDark ? Colors.white : _secondaryColor,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MetodoPagamentoSiteCard extends StatelessWidget {
  final String id;
  final bool isDark;
  final Color bgSecColor;
  final bool selected;
  final Widget icon;
  final String title;
  final String? subtitle;
  final ValueChanged<String> onSelected;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const MetodoPagamentoSiteCard({
    super.key,
    required this.id,
    required this.isDark,
    required this.bgSecColor,
    required this.selected,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onSelected,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onSelected(id),
      child: Container(
        padding: const EdgeInsets.all(16),
        constraints: const BoxConstraints(minHeight: 72),
        decoration: BoxDecoration(
          color: selected
              ? (isDark ? _secondaryColor.withValues(alpha: 0.2) : Colors.white)
              : (isDark ? _secondaryColor.withValues(alpha: 0.1) : bgSecColor),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color:
                selected ? _primaryColor : _primaryColor.withValues(alpha: 0.1),
            width: selected ? 2 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              alignment: Alignment.centerLeft,
              child: icon,
            ),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isDark ? Colors.white : _secondaryColor,
                    ),
                  ),
                  if (subtitle != null)
                    Text(
                      subtitle!,
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        color: isDark
                            ? Colors.grey[400]
                            : _secondaryColor.withValues(alpha: 0.6),
                      ),
                    ),
                ],
              ),
            ),
            Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: selected
                      ? _primaryColor
                      : (isDark
                          ? _secondaryColor.withValues(alpha: 0.2)
                          : Colors.grey[300]!),
                  width: selected ? 5 : 1,
                ),
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
