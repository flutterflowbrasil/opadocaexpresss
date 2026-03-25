import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../controllers/config_adm_controller.dart';
import 'config_adm_shared.dart';

class ConfigTabNotificacoes extends ConsumerWidget {
  const ConfigTabNotificacoes({super.key});

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
        // ── Card de preview do som real ──────────────────────────────────────
        const _SoundPreviewCard(),

        // ── Canais ──────────────────────────────────────────────────────────
        ConfigSection(
          titulo: 'Canais de Notificação',
          subtitulo: 'Quais tipos de push notification estão ativos',
          rows: [
            ConfigRow(
              label: 'Notificações push ativas',
              descricao: 'Habilita ou desabilita todo o sistema de push',
              editavel: editable('notif_ativa'),
              control: ConfigToggle(
                value: val('notif_ativa') == 'true',
                onChanged: editable('notif_ativa')
                    ? (v) => set('notif_ativa', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Notificar sobre pedidos',
              descricao: 'Atualizações de status de pedido ao cliente',
              editavel: editable('notif_pedidos'),
              control: ConfigToggle(
                value: val('notif_pedidos') == 'true',
                onChanged: editable('notif_pedidos')
                    ? (v) => set('notif_pedidos', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Notificar sobre entregas',
              descricao: 'Alertas de localização e status da entrega',
              editavel: editable('notif_entregas'),
              control: ConfigToggle(
                value: val('notif_entregas') == 'true',
                onChanged: editable('notif_entregas')
                    ? (v) => set('notif_entregas', v.toString())
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Notificar promoções',
              descricao: 'Notificações de cupons e promoções ao cliente',
              editavel: editable('notif_promocoes'),
              control: ConfigToggle(
                value: val('notif_promocoes') == 'true',
                onChanged: editable('notif_promocoes')
                    ? (v) => set('notif_promocoes', v.toString())
                    : null,
              ),
            ),
          ],
        ),

        // ── Técnico ──────────────────────────────────────────────────────────
        ConfigSection(
          titulo: 'Configurações Técnicas',
          subtitulo: 'Parâmetros de envio e retry de notificações',
          rows: [
            ConfigRow(
              label: 'Canal Android padrão',
              descricao: 'Canal FCM para Android',
              editavel: editable('canal_android'),
              control: ConfigSel(
                value: val('canal_android'),
                options: const {
                  'pedidos': 'Pedidos',
                  'geral': 'Geral',
                  'promocoes': 'Promoções',
                },
                onChanged: editable('canal_android')
                    ? (v) => set('canal_android', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Countdown de notificação',
              descricao: 'Segundos de timeout antes de expirar a notificação',
              editavel: editable('notif_countdown_seg'),
              control: ConfigNumInput(
                value: val('notif_countdown_seg'),
                suffix: 's',
                decimal: false,
                onChanged: editable('notif_countdown_seg')
                    ? (v) => set('notif_countdown_seg', v)
                    : null,
              ),
            ),
            ConfigRow(
              label: 'Máximo de tentativas push',
              descricao: 'Retentativas antes de marcar como falhou',
              editavel: editable('max_tentativas_push'),
              control: ConfigNumInput(
                value: val('max_tentativas_push'),
                decimal: false,
                onChanged: editable('max_tentativas_push')
                    ? (v) => set('max_tentativas_push', v)
                    : null,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ── Card de preview do som do entregador ─────────────────────────────────────

class _SoundPreviewCard extends StatefulWidget {
  const _SoundPreviewCard();

  @override
  State<_SoundPreviewCard> createState() => _SoundPreviewCardState();
}

class _SoundPreviewCardState extends State<_SoundPreviewCard> {
  AudioPlayer? _player;
  bool _playing = false;

  static const _assetPath = 'sons/notificacoes_entregador.wav';

  @override
  void dispose() {
    _player?.dispose();
    super.dispose();
  }

  Future<void> _toggle() async {
    if (_playing) {
      await _player?.stop();
      if (mounted) setState(() => _playing = false);
      return;
    }
    setState(() => _playing = true);
    try {
      _player ??= AudioPlayer();
      await _player!.play(AssetSource(_assetPath));
      _player!.onPlayerComplete.listen((_) {
        if (mounted) setState(() => _playing = false);
      });
    } catch (e) {
      debugPrint('Erro ao reproduzir áudio: $e');
      if (mounted) setState(() => _playing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(18, 14, 18, 10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Som do App Entregador',
                  style: GoogleFonts.dmSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Toque disparado ao receber um novo pedido',
                  style: GoogleFonts.dmSans(
                    fontSize: 11,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: Color(0xFFEAE8E4)),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
            child: Row(
              children: [
                // Ícone de som
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF7ED),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: const Color(0xFFFED7AA)),
                  ),
                  child: const Icon(
                    Icons.music_note_rounded,
                    size: 20,
                    color: Color(0xFFF97316),
                  ),
                ),
                const SizedBox(width: 12),

                // Info do arquivo
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'notificacoes_entregador.wav',
                        style: GoogleFonts.dmSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF1A0910),
                        ),
                      ),
                      Text(
                        'assets/sons/ · WAVE Audio',
                        style: GoogleFonts.dmSans(
                          fontSize: 11,
                          color: const Color(0xFF9CA3AF),
                        ),
                      ),
                    ],
                  ),
                ),

                // Botão play/stop
                GestureDetector(
                  onTap: _toggle,
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 160),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: _playing
                          ? const Color(0xFFFEF2F2)
                          : const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: _playing
                            ? const Color(0xFFFCA5A5)
                            : const Color(0xFFFED7AA),
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          _playing
                              ? Icons.stop_rounded
                              : Icons.play_arrow_rounded,
                          size: 16,
                          color: _playing
                              ? const Color(0xFFDC2626)
                              : const Color(0xFFF97316),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          _playing ? 'Parar' : 'Ouvir',
                          style: GoogleFonts.dmSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _playing
                                ? const Color(0xFFDC2626)
                                : const Color(0xFFF97316),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
