import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:padoca_express/features/cliente/carrinho/controllers/carrinho_controller.dart';

class ResumoPedidoCard extends StatelessWidget {
  final CarrinhoState estadoCarrinho;
  final bool isDark;
  final double subtotal;
  final double taxaEntrega;
  final double total;

  static const _primaryColor = Color(0xFFFF7034);
  static const _secondaryColor = Color(0xFF7D2D35);

  const ResumoPedidoCard({
    super.key,
    required this.estadoCarrinho,
    required this.isDark,
    required this.subtotal,
    required this.taxaEntrega,
    required this.total,
  });

  @override
  Widget build(BuildContext context) {
    final bgReceipt = isDark
        ? _secondaryColor.withValues(alpha: 0.4)
        : const Color(0xFFFDFCF0);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            'RESUMO DO PEDIDO',
            style: GoogleFonts.outfit(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: isDark ? _primaryColor : _secondaryColor,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          padding: const EdgeInsets.fromLTRB(24, 32, 24, 40),
          decoration: BoxDecoration(
            color: bgReceipt,
            border: Border.symmetric(
              vertical: BorderSide(color: _primaryColor.withValues(alpha: 0.1)),
            ),
          ),
          child: Column(
            children: [
              ...estadoCarrinho.itens.map((item) {
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${item.quantidade}x ${item.produto.nome}',
                              style: GoogleFonts.outfit(
                                fontSize: 14,
                                fontWeight: FontWeight.w500,
                                color: isDark ? Colors.white : _secondaryColor,
                              ),
                            ),
                            if (item.observacao != null &&
                                item.observacao!.isNotEmpty)
                              Text(
                                item.observacao!,
                                style: GoogleFonts.outfit(
                                  fontSize: 12,
                                  fontStyle: FontStyle.italic,
                                  color: isDark
                                      ? Colors.grey[400]
                                      : _secondaryColor.withValues(alpha: 0.5),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Text(
                        'R\$ ${(item.produto.preco * item.quantidade).toStringAsFixed(2).replaceAll('.', ',')}',
                        style: GoogleFonts.outfit(
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                          color: isDark ? Colors.white : _secondaryColor,
                        ),
                      ),
                    ],
                  ),
                );
              }),
              Divider(
                  color: _secondaryColor.withValues(alpha: 0.2),
                  height: 32,
                  thickness: 1),
              _buildResumoRow('Subtotal', subtotal),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Taxa de Entrega',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.green[600],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  Text(
                    taxaEntrega == 0
                        ? 'Grátis'
                        : 'R\$ ${taxaEntrega.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.outfit(
                      fontSize: 14,
                      color: Colors.green[600],
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16, bottom: 8),
                child: Divider(
                    color: _secondaryColor.withValues(alpha: 0.1),
                    thickness: 1),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'TOTAL',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? _primaryColor : _secondaryColor,
                    ),
                  ),
                  Text(
                    'R\$ ${total.toStringAsFixed(2).replaceAll('.', ',')}',
                    style: GoogleFonts.outfit(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: isDark ? _primaryColor : _secondaryColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildResumoRow(String title, double valor) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark
                ? Colors.grey[400]
                : _secondaryColor.withValues(alpha: 0.7),
          ),
        ),
        Text(
          'R\$ ${valor.toStringAsFixed(2).replaceAll('.', ',')}',
          style: GoogleFonts.outfit(
            fontSize: 14,
            color: isDark
                ? Colors.grey[400]
                : _secondaryColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}
