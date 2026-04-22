// lib/features/cliente/carrinho/componentes/cupom_section.dart

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';

const _kOrange = Color(0xFFFF7034);
const _kVinho = Color(0xFF7D2D35);
const _kGreen = Color(0xFF22C55E);

class CupomSection extends ConsumerStatefulWidget {
  final bool isDark;
  const CupomSection({super.key, required this.isDark});

  @override
  ConsumerState<CupomSection> createState() => _CupomSectionState();
}

class _CupomSectionState extends ConsumerState<CupomSection>
    with SingleTickerProviderStateMixin {
  final _ctrl = TextEditingController();
  final _focus = FocusNode();
  late AnimationController _shakeCtrl;
  late Animation<double> _shakeAnim;

  @override
  void initState() {
    super.initState();
    _shakeCtrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 400));
    _shakeAnim = Tween<double>(begin: 0, end: 8).animate(
      CurvedAnimation(parent: _shakeCtrl, curve: Curves.elasticIn),
    );
  }

  @override
  void dispose() {
    _ctrl.dispose();
    _focus.dispose();
    _shakeCtrl.dispose();
    super.dispose();
  }

  Future<void> _aplicar() async {
    _focus.unfocus();
    final codigo = _ctrl.text.trim();
    if (codigo.isEmpty) return;
    await ref.read(carrinhoControllerProvider.notifier).aplicarCupom(codigo);

    // Verificar se deu erro para animação shake
    final erro = ref.read(carrinhoControllerProvider).cupomErro;
    if (erro != null && mounted) {
      _shakeCtrl.forward(from: 0);
    } else {
      _ctrl.clear();
    }
  }

  @override
  Widget build(BuildContext context) {
    final estado = ref.watch(carrinhoControllerProvider);
    final cupom = estado.cupomAplicado;
    final isLoading = estado.isValidandoCupom;
    final erro = estado.cupomErro;
    final isDark = widget.isDark;

    final borderColor = erro != null
        ? Colors.red.shade400
        : cupom != null
            ? _kGreen
            : (isDark ? Colors.white12 : Colors.grey.shade300);

    final cardBg = isDark ? const Color(0xFF232323) : Colors.white;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardBg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: borderColor, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Título ─────────────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.local_offer_outlined,
                  size: 18, color: _kOrange),
              const SizedBox(width: 8),
              Text(
                'Cupom de desconto',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : _kVinho,
                ),
              ),
              if (cupom != null) ...[
                const Spacer(),
                GestureDetector(
                  onTap: () => ref
                      .read(carrinhoControllerProvider.notifier)
                      .removerCupom(),
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.close, size: 12, color: Colors.red),
                        const SizedBox(width: 4),
                        Text('Remover',
                            style: GoogleFonts.outfit(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),

          // ── Cupom Aplicado ─────────────────────────────────────────
          if (cupom != null)
            _CupomAplicadoBadge(cupom: cupom, isDark: isDark)
          // ── Input + Botão ──────────────────────────────────────────
          else
            AnimatedBuilder(
              animation: _shakeAnim,
              builder: (context, child) {
                return Transform.translate(
                  offset: Offset(_shakeAnim.value * _shakeDirection(), 0),
                  child: child,
                );
              },
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _ctrl,
                      focusNode: _focus,
                      textCapitalization: TextCapitalization.characters,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black87,
                        letterSpacing: 1.5,
                      ),
                      decoration: InputDecoration(
                        hintText: 'Ex: DESCONTO10',
                        hintStyle: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isDark ? Colors.white38 : Colors.grey[400],
                          letterSpacing: 1.2,
                        ),
                        filled: true,
                        fillColor:
                            isDark ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(10),
                          borderSide: BorderSide.none,
                        ),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        prefixIcon: Icon(Icons.confirmation_number_outlined,
                            color: _kOrange, size: 18),
                      ),
                      onSubmitted: (_) => _aplicar(),
                    ),
                  ),
                  const SizedBox(width: 8),
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: isLoading ? null : _aplicar,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: _kOrange,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10)),
                        padding:
                            const EdgeInsets.symmetric(horizontal: 18),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                  color: Colors.white, strokeWidth: 2),
                            )
                          : Text('Aplicar',
                              style: GoogleFonts.outfit(
                                  fontWeight: FontWeight.bold, fontSize: 13)),
                    ),
                  ),
                ],
              ),
            ),

          // ── Mensagem de erro ───────────────────────────────────────
          if (erro != null && cupom == null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.error_outline,
                    size: 14, color: Colors.redAccent),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    erro,
                    style: GoogleFonts.outfit(
                      fontSize: 12,
                      color: Colors.redAccent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Direção alternada para efeito shake
  double _shakeDirection() {
    final v = _shakeCtrl.value;
    return v < 0.25
        ? -1
        : v < 0.5
            ? 1
            : v < 0.75
                ? -1
                : 1;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Badge de cupom aplicado com sucesso
// ─────────────────────────────────────────────────────────────────────────────
class _CupomAplicadoBadge extends StatelessWidget {
  final dynamic cupom;
  final bool isDark;
  const _CupomAplicadoBadge({required this.cupom, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: _kGreen.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _kGreen.withValues(alpha: 0.35)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: _kGreen.withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_rounded, color: _kGreen, size: 16),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cupom.codigo as String,
                  style: GoogleFonts.outfit(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: isDark ? Colors.white : Colors.black87,
                    letterSpacing: 1.5,
                  ),
                ),
                Text(
                  '${(cupom as dynamic).labelDesconto} de desconto aplicado!',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    color: _kGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
