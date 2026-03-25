import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

// ── ConfigRow ─────────────────────────────────────────────────────────────────

/// Linha de configuração: label + descrição opcional + controle à direita.
class ConfigRow extends StatelessWidget {
  final String label;
  final String? descricao;
  final bool editavel;
  final Widget control;

  const ConfigRow({
    super.key,
    required this.label,
    required this.control,
    this.descricao,
    this.editavel = true,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF3F4F6))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        label,
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: editavel
                              ? const Color(0xFF1A0910)
                              : const Color(0xFF9CA3AF),
                        ),
                      ),
                    ),
                    if (!editavel) ...[
                      const SizedBox(width: 6),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF3F4F6),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          'somente leitura',
                          style: GoogleFonts.dmSans(
                            fontSize: 9,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
                if (descricao != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    descricao!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 16),
          control,
        ],
      ),
    );
  }
}

// ── ConfigToggle ──────────────────────────────────────────────────────────────

class ConfigToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool>? onChanged;

  const ConfigToggle({super.key, required this.value, this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Switch(
      value: value,
      onChanged: onChanged,
      activeThumbColor: const Color(0xFFF97316),
      activeTrackColor: const Color(0xFFFED7AA),
      inactiveThumbColor: const Color(0xFFD1D5DB),
      inactiveTrackColor: const Color(0xFFF3F4F6),
      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
    );
  }
}

// ── ConfigNumInput ────────────────────────────────────────────────────────────

class ConfigNumInput extends StatefulWidget {
  final String value;
  final String? suffix;
  final String? prefix;
  final ValueChanged<String>? onChanged;
  final bool decimal;

  const ConfigNumInput({
    super.key,
    required this.value,
    this.suffix,
    this.prefix,
    this.onChanged,
    this.decimal = true,
  });

  @override
  State<ConfigNumInput> createState() => _ConfigNumInputState();
}

class _ConfigNumInputState extends State<ConfigNumInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(ConfigNumInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readonly = widget.onChanged == null;
    return SizedBox(
      width: 120,
      height: 36,
      child: TextField(
        controller: _ctrl,
        readOnly: readonly,
        keyboardType: TextInputType.numberWithOptions(
          decimal: widget.decimal,
          signed: false,
        ),
        inputFormatters: [
          FilteringTextInputFormatter.allow(
            widget.decimal ? RegExp(r'^\d*\.?\d*') : RegExp(r'^\d*'),
          ),
        ],
        onChanged: widget.onChanged,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: readonly ? const Color(0xFF9CA3AF) : const Color(0xFF1A0910),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor:
              readonly ? const Color(0xFFF9FAFB) : const Color(0xFFFFF7ED),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
          ),
          prefixText: widget.prefix,
          suffixText: widget.suffix,
          prefixStyle: GoogleFonts.dmSans(
              fontSize: 12, color: const Color(0xFF9CA3AF)),
          suffixStyle: GoogleFonts.dmSans(
              fontSize: 12, color: const Color(0xFF9CA3AF)),
        ),
      ),
    );
  }
}

// ── ConfigSel ─────────────────────────────────────────────────────────────────

class ConfigSel extends StatelessWidget {
  final String value;
  final Map<String, String> options;
  final ValueChanged<String>? onChanged;

  const ConfigSel({
    super.key,
    required this.value,
    required this.options,
    this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final readonly = onChanged == null;
    // Garante que o value existe nas opções
    final safeValue = options.containsKey(value) ? value : options.keys.first;

    return Container(
      height: 36,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: readonly ? const Color(0xFFF9FAFB) : Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: safeValue,
          isDense: true,
          style: GoogleFonts.dmSans(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: readonly
                ? const Color(0xFF9CA3AF)
                : const Color(0xFF374151),
          ),
          icon: Icon(
            Icons.expand_more,
            size: 16,
            color: readonly
                ? const Color(0xFFD1D5DB)
                : const Color(0xFF9CA3AF),
          ),
          onChanged: readonly
              ? null
              : (v) {
                  if (v != null) onChanged!(v);
                },
          items: options.entries
              .map(
                (e) => DropdownMenuItem(
                  value: e.key,
                  child: Text(e.value),
                ),
              )
              .toList(),
        ),
      ),
    );
  }
}

// ── ConfigTextInput ───────────────────────────────────────────────────────────

