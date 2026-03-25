import 'dart:async';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'nova_senha_controller.dart';

class NovaSenhaScreen extends ConsumerStatefulWidget {
  const NovaSenhaScreen({super.key});

  @override
  ConsumerState<NovaSenhaScreen> createState() => _NovaSenhaScreenState();
}

class _NovaSenhaScreenState extends ConsumerState<NovaSenhaScreen> {
  final _senhaController = TextEditingController();
  final _confirmarSenhaController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  bool _showSenha = false;
  bool _showConfirmar = false;
  bool _processandoLink = true; // Iniciamos processando a URL
  String? _erroLink; // Caso o código seja inválido

  // Validação de força da senha
  bool get _temMaiuscula => _senhaController.text.contains(RegExp(r'[A-Z]'));
  bool get _temMinuscula => _senhaController.text.contains(RegExp(r'[a-z]'));
  bool get _temNumero => _senhaController.text.contains(RegExp(r'[0-9]'));
  bool get _temEspecial => _senhaController.text.contains(RegExp(r'[!@#\$%^&*(),.?":{}|<>]'));
  bool get _senhasIguais =>
      _senhaController.text == _confirmarSenhaController.text &&
      _confirmarSenhaController.text.isNotEmpty;

  int get _forca {
    int pts = 0;
    if (_temMaiuscula) pts++;
    if (_temMinuscula) pts++;
    if (_temNumero) pts++;
    if (_temEspecial) pts++;
    if (_senhaController.text.length >= 8) pts++; // Bônus para barra de força
    return (pts / 5 * 3).floor().clamp(0, 3); // 0 fraca · 1 regular · 2 boa · 3 forte
  }

  static const _bgColor = Color(0xFFF0EDE6);
  static const _orange = Color(0xFFF97316);
  static const _wine = Color(0xFF6B1F1F);
  static const _inputBg = Color(0xFFFFFFFF);
  static const _borderColor = Color(0xFFE8E2D9);
  static const _hintColor = Color(0xFFB0A898);
  static const _textColor = Color(0xFF2D2D2D);
  static const _green = Color(0xFF10B981);

  late final StreamSubscription<AuthState> _authSubscription;

