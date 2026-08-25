import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
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
        const ConfigInfoBanner(
          mensagem:
              'Alterações nesta aba afetam checkout Asaas, comissão e repasse. Confirme antes de salvar.',
        ),
        ConfigSection(
          titulo: 'Pagamentos online',
          subtitulo: 'Bloqueio no servidor. A chave Asaas nunca fica no app.',
          rows: [
            ConfigRow(
              label: 'Pix e cartão ativos',
              descricao:
                  'Desligue se a conta Asaas estiver em manutenção. Pedido em dinheiro continua.',
              editavel: editable('pagamentos_online_ativos'),
              control: ConfigToggle(
                value: val('pagamentos_online_ativos') != 'false',
                onChanged: editable('pagamentos_online_ativos')
                    ? (v) => set('pagamentos_online_ativos', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Conexão Asaas',
              descricao: 'Testa a chave do secret (admin). Não expõe a chave.',
              editavel: true,
              control: const _AsaasHealthButton(),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Modelo de repasse Asaas',
          subtitulo: 'Quando o dinheiro sai da conta master para estab/entregador',
          rows: [
            ConfigRow(
              label: 'Modo de liberação',
              descricao: 'Pós-entrega = escrow até o código do cliente',
              editavel: editable('modo_repasse'),
              control: ConfigSel(
                value: val('modo_repasse').isEmpty
                    ? 'pos_entrega'
                    : val('modo_repasse'),
                options: const {
                  'pos_entrega': 'Após entrega',
                  'pos_coleta': 'Após coleta',
                  'checkout_imediato': 'No checkout',
                },
                onChanged: editable('modo_repasse')
                    ? (v) => set('modo_repasse', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Split automático no checkout',
              descricao: 'Só use com modo "No checkout". Desligado = valor na master',
              editavel: editable('split_automatico_ativo'),
              control: ConfigToggle(
                value: val('split_automatico_ativo') == 'true',
                onChanged: editable('split_automatico_ativo')
                    ? (v) => set('split_automatico_ativo', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Exigir subconta homologada',
              descricao:
                  'Bloqueia Pix/cartão se o estabelecimento ainda não passou no KYC Asaas.',
              editavel: editable('exigir_subconta_homologada'),
              control: ConfigToggle(
                value: val('exigir_subconta_homologada') != 'false',
                onChanged: editable('exigir_subconta_homologada')
                    ? (v) => set('exigir_subconta_homologada', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Estorno automático no cancelamento',
              descricao: 'Chama Asaas refund quando o pedido pago é cancelado',
              editavel: editable('estorno_automatico_ativo'),
              control: ConfigToggle(
                value: val('estorno_automatico_ativo') != 'false',
                onChanged: editable('estorno_automatico_ativo')
                    ? (v) => set('estorno_automatico_ativo', v.toString())
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Comissão da plataforma',
          subtitulo: 'Valores usados por calcular_financeiro_pedido',
          rows: [
            ConfigRow(
              label: 'Comissão sobre produtos',
              descricao: 'Percentual retido da plataforma (substitui split_plataforma_pct)',
              editavel: editable('percentual_comissao_estabelecimento'),
              control: ConfigNumInput(
                value: val('percentual_comissao_estabelecimento'),
                suffix: '%',
                onChanged: editable('percentual_comissao_estabelecimento')
                    ? (v) => set('percentual_comissao_estabelecimento', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Teto mensal por estabelecimento',
              descricao: 'Comissão deixa de crescer ao atingir este valor no mês',
              editavel: editable('teto_comissao_mensal'),
              control: ConfigNumInput(
                value: val('teto_comissao_mensal'),
                prefix: 'R\$ ',
                onChanged: editable('teto_comissao_mensal')
                    ? (v) => set('teto_comissao_mensal', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Taxa mínima por pedido',
              descricao: 'Piso de comissão mesmo em pedidos pequenos',
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
              label: 'Taxa de serviço do app',
              descricao: 'Percentual cobrado do cliente sobre o subtotal',
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
              descricao: 'Informativo da taxa Asaas (não altera o split)',
              editavel: editable('taxa_transacao_gateway'),
              control: ConfigNumInput(
                value: val('taxa_transacao_gateway'),
                suffix: '%',
                onChanged: editable('taxa_transacao_gateway')
                    ? (v) => set('taxa_transacao_gateway', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Repasse da corrida',
          subtitulo: 'Percentuais liberados no Transfer após a entrega',
          rows: [
            ConfigRow(
              label: 'Estabelecimento recebe no repasse',
              descricao: 'Percentual do valor do estabelecimento liberado no Transfer Asaas',
              editavel: editable('repasse_estabelecimento_pct'),
              control: ConfigNumInput(
                value: val('repasse_estabelecimento_pct'),
                suffix: '%',
                onChanged: editable('repasse_estabelecimento_pct')
                    ? (v) => set('repasse_estabelecimento_pct', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Entregador recebe',
              descricao: 'Percentual da taxa de entrega liberado no repasse',
              editavel: editable('repasse_entregador_pct'),
              control: ConfigNumInput(
                value: val('repasse_entregador_pct'),
                suffix: '%',
                onChanged: editable('repasse_entregador_pct')
                    ? (v) => set('repasse_entregador_pct', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Retenção',
          subtitulo:
              'Se ativo, o repasse espera N horas após a entrega e o job fn_processar_repasses_pendentes libera depois.',
          rows: [
            ConfigRow(
              label: 'Retenção temporária',
              descricao: 'Se ativo, o worker não transfere imediatamente',
              editavel: editable('retencao_temporaria_ativa'),
              control: ConfigToggle(
                value: val('retencao_temporaria_ativa') == 'true',
                onChanged: editable('retencao_temporaria_ativa')
                    ? (v) => set('retencao_temporaria_ativa', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Horas de retenção',
              descricao: 'Prazo após a entrega (job de liberação tardia em fase 2)',
              editavel: editable('retencao_temporaria_horas'),
              control: ConfigNumInput(
                value: val('retencao_temporaria_horas'),
                suffix: 'h',
                decimal: false,
                onChanged: editable('retencao_temporaria_horas')
                    ? (v) => set('retencao_temporaria_horas', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Chaves antigas (somente leitura)',
          subtitulo: 'Não alteram mais o checkout — use Comissão da plataforma',
          rows: [
            ConfigRow(
              label: 'Estabelecimento recebe (legado)',
              descricao: 'Deprecated',
              editavel: false,
              control: ConfigNumInput(
                value: val('split_estabelecimento_pct'),
                suffix: '%',
              ),
            ),
            ConfigRow(
              label: 'Plataforma retém (legado)',
              descricao: 'Deprecated',
              editavel: false,
              control: ConfigNumInput(
                value: val('split_plataforma_pct'),
                suffix: '%',
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _AsaasHealthButton extends ConsumerStatefulWidget {
  const _AsaasHealthButton();

  @override
  ConsumerState<_AsaasHealthButton> createState() => _AsaasHealthButtonState();
}

class _AsaasHealthButtonState extends ConsumerState<_AsaasHealthButton> {
  bool _loading = false;

  Future<void> _testar() async {
    if (_loading) return;
    setState(() => _loading = true);
    try {
      final resp = await Supabase.instance.client.functions.invoke('asaas-health');
      final data = (resp.data as Map?) ?? {};
      final ok = resp.status == 200 && data['ok'] == true;
      final ambiente = data['ambiente']?.toString() ?? '';
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            ok
                ? 'Asaas conectado ($ambiente).'
                : 'Pagamentos temporariamente indisponíveis.',
          ),
          backgroundColor: ok ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
        ),
      );
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamentos temporariamente indisponíveis.'),
          backgroundColor: Color(0xFFEF4444),
        ),
      );
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return TextButton(
      onPressed: _loading ? null : _testar,
      child: _loading
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Text('Testar conexão'),
    );
  }
}
