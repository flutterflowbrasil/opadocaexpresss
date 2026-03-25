import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/config_adm_controller.dart';
import '../../controllers/config_adm_state.dart';

const List<({String id, String label, IconData icon, bool sensivel})>
    kConfigAbas = [
  (id: 'financeiro', label: 'Financeiro', icon: Icons.attach_money, sensivel: true),
  (id: 'entrega', label: 'Entrega', icon: Icons.delivery_dining, sensivel: false),
  (id: 'despacho', label: 'Despacho', icon: Icons.sensors, sensivel: false),
  (id: 'notificacoes', label: 'Notificações', icon: Icons.notifications_none, sensivel: false),
  (id: 'cupons', label: 'Cupons', icon: Icons.card_giftcard, sensivel: false),
  (id: 'cancelamento', label: 'Cancelamento', icon: Icons.cancel_outlined, sensivel: true),
  (id: 'saques', label: 'Saques PIX', icon: Icons.bolt, sensivel: false),
  (id: 'sistema', label: 'Sistema', icon: Icons.settings, sensivel: true),
];

class ConfigAdmTabBar extends ConsumerWidget {
  const ConfigAdmTabBar({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(
      configAdmControllerProvider
          .select((s) => (aba: s.abaSelecionada, mods: s.modificacoes, configs: s.configs)),
    );

    // Cria um state temporário só para calcular modificacoesNaAba
    final tmpState = ConfigAdmState(
      configs: state.configs,
      modificacoes: state.mods,
    );

    return Container(
      color: Colors.white,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        child: Row(
          children: kConfigAbas.map((aba) {
            final isActive = state.aba == aba.id;
            final count = tmpState.modificacoesNaAba(aba.id);
            return _TabChip(
              aba: aba,
              isActive: isActive,
              modCount: count,
              onTap: () => ref
                  .read(configAdmControllerProvider.notifier)
                  .setAba(aba.id),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _TabChip extends StatelessWidget {
  final ({String id, String label, IconData icon, bool sensivel}) aba;
  final bool isActive;
  final int modCount;
  final VoidCallback onTap;

  const _TabChip({
    required this.aba,
    required this.isActive,
    required this.modCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFFF97316) : const Color(0xFFF9FAFB),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive
                ? const Color(0xFFF97316)
                : const Color(0xFFEAE8E4),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              aba.icon,
              size: 14,
              color: isActive ? Colors.white : const Color(0xFF6B7280),
            ),
            const SizedBox(width: 5),
            Text(
              aba.label,
              style: GoogleFonts.dmSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? Colors.white : const Color(0xFF6B7280),
              ),
            ),
            if (aba.sensivel) ...[
              const SizedBox(width: 4),
              Icon(
                Icons.warning_amber_rounded,
                size: 12,
                color: isActive
                    ? Colors.white.withValues(alpha: 0.8)
                    : const Color(0xFFF59E0B),
              ),
            ],
            if (modCount > 0) ...[
              const SizedBox(width: 5),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 1),
                decoration: BoxDecoration(
                  color: isActive
                      ? Colors.white.withValues(alpha: 0.25)
                      : const Color(0xFFF97316),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$modCount',
                  style: GoogleFonts.dmSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: isActive ? Colors.white : Colors.white,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
