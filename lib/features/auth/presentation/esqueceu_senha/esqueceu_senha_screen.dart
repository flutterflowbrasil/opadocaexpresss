import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'esqueceu_senha_controller.dart';

class EsqueceuSenhaScreen extends ConsumerStatefulWidget {
  const EsqueceuSenhaScreen({super.key});

  @override
  ConsumerState<EsqueceuSenhaScreen> createState() => _EsqueceuSenhaScreenState();
}

class _EsqueceuSenhaScreenState extends ConsumerState<EsqueceuSenhaScreen> {
  final _emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  static const _bgColor = Color(0xFFF0EDE6); // bege igual ao login
  static const _orange = Color(0xFFF97316);
  static const _wine = Color(0xFF6B1F1F);
  static const _inputBg = Color(0xFFFFFFFF);
  static const _borderColor = Color(0xFFE8E2D9);
  static const _hintColor = Color(0xFFB0A898);
  static const _textColor = Color(0xFF2D2D2D);

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  void _sendResetEmail() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus(); // Ocultar teclado
    ref
        .read(esqueceuSenhaControllerProvider.notifier)
        .sendResetEmail(_emailController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(esqueceuSenhaControllerProvider);

    // Reage aos erros do estado exibindo um SnackBar nativo
    ref.listen(esqueceuSenhaControllerProvider, (previous, next) {
      if (next.error != null && (previous?.error != next.error)) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(next.error!),
            backgroundColor: Colors.red.shade600,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
        );
      }
    });

    return Scaffold(
      backgroundColor: _bgColor,
      appBar: AppBar(
        backgroundColor: _bgColor,
        elevation: 0,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: _inputBg,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _borderColor),
            ),
            child: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 16,
              color: _textColor,
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: Column(
                children: [
                  const SizedBox(height: 12),

                  // Ícone central
                  Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: _orange.withOpacity(0.12),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Container(
                        width: 52,
                        height: 52,
                        decoration: BoxDecoration(
                          color: _orange.withOpacity(0.18),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.lock_reset_rounded,
                          color: _orange,
                          size: 28,
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Título
                  Text(
                    'Esqueceu a senha?',
                    style: GoogleFonts.dmSans(
                      fontSize: 26,
                      fontWeight: FontWeight.w800,
                      color: _wine,
                      letterSpacing: -0.4,
                    ),
                  ),

                  const SizedBox(height: 10),

                  // Subtítulo
                  Text(
                    state.emailSent
                        ? 'Verifique sua caixa de entrada.\nEnviamos o link de redefinição para:'
                        : 'Informe o e-mail cadastrado e\nenviaremos um link de redefinição.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.dmSans(
                      fontSize: 14,
                      color: _textColor.withOpacity(0.55),
                      height: 1.5,
                    ),
                  ),

                  const SizedBox(height: 36),

                  // Estado: e-mail enviado
                  if (state.emailSent) ...[
                    _EmailSentCard(
                      email: _emailController.text.trim(),
                      orange: _orange,
                      bgColor: _inputBg,
                      borderColor: _borderColor,
                      textColor: _textColor,
                    ),
                    const SizedBox(height: 28),

                    // Botão voltar ao login
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: () => context.pop(),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: Text(
                          'Voltar ao login',
                          style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Reenviar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Não recebeu? ',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _textColor.withOpacity(0.5),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () {
                              ref
                                  .read(esqueceuSenhaControllerProvider.notifier)
                                  .resetarMensagemSucesso();
                            },
                            child: Text(
                              'Reenviar',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ]
                  // Estado: formulário
                  else ...[
                    Form(
                      key: _formKey,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Label
                          Text(
                            'E-mail',
                            style: GoogleFonts.dmSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: _wine,
                            ),
                          ),
                          const SizedBox(height: 8),

                          // Input e-mail
                          TextFormField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onFieldSubmitted: (_) => _sendResetEmail(),
                            style: GoogleFonts.dmSans(
                              fontSize: 15,
                              color: _textColor,
                              fontWeight: FontWeight.w500,
                            ),
                            decoration: InputDecoration(
                              hintText: 'exemplo@dominio.com',
                              hintStyle: GoogleFonts.dmSans(
                                fontSize: 15,
                                color: _hintColor,
                              ),
                              prefixIcon: const Padding(
                                padding: EdgeInsets.only(left: 16, right: 10),
                                child: Icon(Icons.mail_outline_rounded,
                                    color: _hintColor, size: 20),
                              ),
                              prefixIconConstraints:
                                  const BoxConstraints(minWidth: 0, minHeight: 0),
                              filled: true,
                              fillColor: _inputBg,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _borderColor),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide:
                                    const BorderSide(color: _borderColor),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: _orange, width: 1.8),
                              ),
                              errorBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(
                                    color: Colors.red, width: 1.5),
                              ),
                              contentPadding: const EdgeInsets.symmetric(
                                  vertical: 18, horizontal: 16),
                            ),
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) {
                                return 'Informe seu e-mail';
                              }
                              final emailRegex = RegExp(
                                  r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
                              if (!emailRegex.hasMatch(v.trim())) {
                                return 'E-mail inválido';
                              }
                              return null;
                            },
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Dica informativa
                    Container(
                      padding: const EdgeInsets.all(13),
                      decoration: BoxDecoration(
                        color: _orange.withOpacity(0.07),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: _orange.withOpacity(0.18)),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.info_outline_rounded,
                              size: 16, color: _orange.withOpacity(0.8)),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              'Você receberá um link válido por 1 hora.',
                              style: GoogleFonts.dmSans(
                                fontSize: 12,
                                color: _orange.withOpacity(0.85),
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 28),

                    // Botão enviar
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _sendResetEmail,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: _orange,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: _orange.withOpacity(0.55),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        child: state.isLoading
                            ? const SizedBox(
                                width: 22,
                                height: 22,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.5,
                                  color: Colors.white,
                                ),
                              )
                            : Text(
                                'Enviar link de redefinição',
                                style: GoogleFonts.dmSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    // Link voltar
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Lembrou a senha? ',
                          style: GoogleFonts.dmSans(
                            fontSize: 13,
                            color: _textColor.withOpacity(0.5),
                          ),
                        ),
                        MouseRegion(
                          cursor: SystemMouseCursors.click,
                          child: GestureDetector(
                            onTap: () => context.pop(),
                            child: Text(
                              'Entrar',
                              style: GoogleFonts.dmSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: _orange,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ── Card de confirmação de envio ──────────────────────────────────────────────
class _EmailSentCard extends StatelessWidget {
  final String email;
  final Color orange, bgColor, borderColor, textColor;

  const _EmailSentCard({
    required this.email,
    required this.orange,
    required this.bgColor,
    required this.borderColor,
    required this.textColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        children: [
          // Ícone de sucesso
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: const Color(0xFF10B981).withOpacity(0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.mark_email_read_rounded,
              color: Color(0xFF10B981),
              size: 28,
            ),
          ),
          const SizedBox(height: 14),

          Text(
            'E-mail enviado!',
            style: GoogleFonts.dmSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),

          Text(
            email,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: orange,
            ),
          ),
          const SizedBox(height: 8),

          Text(
            'Verifique também a pasta de spam\ncaso não encontre na caixa de entrada.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 12,
              color: textColor.withOpacity(0.45),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}
