import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/core/app/app_update_service.dart';
import 'package:url_launcher/url_launcher.dart';

class BaixarAppEntregadorScreen extends StatelessWidget {
  const BaixarAppEntregadorScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final primaryColor = const Color(0xFFFF7034);
    final burgundyColor = const Color(0xFF7D2D35);
    final bgDark = const Color(0xFF1C1917);
    final bgLight = const Color(0xFFF9F5F0);
    final textColor = isDark ? const Color(0xFFFFE0B2) : burgundyColor;

    return Scaffold(
      backgroundColor: isDark ? bgDark : bgLight,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new,
            color: isDark ? Colors.white : burgundyColor,
          ),
          onPressed: () => context.pop(),
        ),
      ),
      body: Center(
        child: ScrollConfiguration(
          behavior: ScrollConfiguration.of(context).copyWith(scrollbars: false),
          child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 500),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0x8044403C) : const Color(0xFFFFF7ED),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.two_wheeler_outlined,
                    color: isDark ? primaryColor : const Color(0xFF7D2D35),
                    size: 64,
                  ),
                ),
                const SizedBox(height: 32),
                Text(
                  'Disponível apenas no Aplicativo',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: textColor,
                    height: 1.2,
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'Para garantir a melhor experiência e utilizar recursos como GPS e câmera durante as entregas, o cadastro e uso do painel de entregador devem ser feitos diretamente no aplicativo mobile do Ôpadoca Express.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.outfit(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                    color: isDark ? const Color(0xFFA8A29E) : Colors.grey[700],
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 48),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _buildStoreButton(
                      icon: Icons.android,
                      title: 'Disponível no',
                      store: 'Google Play',
                      onTap: _abrirGooglePlay,
                    ),
                  ],
                ),
                const SizedBox(height: 48),
                TextButton(
                  onPressed: () => context.pop(),
                  child: Text(
                    'Voltar',
                    style: GoogleFonts.outfit(
                      color: isDark ? Colors.grey[400] : Colors.grey[600],
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
            ),
          ),
        ),
      ),
    );
  }

  static Future<void> _abrirGooglePlay() async {
    final uri = Uri.parse(
      'https://play.google.com/store/apps/details?id=$kPlayStorePackageId',
    );
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) {
      await launchUrl(uri, mode: LaunchMode.platformDefault);
    }
  }

  Widget _buildStoreButton({
    required IconData icon,
    required String title,
    required String store,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.white24),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: Colors.white, size: 32),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.outfit(
                    color: Colors.white70,
                    fontSize: 10,
                  ),
                ),
                Text(
                  store,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
