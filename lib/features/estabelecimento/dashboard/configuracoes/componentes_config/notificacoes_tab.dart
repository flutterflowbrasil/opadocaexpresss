// lib/features/estabelecimento/dashboard/configuracoes/componentes_config/notificacoes_tab.dart
//
// Aba de configurações de notificações — desativa som e/ou notificações.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/estabelecimento/notificacoes/notificacao_dash_controller.dart';

class NotificacoesTab extends ConsumerWidget {
  final bool isDark;
  const NotificacoesTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificacaoDashProvider);
    final notifier = ref.read(notificacaoDashProvider.notifier);

    final cardBg = isDark ? Colors.grey[900]! : Colors.white;
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor = isDark ? Colors.grey[400]! : const Color(0xFF6B7280);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Notificações',
            style: GoogleFonts.publicSans(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: textColor,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Controle como você recebe alertas de novos pedidos e eventos importantes.',
            style: GoogleFonts.publicSans(fontSize: 13, color: subColor),
          ),
          const SizedBox(height: 24),

          // ── Card de preferências ───────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: cardBg,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? Colors.grey[800]!
                    : const Color(0xFFEBEBEB),
              ),
            ),
            child: Column(
              children: [
                _ToggleTile(
                  isDark: isDark,
                  icon: Icons.notifications_active_outlined,
                  iconColor: const Color(0xFFF97316),
                  title: 'Notificações de novos pedidos',
                  subtitle:
                      'Exibe um aviso visual no canto da tela quando um novo pedido chegar.',
                  value: state.notifAtiva,
                  onChanged: notifier.setNotifAtiva,
                ),
                Divider(
                  height: 1,
                  color:
                      isDark ? Colors.grey[800] : const Color(0xFFF3F4F6),
                ),
                _ToggleTile(
                  isDark: isDark,
                  icon: Icons.volume_up_outlined,
                  iconColor: const Color(0xFF3B82F6),
                  title: 'Alerta sonoro',
                  subtitle:
                      'Toca um som de notificação quando um novo pedido é recebido.',
                  value: state.somAtivo,
                  onChanged: notifier.setSomAtivo,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Aviso informativo
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: const Color(0xFFFED7AA)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline,
                    color: Color(0xFFF97316), size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'As notificações funcionam apenas no painel web. Para receber notificações fora do painel, mantenha esta aba aberta no navegador.',
                    style: GoogleFonts.publicSans(
                      fontSize: 12,
                      color: const Color(0xFF92400E),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _ToggleTile extends StatelessWidget {
  final bool isDark;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _ToggleTile({
    required this.isDark,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    final textColor = isDark ? Colors.white : const Color(0xFF111827);
    final subColor =
        isDark ? Colors.grey[400]! : const Color(0xFF6B7280);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: iconColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: iconColor, size: 20),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: GoogleFonts.publicSans(
                      fontSize: 12, color: subColor),
                ),
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: const Color(0xFFF97316),
          ),
        ],
      ),
    );
  }
}
