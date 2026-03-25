import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabCancelamento extends ConsumerWidget {
  const ConfigTabCancelamento({super.key});

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
        ConfigInfoBanner(
          mensagem:
              'Compensações e penalidades afetam diretamente o saldo de entregadores e estabelecimentos.',
        ),
        ConfigSection(
          titulo: 'Compensações por Cancelamento',
          subtitulo:
              'Valores pagos ao entregador quando o pedido é cancelado após aceite',
          rows: [
            ConfigRow(
              label: 'Compensação antes da coleta',
              descricao: 'Valor fixo pago ao entregador se cancelado antes de retirar o pedido',
              editavel: editable('compensacao_antes_coleta'),
              control: ConfigNumInput(
                value: val('compensacao_antes_coleta'),
                prefix: 'R\$ ',
                onChanged: editable('compensacao_antes_coleta')
                    ? (v) => set('compensacao_antes_coleta', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Compensação após coleta',
              descricao: 'Percentual do valor de entrega pago ao entregador após coleta',
              editavel: editable('compensacao_apos_coleta_pct'),
              control: ConfigNumInput(
                value: val('compensacao_apos_coleta_pct'),
                suffix: '%',
                onChanged: editable('compensacao_apos_coleta_pct')
                    ? (v) => set('compensacao_apos_coleta_pct', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Limites de Cancelamento',
          subtitulo: 'Penalidades para usuários com alto índice de cancelamento',
          rows: [
            ConfigRow(
              label: 'Limite de cancelamentos em 24h',
              descricao: 'Cancelamentos permitidos por usuário em 24 horas',
              editavel: editable('limite_cancelamentos_24h'),
              control: ConfigNumInput(
                value: val('limite_cancelamentos_24h'),
                decimal: false,
                onChanged: editable('limite_cancelamentos_24h')
                    ? (v) => set('limite_cancelamentos_24h', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Cancelamentos por turno',
              descricao: 'Máximo de cancelamentos por entregador por turno',
              editavel: editable('cancelamentos_por_turno'),
              control: ConfigNumInput(
                value: val('cancelamentos_por_turno'),
                decimal: false,
                onChanged: editable('cancelamentos_por_turno')
                    ? (v) => set('cancelamentos_por_turno', v)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