  @override
  void initState() {
    super.initState();
    _authSubscription = Supabase.instance.client.auth.onAuthStateChange.listen((data) {
      if (data.session != null && mounted) {
        setState(() => _processandoLink = false);
      }
    });

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _processarSessaoInicial();
    });
  }

  Future<void> _processarSessaoInicial() async {
    // Sessão já disponível (troca automática concluída antes da tela montar)
    if (Supabase.instance.client.auth.currentSession != null) {
      if (mounted) setState(() => _processandoLink = false);
      return;
    }

    final code = Uri.base.queryParameters['code'];

    if (code == null || code.isEmpty) {
      if (mounted) {
        setState(() {
          _erroLink = 'Acesso não autorizado ou link incompleto.';
          _processandoLink = false;
        });
      }
      return;
    }

    // Troca explícita do código PKCE por sessão.
    // O SDK às vezes não faz isso automaticamente no web com go_router.
    try {
      await Supabase.instance.client.auth.exchangeCodeForSession(code);
      if (mounted) setState(() => _processandoLink = false);
    } on AuthException {
      if (mounted) {
        setState(() {
          _erroLink = 'O link de recuperação parece inválido ou já foi usado. Tente solicitar um novo.';
          _processandoLink = false;
        });
      }
    } catch (_) {
      if (mounted) {
        setState(() {
          _erroLink = 'O link de recuperação parece inválido ou já foi usado. Tente solicitar um novo.';
          _processandoLink = false;
        });
      }
    }
  }

  @override
  void dispose() {
    _authSubscription.cancel();
    _senhaController.dispose();
    _confirmarSenhaController.dispose();
    super.dispose();
  }

  void _salvarNovaSenha() {
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    ref
        .read(novaSenhaControllerProvider.notifier)
        .updatePassword(_senhaController.text);
  }

  // Faz logout e navega para o login
  Future<void> _irParaLogin() async {
    await Supabase.instance.client.auth.signOut();
    if (mounted) context.go('/login');
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(novaSenhaControllerProvider);

    ref.listen(novaSenhaControllerProvider, (previous, next) {
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
        automaticallyImplyLeading: false,
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 450),
              child: _processandoLink 
                ? _buildLoadingLink()
                : _erroLink != null
                  ? _buildErroLink()
                  : state.sucesso 
                      ? _buildSucesso() 
                      : _buildFormulario(state.isLoading),
            ),
          ),
        ),
      ),
    );
  }

  // ─── TRANSIÇÕES EXTRAS ──────────────────────────────────────────────────────
  Widget _buildLoadingLink() {
    return Column(
      children: [
        const SizedBox(height: 100),
        const CircularProgressIndicator(color: _orange),
        const SizedBox(height: 24),
        Text(
          'Validando acesso seguro...',
          style: GoogleFonts.dmSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: _wine,
          ),
        ),
      ],
    );
  }

  Widget _buildErroLink() {
    return Column(
      children: [
        const SizedBox(height: 60),
        Icon(Icons.error_outline_rounded, size: 60, color: Colors.red.shade400),
        const SizedBox(height: 24),
        Text(
          'Acesso não autorizado',
          style: GoogleFonts.dmSans(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: _wine,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          _erroLink!,
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            height: 1.5,
            color: _textColor.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 32),
        ElevatedButton(
          onPressed: _irParaLogin,
          style: ElevatedButton.styleFrom(
            backgroundColor: _orange,
            foregroundColor: Colors.white,
            minimumSize: const Size(double.infinity, 54),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          ),
          child: Text('Voltar para o Login', style: GoogleFonts.dmSans(fontSize: 16, fontWeight: FontWeight.w700)),
        )
      ],
    );
  }

  // ─── FORMULÁRIO ────────────────────────────────────────────────────────────
  Widget _buildFormulario(bool isLoading) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 8),

        // Ícone
        Center(
          child: Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: _orange.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: _orange.withOpacity(0.16),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.lock_open_rounded,
                  color: _orange,
                  size: 26,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 22),

        // Título e subtítulo
        Center(
          child: Text(
            'Nova senha',
            style: GoogleFonts.dmSans(
              fontSize: 26,
              fontWeight: FontWeight.w800,
              color: _wine,
              letterSpacing: -0.4,
            ),
          ),
        ),
        const SizedBox(height: 8),
        Center(
          child: Text(
            'Crie uma senha forte para\nproteger sua conta.',
            textAlign: TextAlign.center,
            style: GoogleFonts.dmSans(
              fontSize: 14,
              color: _textColor.withOpacity(0.52),
              height: 1.5,
            ),
          ),
        ),

        const SizedBox(height: 32),

        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Campo: Nova senha ──
              _Label('Nova senha'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _senhaController,
                hint: '••••••••',
                obscure: !_showSenha,
                suffixIcon: _ToggleVisibilityButton(
                  visible: _showSenha,
                  onTap: () => setState(() => _showSenha = !_showSenha),
                  hintColor: _hintColor,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Informe a nova senha';
                  if (!_temMaiuscula || !_temMinuscula || !_temNumero || !_temEspecial) {
                    return 'A senha não atende aos requisitos';
                  }
                  return null;
                },
              ),

              const SizedBox(height: 14),

              // ── Indicador de força ──
              _ForcaSenha(forca: _forca, senha: _senhaController.text),

              const SizedBox(height: 8),

              // ── Checklist de requisitos ──
              _Checklist(
                itens: [
                  _CheckItem('Pelo menos 1 letra maiúscula', _temMaiuscula),
                  _CheckItem('Pelo menos 1 letra minúscula', _temMinuscula),
                  _CheckItem('Pelo menos 1 número', _temNumero),
                  _CheckItem('Pelo menos 1 caractere especial', _temEspecial),
                ],
                green: _green,
                hintColor: _hintColor,
              ),

              const SizedBox(height: 22),

              // ── Campo: Confirmar senha ──
              _Label('Confirmar senha'),
              const SizedBox(height: 8),
              _buildInput(
                controller: _confirmarSenhaController,
                hint: '••••••••',
                obscure: !_showConfirmar,
                suffixIcon: _ToggleVisibilityButton(
                  visible: _showConfirmar,
                  onTap: () => setState(() => _showConfirmar = !_showConfirmar),
                  hintColor: _hintColor,
                ),
                onChanged: (_) => setState(() {}),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Confirme a nova senha';
                  if (v != _senhaController.text) {
                    return 'As senhas não conferem';
                  }
                  return null;
                },
                // Borda verde quando as senhas conferem
                matchOk: _senhasIguais,
                green: _green,
              ),

              // Feedback inline de senhas iguais
              if (_confirmarSenhaController.text.isNotEmpty) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Icon(
                      _senhasIguais
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      size: 14,
                      color: _senhasIguais ? _green : Colors.red.shade400,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _senhasIguais ? 'Senhas conferem' : 'Senhas não conferem',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _senhasIguais ? _green : Colors.red.shade400,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),

        const SizedBox(height: 32),

        // ── Botão salvar ──
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: isLoading ? null : _salvarNovaSenha,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              disabledBackgroundColor: _orange.withOpacity(0.50),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: isLoading
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: Colors.white,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.save_rounded, size: 19),
                      const SizedBox(width: 8),
                      Text(
                        'Salvar nova senha',
                        style: GoogleFonts.dmSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ─── TELA DE SUCESSO ───────────────────────────────────────────────────────
  Widget _buildSucesso() {
    return Column(
      children: [
        const SizedBox(height: 48),

        // Ícone de sucesso animado
        Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: _green.withOpacity(0.10),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Container(
                width: 68,
                height: 68,
                decoration: BoxDecoration(
                  color: _green.withOpacity(0.18),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  color: _green,
                  size: 36,
                ),
              ),
            ),
          ),
        ),

        const SizedBox(height: 28),

        Text(
          'Senha redefinida!',
          style: GoogleFonts.dmSans(
            fontSize: 26,
            fontWeight: FontWeight.w800,
            color: _wine,
            letterSpacing: -0.4,
          ),
        ),

        const SizedBox(height: 12),

        Text(
          'Sua senha foi alterada com sucesso.\nAgora você já pode entrar na sua conta.',
          textAlign: TextAlign.center,
          style: GoogleFonts.dmSans(
            fontSize: 14,
            color: _textColor.withOpacity(0.52),
            height: 1.6,
          ),
        ),

        const SizedBox(height: 40),

        // Card de confirmação
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: _green.withOpacity(0.06),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: _green.withOpacity(0.22)),
          ),
          child: Row(
            children: [
              const Icon(Icons.verified_user_rounded, color: _green, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Sua conta está protegida com a nova senha.',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _green.withOpacity(0.85),
                    height: 1.4,
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(height: 32),

        // Botão ir para login
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: _irParaLogin,
            style: ElevatedButton.styleFrom(
              backgroundColor: _orange,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Text(
              'Ir para o login',
              style: GoogleFonts.dmSans(
                fontSize: 16,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ),

        const SizedBox(height: 40),
      ],
    );
  }

  // ─── INPUT HELPER ──────────────────────────────────────────────────────────
  Widget _buildInput({
    required TextEditingController controller,
    required String hint,
    required bool obscure,
    required Widget suffixIcon,
    required String? Function(String?) validator,
    void Function(String)? onChanged,
    bool matchOk = false,
    Color green = _green,
  }) {
    final focusedBorder = OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(
        color: matchOk ? green : _orange,
        width: 1.8,
      ),
    );
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      onChanged: onChanged,
      textInputAction: TextInputAction.next,
      style: GoogleFonts.dmSans(
        fontSize: 15,
        color: _textColor,
        fontWeight: FontWeight.w500,
        letterSpacing: obscure ? 2.0 : 0,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.dmSans(
            fontSize: 15, color: _hintColor, letterSpacing: 2),
        prefixIcon: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(Icons.lock_outline_rounded, color: _hintColor, size: 20),
        ),
        prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
        suffixIcon: suffixIcon,
        filled: true,
        fillColor: _inputBg,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _borderColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: matchOk ? green.withOpacity(0.5) : _borderColor,
          ),
        ),
        focusedBorder: focusedBorder,
        focusedErrorBorder: focusedBorder,
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Colors.red, width: 1.5),
        ),
        contentPadding:
            const EdgeInsets.symmetric(vertical: 18, horizontal: 16),
      ),
      validator: validator,
    );
  }

  // Label padrão
  Widget _Label(String text) => Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 14,
          fontWeight: FontWeight.w700,
          color: _wine,
        ),
      );
}

