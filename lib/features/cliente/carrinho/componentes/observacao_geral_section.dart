import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';

class ObservacaoGeralSection extends ConsumerStatefulWidget {
  final bool isDark;

  const ObservacaoGeralSection({super.key, required this.isDark});

  @override
  ConsumerState<ObservacaoGeralSection> createState() =>
      _ObservacaoGeralSectionState();
}

class _ObservacaoGeralSectionState
    extends ConsumerState<ObservacaoGeralSection> {
  bool _expandido = false;
  late final TextEditingController _obsController;
  static const int _maxLength = 200;

  @override
  void initState() {
    super.initState();
    final obs = ref.read(carrinhoControllerProvider).observacaoGeral ?? '';
    _obsController = TextEditingController(text: obs);
    _expandido = obs.isNotEmpty;
  }

  @override
  void dispose() {
    _obsController.dispose();
    super.dispose();
  }

  void _salvar() {
    ref
        .read(carrinhoControllerProvider.notifier)
        .atualizarObservacaoGeral(_obsController.text);
    FocusScope.of(context).unfocus();
    if (_obsController.text.trim().isEmpty) {
      setState(() => _expandido = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final primaryColor = const Color(0xFFFF7034);
    final cardColor = isDark ? const Color(0xFF27272A) : Colors.white;
    final borderColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
    final textColor = isDark ? Colors.white : const Color(0xFF4a4a4a);
    final mutedColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;

    final obsAtual =
        ref.watch(carrinhoControllerProvider).observacaoGeral ?? '';

    return AnimatedSize(
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: _expandido ? primaryColor.withValues(alpha: 0.4) : borderColor,
          ),
          boxShadow: [
            if (!isDark)
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header clicável
            InkWell(
              onTap: () {
                setState(() {
                  _expandido = !_expandido;
                  if (!_expandido) {
                    _obsController.clear();
                    ref
                        .read(carrinhoControllerProvider.notifier)
                        .atualizarObservacaoGeral('');
                  }
                });
              },
              borderRadius: BorderRadius.circular(16),
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        color: primaryColor,
                        size: 18,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Observação do pedido',
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: textColor,
                            ),
                          ),
                          if (!_expandido)
                            Text(
                              obsAtual.isNotEmpty
                                  ? obsAtual
                                  : 'Alguma instrução especial? Ex: troco, portão...',
                              style: GoogleFonts.outfit(
                                fontSize: 12,
                                color: obsAtual.isNotEmpty
                                    ? primaryColor
                                    : mutedColor,
                                fontStyle: obsAtual.isEmpty
                                    ? FontStyle.italic
                                    : FontStyle.normal,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ),
                    Icon(
                      _expandido
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: mutedColor,
                    ),
                  ],
                ),
              ),
            ),

            // Área de input expandível
            if (_expandido)
              Padding(
                padding:
                    const EdgeInsets.fromLTRB(16, 0, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    ValueListenableBuilder<TextEditingValue>(
                      valueListenable: _obsController,
                      builder: (_, value, __) => Text(
                        '${value.text.length} / $_maxLength',
                        style: GoogleFonts.outfit(
                          fontSize: 11,
                          color: mutedColor,
                        ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    TextField(
                      controller: _obsController,
                      maxLength: _maxLength,
                      maxLines: 3,
                      textInputAction: TextInputAction.done,
                      onSubmitted: (_) => _salvar(),
                      style: GoogleFonts.outfit(
                        color: textColor,
                        fontSize: 13,
                      ),
                      decoration: InputDecoration(
                        counterText: '',
                        hintText:
                            'Ex: portão azul, preciso de troco para R\$ 50, não colocar cebola...',
                        hintStyle: GoogleFonts.outfit(
                          color: Colors.grey[400],
                          fontSize: 13,
                        ),
                        filled: true,
                        fillColor: isDark
                            ? const Color(0xFF3A3A3A)
                            : const Color(0xFFF9F5F0),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide.none,
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(
                            color: isDark ? Colors.grey[700]! : Colors.grey[200]!,
                          ),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: BorderSide(color: primaryColor),
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),
                    ElevatedButton(
                      onPressed: _salvar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 20, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'Salvar',
                        style: GoogleFonts.outfit(
                          fontWeight: FontWeight.bold,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}
