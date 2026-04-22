import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../shared/widgets/responsive_layout.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // ── Anexo 2 — Logo: Ease Out · 600ms · delay 0ms ──────────────────────────
  late final Animation<double> _logoFade; // 0 → 1
  late final Animation<double> _logoScale; // 0.8x → 1x
  late final Animation<double> _logoSlideX; // -70px → 0px
  late final Animation<double> _logoRotate; // -2 turns → 2 turns (em radianos)

  // ── Anexo 1 — Texto: Ease In Out · 600ms · delay 200ms ────────────────────
  late final Animation<double> _textFade; // 0 → 1
  late final Animation<double> _textScale; // 1.1x → 1x

  /// Duração total do controller: 200ms (delay texto) + 600ms = 800ms
  static const int _totalMs = 800;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      duration: const Duration(milliseconds: _totalMs),
      vsync: this,
    );

    // Logo: 0ms → 600ms  →  intervalo normalizado [0.0, 0.75]
    final logoCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(0.0, 600 / _totalMs, curve: Curves.easeOut),
    );

    // Texto: 200ms → 800ms  →  intervalo normalizado [0.25, 1.0]
    final textCurve = CurvedAnimation(
      parent: _controller,
      curve: const Interval(200 / _totalMs, 1.0, curve: Curves.easeInOut),
    );

    // Logo animations
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(logoCurve);
    _logoScale = Tween<double>(begin: 0.8, end: 1.0).animate(logoCurve);
    _logoSlideX = Tween<double>(begin: -70.0, end: 0.0).animate(logoCurve);
    // -2 turns → +2 turns em radianos (4 rotações completas, decelerada pelo Ease Out)
    _logoRotate = Tween<double>(
      begin: -2.0 * 2.0 * math.pi,
      end: 2.0 * 2.0 * math.pi,
    ).animate(logoCurve);

    // Texto animations
    _textFade = Tween<double>(begin: 0.0, end: 1.0).animate(textCurve);
    _textScale = Tween<double>(begin: 1.1, end: 1.0).animate(textCurve);

    _controller.forward();

    // Navega para /login após 3 segundos
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) context.go('/login');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFFFB74D),
              Color(0xFFFF8F00),
            ],
          ),
        ),
        child: ResponsiveLayout(
          mobile: (context) =>
              _buildContent(context, logoFraction: 0.30, fontSize: 28),
          tablet: (context) =>
              _buildContent(context, logoFraction: 0.22, fontSize: 32),
          desktop: (context) =>
              _buildContent(context, logoFraction: 0.18, fontSize: 36),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required double logoFraction,
    required double fontSize,
  }) {
    final logoSize =
        (MediaQuery.of(context).size.width * logoFraction).clamp(100.0, 260.0);

    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),

        // ── Logo (Anexo 2) ─────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _logoFade.value,
              child: Transform.translate(
                offset: Offset(_logoSlideX.value, 0),
                child: Transform.scale(
                  scale: _logoScale.value,
                  child: Transform.rotate(
                    angle: _logoRotate.value,
                    child: child,
                  ),
                ),
              ),
            );
          },
          child: Container(
            width: logoSize,
            height: logoSize,
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(24),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            // Leve inclinação estática de -2° no card (design original)
            transform: Matrix4.rotationZ(-2 * math.pi / 180),
            transformAlignment: Alignment.center,
            child: Image.asset(
              'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
              fit: BoxFit.contain,
            ),
          ),
        ),

        const SizedBox(height: 48),

        // ── Texto (Anexo 1) ────────────────────────────────────────────────
        AnimatedBuilder(
          animation: _controller,
          builder: (context, child) {
            return Opacity(
              opacity: _textFade.value,
              child: Transform.scale(
                scale: _textScale.value,
                child: child,
              ),
            );
          },
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Text(
              'Ôpadoca entrega rapidinho!',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: fontSize,
                fontWeight: FontWeight.bold,
                shadows: const [
                  Shadow(
                    color: Colors.black26,
                    offset: Offset(0, 2),
                    blurRadius: 4,
                  ),
                ],
              ),
            ),
          ),
        ),

        const SizedBox(height: 16),

        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.9),
            borderRadius: BorderRadius.circular(4),
          ),
        ),

        const Spacer(),

        const Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Text(
            'ÔPADOCA EXPRESS',
            style: TextStyle(
              color: Color(0xCCFFFFFF),
              fontSize: 14,
              fontWeight: FontWeight.w500,
              letterSpacing: 2.0,
            ),
          ),
        ),
      ],
    );
  }
}
