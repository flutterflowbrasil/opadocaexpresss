import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/pedido_kanban_model.dart';
import 'kanban_ui_constants.dart';

class ModalPedidoDetalhes extends StatelessWidget {
  final PedidoKanbanModel pedido;
  final VoidCallback onAvancar;
  final VoidCallback onRejeitar;
  final VoidCallback onImprimir;

  const ModalPedidoDetalhes({
    super.key,
    required this.pedido,
    required this.onAvancar,
    required this.onRejeitar,
    required this.onImprimir,
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
      nextLabel = 'Iniciar preparo';
      nextColor = KanbanColors.preparandoColor;
    } else if (pedido.status == 'preparando') {
      nextLabel = 'Marcar pronto';
      nextColor = KanbanColors.prontoColor;
    }

    final temPagamentoGarantido =
        ['pix', 'credito', 'debito'].contains(pedido.pgto);
    final temRiscoPagamento =
        ['dinheiro', 'credito_maquina', 'debito_maquina'].contains(pedido.pgto);

    return Dialog(
      backgroundColor: Colors.transparent,
      elevation: 0,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: Container(
        width: 480,
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.9,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.18),
                blurRadius: 64,
                offset: const Offset(0, 24)),
          ],
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
              decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              'Pedido #${pedido.numero}',
                              style: GoogleFonts.publicSans(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF1A0910)),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 3),
                              decoration: BoxDecoration(
                                color: st.bg,
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(color: st.border),
                              ),
                              child: Text(
                                st.label,
                                style: GoogleFonts.publicSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: st.color),
                              ),
                            ),
                            if (atrasado) ...[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFFEF2F2),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.warning_amber_rounded,
                                        color: Color(0xFFDC2626), size: 12),
                                    const SizedBox(width: 3),
                                    Text('Atrasado',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFFDC2626))),
                                  ],
                                ),
                              )
                            ]
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${pedido.cliente} · ${pedido.tel}',
                          style: GoogleFonts.publicSans(
                              fontSize: 12, color: const Color(0xFF9CA3AF)),
                        ),
                      ],
                    ),
                  ),
                  InkWell(
                    onTap: () => Navigator.of(context).pop(),
                    borderRadius: BorderRadius.circular(8),
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        border: Border.all(
                            color: const Color(0xFFEAE8E4), width: 1.5),
                        borderRadius: BorderRadius.circular(8),
                        color: Colors.white,
                      ),
                      alignment: Alignment.center,
                      child: const Icon(Icons.close,
                          size: 16, color: Color(0xFF6B7280)),
                    ),
                  ),
                ],
              ),
            ),

            // Scrollable Body
            Expanded(
              child: SingleChildScrollView(
                padding:
                    const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Metrics Row
                    Row(
                      children: [
                        _buildMetricBox(
                            'Tempo',
                            _formatElapsed(pedido.at),
                            atrasado
                                ? const Color(0xFFDC2626)
                                : const Color(0xFF1A0910)),
                        const SizedBox(width: 8),
                        _buildMetricBox('Pagamento', pgto.label, pgto.color),
                        const SizedBox(width: 8),
                        _buildMetricBox(
                            'Total',
                            'R\$ ${pedido.total.toStringAsFixed(2)}',
                            const Color(0xFFF97316)),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // Payment Warning
                    if (pedido.status == 'pendente') ...[
                      if (temPagamentoGarantido)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFFECFDF5),
                              border: Border.all(
                                  color: const Color(0xFFA7F3D0), width: 1.5),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            children: [
                              const Icon(Icons.check_circle_outline,
                                  color: Color(0xFF10B981), size: 18),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Pagamento confirmado',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF065F46))),
                                    Text(
                                        'Pago · ${pgto.label} · verificado via Asaas',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 11,
                                            color: const Color(0xFF047857))),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFF10B981),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text('Seguro ✓',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        )
                      else if (temRiscoPagamento)
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 10),
                          decoration: BoxDecoration(
                              color: const Color(0xFFFFFBEB),
                              border: Border.all(
                                  color: const Color(0xFFFDE68A), width: 1.5),
                              borderRadius: BorderRadius.circular(10)),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Padding(
                                padding: EdgeInsets.only(top: 2),
                                child: Icon(Icons.info_outline,
                                    color: Color(0xFFD97706), size: 18),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                        'Pagamento na entrega — Pagar na entrega',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w700,
                                            color: const Color(0xFF92400E))),
                                    const SizedBox(height: 2),
                                    Text(
                                        pedido.pgto == 'dinheiro'
                                            ? 'Confirme se o cliente terá o troco exato.'
                                            : 'Pagamento na maquininha. Confirme disponibilidade.',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 11,
                                            color: const Color(0xFFB45309),
                                            height: 1.4)),
                                  ],
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 9, vertical: 3),
                                decoration: BoxDecoration(
                                    color: const Color(0xFFF59E0B),
                                    borderRadius: BorderRadius.circular(20)),
                                child: Text('Atenção',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white)),
                              ),
                            ],
                          ),
                        ),
                      const SizedBox(height: 12),
                    ],

                    // Address
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 10),
                      decoration: BoxDecoration(
                          color: const Color(0xFFF9F8F7),
                          border: Border.all(color: const Color(0xFFEAE8E4)),
                          borderRadius: BorderRadius.circular(10)),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Padding(
                            padding: EdgeInsets.only(top: 2),
                            child: Icon(Icons.location_on_outlined,
                                color: Color(0xFF9CA3AF), size: 16),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Endereço de entrega',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 10,
                                        color: const Color(0xFF9CA3AF))),
                                const SizedBox(height: 1),
                                Text(pedido.end,
                                    style: GoogleFonts.publicSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF1A0910))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),

                    // ITENS DO PEDIDO
                    Container(
                      decoration: BoxDecoration(
                          border: Border.all(color: const Color(0xFFEAE8E4)),
                          borderRadius: BorderRadius.circular(10)),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 8),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9F8F7),
                              border: Border(
                                  bottom: BorderSide(color: Color(0xFFEAE8E4))),
                              borderRadius: BorderRadius.vertical(
                                  top: Radius.circular(10)),
                            ),
                            child: Text('ITENS DO PEDIDO',
                                style: GoogleFonts.publicSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF6B7280))),
                          ),
                          ...pedido.itens.asMap().entries.map((entry) {
                            final idx = entry.key;
                            final it = entry.value;
                            return Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 10),
                              decoration: BoxDecoration(
                                border: Border(
                                    bottom: BorderSide(
                                        color: idx < pedido.itens.length - 1
                                            ? const Color(0xFFF3F1EE)
                                            : Colors.transparent)),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 24,
                                    height: 24,
                                    decoration: BoxDecoration(
                                        color: const Color(0xFFFFF7ED),
                                        borderRadius: BorderRadius.circular(6)),
                                    alignment: Alignment.center,
                                    child: Text('${it.q}×',
                                        style: GoogleFonts.publicSans(
                                            fontSize: 10,
                                            fontWeight: FontWeight.w800,
                                            color: const Color(0xFFF97316))),
                                  ),
                                  const SizedBox(width: 10),
                                  Expanded(
                                    child: Text(it.n,
                                        style: GoogleFonts.publicSans(
                                            fontSize: 13,
                                            color: const Color(0xFF1A0910))),
                                  ),
                                  Text(
                                      'R\$ ${(it.q * it.p).toStringAsFixed(2)}',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF6B7280))),
                                ],
                              ),
                            );
                          }),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              color: Color(0xFFF9F8F7),
                              border: Border(
                                  top: BorderSide(color: Color(0xFFEAE8E4))),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Taxa de entrega',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 12,
                                        color: const Color(0xFF9CA3AF))),
                                Text('R\$ ${pedido.tx.toStringAsFixed(2)}',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF6B7280))),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 14, vertical: 10),
                            decoration: const BoxDecoration(
                              borderRadius: BorderRadius.vertical(
                                  bottom: Radius.circular(10)),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Total',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: const Color(0xFF1A0910))),
                                Text('R\$ ${(pedido.total).toStringAsFixed(2)}',
                                    style: GoogleFonts.publicSans(
                                        fontSize: 15,
                                        fontWeight: FontWeight.w800,
                                        color: const Color(0xFFF97316))),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Driver info
                    if (pedido.entregador != null) ...[
                      const SizedBox(height: 12),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFFF7ED),
                            border: Border.all(color: const Color(0xFFFED7AA)),
                            borderRadius: BorderRadius.circular(10)),
                        child: Row(
                          children: [
                            Container(
                              width: 38,
                              height: 38,
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                    colors: [
                                      Color(0xFFF97316),
                                      Color(0xFFEA580C)
                                    ],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              alignment: Alignment.center,
                              child: Text(pedido.entregador!.foto ?? 'E',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w800,
                                      color: Colors.white)),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(pedido.entregador!.nome,
                                      style: GoogleFonts.publicSans(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A0910))),
                                  Text(pedido.entregador!.veiculo ?? '',
                                      style: GoogleFonts.publicSans(
                                          fontSize: 11,
                                          color: const Color(0xFF92400E))),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 9, vertical: 3),
                              decoration: BoxDecoration(
                                  color: const Color(0xFFFEF3C7),
                                  borderRadius: BorderRadius.circular(20)),
                              child: Text('Em rota',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF92400E))),
                            ),
                          ],
                        ),
                      )
                    ]
                  ],
                ),
              ),
            ),

            // Footer / Actions
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F1EE))),
              ),
              child: Row(
                children: [
                  if (pedido.status == 'pendente')
                    InkWell(
                      onTap: onImprimir,
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                            border: Border.all(
                                color: const Color(0xFFEAE8E4), width: 1.5),
                            borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.print,
                                size: 14, color: Color(0xFF6B7280)),
                            const SizedBox(width: 6),
                            Text('Comanda',
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF6B7280))),
                          ],
                        ),
                      ),
                    ),
                  const Spacer(),
                  if (pedido.status == 'pendente') ...[
                    InkWell(
                      onTap: () {
                        Navigator.of(context).pop();
                        onRejeitar();
                      },
                      borderRadius: BorderRadius.circular(9),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 9),
                        decoration: BoxDecoration(
                            color: const Color(0xFFFEF2F2),
                            border: Border.all(
                                color: const Color(0xFFFCA5A5), width: 1.5),
                            borderRadius: BorderRadius.circular(9)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.close,
                                size: 14, color: Color(0xFFDC2626)),
                            const SizedBox(width: 6),
                            Text('Recusar',
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFFDC2626))),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                  ],
                  if (nextLabel != null)
                    Expanded(
                      flex: pedido.status == 'pendente' ? 0 : 1,
                      child: InkWell(
                        onTap: () {
                          Navigator.of(context).pop();
                          onAvancar();
                        },
                        borderRadius: BorderRadius.circular(9),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 10),
                          decoration: BoxDecoration(
                              color: nextColor,
                              borderRadius: BorderRadius.circular(9)),
                          alignment: pedido.status == 'pendente'
                              ? null
                              : Alignment.center,
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.check,
                                  size: 14, color: Colors.white),
                              const SizedBox(width: 6),
                              Text(nextLabel,
                                  style: GoogleFonts.publicSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white)),
                            ],
                          ),
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

  Widget _buildMetricBox(String label, String value, Color valueColor) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        decoration: BoxDecoration(
            color: const Color(0xFFF9F8F7),
            border: Border.all(color: const Color(0xFFEAE8E4)),
            borderRadius: BorderRadius.circular(10)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.publicSans(
                    fontSize: 10, color: const Color(0xFF9CA3AF))),
            const SizedBox(height: 2),
            Text(value,
                style: GoogleFonts.publicSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: valueColor)),
          ],
        ),
      ),
    );
  }
}
