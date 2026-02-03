import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  // bool _isRegistering = false; // Removed as we navigate to pre-cadastro
  bool _acceptedTerms = false;
  bool _isPasswordVisible = false;

  // void _toggleMode() ... // Removed

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFFFF7034);
    final burgundyColor = const Color(0xFF7D2D35);
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final bgLight = const Color(0xFFF9F5F0);
    final bgDark = const Color(0xFF1A1614);

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Logo
              Container(
                width: 160,
                height: 160,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF27272A) : Colors.white,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 20,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Image.asset(
                  'assets/imagens/6ecd0f44-dfa4-4738-9674-3876102610c9.png',
                  fit: BoxFit.contain,
                ),
              ),
              const SizedBox(height: 32),

              // Title
              Text(
                'Login',
                style: GoogleFonts.outfit(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isDark ? const Color(0xFFFFE0B2) : burgundyColor,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Bem-vindo de volta ao Padoca Express!',
                style: GoogleFonts.outfit(
                  fontSize: 14,
                  color: isDark
                      ? const Color(0xFFA1A1AA)
                      : const Color(0xFF71717A),
                ),
              ),
              const SizedBox(height: 32),

              // Form Container
              Container(
                constraints: const BoxConstraints(maxWidth: 400),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildLabel('E-mail', isDark, burgundyColor),
                    const SizedBox(height: 6),
                    _buildTextField(
                      icon: Icons.email_outlined,
                      hint: 'exemplo@dominio.com',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      burgundyColor: burgundyColor,
                      keyboardType: TextInputType.emailAddress,
                    ),
                    const SizedBox(height: 20),

                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _buildLabel('Senha', isDark, burgundyColor),
                        GestureDetector(
                          onTap: () {
                            // TODO: Forgot password logic
                          },
                          child: Text(
                            'Esqueceu a senha?',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: primaryColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    _buildTextField(
                      icon: Icons.lock_outline,
                      hint: '••••••••',
                      isDark: isDark,
                      primaryColor: primaryColor,
                      burgundyColor: burgundyColor,
                      obscureText: !_isPasswordVisible,
                      suffixIcon: IconButton(
                        icon: Icon(
                          _isPasswordVisible
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          color: const Color(0xFFA1A1AA),
                        ),
                        onPressed: () {
                          setState(() {
                            _isPasswordVisible = !_isPasswordVisible;
                          });
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Checkbox(
                          value: _acceptedTerms,
                          activeColor: primaryColor,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                          onChanged: (value) {
                            setState(() {
                              _acceptedTerms = value ?? false;
                            });
                          },
                        ),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => context.push('/privacy'),
                            child: RichText(
                              text: TextSpan(
                                style: GoogleFonts.outfit(
                                  fontSize: 14,
                                  color: isDark
                                      ? const Color(0xFFD4D4D8)
                                      : burgundyColor,
                                ),
                                children: [
                                  const TextSpan(text: 'Aceito os '),
                                  TextSpan(
                                    text: 'termos e condições',
                                    style: GoogleFonts.outfit(
                                      color: primaryColor,
                                      fontWeight: FontWeight.bold,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),

                    ElevatedButton(
                      onPressed: () {
                        // TODO: Implement login/register logic
                        if (!_acceptedTerms) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Você precisa aceitar os termos.'),
                            ),
                          );
                          return;
                        }
                        context.go('/home'); // Placeholder navigation
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
                      child: Text(
                        'Entrar',
                        style: GoogleFonts.outfit(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),

                    const SizedBox(height: 24),

                    Row(
                      children: [
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(
                            'ou continuar com',
                            style: GoogleFonts.outfit(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                              color: isDark
                                  ? Colors.grey[500]
                                  : Colors.grey[400],
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Divider(
                            color: isDark ? Colors.grey[800] : Colors.grey[300],
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 24),

                    // Google Button Placeholder
                    OutlinedButton.icon(
                      onPressed: () {
                        // TODO: Google Sign In
                      },
                      style: OutlinedButton.styleFrom(
                        backgroundColor: isDark
                            ? const Color(0xFF27272A)
                            : Colors.white,
                        foregroundColor: isDark
                            ? Colors.white
                            : Colors.grey[800],
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        side: BorderSide(
                          color: isDark ? Colors.grey[800]! : Colors.grey[300]!,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      icon: Icon(
                        Icons.g_mobiledata,
                        size: 28,
                        color: Colors.blue,
                      ), // Using icon for simplicity
                      label: Text(
                        'Continuar com Google',
                        style: GoogleFonts.outfit(fontWeight: FontWeight.w600),
                      ),
                    ),

                    const SizedBox(height: 32),

                    Center(
                      child: GestureDetector(
                        onTap: () {
                          context.push('/pre_cadastro');
                        },
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.outfit(
                              fontSize: 14,
                              color: isDark
                                  ? Colors.grey[400]
                                  : Colors.grey[500],
                            ),
                            children: [
                              TextSpan(text: 'Ainda não tem conta? '),
                              TextSpan(
                                text: 'Cadastre-se',
                                style: GoogleFonts.outfit(
                                  color: primaryColor,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
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
  }) {
    return Container(
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
      child: TextField(
        obscureText: obscureText,
        keyboardType: keyboardType,
        style: GoogleFonts.outfit(color: isDark ? Colors.white : burgundyColor),
        decoration: InputDecoration(
          prefixIcon: Icon(
            icon,
            color: isDark
                ? Colors.grey[600]
                : burgundyColor.withValues(alpha: 0.4),
          ),
          hintText: hint,
          hintStyle: GoogleFonts.outfit(color: Colors.grey[400]),
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
          contentPadding: const EdgeInsets.all(20),
        ),
      ),
    );
  }
}
