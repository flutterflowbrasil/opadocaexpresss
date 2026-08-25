import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabCupons extends ConsumerWidget {
  const ConfigTabCupons({super.key});

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
          titulo: 'Sistema',
          subtitulo: 'Liga ou desliga cupons em toda a plataforma',
          rows: [
            ConfigRow(
              label: 'Sistema de cupons ativo',
              descricao:
                  'Desativa cupons no checkout do cliente, oculta o campo de cupom no carrinho e oculta a aba Cupons & Ofertas no painel do estabelecimento',
              editavel: editable('cupons_ativos'),
              control: ConfigToggle(
                value: val('cupons_ativos') == 'true',
                onChanged: editable('cupons_ativos')
                    ? (v) => set('cupons_ativos', v.toString())
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Onde isso aparece',
          subtitulo: 'Efeito imediato ao desligar o sistema de cupons',
          rows: [
            ConfigRow(
              label: 'Painel do estabelecimento',
              descricao: 'Aba Cupons & Ofertas some do menu lateral',
              editavel: false,
              control: const Icon(
                Icons.storefront_outlined,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ),
            ConfigRow(
              label: 'App do cliente',
              descricao: 'Campo de cupom some do carrinho e do checkout',
              editavel: false,
              control: const Icon(
                Icons.shopping_bag_outlined,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ),
            ConfigRow(
              label: 'Pedido',
              descricao: 'O servidor recusa cupom mesmo se enviado pela API',
              editavel: false,
              control: const Icon(
                Icons.verified_outlined,
                size: 18,
                color: Color(0xFF9CA3AF),
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Tipos Permitidos',
          subtitulo: 'Quais categorias de cupom podem ser criadas',
          rows: [
            ConfigRow(
              label: 'Permite entrega grátis',
              descricao: 'Cupons que zerem a taxa de entrega',
              editavel: editable('permite_entrega_gratis'),
              control: ConfigToggle(
                value: val('permite_entrega_gratis') == 'true',
                onChanged: editable('permite_entrega_gratis')
                    ? (v) => set('permite_entrega_gratis', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Permite desconto percentual',
              descricao: 'Cupons com percentual de desconto no subtotal',
              editavel: editable('permite_percentual'),
              control: ConfigToggle(
                value: val('permite_percentual') == 'true',
                onChanged: editable('permite_percentual')
                    ? (v) => set('permite_percentual', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Permite desconto em valor fixo',
              descricao: 'Cupons com valor fixo de desconto',
              editavel: editable('permite_valor_fixo'),
              control: ConfigToggle(
                value: val('permite_valor_fixo') == 'true',
                onChanged: editable('permite_valor_fixo')
                    ? (v) => set('permite_valor_fixo', v.toString())
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Limites',
          subtitulo: 'Restrições padrão aplicadas a todos os cupons',
          rows: [
            ConfigRow(
              label: 'Pedido mínimo padrão',
              descricao: 'Valor mínimo do pedido para aplicar o cupom',
              editavel: editable('valor_minimo_padrao'),
              control: ConfigNumInput(
                value: val('valor_minimo_padrao'),
                prefix: 'R\$ ',
                onChanged: editable('valor_minimo_padrao')
                    ? (v) => set('valor_minimo_padrao', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Limite por cliente',
              descricao: 'Quantas vezes um cliente pode usar o mesmo cupom',
              editavel: editable('limite_por_cliente'),
              control: ConfigNumInput(
                value: val('limite_por_cliente'),
                decimal: false,
                onChanged: editable('limite_por_cliente')
                    ? (v) => set('limite_por_cliente', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Limite total por campanha',
              descricao: 'Total de usos antes de desativar o cupom automaticamente',
              editavel: editable('limite_total_campanha'),
              control: ConfigNumInput(
                value: val('limite_total_campanha'),
                decimal: false,
                onChanged: editable('limite_total_campanha')
                    ? (v) => set('limite_total_campanha', v)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
