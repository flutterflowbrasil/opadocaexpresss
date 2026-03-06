import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../controllers/configuracoes_controller.dart';
import '../../componentes_dash/dashboard_colors.dart';
import 'config_widgets.dart';

class EntregaTab extends ConsumerWidget {
  final bool isDark;

  const EntregaTab({super.key, required this.isDark});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configuracoesControllerProvider);
    final editedEstab = state.editedEstab;

    if (editedEstab == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final config = editedEstab.configEntrega;
    final notifier = ref.read(configuracoesControllerProvider.notifier);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ConfigSectionCard(
            title: 'Configurações de Entrega',
            icon: Icons.local_shipping,
            isDark: isDark,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Taxa de Entrega Fixa (R\$)',
                      placeholder: '5.00',
                      isDark: isDark,
                      prefix: const Text('R\$ '),
                      controller: TextEditingController(
                          text: config.taxaEntregaFixa.toStringAsFixed(2))
                        ..selection = TextSelection.collapsed(
                            offset: config.taxaEntregaFixa
                                .toStringAsFixed(2)
                                .length),
                      onChanged: (val) => notifier.updateConfigEntrega((c) =>
                          c.copyWith(
                              taxaEntregaFixa: double.tryParse(val) ?? 0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'Taxa por KM (R\$)',
                      placeholder: '2.00',
                      isDark: isDark,
                      prefix: const Text('R\$ '),
                      controller: TextEditingController(
                          text: config.taxaPorKm.toStringAsFixed(2))
                        ..selection = TextSelection.collapsed(
                            offset: config.taxaPorKm.toStringAsFixed(2).length),
                      onChanged: (val) => notifier.updateConfigEntrega((c) =>
                          c.copyWith(taxaPorKm: double.tryParse(val) ?? 0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: ConfigTextField(
                      label: 'Pedido Mínimo (R\$)',
                      placeholder: '15.00',
                      isDark: isDark,
                      prefix: const Text('R\$ '),
                      controller: TextEditingController(
                          text: config.pedidoMinimo.toStringAsFixed(2))
                        ..selection = TextSelection.collapsed(
                            offset:
                                config.pedidoMinimo.toStringAsFixed(2).length),
                      onChanged: (val) => notifier.updateConfigEntrega((c) =>
                          c.copyWith(pedidoMinimo: double.tryParse(val) ?? 0)),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ConfigTextField(
                      label: 'Frete Grátis Acima de (R\$)',
                      placeholder: '50.00',
                      isDark: isDark,
                      prefix: const Text('R\$ '),
                      helperText: 'deixe 0 para desativar',
                      controller: TextEditingController(
                          text: config.gratisAcimaDe.toStringAsFixed(2))
                        ..selection = TextSelection.collapsed(
                            offset:
                                config.gratisAcimaDe.toStringAsFixed(2).length),
                      onChanged: (val) => notifier.updateConfigEntrega((c) =>
                          c.copyWith(gratisAcimaDe: double.tryParse(val) ?? 0)),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Raio Máximo de Entrega (km)',
                      style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: Slider(
                            value:
                                config.raioMaximoKm.toDouble().clamp(1.0, 30.0),
                            min: 1,
                            max: 30,
                            activeColor: DashboardColors.primary,
                            onChanged: (v) => notifier.updateConfigEntrega(
                                (c) => c.copyWith(raioMaximoKm: v.toInt()))),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        decoration: BoxDecoration(
                            color: DashboardColors.primary,
                            borderRadius: BorderRadius.circular(8)),
                        child: Text('${config.raioMaximoKm} km',
                            style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold)),
                      )
                    ],
                  )
                ],
              )
            ],
          ),
          ConfigSectionCard(
            title: 'Tempo de Preparo',
            icon: Icons.timer,
            isDark: isDark,
            children: [
              ConfigTextField(
                label: 'Tempo médio de preparo (min)',
                placeholder: '30',
                isDark: isDark,
                controller: TextEditingController(
                    text: config.tempoMedioPreparoMin.toString())
                  ..selection = TextSelection.collapsed(
                      offset: config.tempoMedioPreparoMin.toString().length),
                onChanged: (val) => notifier.updateConfigEntrega((c) =>
                    c.copyWith(tempoMedioPreparoMin: int.tryParse(val) ?? 0)),
              ),
            ],
          )
        ],
      ),
    );
  }
}
