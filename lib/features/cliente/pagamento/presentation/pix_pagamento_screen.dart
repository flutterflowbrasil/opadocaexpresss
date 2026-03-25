import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/pagamento/controllers/pagamento_controller.dart';
import 'package:padoca_express/features/cliente/pagamento/presentation/pix_pagamento_widgets.dart';
import 'package:padoca_express/features/cliente/pagamento/state/pagamento_state.dart';

class PixPagamentoScreen extends ConsumerStatefulWidget {
  final String pedidoId;
  final String pixCopiaECola;
  final String? pixQrCodeBase64;
  final int? segundosIniciaisRestantes;

  const PixPagamentoScreen({
    super.key,
    required this.pedidoId,
    required this.pixCopiaECola,
    this.pixQrCodeBase64,
    this.segundosIniciaisRestantes,
  });

  @override
  ConsumerState<PixPagamentoScreen> createState() =>
      _PixPagamentoScreenState();
}

class _PixPagamentoScreenState extends ConsumerState<PixPagamentoScreen> {
  late int _segundosRestantes;
  Timer? _timer;

  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  void initState() {
    super.initState();
    _segundosRestantes =
        widget.segundosIniciaisRestantes ?? 300; // 5 min padrão
    _iniciarTimer();
  }

  void _iniciarTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() {
        if (_segundosRestantes > 0) {
          _segundosRestantes--;
        } else {
          _timer?.cancel();
          ref
              .read(pagamentoControllerProvider.notifier)
              .onPixExpirado();
        }
      });
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor =
        isDark ? const Color(0xFF1C1917) : const Color(0xFFF9F5F0);

    // Reagir a mudanças de status
    ref.listen<PagamentoState>(pagamentoControllerProvider, (_, next) {
      if (!mounted) return;
      if (next.status == PagamentoStatus.confirmado) {
        _timer?.cancel();
        context.go('/pagamento/sucesso',
            extra: {'pedidoId': widget.pedidoId});
      } else if (next.status == PagamentoStatus.expirado) {
        _timer?.cancel();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Tempo esgotado. Gere um novo pagamento.',
              style: GoogleFonts.outfit(),
            ),
            backgroundColor: Colors.red[400],
          ),
        );
        context.go('/finalizar_pedido');
      }
    });

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final confirm = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16)),
            title: Text(
              'Cancelar pagamento?',
              style: GoogleFonts.outfit(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'O pedido foi criado. Você pode retornar e pagar dentro do prazo.',
              style: GoogleFonts.outfit(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child:
                    Text('Continuar', style: GoogleFonts.outfit()),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text('Sair',
                    style: GoogleFonts.outfit(color: Colors.red)),
              ),
            ],
          ),
        );
        if (confirm == true && context.mounted) {
          context.go('/home');
        }
      },
      child: Scaffold(
        backgroundColor: bgColor,
        appBar: AppBar(
          backgroundColor: bgColor,
          elevation: 0,
          centerTitle: true,
          leading: IconButton(
            icon: Icon(Icons.arrow_back_ios_new,
                color: isDark ? Colors.white : _secondaryColor, size: 20),
            onPressed: () async {
              final confirm = await showDialog<bool>(
                context: context,
                builder: (ctx) => AlertDialog(
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  title: Text(
                    'Cancelar pagamento?',
                    style:
                        GoogleFonts.outfit(fontWeight: FontWeight.bold),
                  ),
                  content: Text(
                    'O pedido foi criado. Você pode retornar e pagar dentro do prazo.',
                    style: GoogleFonts.outfit(),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      child: Text('Continuar',
                          style: GoogleFonts.outfit()),
                    ),
                    TextButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      child: Text('Sair',
                          style:
                              GoogleFonts.outfit(color: Colors.red)),
                    ),
                  ],
                ),
              );
              if (confirm == true && context.mounted) {
                context.go('/home');
              }
            },
          ),
          title: Text(
            'Pagamento via Pix',
            style: GoogleFonts.outfit(
              color: isDark ? Colors.white : _secondaryColor,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              // QR Code
              PixQrCodeCard(
                pixCopiaECola: widget.pixCopiaECola,
                pixQrCodeBase64: widget.pixQrCodeBase64,
              ),
              const SizedBox(height: 24),
              // Countdown
              CountdownTimerWidget(
                  segundosRestantes: _segundosRestantes),
              const SizedBox(height: 24),
              // Copia e cola
              if (widget.pixCopiaECola.isNotEmpty)
                CopiaColaButton(pixCopiaECola: widget.pixCopiaECola),
              const SizedBox(height: 32),
              // Como funciona
              _ComoFuncionaCard(isDark: isDark),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
class _ComoFuncionaCard extends StatelessWidget {
  final bool isDark;

  const _ComoFuncionaCard({required this.isDark});

  static const _primaryColor = Color(0xFFFF7034);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _primaryColor.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border:
            Border.all(color: _primaryColor.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Como funciona',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: _primaryColor,
            ),
          ),
          const SizedBox(height: 10),
          ...[
            'Abra o app do seu banco',
            'Escolha a opção Pagar via PIX',
            'Escaneie o QR Code ou use o código copia-e-cola',
            'Confirme o pagamento e aguarde a confirmação',
          ].map((step) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 3),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.check_circle_outline,
                        color: _primaryColor, size: 16),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        step,
                        style: GoogleFonts.outfit(
                          fontSize: 13,
                          color: isDark
                              ? Colors.grey[300]
                              : Colors.grey[700],
                        ),
                      ),
                    ),
                  ],
                ),
              )),
        ],
      ),
    );
  }
}
