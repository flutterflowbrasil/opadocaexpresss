import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/gestures.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/shared/widgets/responsive_layout.dart';

class CadastroClienteScreen extends StatefulWidget {
  const CadastroClienteScreen({super.key});

  @override
  State<CadastroClienteScreen> createState() => _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends State<CadastroClienteScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
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
            burgundyColor: burgundyColor,
            textColor: textColor,
            isDark: isDark,
            cardColor: isDark ? cardDark : cardLight,
          ),
          desktop: (context) => _buildContent(
            context,
            isDesktop: true,
            primaryColor: primaryColor,
            burgundyColor: burgundyColor,
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
    required Color burgundyColor,
    required Color textColor,
    required bool isDark,
    required Color cardColor,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header with Back Button
              Row(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xFF292524) : Colors.white,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: isDark
                            ? const Color(0xFF44403C)
                            : Colors.grey[200]!,
                      ),
                    ),
                    child: IconButton(
                      icon: Icon(
                        Icons.arrow_back,
                        color: isDark ? Colors.grey[200] : Colors.grey[700],
                      ),
                      onPressed: () => context.pop(),
                    ),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bakery_dining,
                          color: isDark ? primaryColor : burgundyColor,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ÔPADOCA EXPRESS',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: isDark ? Colors.grey[100] : burgundyColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Spacer to balance back button
                ],
              ),

              const SizedBox(height: 32),

              // Title Section
              Center(
                child: Container(
                  width: 96,
                  height: 96,
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Image.asset(
                    'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
                    fit: BoxFit.contain,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.person_add,
                    color: isDark ? primaryColor : burgundyColor,
                    size: 28,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Cadastro de Cliente',
                    style: GoogleFonts.outfit(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Crie sua conta e faça seus pedidos com facilidade.',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark ? Colors.grey[400] : Colors.grey[500],
                ),
              ),

              const SizedBox(height: 32),

              // Form
              _buildLabel('Nome Completo', isDark, burgundyColor),
              const SizedBox(height: 6),
              _buildTextField(
                icon: Icons.person_outline,
                hint: 'Digite seu nome completo',
                isDark: isDark,
                primaryColor: primaryColor,
                burgundyColor: burgundyColor,
              ),

              const SizedBox(height: 16),

              _buildLabel('Telefone/WhatsApp', isDark, burgundyColor),
              const SizedBox(height: 6),
              _buildTextField(
                icon: Icons.phone_outlined,
                hint: '(11) 99999-9999',
                isDark: isDark,
                primaryColor: primaryColor,
                burgundyColor: burgundyColor,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
              ),

              const SizedBox(height: 16),

              _buildLabel('E-mail', isDark, burgundyColor),
              const SizedBox(height: 6),
              _buildTextField(
                icon: Icons.mail_outline,
                hint: 'seu@email.com',
                isDark: isDark,
                primaryColor: primaryColor,
                burgundyColor: burgundyColor,
                keyboardType: TextInputType.emailAddress,
              ),

              const SizedBox(height: 16),

              _buildLabel('Senha', isDark, burgundyColor),
              const SizedBox(height: 6),
              _buildTextField(
                icon: Icons.lock_outline,
                hint: 'Mínimo 6 caracteres',
                isDark: isDark,
                primaryColor: primaryColor,
                burgundyColor: burgundyColor,
                obscureText: !_isPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey[400],
                  ),
                  onPressed: () =>
                      setState(() => _isPasswordVisible = !_isPasswordVisible),
                ),
              ),

              const SizedBox(height: 16),

              _buildLabel('Confirmar Senha', isDark, burgundyColor),
              const SizedBox(height: 6),
              _buildTextField(
                icon: Icons.lock_outline,
                hint: 'Digite a senha novamente',
                isDark: isDark,
                primaryColor: primaryColor,
                burgundyColor: burgundyColor,
                obscureText: !_isConfirmPasswordVisible,
                suffixIcon: IconButton(
                  icon: Icon(
                    _isConfirmPasswordVisible
                        ? Icons.visibility_outlined
                        : Icons.visibility_off_outlined,
                    color: Colors.grey[400],
                  ),
                  onPressed: () => setState(
                    () =>
                        _isConfirmPasswordVisible = !_isConfirmPasswordVisible,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Terms Checkbox
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    height: 24,
                    width: 24,
                    child: Checkbox(
                      value: _acceptedTerms,
                      activeColor: primaryColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                      side: BorderSide(
                        color: isDark ? Colors.grey[700]! : Colors.grey[300]!,
                      ),
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        children: [
                          const TextSpan(text: 'Eu aceito os '),
                          TextSpan(
                            text: 'termos de serviço e política de privacidade',
                            style: GoogleFonts.outfit(
                              color: primaryColor,
                              fontWeight: FontWeight.w500,
                              decoration: TextDecoration.underline,
                            ),
                            recognizer: TapGestureRecognizer()
                              ..onTap = () {
                                context.push('/privacy');
                              },
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 24),

              // Info Box
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? const Color(0xFF1E1E1E).withValues(alpha: 0.4)
                      : Colors.white.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: primaryColor.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.shopping_cart_outlined,
                        color: primaryColor,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Pronto para fazer seus pedidos!',
                            style: GoogleFonts.outfit(
                              fontWeight: FontWeight.bold,
                              fontSize: 14,
                              color: isDark ? primaryColor : burgundyColor,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Pães frescos, doces e muito mais direto na sua casa.',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Register Button
              ElevatedButton.icon(
                onPressed: () {
                  // TODO: Implement registration logic
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                ),
                icon: const Icon(Icons.person_add_alt_1_outlined),
                label: Text(
                  'Cadastrar',
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),

              const SizedBox(height: 32),

              // Login Link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Já tem uma conta? ',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey[400] : Colors.grey[500],
                      fontSize: 14,
                    ),
                  ),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: Text(
                      'Fazer Login',
                      style: GoogleFonts.outfit(
                        color: isDark ? primaryColor : burgundyColor,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String text, bool isDark, Color color) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: Text(
        text,
        style: GoogleFonts.outfit(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: isDark ? const Color(0xFFD4D4D8) : color,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required IconData icon,
    required String hint,
    required bool isDark,
    required Color primaryColor,
    required Color burgundyColor,
    bool obscureText = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    List<dynamic>? inputFormatters,
  }) {
    // Cast list to TextInputFormatter
    final formatters = inputFormatters?.cast<MaskTextInputFormatter>();

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF27272A) : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: isDark ? Colors.grey[800]! : Colors.grey[100]!,
        ),
      ),
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: formatters,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.white : Colors.grey[800],
        ),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isDark
                ? Colors.grey[600]
                : Colors.grey[400], // Matches Tailwind text-gray-400
          ),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(
            color: isDark ? Colors.grey[600] : Colors.grey[400],
          ),
          suffixIcon: suffixIcon,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide.none,
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: BorderSide(color: primaryColor, width: 1.5),
          ),
          contentPadding: const EdgeInsets.symmetric(
            vertical: 20,
            horizontal: 16,
          ),
          filled: true,
          fillColor: isDark ? const Color(0xFF1E1E1E) : Colors.white,
        ),
      ),
    );
  }
}
