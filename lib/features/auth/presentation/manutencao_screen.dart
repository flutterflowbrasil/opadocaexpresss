import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';

class ManutencaoScreen extends StatelessWidget {
  const ManutencaoScreen({super.key, this.config});

  final PlataformaRuntimeConfig? config;

  @override
  Widget build(BuildContext context) {
    final nome = config?.plataformaNome ?? 'Ôpadoca Express';
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.cloud_off_rounded,
                  size: 56, color: Color(0xFFF97316)),
              const SizedBox(height: 16),
              Text(
                '$nome em manutenção',
                textAlign: TextAlign.center,
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7D2D35),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Estamos ajustando a plataforma. Tente novamente em alguns minutos.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
              if ((config?.suporteWhatsapp ?? '').isNotEmpty) ...[
                const SizedBox(height: 24),
                TextButton(
                  onPressed: () {
                    final wa = config!.suporteWhatsapp.replaceAll(RegExp(r'\D'), '');
                    launchUrl(Uri.parse('https://wa.me/$wa'));
                  },
                  child: const Text('Falar com o suporte'),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class AtualizarAppScreen extends StatelessWidget {
  const AtualizarAppScreen({super.key, this.config});

  final PlataformaRuntimeConfig? config;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF9F5F0),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.system_update_alt_rounded,
                  size: 56, color: Color(0xFFF97316)),
              const SizedBox(height: 16),
              Text(
                'Atualize o aplicativo',
                style: GoogleFonts.outfit(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF7D2D35),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'A versão mínima é ${config?.versaoMinimaApp ?? '-'}. Você está em $kAppVersion.',
                textAlign: TextAlign.center,
                style: GoogleFonts.dmSans(
                  fontSize: 14,
                  color: const Color(0xFF6B7280),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
