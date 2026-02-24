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
  late final Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(seconds: 3),
      vsync: this,
    )..repeat(reverse: true);

    _animation = Tween<double>(
      begin: 0,
      end: -10,
    ).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        context.go('/login');
      }
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
              Color(0xFFFFB74D), // #FFB74D
              Color(0xFFFF8F00), // #FF8F00
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
    final screenWidth = MediaQuery.of(context).size.width;
    final logoSize = (screenWidth * logoFraction).clamp(100.0, 260.0);
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        const Spacer(),
        AnimatedBuilder(
          animation: _animation,
          builder: (context, child) {
            return Transform.translate(
              offset: Offset(0, _animation.value),
              child: child,
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
                  color: Colors.black.withValues(
                    alpha: 0.2,
                  ), // was 50 (50/255 ~= 0.2)
                  blurRadius: 25,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            transform: Matrix4.rotationZ(-2 * 3.14159 / 180),
            transformAlignment: Alignment.center,
            child: Image.asset(
              'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 48),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'Ôpadoca entrega rapidinho!',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white,
              fontSize: fontSize,
              fontWeight: FontWeight.bold,
              shadows: [
                const Shadow(
                  color: Colors.black26,
                  offset: Offset(0, 2),
                  blurRadius: 4,
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        Container(
          width: 80,
          height: 4,
          decoration: BoxDecoration(
            color: Colors.white.withValues(
              alpha: 0.9,
            ), // was 230 (230/255 ~= 0.9)
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const Spacer(),
        const Padding(
          padding: EdgeInsets.only(bottom: 48),
          child: Text(
            'PADOCA EXPRESS',
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
