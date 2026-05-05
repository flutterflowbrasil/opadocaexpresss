import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_cliente/cadastro_cliente_controller.dart';
import 'package:padoca_express/shared/widgets/responsive_layout.dart';

class CadastroClienteScreen extends ConsumerStatefulWidget {
  const CadastroClienteScreen({super.key});

  @override
  ConsumerState<CadastroClienteScreen> createState() =>
      _CadastroClienteScreenState();
}

class _CadastroClienteScreenState extends ConsumerState<CadastroClienteScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nomeController = TextEditingController();
  final _telefoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();

  bool _isPasswordVisible = false;
  bool _isConfirmPasswordVisible = false;
  bool _acceptedTerms = false;
  bool _showValidationErrors = false;

  final _phoneFormatter = MaskTextInputFormatter(
    mask: '(##) #####-####',
    filter: {'#': RegExp(r'[0-9]')},
  );

  final _passwordRegex = RegExp(
    r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)(?=.*[@$!%*?&])[A-Za-z\d@$!%*?&]{6,}$',
  );

  @override
  void dispose() {
    _nomeController.dispose();
    _telefoneController.dispose();
    _emailController.dispose();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  Future<void> _cadastrar() async {
    FocusScope.of(context).unfocus();
    if (!_showValidationErrors) {
      setState(() => _showValidationErrors = true);
    }
    if (!(_formKey.currentState?.validate() ?? false)) return;

    if (!_acceptedTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Você precisa aceitar os termos de serviço.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final controller = ref.read(cadastroClienteControllerProvider.notifier);

    await controller.cadastrar(
      nome: _nomeController.text.trim(),
      email: _emailController.text.trim(),
      telefone: _telefoneController.text.trim(),
      senha: _senhaController.text,
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(cadastroClienteControllerProvider, (previous, next) {
      if (next.error != null) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      } else if (next.success) {
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).hideCurrentSnackBar();
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Cadastro realizado com sucesso!'),
            backgroundColor: Colors.green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
      }
    });

    final state = ref.watch(cadastroClienteControllerProvider);
    const primaryColor = Color(0xFFFF7034);
    const burgundyColor = Color(0xFF8E2A2B);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1A1614) : const Color(0xFFF9F5F0);
    final textColor = isDark ? const Color(0xFFFFE0B2) : burgundyColor;

    return Scaffold(
      backgroundColor: bg,
      body: SafeArea(
        child: ResponsiveLayout(
          mobile: (context) => _buildContent(
            primaryColor: primaryColor,
            burgundyColor: burgundyColor,
            textColor: textColor,
            isDark: isDark,
            isLoading: state.isLoading,
          ),
          desktop: (context) => _buildContent(
            primaryColor: primaryColor,
            burgundyColor: burgundyColor,
            textColor: textColor,
            isDark: isDark,
            isLoading: state.isLoading,
          ),
        ),
      ),
    );
  }

  Widget _buildContent({
    required Color primaryColor,
    required Color burgundyColor,
    required Color textColor,
    required bool isDark,
    required bool isLoading,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Header(
                  title: 'Cadastro de Cliente',
                  subtitle: 'Crie sua conta e faça seus pedidos com facilidade.',
                  isDark: isDark,
                  textColor: textColor,
                  primaryColor: primaryColor,
                  burgundyColor: burgundyColor,
                ),
                const SizedBox(height: 24),
                _buildInput(
                  controller: _nomeController,
                  label: 'Nome Completo',
                  icon: Icons.person_outline,
                  hint: 'Digite seu nome completo',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  validator: (value) {
                    if (value == null || value.trim().length < 3) {
                      return 'Por favor, insira seu nome completo';
                    }
                    return null;
                  },
                ),
                _buildInput(
                  controller: _telefoneController,
                  label: 'Telefone/WhatsApp',
                  icon: Icons.call_outlined,
                  hint: '(11) 99999-9999',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [_phoneFormatter],
                  validator: (value) {
                    final digits =
                        (value ?? '').replaceAll(RegExp(r'\D'), '');
                    if (digits.length < 10) {
                      return 'Por favor, insira seu telefone';
                    }
                    return null;
                  },
                ),
                _buildInput(
                  controller: _emailController,
                  label: 'E-mail',
                  icon: Icons.mail_outline,
                  hint: 'seu@email.com',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    final email = value?.trim() ?? '';
                    final emailRegex = RegExp(
                      r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$',
                    );
                    if (!emailRegex.hasMatch(email)) {
                      return 'Por favor, insira um e-mail válido';
                    }
                    return null;
                  },
                ),
                _buildInput(
                  controller: _senhaController,
                  label: 'Senha',
                  icon: Icons.lock_outline,
                  hint: 'Mínimo 6 caracteres',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  obscureText: !_isPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _isPasswordVisible = !_isPasswordVisible,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, insira uma senha';
                    }
                    if (!_passwordRegex.hasMatch(value)) {
                      return 'A senha deve conter letra maiúscula, minúscula, número e caractere especial';
                    }
                    return null;
                  },
                ),
                _buildInput(
                  controller: _confirmarSenhaController,
                  label: 'Confirmar Senha',
                  icon: Icons.lock_outline,
                  hint: 'Digite a senha novamente',
                  isDark: isDark,
                  primaryColor: primaryColor,
                  obscureText: !_isConfirmPasswordVisible,
                  suffixIcon: IconButton(
                    icon: Icon(
                      _isConfirmPasswordVisible
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                    onPressed: () => setState(
                      () => _isConfirmPasswordVisible =
                          !_isConfirmPasswordVisible,
                    ),
                  ),
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Por favor, confirme sua senha';
                    }
                    if (value != _senhaController.text) {
                      return 'As senhas não conferem';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 18),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Checkbox(
                      value: _acceptedTerms,
                      activeColor: primaryColor,
                      onChanged: (value) =>
                          setState(() => _acceptedTerms = value ?? false),
                    ),
                    Expanded(
                      child: Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 13,
                              color:
                                  isDark ? Colors.grey[400] : Colors.grey[600],
                            ),
                            children: [
                              const TextSpan(text: 'Eu aceito os '),
                              TextSpan(
                                text:
                                    'termos de serviço e política de privacidade',
                                style: GoogleFonts.outfit(
                                  color: primaryColor,
                                  fontWeight: FontWeight.w600,
                                  decoration: TextDecoration.underline,
                                ),
                                recognizer: TapGestureRecognizer()
                                  ..onTap = () => context.push('/privacy'),
                              ),
                              const TextSpan(text: ' da Padoca Express.'),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: isLoading ? null : _cadastrar,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    elevation: 4,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.person_add_alt_1_outlined),
                  label: Text(
                    isLoading ? 'Cadastrando...' : 'Cadastrar',
                    style: GoogleFonts.outfit(fontWeight: FontWeight.w700),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Já tem uma conta? ',
                      style: GoogleFonts.outfit(
                        color: isDark ? Colors.grey[400] : Colors.grey[600],
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
      ),
    );
  }

  Widget _buildInput({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required String hint,
    required bool isDark,
    required Color primaryColor,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    bool obscureText = false,
    Widget? suffixIcon,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 18),
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        inputFormatters: inputFormatters,
        validator: validator,
        style: GoogleFonts.outfit(
          color: isDark ? Colors.grey[100] : Colors.grey[800],
        ),
        decoration: InputDecoration(
          labelText: label,
          hintText: hint,
          prefixIcon: Icon(icon, size: 20),
          suffixIcon: suffixIcon,
          filled: true,
          fillColor: isDark ? const Color(0xFF171717) : Colors.white,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            ),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
              color: isDark ? Colors.grey[700]! : const Color(0xFFE5E7EB),
            ),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: primaryColor, width: 2),
          ),
          errorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
          focusedErrorBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Colors.red, width: 1.5),
          ),
        ),
      ),
    );
  }
}

class _Header extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool isDark;
  final Color textColor;
  final Color primaryColor;
  final Color burgundyColor;

  const _Header({
    required this.title,
    required this.subtitle,
    required this.isDark,
    required this.textColor,
    required this.primaryColor,
    required this.burgundyColor,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back_ios_new, color: textColor),
              onPressed: () => context.pop(),
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
                      color: textColor,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          width: 82,
          height: 82,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF262626) : Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ClipOval(
            child: Image.asset(
              'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
              fit: BoxFit.contain,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.person_add, color: textColor, size: 28),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: textColor,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          textAlign: TextAlign.center,
          style: GoogleFonts.outfit(
            fontSize: 14,
            height: 1.45,
            color: isDark ? Colors.grey[400] : Colors.grey[600],
          ),
        ),
      ],
    );
  }
}
