// lib/features/estabelecimento/notificacoes/widgets/notif_toast_overlay.dart
//
// Toast flutuante que aparece no canto superior-direito quando chega uma nova
// notificação.  Fecha automaticamente após 10 s, toca o som WAV (web) e
// permite fechar manualmente.  Web-only.

import 'dart:async';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../notificacao_dash_controller.dart';
import '../notificacao_dash_model.dart';

class NotifToastOverlay extends ConsumerStatefulWidget {
  const NotifToastOverlay({super.key});

  @override
  ConsumerState<NotifToastOverlay> createState() => _NotifToastOverlayState();
}

class _NotifToastOverlayState extends ConsumerState<NotifToastOverlay> {
  // Notificações que estão atualmente visíveis como toast
  final List<_ToastEntry> _visibles = [];
  // Para evitar re-exibir a mesma notificação
  final Set<String> _shown = {};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {
    // Observa mudanças no provider
    ref.listen<NotificacaoDashState>(notificacaoDashProvider, (prev, next) {
      if (!next.notifAtiva) return;
      final novas = next.notificacoes.where((n) => !_shown.contains(n.id));
      for (final notif in novas) {
        _shown.add(notif.id);
        _showToast(notif, next.somAtivo);
      }
    });

    // Usamos Stack para sobrepor os toasts acima do conteúdo
    return Stack(
      children: [
        // Posiciona os toasts no canto superior direito
        Positioned(
          top: 72,
          right: 16,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: _visibles.map((e) => e.widget).toList(),
          ),
        ),
      ],
    );
  }

  void _showToast(NotificacaoDashModel notif, bool comSom) {
    if (comSom) _playSound();

    late _ToastEntry entry;
    final widget = _NotifToastCard(
      notif: notif,
      onClose: () => _removeToast(entry),
      onTap: () {
        _removeToast(entry);
        ref.read(notificacaoDashProvider.notifier).marcarComoLida(notif.id);
        context.go(notif.rotaDestino);
      },
    );

    entry = _ToastEntry(id: notif.id, widget: widget);

    setState(() => _visibles.insert(0, entry));

    // Auto-close após 10 segundos
    Timer(const Duration(seconds: 10), () {
      if (mounted) _removeToast(entry);
    });
  }

  void _removeToast(_ToastEntry entry) {
    if (!mounted) return;
    setState(() => _visibles.removeWhere((e) => e.id == entry.id));
  }

  void _playSound() {
    try {
      final player = AudioPlayer();
      player.play(AssetSource('sons/notificacoes_entregador.wav'));
    } catch (_) {}
  }
}

class _ToastEntry {
  final String id;
  final Widget widget;
  _ToastEntry({required this.id, required this.widget});
}

// ─── Card visual do toast ─────────────────────────────────────────────────────

class _NotifToastCard extends StatefulWidget {
  final NotificacaoDashModel notif;
  final VoidCallback onClose;
  final VoidCallback onTap;

  const _NotifToastCard({
    required this.notif,
    required this.onClose,
    required this.onTap,
  });

  @override
  State<_NotifToastCard> createState() => _NotifToastCardState();
}

class _NotifToastCardState extends State<_NotifToastCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _ac;
  late Animation<Offset> _slide;
  late Animation<double> _fade;
  // Progresso do timer (1 → 0)
  double _progress = 1.0;
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _ac = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 320));
    _slide = Tween<Offset>(begin: const Offset(1.2, 0), end: Offset.zero)
        .animate(CurvedAnimation(parent: _ac, curve: Curves.easeOutCubic));
    _fade =
        Tween<double>(begin: 0, end: 1).animate(CurvedAnimation(parent: _ac, curve: Curves.easeOut));
    _ac.forward();

    // Decrementa barra de progresso ao longo de 10s
    _progressTimer =
        Timer.periodic(const Duration(milliseconds: 100), (t) {
      if (!mounted) {
        t.cancel();
        return;
      }
      setState(() => _progress = (_progress - 0.01).clamp(0.0, 1.0));
      if (_progress <= 0) t.cancel();
    });
  }

  @override
  void dispose() {
    _ac.dispose();
    _progressTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isNovoPedido = widget.notif.tipo == NotifTipo.novoPedido;
    final accentColor = isNovoPedido
        ? const Color(0xFFF97316)
        : const Color(0xFF3B82F6);

    return SlideTransition(
      position: _slide,
      child: FadeTransition(
        opacity: _fade,
        child: Container(
          width: 320,
          margin: const EdgeInsets.only(bottom: 10),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(14),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.15),
                blurRadius: 20,
                offset: const Offset(0, 6),
              ),
            ],
            border: Border.all(color: const Color(0xFFEBEBEB)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Barra de progresso no topo
                LinearProgressIndicator(
                  value: _progress,
                  minHeight: 3,
                  backgroundColor: const Color(0xFFF3F4F6),
                  valueColor: AlwaysStoppedAnimation<Color>(accentColor),
                ),
                // Conteúdo principal
                InkWell(
                  onTap: widget.onTap,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Ícone
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: accentColor.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Icon(
                            isNovoPedido
                                ? Icons.shopping_bag_outlined
                                : Icons.notifications_outlined,
                            color: accentColor,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        // Texto
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                widget.notif.titulo,
                                style: GoogleFonts.publicSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF111827),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(height: 2),
                              Text(
                                widget.notif.mensagem,
                                style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  color: const Color(0xFF6B7280),
                                ),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        // Fechar
                        GestureDetector(
                          onTap: widget.onClose,
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF3F4F6),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: const Icon(Icons.close,
                                size: 14, color: Color(0xFF9CA3AF)),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
