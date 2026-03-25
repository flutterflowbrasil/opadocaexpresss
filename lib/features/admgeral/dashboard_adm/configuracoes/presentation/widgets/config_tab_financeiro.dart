import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabFinanceiro extends ConsumerWidget {
  const ConfigTabFinanceiro({super.key});

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
              'Alterações nesta aba afetam diretamente o modelo financeiro da plataforma. Confirme antes de salvar.',
        ),
        ConfigSection(
          titulo: 'Modelo de Split',
          subtitulo: 'Distribuição percentual do valor pago pelo cliente',
          rows: [
            ConfigRow(
              label: 'Estabelecimento recebe',
              descricao: 'Percentual do subtotal do pedido',
              editavel: editable('split_estabelecimento_pct'),
              control: ConfigNumInput(
                value: val('split_estabelecimento_pct'),
                suffix: '%',
                onChanged: editable('split_estabelecimento_pct')
                    ? (v) => set('split_estabelecimento_pct', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Plataforma retém',
              descricao: 'Percentual sobre o subtotal',
              editavel: editable('split_plataforma_pct'),
              control: ConfigNumInput(
                value: val('split_plataforma_pct'),
                suffix: '%',
                onChanged: editable('split_plataforma_pct')
                    ? (v) => set('split_plataforma_pct', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Entregador recebe taxa de entrega integral',
              descricao: '100% da taxa de entrega vai ao entregador',
              editavel: editable('split_entregador_taxa_full'),
              control: ConfigToggle(
                value: val('split_entregador_taxa_full') == 'true',
                onChanged: editable('split_entregador_taxa_full')
                    ? (v) => set('split_entregador_taxa_full', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Split automático ativo',
              descricao: 'Processa splits via Edge Function ao confirmar pagamento',
              editavel: editable('split_automatico_ativo'),
              control: ConfigToggle(
                value: val('split_automatico_ativo') == 'true',
                onChanged: editable('split_automatico_ativo')
                    ? (v) => set('split_automatico_ativo', v.toString())
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Taxas da Plataforma',
          subtitulo: 'Taxas cobradas em cada transação',
          rows: [
            ConfigRow(
              label: 'Taxa de serviço do app',
              descricao: 'Percentual cobrado sobre o subtotal dos produtos',
              editavel: editable('taxa_servico_app_pct'),
              control: ConfigNumInput(
                value: val('taxa_servico_app_pct'),
                suffix: '%',
                onChanged: editable('taxa_servico_app_pct')
                    ? (v) => set('taxa_servico_app_pct', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Taxa de transação gateway',
              descricao: 'Taxa do Asaas por transação (repassada internamente)',
              editavel: editable('taxa_transacao_gateway'),
              control: ConfigNumInput(
                value: val('taxa_transacao_gateway'),
                suffix: '%',
                onChanged: editable('taxa_transacao_gateway')
                    ? (v) => set('taxa_transacao_gateway', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Taxa mínima da plataforma',
              descricao: 'Valor mínimo cobrado mesmo em pedidos de baixo valor',
              editavel: editable('taxa_minima_plataforma'),
              control: ConfigNumInput(
                value: val('taxa_minima_plataforma'),
                prefix: 'R\$ ',
                onChanged: editable('taxa_minima_plataforma')
                    ? (v) => set('taxa_minima_plataforma', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Retenção temporária',
              descricao: 'Dias de bloqueio do saldo antes de liberar para saque',
              editavel: editable('retencao_temporaria'),
              control: ConfigNumInput(
                value: val('retencao_temporaria'),
                suffix: 'dias',
                decimal: false,
                onChanged: editable('retencao_temporaria')
                    ? (v) => set('retencao_temporaria', v)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
