import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../componentes_dash/dashboard_colors.dart';

class ConfigSectionCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final String? subtitle;
  final Widget? trailing;
  final List<Widget> children;
  final bool isDark;
  final Color? headerIconColor;
  final Color? backgroundColor;
  final Color? borderColor;
  final Widget? headerBadge;

  const ConfigSectionCard({
    super.key,
    required this.title,
    required this.icon,
    this.subtitle,
    this.trailing,
    required this.children,
    required this.isDark,
    this.headerIconColor,
    this.backgroundColor,
    this.borderColor,
    this.headerBadge,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 24),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: backgroundColor ?? (isDark ? Colors.grey[900] : Colors.white),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color:
              borderColor ?? (isDark ? Colors.grey[800]! : Colors.grey[200]!),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Icon(icon,
                            color: headerIconColor ?? DashboardColors.primary,
                            size: 20),
                        const SizedBox(width: 8),
                        Text(
                          title,
                          style: GoogleFonts.publicSans(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isDark ? Colors.white : Colors.black87,
                          ),
                        ),
                        if (headerBadge != null) ...[
                          const SizedBox(width: 12),
                          headerBadge!,
                        ],
                      ],
                    ),
                    if (subtitle != null) ...[
                      const SizedBox(height: 4),
                      Text(
                        subtitle!,
                        style: GoogleFonts.publicSans(
                          fontSize: 14,
                          color: Colors.grey[500],
                        ),
                      ),
                    ]
                  ],
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 24),
          ...children,
        ],
      ),
    );
  }
}

class ConfigTextField extends StatelessWidget {
  final String label;
  final String placeholder;
  final bool isDark;
  final int maxLines;
  final Widget? prefix;
  final Widget? suffix;
  final String? helperText;
  final String? initialValue;
  final TextEditingController? controller;
  final ValueChanged<String>? onChanged;
  final TextInputType? keyboardType;
  final bool isRequired;
  final bool readOnly;

  const ConfigTextField({
    super.key,
    required this.label,
    required this.placeholder,
    required this.isDark,
    this.maxLines = 1,
    this.prefix,
    this.suffix,
    this.helperText,
    this.initialValue,
    this.controller,
    this.onChanged,
    this.keyboardType,
    this.isRequired = false,
    this.readOnly = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.bold,
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
            if (isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: DashboardColors.primary,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          initialValue: initialValue,
          controller: controller,
          onChanged: onChanged,
          maxLines: maxLines,
          keyboardType: keyboardType,
          readOnly: readOnly,
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
          decoration: InputDecoration(
            hintText: placeholder,
            hintStyle: TextStyle(color: Colors.grey[400]),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: DashboardColors.primary, width: 2),
            ),
            prefixIcon: prefix != null
                ? Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [prefix!]))
                : null,
            suffixIcon: suffix,
          ),
        ),
        if (helperText != null) ...[
          const SizedBox(height: 4),
          Text(helperText!,
              style: TextStyle(fontSize: 12, color: Colors.grey[500]))
        ]
      ],
    );
  }
}

class ConfigDropdownField extends StatelessWidget {
  final String label;
  final List<String> items;
  final String? value;
  final bool isDark;
  final ValueChanged<String?>? onChanged;

  const ConfigDropdownField({
    super.key,
    required this.label,
    required this.items,
    this.value,
    required this.isDark,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: isDark ? Colors.white70 : Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: value ?? (items.isNotEmpty ? items.first : null),
          dropdownColor: isDark ? Colors.grey[800] : Colors.white,
          icon: Icon(Icons.keyboard_arrow_down, color: Colors.grey[500]),
          style: TextStyle(
              color: isDark ? Colors.white : Colors.black87, fontSize: 14),
          decoration: InputDecoration(
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            filled: true,
            fillColor: isDark ? Colors.grey[800] : Colors.grey[50],
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(
                  color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide:
                  const BorderSide(color: DashboardColors.primary, width: 2),
            ),
          ),
          onChanged: onChanged,
          items: items.map<DropdownMenuItem<String>>((String value) {
            return DropdownMenuItem<String>(
              value: value,
              child: Text(value, overflow: TextOverflow.ellipsis),
            );
          }).toList(),
        ),
      ],
    );
  }
}
