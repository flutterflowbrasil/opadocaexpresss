import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class PoliticaPrivacidadeScreen extends StatelessWidget {
  const PoliticaPrivacidadeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Colors based on reference
    final primaryColor = const Color(0xFFEE6C2B);
    final backgroundColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF221610)
        : const Color(0xFFF9F5F0);
    final textColor = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFFFFF7ED) // orange-50
        : const Color(0xFF7D2D35); // burgundy

    return Scaffold(
      backgroundColor: backgroundColor,
      body: SafeArea(
        child: Column(
          children: [
            // Top App Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
              decoration: BoxDecoration(
                border: Border(
                  bottom: BorderSide(
                    color: textColor.withValues(alpha: 0.1), // 10% opacity
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () {
                      if (context.canPop()) {
                        context.pop();
                      } else {
                        context.go('/login');
                      }
                    },
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: textColor,
                      size: 24,
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: textColor.withValues(
                        alpha: 0.05,
                      ), // 5% opacity
                      padding: const EdgeInsets.all(12),
                    ),
                  ),
                  Expanded(
                    child: Text(
                      'Termos de Uso',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: textColor,
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48), // Balance for back button
                ],
              ),
            ),

            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildSectionTitle(
                      context,
                      '1. Aceitação dos Termos',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Ao usar o Opadoca Express, você concorda com os presentes Termos de Uso. Se não concordar, não utilize a plataforma.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '2. Cadastro e Conta',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'O usuário deve fornecer dados reais e atualizados.\nContas são pessoais e intransferíveis.\nUso indevido pode resultar em banimento.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '3. Funcionalidade do Serviço',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Entrega de produtos por estabelecimentos parceiros.\nGerenciamento de pedidos e pagamentos via ASAAS.\nÁrea do cliente e notificações em tempo real (via Supabase).',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '4. Pagamentos',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Cobranças realizadas via ASAAS com segurança.\nAssinaturas podem ser gerenciadas a qualquer momento pelo usuário.\nReembolsos seguem a política de cada parceiro.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '5. Limitações de Uso',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'É proibido:\n\nTentar invadir o sistema\nUsar a plataforma para fins ilegais\nViolar direitos de propriedade intelectual.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '6. Suspensão e Encerramento',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Reservamo-nos o direito de suspender ou encerrar contas por violação dos termos ou atividades suspeitas.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '7. Alterações nos Termos',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Estes termos podem ser alterados a qualquer momento, com aviso prévio.',
                      textColor,
                    ),

                    _buildSectionTitle(
                      context,
                      '8. Contato',
                      textColor,
                      primaryColor,
                    ),
                    _buildSectionBody(
                      'Dúvidas podem ser enviadas para: contatoopadoca@gmail.com',
                      textColor,
                    ),

                    const SizedBox(height: 24),
                    Text(
                      'Última atualização: 01/10/2025',
                      style: GoogleFonts.plusJakartaSans(
                        color: textColor.withValues(alpha: 0.6), // was 150/255
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 100), // Space for bottom button
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomSheet: Container(
        color: backgroundColor, // Match page background
        padding: const EdgeInsets.all(24),
        child: SizedBox(
          width: double.infinity,
          height: 56,
          child: ElevatedButton(
            onPressed: () {
              if (context.canPop()) {
                context.pop();
              } else {
                context.go('/login');
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: primaryColor,
              foregroundColor: Colors.white,
              elevation: 4,
              shadowColor: primaryColor.withValues(alpha: 0.4), // was 100/255
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  'Entendi',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(width: 8),
                const Icon(Icons.check_circle_outline, size: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(
    BuildContext context,
    String title,
    Color textColor,
    Color primaryColor,
  ) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, top: 4),
      child: Text(
        title,
        style: GoogleFonts.plusJakartaSans(
          color: Theme.of(context).brightness == Brightness.dark
              ? primaryColor
              : const Color(0xFF7D2D35),
          fontSize: 18,
          fontWeight: FontWeight.w800,
          letterSpacing: -0.5,
        ),
      ),
    );
  }

  Widget _buildSectionBody(String text, Color textColor) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Text(
        text,
        style: GoogleFonts.plusJakartaSans(
          color: textColor.withValues(alpha: 0.9), // 90% opacity roughly
          fontSize: 16,
          fontWeight: FontWeight.normal,
          height: 1.6,
        ),
      ),
    );
  }
}
