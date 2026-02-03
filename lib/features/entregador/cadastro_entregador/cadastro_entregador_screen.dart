import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/shared/widgets/responsive_layout.dart';

class CadastroEntregadorScreen extends StatefulWidget {
  const CadastroEntregadorScreen({super.key});

  @override
  State<CadastroEntregadorScreen> createState() =>
      _CadastroEntregadorScreenState();
}

class _CadastroEntregadorScreenState extends State<CadastroEntregadorScreen> {
  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final _cpfFormatter = MaskTextInputFormatter(
    mask: '###.###.###-##',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  Widget build(BuildContext context) {
    // Colors based on reference
    final primaryColor = const Color(0xFFFF7034);
    final burgundyColor = const Color(0xFF8E2A2B);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgLight = const Color(0xFFF9F5F0);
    final bgDark = const Color(0xFF1A1614);
    final cardLight = Colors.white;
    final cardDark = const Color(0xFF292524); // Neutral 800 approx
    final textColor = isDark
        ? const Color(0xFFFFE0B2)
        : burgundyColor; // Orange 100 for dark text

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
              // Header
              Row(
                children: [
                  IconButton(
                    icon: Icon(
                      Icons.arrow_back_ios_new,
                      color: isDark
                          ? const Color(0xFFFFE0B2)
                          : burgundyColor, // Orange 100 or Burgundy
                    ),
                    onPressed: () => context.pop(),
                  ),
                  Expanded(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        // Mini Logo
                        Icon(
                          Icons.bakery_dining,
                          color: isDark ? primaryColor : burgundyColor,
                          size: 24,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'ÔPADOCA EXPRESS',
                          style: GoogleFonts.outfit(
                            fontWeight: FontWeight.bold,
                            fontSize: 14, // Matches CadastroClienteScreen
                            color: isDark
                                ? const Color(0xFFFFE0B2)
                                : burgundyColor,
                            letterSpacing: 1.2,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 40), // Balance back button
                ],
              ),
              const SizedBox(height: 32),

              // Logo & Title
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 96,
                      height: 96,
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xFF262626) : Colors.white,
                        borderRadius: BorderRadius.circular(16),
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
                    const SizedBox(height: 16),
                    Text(
                      'Cadastro de Entregador',
                      style: GoogleFonts.outfit(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Junte-se à equipe Ôpadoca Express e comece a trabalhar conosco!',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.outfit(
                        fontSize: 14,
                        color: isDark ? Colors.grey[400] : Colors.grey[500],
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Profile Photo
              Center(
                child: Column(
                  children: [
                    Stack(
                      children: [
                        Container(
                          width: 112,
                          height: 112,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isDark ? Colors.grey[700] : Colors.grey[200],
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF262626)
                                  : Colors.white,
                              width: 4,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withValues(
                                  alpha: isDark ? 0.3 : 0.1,
                                ),
                                blurRadius: 8,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: ClipOval(
                            child: Image.network(
                              'https://lh3.googleusercontent.com/aida-public/AB6AXuBW1w9QA98Wv8nkFDEEGbc6pGBysCTBya_KyvJFd5nTx9giZ3c2gK7mHtWeVZ0FB3t2ZDGezQpdY9ZFOzhTvIVe05SkxCiD2yyOomBN1JVzWmRtDbOIXzlMRshuS6uEMESXENp6T7OzOmlUOqAQCxW5FK8VVw6ncU8b7HUqAEXtSlJwpGmHwrJJtRnopPZZ-2gOwt5ij2r27XnatRBu4SUw_rwD8Sr-uFudhWpmXdHYiICbWOSHmjiPXR3KFluYFdoUtOvyebiO',
                              fit: BoxFit.cover,
                            ),
                          ),
                        ),
                        Positioned(
                          bottom: 0,
                          right: 0,
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: primaryColor,
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isDark
                                    ? const Color(0xFF262626)
                                    : Colors.white,
                                width: 2,
                              ),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 2),
                                ),
                              ],
                            ),
                            child: const Icon(
                              Icons.photo_camera,
                              size: 14,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Toque para adicionar foto',
                      style: GoogleFonts.outfit(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: isDark ? Colors.grey[500] : Colors.grey[400],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),

              // Form
              _buildInputContainer(
                label: 'Nome Completo',
                icon: Icons.person,
                hint: 'Nome completo',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
              ),
              _buildInputContainer(
                label: 'Telefone / WhatsApp',
                icon: Icons.call,
                hint: '(11) 99999-9999',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                keyboardType: TextInputType.phone,
                inputFormatters: [_phoneFormatter],
              ),
              _buildInputContainer(
                label: 'CPF',
                icon: Icons.badge,
                hint: '000.000.000-00',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                keyboardType: TextInputType.number,
                inputFormatters: [_cpfFormatter],
              ),

              Padding(
                padding: const EdgeInsets.symmetric(vertical: 24),
                child: Text(
                  'Tipo de Veículo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: isDark
                        ? const Color(0xFFFFCC80)
                        : burgundyColor, // Orange 200 or Burgundy
                  ),
                ),
              ),

              _buildInputContainer(
                label: 'Placa do Veículo',
                icon: Icons.directions_car,
                hint: 'ABC-1234 (opcional para bicicleta)',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                textCapitalization: TextCapitalization.characters,
              ),
              _buildInputContainer(
                label: 'Dados para Pagamento (ASAAS)',
                icon: Icons.account_balance,
                hint: 'Chave PIX ou dados bancários',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
              ),
              _buildInputContainer(
                label: 'E-mail',
                icon: Icons.mail,
                hint: 'seu@email.com',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
                keyboardType: TextInputType.emailAddress,
              ),
              _buildInputContainer(
                label: 'Senha',
                icon: Icons.lock,
                hint: 'Mínimo 6 caracteres',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
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
              _buildInputContainer(
                label: 'Confirmar Senha',
                icon: Icons.lock,
                hint: 'Digite a senha novamente',
                isDark: isDark,
                primaryColor: primaryColor,
                textColor: textColor,
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

              const SizedBox(height: 24),

              // Terms Checkbox
              Row(
                crossAxisAlignment:
                    CrossAxisAlignment.center, // Align center vertically
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
                        color: isDark ? Colors.grey[600]! : Colors.grey[300]!,
                        width: 1.5,
                      ),
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: RichText(
                      text: TextSpan(
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.normal,
                          color: isDark ? Colors.grey[400] : Colors.grey[500],
                        ),
                        children: [
                          const TextSpan(text: 'Eu aceito os '),
                          TextSpan(
                            text: 'termos de serviço e política de privacidade',
                            style: TextStyle(
                              color: primaryColor,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                              decorationColor: primaryColor,
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

              ElevatedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.delivery_dining),
                label: const Text('Cadastrar / Iniciar cadastro financeiro'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 6,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () {},
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  elevation: 6,
                  shadowColor: primaryColor.withValues(alpha: 0.3),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  textStyle: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                child: const Text('Cadastrar'),
              ),

              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInputContainer({
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    required Color primaryColor,
    required Color textColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    TextCapitalization textCapitalization = TextCapitalization.none,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 24),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Container(
            decoration: BoxDecoration(
              color: isDark
                  ? const Color(0xFF171717)
                  : Colors.white, // Neutral 900 or White
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark
                    ? Colors.grey[700]!
                    : const Color(0xFF8E2A2B).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                Padding(
                  padding: const EdgeInsets.only(
                    left: 16,
                    right: 12,
                    top: 12,
                    bottom: 12,
                  ),
                  child: Icon(
                    icon,
                    color: isDark ? Colors.grey[500] : Colors.grey[400],
                    size: 20,
                  ),
                ),
                Expanded(
                  child: TextField(
                    obscureText: obscureText,
                    keyboardType: keyboardType,
                    inputFormatters: inputFormatters,
                    textCapitalization: textCapitalization,
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey[100] : Colors.grey[800],
                    ),
                    decoration: InputDecoration(
                      hintText: hint,
                      hintStyle: GoogleFonts.outfit(
                        color: isDark
                            ? Colors.grey[600]
                            : Colors.grey[400], // Adjust placeholder color
                      ),
                      border: InputBorder.none,
                      contentPadding: const EdgeInsets.symmetric(vertical: 16),
                      suffixIcon: suffixIcon,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Positioned(
            top: -10,
            left: 12,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              color: isDark
                  ? const Color(0xFF1A1614)
                  : const Color(0xFFF9F5F0), // Match background
              child: Text(
                label,
                style: GoogleFonts.outfit(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: isDark ? primaryColor : const Color(0xFF8E2A2B),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