class ConfigTextInput extends StatefulWidget {
  final String value;
  final ValueChanged<String>? onChanged;

  const ConfigTextInput({super.key, required this.value, this.onChanged});

  @override
  State<ConfigTextInput> createState() => _ConfigTextInputState();
}

class _ConfigTextInputState extends State<ConfigTextInput> {
  late TextEditingController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = TextEditingController(text: widget.value);
  }

  @override
  void didUpdateWidget(ConfigTextInput oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.value != widget.value && _ctrl.text != widget.value) {
      _ctrl.text = widget.value;
    }
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final readonly = widget.onChanged == null;
    return SizedBox(
      width: 200,
      height: 36,
      child: TextField(
        controller: _ctrl,
        readOnly: readonly,
        onChanged: widget.onChanged,
        style: GoogleFonts.dmSans(
          fontSize: 13,
          color: readonly ? const Color(0xFF9CA3AF) : const Color(0xFF1A0910),
        ),
        decoration: InputDecoration(
          filled: true,
          fillColor:
              readonly ? const Color(0xFFF9FAFB) : const Color(0xFFFFF7ED),
          contentPadding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFEAE8E4)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(8),
            borderSide: const BorderSide(color: Color(0xFFF97316), width: 1.5),
          ),
        ),
      ),
    );
  }
}

// ── ConfigSection ─────────────────────────────────────────────────────────────

/// Card de seção com título e lista de ConfigRow.
class ConfigSection extends StatelessWidget {
  final String titulo;
  final String? subtitulo;
  final List<Widget> rows;

  const ConfigSection({
    super.key,
    required this.titulo,
    required this.rows,
    this.subtitulo,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                if (subtitulo != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    subtitulo!,
                    style: GoogleFonts.dmSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAE8E4)),
          ...rows,
        ],
      ),
    );
  }
}

// ── ConfigInfoBanner ──────────────────────────────────────────────────────────

/// Banner informativo (amarelo) para campos sensíveis ou avisos gerais.
class ConfigInfoBanner extends StatelessWidget {
  final String mensagem;
  final Color? borderColor;
  final Color? bgColor;
  final Color? iconColor;
  final Color? textColor;

  const ConfigInfoBanner({
    super.key,
    required this.mensagem,
    this.borderColor,
    this.bgColor,
    this.iconColor,
    this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: bgColor ?? const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: borderColor ?? const Color(0xFFFDE68A)),
      ),
      child: Row(
        children: [
          Icon(
            Icons.warning_amber_rounded,
            size: 15,
            color: iconColor ?? const Color(0xFFF59E0B),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              mensagem,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                color: textColor ?? const Color(0xFF92400E),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── ConfigShimmer ─────────────────────────────────────────────────────────────

/// Shimmer de carregamento para a tela de configurações.
class ConfigShimmer extends StatefulWidget {
  const ConfigShimmer({super.key});

  @override
  State<ConfigShimmer> createState() => _ConfigShimmerState();
}

class _ConfigShimmerState extends State<ConfigShimmer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1400),
    )..repeat();
    _animation = CurvedAnimation(parent: _controller, curve: Curves.easeInOut);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (_, __) {
        return Column(
          children: List.generate(
            3,
            (i) => Container(
              margin: const EdgeInsets.only(bottom: 16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFEAE8E4)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 14),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: _shimmerBox(120, 13),
                  ),
                  const SizedBox(height: 10),
                  const Divider(height: 1, color: Color(0xFFEAE8E4)),
                  ...List.generate(
                    3 + i,
                    (_) => Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 18, vertical: 14),
                      child: Row(
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              _shimmerBox(160, 12),
                              const SizedBox(height: 5),
                              _shimmerBox(220, 10),
                            ],
                          ),
                          const Spacer(),
                          _shimmerBox(80, 30),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _shimmerBox(double w, double h) {
    return Container(
      width: w,
      height: h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        gradient: LinearGradient(
          colors: const [Color(0xFFF3F4F6), Color(0xFFE5E7EB), Color(0xFFF3F4F6)],
          stops: [
            (_animation.value - 0.3).clamp(0.0, 1.0),
            _animation.value.clamp(0.0, 1.0),
            (_animation.value + 0.3).clamp(0.0, 1.0),
          ],
        ),
      ),
    );
  }
}
