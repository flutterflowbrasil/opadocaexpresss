import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/pedidos/models/pedido_cliente_model.dart';
import 'package:intl/intl.dart';

class PedidoCard extends StatelessWidget {
  final PedidoClienteModel pedido;

  const PedidoCard({super.key, required this.pedido});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark
        ? const Color(0xFF0F172A)
        : Colors.white; // Tailwind slate-900 / white
    final borderColor = isDark
        ? const Color(0x1AEC5B13)
        : const Color(0x1AEC5B13); // primary/10
    final primaryColor = const Color(0xFFEC5B13);
    final burgundy = const Color(0xFF4A1010);

    // Tratamentos de cor de status
    Color statusBgColor;
    Color statusTextColor;

    if (pedido.statusDisplay == 'entregue') {
      statusBgColor = isDark
          ? Colors.green[900]!.withValues(alpha: 0.3)
          : Colors.green[100]!;
      statusTextColor = isDark ? Colors.green[400]! : Colors.green[700]!;
    } else if (pedido.statusDisplay == 'cancelado') {
      statusBgColor = isDark ? Colors.grey[800]! : Colors.grey[200]!;
      statusTextColor = isDark ? Colors.grey[400]! : Colors.grey[600]!;
    } else {
      statusBgColor = isDark
          ? Colors.orange[900]!.withValues(alpha: 0.3)
          : Colors.orange[100]!;
      statusTextColor = isDark ? Colors.orange[400]! : Colors.orange[700]!;
    }

    // Formatação Moeda BRL
    final currency =
        NumberFormat.simpleCurrency(locale: 'pt_BR').format(pedido.total);

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: bgColor.withValues(
            alpha: pedido.statusDisplay == 'cancelado' ? 0.6 : 1.0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header do Card
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Flexible(
                            child: Text(
                              (pedido.estabelecimentoNome ?? 'Restaurante')
                                  .toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 10,
                                fontWeight: FontWeight.bold,
                                color: isDark
                                    ? primaryColor.withValues(alpha: 0.8)
                                    : burgundy,
                                letterSpacing: 1.0,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: statusBgColor,
                              borderRadius: BorderRadius.circular(100),
                            ),
                            child: Text(
                              pedido.statusDisplay.toUpperCase(),
                              style: GoogleFonts.outfit(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: statusTextColor,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Pedido #\${pedido.numeroPedido ?? pedido.id.substring(0, 4)}',
                        style: GoogleFonts.outfit(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : burgundy,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "\${pedido.dataFormatada} • \${pedido.quantidadeTotalItens} \${pedido.quantidadeTotalItens == 1 ? 'item' : 'itens'}",
                        style: GoogleFonts.outfit(
                          fontSize: 12,
                          color: isDark ? Colors.grey[400] : Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      currency,
                      style: GoogleFonts.outfit(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: isDark ? primaryColor : burgundy,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        Icon(
                          Icons.credit_card, // Icone generico por hora
                          size: 14,
                          color: isDark ? Colors.grey[500] : Colors.grey[400],
                        ),
                        const SizedBox(width: 4),
                        Text(
                          pedido.pagamentoMetodo == 'pix' ? 'Pix' : 'Cartão',
                          style: GoogleFonts.outfit(
                            fontSize: 10,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),

          Container(height: 1, color: borderColor),

          // Corpo do Card (Foto e Resumo)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.grey[200],
                    borderRadius: BorderRadius.circular(8),
                    image: pedido.estabelecimentoLogoUrl != null
                        ? DecorationImage(
                            image: NetworkImage(pedido.estabelecimentoLogoUrl!),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: pedido.estabelecimentoLogoUrl == null
                      ? Icon(Icons.storefront, color: Colors.grey[400])
                      : null,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    pedido.resumoItensText,
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: isDark ? Colors.grey[300] : Colors.grey[700],
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          // Footers Actions
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () {
                      // TODO: Ver Detalhes
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: pedido.isAtivo
                          ? primaryColor
                          : (isDark ? Colors.grey[300] : Colors.grey[700]),
                      side: BorderSide(
                          color: pedido.isAtivo
                              ? primaryColor
                              : (isDark
                                  ? Colors.grey[700]!
                                  : Colors.grey[300]!)),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                    child: Text(
                      'Ver Detalhes',
                      style: GoogleFonts.outfit(
                          fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                if (!pedido.isAtivo && pedido.statusDisplay != 'cancelado') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // TODO: Pedir Novamente
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Pedir Novamente',
                        style: GoogleFonts.outfit(
                            fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ]
              ],
            ),
          ),
        ],
      ),
    );
  }
}
