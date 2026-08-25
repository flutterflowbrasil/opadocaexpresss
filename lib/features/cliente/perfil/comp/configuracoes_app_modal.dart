import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/core/app/app_update_service.dart';
import 'package:padoca_express/core/config/plataforma_runtime_config.dart';
import 'package:url_launcher/url_launcher.dart';

class ConfiguracoesAppModal extends ConsumerStatefulWidget {
  const ConfiguracoesAppModal({super.key});

  static Future<void> show(BuildContext context) {
    return showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      useSafeArea: true,
      builder: (_) => const ConfiguracoesAppModal(),
    );
  }

  @override
  ConsumerState<ConfiguracoesAppModal> createState() =>
      _ConfiguracoesAppModalState();
}

class _ConfiguracoesAppModalState extends ConsumerState<ConfiguracoesAppModal> {
  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  bool _verificando = false;
  String? _feedback;

  Future<void> _verificarAtualizacao(PlataformaRuntimeConfig cfg) async {
    if (_verificando) return;
    setState(() {
      _verificando = true;
      _feedback = null;
    });

    try {
      final result = await AppUpdateService.verificarAtualizacao(
        cfg: cfg,
        ref: ref,
      );
      if (!mounted) return;
      setState(() {
        _feedback = AppUpdateService.mensagemResultado(result);
        _verificando = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _feedback = 'Não foi possível verificar agora. Tente novamente.';
        _verificando = false;
      });
    }
  }

  Future<void> _abrirEmail(String email) async {
    final uri = Uri(scheme: 'mailto', path: email);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _abrirWhatsapp(String numero) async {
    final digits = numero.replaceAll(RegExp(r'\D'), '');
    if (digits.isEmpty) return;
    final uri = Uri.parse('https://wa.me/$digits');
    await launchUrl(uri, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = isDark ? const Color(0xFF1C1917) : Colors.white;
    final cfg = ref.watch(plataformaRuntimeConfigProvider).valueOrNull ??
        const PlataformaRuntimeConfig();
    final minima = cfg.versaoMinimaApp.trim();
    final precisaAtualizar = cfg.appAbaixoDaMinima();

    return Container(
      decoration: BoxDecoration(
        color: bg,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.fromLTRB(
        24,
        16,
        24,
        MediaQuery.of(context).padding.bottom + 24,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Ajuda e suporte',
            style: GoogleFonts.outfit(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : _secondaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Contatos oficiais, versão do app e verificação de atualização.',
            style: GoogleFonts.dmSans(
              fontSize: 13,
              color: isDark ? Colors.grey[400] : Colors.grey[600],
            ),
          ),
          const SizedBox(height: 20),
          if (cfg.suporteEmail.isNotEmpty)
            _InfoTile(
              icon: Icons.mail_outline,
              label: 'E-mail de suporte',
              value: cfg.suporteEmail,
              isDark: isDark,
              onTap: () => _abrirEmail(cfg.suporteEmail),
            ),
          if (cfg.suporteWhatsapp.isNotEmpty) ...[
            if (cfg.suporteEmail.isNotEmpty) const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.chat_outlined,
              label: 'WhatsApp',
              value: cfg.suporteWhatsapp,
              isDark: isDark,
              onTap: () => _abrirWhatsapp(cfg.suporteWhatsapp),
            ),
          ],
          if (cfg.suporteEmail.isEmpty && cfg.suporteWhatsapp.isEmpty)
            Text(
              'Nenhum contato de suporte configurado no momento.',
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? Colors.grey[400] : Colors.grey[600],
              ),
            ),
          const SizedBox(height: 20),
          Divider(color: Colors.grey.withValues(alpha: 0.15)),
          const SizedBox(height: 16),
          _InfoTile(
            icon: Icons.info_outline,
            label: 'Versão instalada',
            value: kAppVersion,
            isDark: isDark,
          ),
          if (minima.isNotEmpty) ...[
            const SizedBox(height: 12),
            _InfoTile(
              icon: Icons.system_update_alt_outlined,
              label: 'Versão mínima da plataforma',
              value: minima,
              isDark: isDark,
              valueColor: precisaAtualizar ? Colors.orange[800] : null,
            ),
          ],
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _verificando ? null : () => _verificarAtualizacao(cfg),
              style: ElevatedButton.styleFrom(
                backgroundColor: _primaryColor,
                disabledBackgroundColor: Colors.grey[400],
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              icon: _verificando
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.refresh_rounded, color: Colors.white),
              label: Text(
                _verificando ? 'Verificando…' : 'Verificar atualização',
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          if (_feedback != null) ...[
            const SizedBox(height: 12),
            Text(
              _feedback!,
              style: GoogleFonts.dmSans(
                fontSize: 13,
                color: isDark ? Colors.grey[300] : Colors.grey[700],
              ),
            ),
          ],
          const SizedBox(height: 8),
          Text(
            kIsWeb
                ? 'Na web, a verificação limpa o cache do navegador e recarrega o app.'
                : 'No Android, se houver atualização obrigatória, você será direcionado à Play Store.',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: isDark ? Colors.grey[500] : Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  const _InfoTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.isDark,
    this.onTap,
    this.valueColor,
  });

  final IconData icon;
  final String label;
  final String value;
  final bool isDark;
  final VoidCallback? onTap;
  final Color? valueColor;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  @override
  Widget build(BuildContext context) {
    final content = Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: _primaryColor.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: _primaryColor, size: 22),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.dmSans(
                  fontSize: 12,
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
              const SizedBox(height: 2),
              Text(
                value,
                style: GoogleFonts.outfit(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                  color: valueColor ??
                      (isDark ? Colors.white : _secondaryColor),
                ),
              ),
            ],
          ),
        ),
        if (onTap != null)
          Icon(Icons.open_in_new, size: 18, color: Colors.grey[400]),
      ],
    );

    if (onTap == null) return content;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: content,
        ),
      ),
    );
  }
}
