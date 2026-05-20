import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_cliente/cadastro_cliente_controller.dart';
import 'package:padoca_express/features/estabelecimento/componentes/app_bar_estabelecimento.dart';

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
    const burgundyColor = Color(0xFF7D2D35);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF23150F) : const Color(0xFFF9F5F0),
      appBar: const AppBarEstabelecimento(),
      body: _buildContent(
        primaryColor: primaryColor,
        burgundyColor: burgundyColor,
        isDark: isDark,
        isLoading: state.isLoading,
      ),
    );
  }

  Widget _buildContent({
    required Color primaryColor,
    required Color burgundyColor,
    required bool isDark,
    required bool isLoading,
  }) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 24, 16, 40),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 500),
          child: Form(
            key: _formKey,
            autovalidateMode: _showValidationErrors
                ? AutovalidateMode.onUserInteraction
                : AutovalidateMode.disabled,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Cadastro de Cliente',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark ? Colors.white : burgundyColor,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Crie sua conta e faça seus pedidos com facilidade.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    color: isDark
                        ? Colors.grey[400]
                        : burgundyColor.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 32),
                _buildSectionTitle(
                  Icons.person,
                  'Dados Pessoais',
                  isDark,
                  burgundyColor,
                  primaryColor,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 32),
                _buildSectionTitle(
                  Icons.lock,
                  'Credenciais de Acesso',
                  isDark,
                  burgundyColor,
                  primaryColor,
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      height: 24,
                      width: 24,
                      child: Checkbox(
                        value: _acceptedTerms,
                        onChanged: (value) =>
                            setState(() => _acceptedTerms = value ?? false),
                        fillColor: WidgetStateProperty.resolveWith(
                          (states) => states.contains(WidgetState.selected)
                              ? primaryColor
                              : Colors.transparent,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.plusJakartaSans(
                            color: isDark
                                ? Colors.grey[400]
                                : burgundyColor.withValues(alpha: 0.7),
                            fontSize: 12,
                          ),
                          children: [
                            const TextSpan(text: 'Eu aceito os '),
                            TextSpan(
                              text:
                                  'Termos de Serviço e Política de Privacidade',
                              style: GoogleFonts.outfit(
                                color: primaryColor,
                                fontWeight: FontWeight.w500,
                                fontSize: 14,
                                decoration: TextDecoration.underline,
                              ),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () => context.push('/privacy'),
                            ),
                            const TextSpan(text: ' da Ôpadoca Express.'),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: isLoading ? null : _cadastrar,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryColor,
                      foregroundColor: Colors.white,
                      elevation: 4,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
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
    const burgundyColor = Color(0xFF7D2D35);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(left: 4, bottom: 6),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isDark ? const Color(0xFFD4D4D8) : burgundyColor,
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF27272A) : Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.05),
                  blurRadius: 20,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: TextFormField(
              controller: controller,
              obscureText: obscureText,
              keyboardType: keyboardType,
              inputFormatters: inputFormatters,
              validator: validator,
              style: GoogleFonts.plusJakartaSans(
                color: isDark ? Colors.white : burgundyColor,
              ),
              decoration: InputDecoration(
                hintText: hint,
                hintStyle: GoogleFonts.plusJakartaSans(
                  color: isDark ? Colors.grey[600] : Colors.grey[400],
                  fontSize: 14,
                ),
                prefixIcon: Icon(
                  icon,
                  color: isDark
                      ? Colors.grey[600]
                      : burgundyColor.withValues(alpha: 0.4),
                ),
                suffixIcon: suffixIcon,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey[800]! : Colors.grey[200]!,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: primaryColor, width: 2),
                ),
                errorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red[400]!),
                ),
                focusedErrorBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: Colors.red[400]!, width: 2),
                ),
                contentPadding: const EdgeInsets.all(20),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(
    IconData icon,
    String title,
    bool isDark,
    Color color,
    Color primary,
  ) {
    return Row(
      children: [
        Icon(icon, color: primary, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            color: isDark ? Colors.white : color,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
