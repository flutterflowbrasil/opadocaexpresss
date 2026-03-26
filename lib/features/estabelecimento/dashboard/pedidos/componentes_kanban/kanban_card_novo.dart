import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pedido_kanban_model.dart';
import 'kanban_ui_constants.dart';
import 'modal_pedido_detalhes.dart';
import 'modal_cancelar_pedido.dart';

class KanbanCardNovo extends StatelessWidget {
  final PedidoKanbanModel pedido;
  final VoidCallback onAvancar;
  final VoidCallback onRejeitar;
  final VoidCallback onImprimir;
  final VoidCallback onOpen;

  const KanbanCardNovo({
    super.key,
    required this.pedido,
    required this.onAvancar,
    required this.onRejeitar,
    required this.onImprimir,
    required this.onOpen,
  });

  String _formatElapsed(DateTime at) {
    final diff = DateTime.now().difference(at);
    if (diff.inMinutes < 60) return '${diff.inMinutes}min';
    return '${diff.inHours}h${(diff.inMinutes % 60)}min';
  }

  @override
  Widget build(BuildContext context) {
    final st = StatusMeta.fromStatus(pedido.status);
    final pgto = PgtoMeta.fromKey(pedido.pgto);

    final diffMins = DateTime.now().difference(pedido.at).inMinutes;
    final atrasado = (pedido.status == 'preparando' && diffMins > 20) ||
        (pedido.status == 'pendente' && diffMins > 5);

    String? nextLabel;
    Color? nextColor;
    if (pedido.status == 'pendente') {
      nextLabel = 'Confirmar';
      nextColor = KanbanColors.prontoColor;
    } else if (pedido.status == 'confirmado') {
      nextLabel = 'Preparar';
      nextColor = KanbanColors.preparandoColor;
    } else if (pedido.status == 'preparando') {
      nextLabel = 'Marcar Pronto';
      nextColor = KanbanColors.prontoColor;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
            color: atrasado ? const Color(0xFFFCA5A5) : const Color(0xFFEAE8E4),
            width: 1.5),
        boxShadow: atrasado
            ? [const BoxShadow(color: Color(0x14DC2626), spreadRadius: 2)]
            : null,
      ),
      clipBehavior: Clip.hardEdge,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            height: 3,
            color: atrasado ? const Color(0xFFEF4444) : st.color,
          ),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Top Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Text(
                              '#${pedido.numero}',
                              style: GoogleFonts.publicSans(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A0910)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (atrasado) ...[
                            const SizedBox(width: 6),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF2F2),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.warning_amber_rounded,
                                      color: Color(0xFFDC2626), size: 10),
                                  const SizedBox(width: 3),
                                  Text('Atrasado',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFFDC2626))),
                                ],
                              ),
                            )
                          ]
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.schedule,
                            size: 11,
                            color: atrasado
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF9CA3AF)),
                        const SizedBox(width: 3),
                        Text(
                          _formatElapsed(pedido.at),
                          style: GoogleFonts.publicSans(
                              fontSize: 11,
                              fontWeight:
                                  atrasado ? FontWeight.w700 : FontWeight.w500,
                              color: atrasado
                                  ? const Color(0xFFDC2626)
                                  : const Color(0xFF9CA3AF)),
                        ),
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 6),

                // Client Info
                Text(
                  pedido.cliente,
                  style: GoogleFonts.publicSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A0910)),
                ),
                const SizedBox(height: 2),
                Text(
                  pedido.itens.map((i) => '${i.q}x ${i.n}').join(' · '),
                  style: GoogleFonts.publicSans(
                      fontSize: 11,
                      color: const Color(0xFF9CA3AF),
                      height: 1.4),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),

                // Pay | Total
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Row(
                        children: [
                          Flexible(
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                  color: pgto.color.withAlpha(38),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(pgto.icon, size: 11, color: pgto.color),
                                  const SizedBox(width: 4),
                                  Flexible(
                                    child: Text(pgto.label,
                                        style: GoogleFonts.publicSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w600,
                                            color: pgto.color),
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 4),
                    Flexible(
                      child: Text(
                        'R\$ ${pedido.total.toStringAsFixed(2)}',
                        style: GoogleFonts.publicSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A0910)),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),

                if (pedido.entregador != null) ...[
                  const SizedBox(height: 8),
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                    decoration: BoxDecoration(
                        color: const Color(0xFFFFF7ED),
                        border: Border.all(color: const Color(0xFFFED7AA)),
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        Container(
                          width: 22,
                          height: 22,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                                colors: [Color(0xFFF97316), Color(0xFFEA580C)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          alignment: Alignment.center,
                          child: Text(pedido.entregador!.foto ?? 'E',
                              style: GoogleFonts.publicSans(
                                  fontSize: 8,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.white)),
                        ),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(pedido.entregador!.nome,
                              style: GoogleFonts.publicSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFFC2410C)),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis),
                        ),
                        const Icon(Icons.motorcycle,
                            size: 12, color: Color(0xFFF97316)),
                      ],
                    ),
                  )
                ],

                const SizedBox(height: 8),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ModalPedidoDetalhes(
                              pedido: pedido,
                              onAvancar: onAvancar,
                              onRejeitar: () {
                                showDialog(
                                  context: context,
                                  builder: (ctxCancel) => ModalCancelarPedido(
                                    pedido: pedido,
                                    onConfirmarCancelamento: onRejeitar,
                                  ),
                                );
                              },
                              onImprimir: onImprimir,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFEAE8E4), width: 1.5),
                              borderRadius: BorderRadius.circular(8)),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.remove_red_eye_outlined,
                                  size: 13, color: Color(0xFF6B7280)),
                              const SizedBox(width: 4),
                              Flexible(
                                child: Text('Detalhes',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    if (pedido.status == 'pendente') ...[
                      const SizedBox(width: 6),
                      InkWell(
                        onTap: () {
                          showDialog(
                            context: context,
                            builder: (ctx) => ModalCancelarPedido(
                              pedido: pedido,
                              onConfirmarCancelamento: onRejeitar,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(8),
                        child: Container(
                          width: 34,
                          height: 34,
                          decoration: BoxDecoration(
                              border: Border.all(
                                  color: const Color(0xFFFCA5A5), width: 1.5),
                              borderRadius: BorderRadius.circular(8),
                              color: const Color(0xFFFEF2F2)),
                          alignment: Alignment.center,
                          child: const Icon(Icons.close,
                              size: 16, color: Color(0xFFDC2626)),
                        ),
                      ),
                    ],
                    if (nextLabel != null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: InkWell(
                          onTap: onAvancar,
                          borderRadius: BorderRadius.circular(8),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 7),
                            decoration: BoxDecoration(
                                color: nextColor,
                                borderRadius: BorderRadius.circular(8)),
                            alignment: Alignment.center,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(Icons.check,
                                    size: 13, color: Colors.white),
                                const SizedBox(width: 4),
                                Flexible(
                                  child: Text(nextLabel,
                                      style: GoogleFonts.publicSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: Colors.white),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ] else if (pedido.status == 'pronto' && pedido.entregador == null) ...[
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(vertical: 7),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFF7ED),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: const Color(0xFFFED7AA))),
                          alignment: Alignment.center,
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const SizedBox(
                                width: 12,
                                height: 12,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  valueColor: AlwaysStoppedAnimation<Color>(Color(0xFFF97316)),
                                ),
                              ),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text('Aguardando Entregador',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFFEA580C)),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ]
                  ],
                )
              ],
            ),
          )
        ],
      ),
    );
  }
}
