// lib/features/estabelecimento/notificacoes/widgets/notif_modal.dart
//
// Modal/Dialog que exibe o histórico de notificações.  Abre ao clicar no sino.

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../notificacao_dash_controller.dart';
import '../notificacao_dash_model.dart';

void showNotifModal(BuildContext context) {
  showDialog(
    context: context,
    builder: (_) => const _NotifDialog(),
  );
}

class _NotifDialog extends ConsumerWidget {
  const _NotifDialog();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(notificacaoDashProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      insetPadding:
          const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 440, maxHeight: 600),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // ── Header ────────────────────────────────────────────────
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: const BoxDecoration(
                border: Border(
                    bottom: BorderSide(color: Color(0xFFF3F4F6))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.notifications_outlined,
                          color: Color(0xFFF97316), size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Notificações',
                        style: GoogleFonts.publicSans(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF111827),
                        ),
                      ),
                      if (state.naoLidas > 0) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF97316),
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            '${state.naoLidas}',
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  Row(
                    children: [
                      if (state.notificacoes.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            ref
                                .read(notificacaoDashProvider.notifier)
                                .marcarTodasLidas();
                          },
                          child: Text(
                            'Marcar todas como lidas',
                            style: GoogleFonts.publicSans(
                              fontSize: 11,
                              color: const Color(0xFF6B7280),
                            ),
                          ),
                        ),
                      IconButton(
                        icon: const Icon(Icons.close,
                            size: 18, color: Color(0xFF6B7280)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // ── Lista ─────────────────────────────────────────────────
            Flexible(
              child: state.notificacoes.isEmpty
                  ? _buildEmpty()
                  : ListView.separated(
                      shrinkWrap: true,
                      itemCount: state.notificacoes.length,
                      separatorBuilder: (_, __) => const Divider(
                          height: 1, color: Color(0xFFF3F4F6)),
                      itemBuilder: (ctx, i) {
                        final notif = state.notificacoes[i];
                        return _NotifTile(
                          notif: notif,
                          onTap: () {
                            ref
                                .read(notificacaoDashProvider.notifier)
                                .marcarComoLida(notif.id);
                            Navigator.of(ctx).pop();
                            context.go(notif.rotaDestino);
                          },
                          onDismiss: () => ref
                              .read(notificacaoDashProvider.notifier)
                              .remover(notif.id),
                        );
                      },
                    ),
            ),

            // ── Footer ────────────────────────────────────────────────
            if (state.notificacoes.isNotEmpty)
              Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 20, vertical: 12),
                decoration: const BoxDecoration(
                    border: Border(
                        top: BorderSide(color: Color(0xFFF3F4F6)))),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton.icon(
                      onPressed: () {
                        ref
                            .read(notificacaoDashProvider.notifier)
                            .limparTodas();
                        Navigator.of(context).pop();
                      },
                      icon: const Icon(Icons.delete_sweep_outlined,
                          size: 16, color: Colors.redAccent),
                      label: Text(
                        'Limpar todas',
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: Colors.redAccent,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Padding(
      padding: const EdgeInsets.all(48),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.notifications_off_outlined,
              size: 48, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            'Sem notificações',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: const Color(0xFF374151),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Você verá os alertas de novos pedidos aqui.',
            textAlign: TextAlign.center,
            style: GoogleFonts.publicSans(
              fontSize: 13,
              color: const Color(0xFF9CA3AF),
            ),
          ),
        ],
      ),
    );
  }
}

class _NotifTile extends StatelessWidget {
  final NotificacaoDashModel notif;
  final VoidCallback onTap;
  final VoidCallback onDismiss;

  const _NotifTile({
    required this.notif,
    required this.onTap,
    required this.onDismiss,
  });

  @override
  Widget build(BuildContext context) {
    final isNovoPedido = notif.tipo == NotifTipo.novoPedido;
    final accentColor =
        isNovoPedido ? const Color(0xFFF97316) : const Color(0xFF3B82F6);
    final hora = DateFormat('HH:mm').format(notif.criadoEm);

    return Dismissible(
      key: Key(notif.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: Colors.red.shade50,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.delete_outline,
            color: Colors.redAccent, size: 20),
      ),
      onDismissed: (_) => onDismiss(),
      child: InkWell(
        onTap: onTap,
        child: Container(
          color: notif.lida
              ? Colors.transparent
              : const Color(0xFFFFF7ED),
          padding:
              const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
          child: Row(
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
              const SizedBox(width: 14),
              // Texto
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment:
                          MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            notif.titulo,
                            style: GoogleFonts.publicSans(
                              fontSize: 13,
                              fontWeight: notif.lida
                                  ? FontWeight.w500
                                  : FontWeight.w700,
                              color: const Color(0xFF111827),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          hora,
                          style: GoogleFonts.publicSans(
                            fontSize: 11,
                            color: const Color(0xFF9CA3AF),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      notif.mensagem,
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
              // Indicador não-lida
              if (!notif.lida) ...[
                const SizedBox(width: 10),
                Container(
                  width: 8,
                  height: 8,
                  decoration: BoxDecoration(
                    color: accentColor,
                    shape: BoxShape.circle,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
