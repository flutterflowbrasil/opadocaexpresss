import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';

class PagamentoSucessoScreen extends ConsumerStatefulWidget {
  final String pedidoId;

  const PagamentoSucessoScreen({super.key, required this.pedidoId});

  @override
  ConsumerState<PagamentoSucessoScreen> createState() =>
      _PagamentoSucessoScreenState();
}

class _PagamentoSucessoScreenState
    extends ConsumerState<PagamentoSucessoScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  void initState() {
    super.initState();
    // Limpa o carrinho ao confirmar
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(carrinhoControllerProvider.notifier).limparCarrinho();
    });

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _scaleAnim = CurvedAnimation(
      parent: _animController,
      curve: Curves.elasticOut,
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Ícone animado
              ScaleTransition(
                scale: _scaleAnim,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_circle_rounded,
                    color: Colors.green,
                    size: 72,
                  ),
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Pedido Confirmado!',
                style: GoogleFonts.outfit(
                  fontSize: 26,
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : _secondaryColor,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
              Text(
                'Seu pedido está sendo preparado com carinho.',
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
                textAlign: TextAlign.center,
              ),
              if (widget.pedidoId.isNotEmpty) ...[
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 20, vertical: 12),
                  decoration: BoxDecoration(
                    color: _primaryColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: _primaryColor.withValues(alpha: 0.2)),
                  ),
                  child: Text(
                    'Acompanhe em "Meus Pedidos"',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: _primaryColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
              const SizedBox(height: 48),
              // Botão primário
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: () => context.go('/cliente/pedidos'),
                  icon:
                      const Icon(Icons.receipt_long, color: Colors.white),
                  label: Text(
                    'Ver meus pedidos',
                    style: GoogleFonts.outfit(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryColor,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    elevation: 4,
                    shadowColor: _primaryColor.withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              // Botão secundário
              SizedBox(
                width: double.infinity,
                height: 48,
                child: TextButton(
                  onPressed: () => context.go('/home'),
                  child: Text(
                    'Voltar ao início',
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      color: isDark
                          ? Colors.grey[400]
                          : _secondaryColor.withValues(alpha: 0.7),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
