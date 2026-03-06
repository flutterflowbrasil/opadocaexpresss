import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pedido_kanban_model.dart';

class ModalCancelarPedido extends StatelessWidget {
  final PedidoKanbanModel pedido;
  final VoidCallback onConfirmarCancelamento;

  const ModalCancelarPedido({
    super.key,
    required this.pedido,
    required this.onConfirmarCancelamento,
  });

  @override
  Widget build(BuildContext context) {
    // Definir se tem reembolso
    final temReembolso = pedido.pgto == 'pix' ||
        pedido.pgto == 'credito' ||
        pedido.pgto == 'debito';

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      child: Container(
        width: 440,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 64,
                offset: const Offset(0, 24)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 20),
              decoration: const BoxDecoration(
                color: Color(0xFFFEF2F2),
                border: Border(bottom: BorderSide(color: Color(0xFFFCA5A5))),
              ),
              child: Row(
                children: [
                  Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: const Color(0xFFDC2626).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Color(0xFFDC2626), size: 20),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Cancelar e Recusar Pedido',
                          style: GoogleFonts.publicSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: const Color(0xFFDC2626)),
                        ),
                        Text(
                          'Pedido #${pedido.numero} · ${pedido.cliente}',
                          style: GoogleFonts.publicSans(
                              fontSize: 11, color: const Color(0xFF991B1B)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Body
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 18),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Você está prestes a cancelar este pedido. Esta ação não pode ser desfeita.',
                    style: GoogleFonts.publicSans(
                        fontSize: 13,
                        color: const Color(0xFF4B5563),
                        height: 1.4),
                  ),
                  const SizedBox(height: 16),
                  if (temReembolso)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEF2F2),
                        border: Border.all(color: const Color(0xFFFCA5A5)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.currency_exchange,
                              color: Color(0xFFDC2626), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Estorno automático',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFDC2626)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Como o cliente pagou via online (Pix/Cartão), o valor de R\$ ${pedido.total.toStringAsFixed(2)} será estornado automaticamente pelo Gateway (Asaas).',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 11,
                                      color: const Color(0xFF991B1B),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFFFBEB),
                        border: Border.all(color: const Color(0xFFFDE68A)),
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.info_outline,
                              color: Color(0xFFD97706), size: 18),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Pagamento na entrega',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 13,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFFD97706)),
                                ),
                                const SizedBox(height: 3),
                                Text(
                                  'Cancele sem se preocupar com estornos, pois o cliente optou por pagar apenas na entrega.',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 11,
                                      color: const Color(0xFF92400E),
                                      height: 1.4),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    )
                ],
              ),
            ),

            // Footer
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text(
                      'Voltar',
                      style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF6B7280)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pop(); // Fechar Modal
                      onConfirmarCancelamento();
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFFDC2626),
                      elevation: 0,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(9)),
                    ),
                    child: Text(
                      'Confirmar Cancelamento',
                      style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white),
                    ),
                  ),
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
