import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabSaques extends ConsumerWidget {
  const ConfigTabSaques({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(configAdmControllerProvider);
    final notifier = ref.read(configAdmControllerProvider.notifier);

    String val(String chave) => state.valorEfetivo(chave);
    bool editable(String chave) {
      final cfg = state.configs.where((c) => c.chave == chave).firstOrNull;
      return cfg?.editavel ?? false;
    }

    void set(String chave, String v) => notifier.setValor(chave, v);

    return Column(
      children: [
        ConfigSection(
          titulo: 'Saques PIX',
          subtitulo: 'Parâmetros para saques de entregadores e estabelecimentos',
          rows: [
            ConfigRow(
              label: 'Valor mínimo para saque',
              descricao: 'Saldo mínimo disponível para solicitar saque',
              editavel: editable('saque_valor_minimo'),
              control: ConfigNumInput(
                value: val('saque_valor_minimo'),
                prefix: 'R\$ ',
                onChanged: editable('saque_valor_minimo')
                    ? (v) => set('saque_valor_minimo', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Limite diário de saques',
              descricao: 'Valor máximo que pode ser sacado em um único dia',
              editavel: editable('saque_limite_diario'),
              control: ConfigNumInput(
                value: val('saque_limite_diario'),
                prefix: 'R\$ ',
                onChanged: editable('saque_limite_diario')
                    ? (v) => set('saque_limite_diario', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Tarifa fixa por saque',
              descricao: 'Valor cobrado pela plataforma em cada saque processado',
              editavel: editable('saque_tarifa_fixa'),
              control: ConfigNumInput(
                value: val('saque_tarifa_fixa'),
                prefix: 'R\$ ',
                onChanged: editable('saque_tarifa_fixa')
                    ? (v) => set('saque_tarifa_fixa', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'PIX instantâneo',
              descricao: 'Processa saques imediatamente (sem período de espera)',
              editavel: editable('saque_pix_instantaneo'),
              control: ConfigToggle(
                value: val('saque_pix_instantaneo') == 'true',
                onChanged: editable('saque_pix_instantaneo')
                    ? (v) => set('saque_pix_instantaneo', v.toString())
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