// ─── TOGGLE VISIBILIDADE ──────────────────────────────────────────────────────
class _ToggleVisibilityButton extends StatelessWidget {
  final bool visible;
  final VoidCallback onTap;
  final Color hintColor;
  const _ToggleVisibilityButton({
    required this.visible,
    required this.onTap,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return IconButton(
      onPressed: onTap,
      icon: Icon(
        visible ? Icons.visibility_off_outlined : Icons.visibility_outlined,
        color: hintColor,
        size: 20,
      ),
    );
  }
}

// ─── INDICADOR DE FORÇA DA SENHA ─────────────────────────────────────────────
class _ForcaSenha extends StatelessWidget {
  final int forca;
  final String senha;
  const _ForcaSenha({required this.forca, required this.senha});

  static const _labels = ['', 'Fraca', 'Razoável', 'Forte'];
  static const _cores = [
    Color(0xFFE5E7EB),
    Color(0xFFEF4444),
    Color(0xFFF59E0B),
    Color(0xFF10B981),
  ];

  @override
  Widget build(BuildContext context) {
    if (senha.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: List.generate(3, (i) {
            final ativo = i < forca;
            return Expanded(
              child: Container(
                margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                height: 4,
                decoration: BoxDecoration(
                  color: ativo ? _cores[forca] : const Color(0xFFE8E2D9),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
            );
          }),
        ),
        const SizedBox(height: 5),
        if (forca > 0)
          Text(
            'Senha ${_labels[forca]}',
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: _cores[forca],
            ),
          ),
      ],
    );
  }
}

// ─── CHECKLIST DE REQUISITOS ──────────────────────────────────────────────────
class _CheckItem {
  final String label;
  final bool ok;
  const _CheckItem(this.label, this.ok);
}

class _Checklist extends StatelessWidget {
  final List<_CheckItem> itens;
  final Color green, hintColor;
  const _Checklist({
    required this.itens,
    required this.green,
    required this.hintColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFFFF),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE8E2D9)),
      ),
      child: Column(
        children: itens
            .map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      Icon(
                        item.ok
                            ? Icons.check_circle_rounded
                            : Icons.radio_button_unchecked_rounded,
                        size: 15,
                        color: item.ok ? green : hintColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        item.label,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight:
                              item.ok ? FontWeight.w600 : FontWeight.w400,
                          color: item.ok ? green : hintColor,
                        ),
                      ),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
