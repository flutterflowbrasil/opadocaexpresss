import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabSistema extends ConsumerWidget {
  const ConfigTabSistema({super.key});

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
              'Alterações críticas: desativar a plataforma ou ativar modo manutenção afeta TODOS os usuários imediatamente.',
          bgColor: const Color(0xFFFEF2F2),
          borderColor: const Color(0xFFFCA5A5),
          iconColor: const Color(0xFFDC2626),
          textColor: const Color(0xFF991B1B),
        ),
        ConfigSection(
          titulo: 'Identidade da Plataforma',
          subtitulo: 'Informações gerais exibidas no app',
          rows: [
            ConfigRow(
              label: 'Nome da plataforma',
              descricao: 'Nome exibido no app e notificações',
              editavel: editable('plataforma_nome'),
              control: ConfigTextInput(
                value: val('plataforma_nome'),
                onChanged: editable('plataforma_nome')
                    ? (v) => set('plataforma_nome', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Fuso horário',
              descricao: 'Fuso usado para todos os horários da plataforma',
              editavel: editable('fuso_horario'),
              control: ConfigSel(
                value: val('fuso_horario'),
                options: const {
                  'America/Sao_Paulo': 'São Paulo (GMT-3)',
                  'America/Manaus': 'Manaus (GMT-4)',
                  'America/Fortaleza': 'Fortaleza (GMT-3)',
                  'America/Belem': 'Belém (GMT-3)',
                },
                onChanged: editable('fuso_horario')
                    ? (v) => set('fuso_horario', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Versão mínima do app',
              descricao: 'Versões abaixo desta forçam atualização',
              editavel: editable('versao_minima_app'),
              control: ConfigTextInput(
                value: val('versao_minima_app'),
                onChanged: editable('versao_minima_app')
                    ? (v) => set('versao_minima_app', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Suporte',
          subtitulo: 'Canais de atendimento exibidos no app',
          rows: [
            ConfigRow(
              label: 'E-mail de suporte',
              editavel: editable('suporte_email'),
              control: ConfigTextInput(
                value: val('suporte_email'),
                onChanged: editable('suporte_email')
                    ? (v) => set('suporte_email', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'WhatsApp de suporte',
              descricao: 'Número com código do país (ex: 5511999990000)',
              editavel: editable('suporte_whatsapp'),
              control: ConfigTextInput(
                value: val('suporte_whatsapp'),
                onChanged: editable('suporte_whatsapp')
                    ? (v) => set('suporte_whatsapp', v)
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Operação',
          subtitulo: 'Controles de funcionamento da plataforma',
          rows: [
            ConfigRow(
              label: 'Plataforma ativa',
              descricao: 'Desativar bloqueia novos pedidos em toda a plataforma',
              editavel: editable('plataforma_ativa'),
              control: ConfigToggle(
                value: val('plataforma_ativa') == 'true',
                onChanged: editable('plataforma_ativa')
                    ? (v) => set('plataforma_ativa', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Modo manutenção',
              descricao: 'Exibe aviso de manutenção para todos os usuários',
              editavel: editable('modo_manutencao'),
              control: ConfigToggle(
                value: val('modo_manutencao') == 'true',
                onChanged: editable('modo_manutencao')
                    ? (v) => set('modo_manutencao', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Permite cadastro de estabelecimentos',
              descricao: 'Novos estabelecimentos podem se cadastrar',
              editavel: editable('permite_cadastro_estab'),
              control: ConfigToggle(
                value: val('permite_cadastro_estab') == 'true',
                onChanged: editable('permite_cadastro_estab')
                    ? (v) => set('permite_cadastro_estab', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Permite cadastro de entregadores',
              descricao: 'Novos entregadores podem se cadastrar',
              editavel: editable('permite_cadastro_entregador'),
              control: ConfigToggle(
                value: val('permite_cadastro_entregador') == 'true',
                onChanged: editable('permite_cadastro_entregador')
                    ? (v) => set('permite_cadastro_entregador', v.toString())
                    : null,
              ),
            ),
          ],
        ),
        ConfigSection(
          titulo: 'Debug & Logs',
          subtitulo: 'Apenas para uso em desenvolvimento',
          rows: [
            ConfigRow(
              label: 'Logs avançados',
              descricao: 'Registra logs detalhados no Supabase (aumenta volume de dados)',
              editavel: editable('logs_avancados'),
              control: ConfigToggle(
                value: val('logs_avancados') == 'true',
                onChanged: editable('logs_avancados')
                    ? (v) => set('logs_avancados', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Modo debug',
              descricao: 'Exibe informações de debug no app (NUNCA em produção)',
              editavel: editable('modo_debug'),
              control: ConfigToggle(
                value: val('modo_debug') == 'true',
                onChanged: editable('modo_debug')
                    ? (v) => set('modo_debug', v.toString())
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}
