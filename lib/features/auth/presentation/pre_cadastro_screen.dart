import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/shared/widgets/responsive_layout.dart';

class PreCadastroScreen extends StatelessWidget {
  const PreCadastroScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors based on design
    final primaryColor = const Color(0xFFFF7034);
    final burgundyColor = const Color(0xFF7D2D35);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgLight = const Color(0xFFF9F5F0);
    final bgDark = const Color(0xFF1C1917);
    final cardLight = Colors.white;
    final cardDark = const Color(0xFF292524);

    final textColor = isDark ? const Color(0xFFFFE0B2) : burgundyColor;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: (context) => _buildContent(
            context,
            isDesktop: false,
            primaryColor: primaryColor,
            textColor: textColor,
            isDark: isDark,
            cardColor: isDark ? cardDark : cardLight,
          ),
          desktop: (context) => _buildContent(
            context,
            isDesktop: true,
            primaryColor: primaryColor,
            textColor: textColor,
            isDark: isDark,
            cardColor: isDark ? cardDark : cardLight,
          ),
        ),
      ),
    );
  }

  Widget _buildContent(
    BuildContext context, {
    required bool isDesktop,
    required Color primaryColor,
    required Color textColor,
    required bool isDark,
    required Color cardColor,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Header Section
            ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 800),
              child: Column(
                children: [
                  // Logo
                  Container(
                    width: isDesktop ? 120 : 96,
                    height: isDesktop ? 120 : 96,
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isDark ? cardColor : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF44403C)
                            : const Color(0xFFFFF7ED),
                        width: 1,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Title
                  Text(
                    'Como você deseja usar o Padoca Express?',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: isDesktop ? 32 : 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Subtitle
                  Text(
                    'Escolha a opção que melhor se adequa ao seu perfil',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.outfit(
                      fontSize: isDesktop ? 18 : 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? const Color(0xFFA8A29E)
                          : Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),

            SizedBox(height: isDesktop ? 48 : 32),

            // Options Container
            if (isDesktop)
              Wrap(
                spacing: 24,
                runSpacing: 24,
                alignment: WrapAlignment.center,
                children: [
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _buildOptionCard(
                      context: context,
                      title: 'Cliente',
                      description: 'Quero pedir rapidinho!',
                      icon: Icons.person_outline,
                      buttonText: 'Cadastrar como Cliente',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _buildOptionCard(
                      context: context,
                      title: 'Estabelecimento',
                      description: 'Sou parceiro, quero me cadastrar.',
                      icon: Icons.storefront_outlined,
                      buttonText: 'Cadastrar Estabelecimento',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                  ),
                  ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 320),
                    child: _buildOptionCard(
                      context: context,
                      title: 'Entregador',
                      description: 'Quero fazer entregas!',
                      icon: Icons.two_wheeler_outlined,
                      buttonText: 'Cadastrar como Entregador',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                  ),
                ],
              )
            else
              ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  children: [
                    _buildOptionCard(
                      context: context,
                      title: 'Cliente',
                      description: 'Quero pedir rapidinho!',
                      icon: Icons.person_outline,
                      buttonText: 'Cadastrar como Cliente',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context: context,
                      title: 'Estabelecimento',
                      description: 'Sou parceiro, quero me cadastrar.',
                      icon: Icons.storefront_outlined,
                      buttonText: 'Cadastrar Estabelecimento',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                    const SizedBox(height: 16),
                    _buildOptionCard(
                      context: context,
                      title: 'Entregador',
                      description: 'Quero fazer entregas!',
                      icon: Icons.two_wheeler_outlined,
                      buttonText: 'Cadastrar como Entregador',
                      onTap: () {},
                      isDark: isDark,
                      cardColor: cardColor,
                      textColor: textColor,
                      primaryColor: primaryColor,
                    ),
                  ],
                ),
              ),

            // Back Button
            SizedBox(height: isDesktop ? 48 : 32),
            TextButton(
              onPressed: () => context.pop(),
              child: Text(
                'Voltar para Login',
                style: GoogleFonts.outfit(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionCard({
    required BuildContext context,
    required String title,
    required String description,
    required IconData icon,
    required String buttonText,
    required VoidCallback onTap,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color primaryColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(32), // large rounded corners
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
            blurRadius: 30,
            offset: const Offset(0, 8),
          ),
        ],
        border: isDark ? Border.all(color: const Color(0xFF44403C)) : null,
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0x8044403C)
                      : const Color(0xFFFFF7ED),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  color: isDark ? primaryColor : const Color(0xFF7D2D35),
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                title,
                style: GoogleFonts.outfit(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            description,
            style: GoogleFonts.outfit(
              fontSize: 14,
              color: isDark ? const Color(0xFFA8A29E) : Colors.grey[500],
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onTap,
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: primaryColor.withValues(alpha: 0.3),
              ),
              child: Text(
                buttonText,
                style: GoogleFonts.outfit(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
