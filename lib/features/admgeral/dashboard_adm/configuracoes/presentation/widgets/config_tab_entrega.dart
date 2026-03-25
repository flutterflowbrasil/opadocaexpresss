import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabEntrega extends ConsumerWidget {
  const ConfigTabEntrega({super.key});

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
          titulo: 'Taxas de Entrega',
          subtitulo: 'Valores cobrados ao cliente na entrega',
          rows: [
            ConfigRow(
              label: 'Taxa de entrega fixa padrão',
              descricao: 'Valor base cobrado por entrega',
              editavel: editable('taxa_entrega_fixa_padrao'),
              control: ConfigNumInput(
                value: val('taxa_entrega_fixa_padrao'),
                prefix: 'R\$ ',
                onChanged: editable('taxa_entrega_fixa_padrao')
                    ? (v) => set('taxa_entrega_fixa_padrao', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Taxa por quilômetro',
              descricao: 'Valor adicional por km rodado',
              editavel: editable('taxa_por_km'),
              control: ConfigNumInput(
                value: val('taxa_por_km'),
                prefix: 'R\$ ',
                suffix: '/km',
                onChanged: editable('taxa_por_km')
                    ? (v) => set('taxa_por_km', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Entrega grátis acima de',
              descricao: 'Pedidos acima deste valor têm frete grátis',
              editavel: editable('entrega_gratis_acima_de'),
              control: ConfigNumInput(
                value: val('entrega_gratis_acima_de'),
                prefix: 'R\$ ',
                onChanged: editable('entrega_gratis_acima_de')
                    ? (v) => set('entrega_gratis_acima_de', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Limites e Tempos',
          subtitulo: 'Parâmetros operacionais de entrega',
          rows: [
            ConfigRow(
              label: 'Pedido mínimo',
              descricao: 'Valor mínimo para realizar um pedido',
              editavel: editable('pedido_minimo'),
              control: ConfigNumInput(
                value: val('pedido_minimo'),
                prefix: 'R\$ ',
                onChanged: editable('pedido_minimo')
                    ? (v) => set('pedido_minimo', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Raio máximo de entrega',
              descricao: 'Distância máxima aceita para entrega',
              editavel: editable('raio_maximo_km'),
              control: ConfigNumInput(
                value: val('raio_maximo_km'),
                suffix: 'km',
                decimal: false,
                onChanged: editable('raio_maximo_km')
                    ? (v) => set('raio_maximo_km', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Tempo médio de preparo',
              descricao: 'Estimativa padrão de preparo pelo estabelecimento',
              editavel: editable('tempo_medio_preparo_min'),
              control: ConfigNumInput(
                value: val('tempo_medio_preparo_min'),
                suffix: 'min',
                decimal: false,
                onChanged: editable('tempo_medio_preparo_min')
                    ? (v) => set('tempo_medio_preparo_min', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Tempo médio de entrega',
              descricao: 'Estimativa padrão do tempo de entrega',
              editavel: editable('tempo_medio_entrega_min'),
              control: ConfigNumInput(
                value: val('tempo_medio_entrega_min'),
                suffix: 'min',
                decimal: false,
                onChanged: editable('tempo_medio_entrega_min')
                    ? (v) => set('tempo_medio_entrega_min', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Tempo máximo de entrega',
              descricao: 'Prazo máximo antes de marcar atraso',
              editavel: editable('tempo_maximo_entrega_min'),
              control: ConfigNumInput(
                value: val('tempo_maximo_entrega_min'),
                suffix: 'min',
                decimal: false,
                onChanged: editable('tempo_maximo_entrega_min')
                    ? (v) => set('tempo_maximo_entrega_min', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Entrega agendada',
              descricao: 'Permite que clientes agendem entregas',
              editavel: editable('entrega_agendada'),
              control: ConfigToggle(
                value: val('entrega_agendada') == 'true',
                onChanged: editable('entrega_agendada')
                    ? (v) => set('entrega_agendada', v.toString())
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
