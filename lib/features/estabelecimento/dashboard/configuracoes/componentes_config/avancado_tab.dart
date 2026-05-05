import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/configuracoes_controller.dart';
import 'config_widgets.dart';

class AvancadoTab extends ConsumerWidget {
  final bool isDark;

  const AvancadoTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final notifier = ref.read(configuracoesControllerProvider.notifier);
    final estab = state.editedEstab;

    if (estab == null) return const SizedBox.shrink();

    final dangerColor = isDark ? Colors.red[400]! : Colors.red[700]!;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: ConfigSectionCard(
        title: 'Status da loja',
        icon: Icons.power_settings_new,
        subtitle: 'Controle a disponibilidade do estabelecimento para pedidos.',
        isDark: isDark,
        headerIconColor: dangerColor,
        borderColor:
            isDark ? Colors.red[900]!.withValues(alpha: 0.3) : Colors.red[100]!,
        backgroundColor:
            isDark ? Colors.red[900]?.withValues(alpha: 0.1) : Colors.red[50],
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      estab.statusAberto
                          ? 'Desativar loja temporariamente'
                          : 'Loja desativada',
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                        color: dangerColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      estab.statusAberto
                          ? 'Ao desativar, novos pedidos serão pausados até que a loja seja aberta novamente.'
                          : 'A loja está fechada para novos pedidos.',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? Colors.red[300]
                            : Colors.red[600]?.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 16),
              OutlinedButton(
                style: OutlinedButton.styleFrom(
                  foregroundColor: dangerColor,
                  side: BorderSide(color: dangerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                ),
                onPressed: () {
                  notifier.updateStatusAberto(!estab.statusAberto);
                },
                child: Text(
                  estab.statusAberto ? 'Desativar loja' : 'Ativar loja',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
