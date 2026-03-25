import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabDespacho extends ConsumerWidget {
  const ConfigTabDespacho({super.key});

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
          titulo: 'Modo de Despacho',
          subtitulo: 'Como pedidos são atribuídos aos entregadores',
          rows: [
            ConfigRow(
              label: 'Modo de despacho padrão',
              descricao:
                  'automatico: sistema atribui | manual: admin atribui',
              editavel: editable('modo_despacho_padrao'),
              control: ConfigSel(
                value: val('modo_despacho_padrao'),
                options: const {
                  'automatico': 'Automático',
                  'manual': 'Manual',
                },
                onChanged: editable('modo_despacho_padrao')
                    ? (v) => set('modo_despacho_padrao', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Critério de prioridade',
              descricao: 'Como o sistema escolhe o entregador',
              editavel: editable('prioridade_criterio'),
              control: ConfigSel(
                value: val('prioridade_criterio'),
                options: const {
                  'distancia': 'Menor distância',
                  'score': 'Maior score',
                  'disponibilidade': 'Disponibilidade',
                },
                onChanged: editable('prioridade_criterio')
                    ? (v) => set('prioridade_criterio', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Parâmetros de Busca',
          subtitulo: 'Raios e tentativas de despacho automático',
          rows: [
            ConfigRow(
              label: 'Tempo de resposta do entregador',
              descricao: 'Segundos para aceitar antes de tentar próximo',
              editavel: editable('tempo_resposta_seg'),
              control: ConfigNumInput(
                value: val('tempo_resposta_seg'),
                suffix: 's',
                decimal: false,
                onChanged: editable('tempo_resposta_seg')
                    ? (v) => set('tempo_resposta_seg', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Máximo de tentativas',
              descricao: 'Tentativas antes de colocar pedido em espera',
              editavel: editable('max_tentativas'),
              control: ConfigNumInput(
                value: val('max_tentativas'),
                decimal: false,
                onChanged: editable('max_tentativas')
                    ? (v) => set('max_tentativas', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Raio de busca inicial',
              descricao: 'Distância inicial para procurar entregadores',
              editavel: editable('raio_busca_inicial_km'),
              control: ConfigNumInput(
                value: val('raio_busca_inicial_km'),
                suffix: 'km',
                onChanged: editable('raio_busca_inicial_km')
                    ? (v) => set('raio_busca_inicial_km', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Expansão do raio por tentativa',
              descricao: 'Km adicionados ao raio em cada nova tentativa',
              editavel: editable('raio_busca_expansao_km'),
              control: ConfigNumInput(
                value: val('raio_busca_expansao_km'),
                suffix: 'km',
                onChanged: editable('raio_busca_expansao_km')
                    ? (v) => set('raio_busca_expansao_km', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Raio máximo de busca',
              descricao: 'Limite máximo de expansão do raio',
              editavel: editable('raio_busca_maximo_km'),
              control: ConfigNumInput(
                value: val('raio_busca_maximo_km'),
                suffix: 'km',
                onChanged: editable('raio_busca_maximo_km')
                    ? (v) => set('raio_busca_maximo_km', v)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
