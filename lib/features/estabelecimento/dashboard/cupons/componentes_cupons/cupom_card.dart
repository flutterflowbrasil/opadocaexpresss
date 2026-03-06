import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import '../models/cupom_model.dart';

class CupomCard extends StatelessWidget {
  final CupomModel cupom;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final ValueChanged<bool> onToggleStatus;

  const CupomCard({
    super.key,
    required this.cupom,
    required this.onEdit,
    required this.onDelete,
    required this.onToggleStatus,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    // Lógica visual baseada no estado do cupom
    final now = DateTime.now();
    bool isExpirado = false;
    bool isEsgotado = false;

    if (cupom.dataFim != null && cupom.dataFim!.isBefore(now)) {
      isExpirado = true;
    }
    if (cupom.limiteUsos != null && cupom.usosAtuais >= cupom.limiteUsos!) {
      isEsgotado = true;
    }

    final bool isAtivo = cupom.ativo && !isExpirado && !isEsgotado;

    // Cores de Status
    Color statusColor = Colors.grey;
    String statusText = 'Inativo';

    if (isExpirado) {
      statusColor = Colors.red.shade400;
      statusText = 'Expirado';
    } else if (isEsgotado) {
      statusColor = Colors.orange.shade400;
      statusText = 'Esgotado';
    } else if (cupom.ativo) {
      statusColor = Colors.green.shade500;
      statusText = 'Ativo';
    }

    String valorFormatado = '';
    IconData iconTipo;

    switch (cupom.tipo) {
      case 'percentual':
        valorFormatado = '\${cupom.valor.toInt()}% OFF';
        iconTipo = Icons.percent_rounded;
        break;
      case 'valor_fixo':
        valorFormatado = NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
            .format(cupom.valor);
        iconTipo = Icons.attach_money_rounded;
        break;
      case 'entrega_gratis':
        valorFormatado = 'Frete Grátis';
        iconTipo = Icons.delivery_dining_rounded;
        break;
      default:
        valorFormatado = '\${cupom.valor}';
        iconTipo = Icons.local_offer_rounded;
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isAtivo
              ? theme.primaryColor.withValues(alpha: 0.3)
              : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Column(
          children: [
            // Top Section (Header)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isAtivo
                    ? theme.primaryColor.withValues(alpha: 0.05)
                    : Colors.grey.shade50,
                border: Border(
                  bottom: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: isAtivo
                          ? theme.primaryColor.withValues(alpha: 0.1)
                          : Colors.grey.shade200,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      iconTipo,
                      color:
                          isAtivo ? theme.primaryColor : Colors.grey.shade600,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text(
                              cupom.codigo,
                              style: GoogleFonts.publicSans(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                                letterSpacing: 0.5,
                              ),
                            ),
                            const SizedBox(width: 8),
                            InkWell(
                              onTap: () {
                                Clipboard.setData(
                                    ClipboardData(text: cupom.codigo));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Código copiado!'),
                                    duration: Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                              },
                              child: Icon(Icons.copy,
                                  size: 16, color: Colors.grey.shade500),
                            ),
                          ],
                        ),
                        if (cupom.descricao != null &&
                            cupom.descricao!.isNotEmpty) ...[
                          const SizedBox(height: 2),
                          Text(
                            cupom.descricao!,
                            style: GoogleFonts.publicSans(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ]
                      ],
                    ),
                  ),
                  // Badge Status
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                      border:
                          Border.all(color: statusColor.withValues(alpha: 0.3)),
                    ),
                    child: Text(
                      statusText,
                      style: GoogleFonts.publicSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Middle Section (Details)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDetailInfo('Desconto', valorFormatado,
                          isHighlighted: true),
                      _buildDetailInfo(
                        'Mínimo',
                        cupom.valorMinimoPedido > 0
                            ? NumberFormat.currency(
                                    locale: 'pt_BR', symbol: 'R\$')
                                .format(cupom.valorMinimoPedido)
                            : 'Livre',
                      ),
                      _buildDetailInfo(
                        'Usos',
                        '\${cupom.usosAtuais}/\${cupom.limiteUsos == null ? "Ilimitado" : cupom.limiteUsos}',
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildDateInfo(
                          'Validade',
                          cupom.dataFim != null
                              ? DateFormat('dd/MM/yyyy • HH:mm')
                                  .format(cupom.dataFim!)
                              : 'Sem limite'),
                      Text(
                        'Máx \${cupom.limiteUsosPorCliente} por cliente',
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      )
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(),

            // Bottom Action Bar
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                border: Border(
                  top: BorderSide(color: Colors.grey.shade100),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Switch(
                        value: cupom.ativo,
                        onChanged:
                            isExpirado || isEsgotado ? null : onToggleStatus,
                        activeThumbColor: theme.primaryColor,
                      ),
                      Text(
                        cupom.ativo ? 'Pausar' : 'Ativar',
                        style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: isExpirado || isEsgotado
                              ? Colors.grey
                              : (cupom.ativo
                                  ? Colors.grey.shade700
                                  : theme.primaryColor),
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      IconButton(
                        onPressed: onEdit,
                        icon: Icon(Icons.edit_outlined,
                            color: Colors.grey.shade700, size: 20),
                        tooltip: 'Editar Cupom',
                        splashRadius: 24,
                      ),
                      IconButton(
                        onPressed: onDelete,
                        icon: Icon(Icons.delete_outline,
                            color: Colors.red.shade400, size: 20),
                        tooltip: 'Excluir Cupom',
                        splashRadius: 24,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailInfo(String label, String value,
      {bool isHighlighted = false}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            color: Colors.grey.shade500,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.publicSans(
            fontSize: isHighlighted ? 18 : 14,
            fontWeight: isHighlighted ? FontWeight.bold : FontWeight.w600,
            color: isHighlighted ? Colors.black87 : Colors.grey.shade800,
          ),
        ),
      ],
    );
  }

  Widget _buildDateInfo(String label, String value) {
    return Row(
      children: [
        Icon(Icons.calendar_today_outlined,
            size: 14, color: Colors.grey.shade500),
        const SizedBox(width: 4),
        Text(
          '\$label: \$value',
          style: GoogleFonts.publicSans(
            fontSize: 12,
            color: Colors.grey.shade600,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
