import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'dashboard_colors.dart';

class RecentOrdersTable extends StatelessWidget {
  final List<Map<String, dynamic>> pedidos;

  const RecentOrdersTable({super.key, required this.pedidos});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? Colors.grey[800] : Colors.white;
    final borderColor = isDark ? Colors.grey[700]! : Colors.grey[200]!;
    final headerBgColor =
        isDark ? Colors.grey[900]!.withValues(alpha: 0.5) : Colors.grey[50]!;

    return Container(
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pedidos Recentes',
                  style: GoogleFonts.publicSans(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                TextButton(
                  onPressed: () {},
                  child: Text(
                    'Ver Todos',
                    style: GoogleFonts.publicSans(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: DashboardColors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(
              height: 1, color: isDark ? Colors.grey[700] : Colors.grey[100]),
          if (pedidos.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24),
              child: Text(
                'Sem pedidos recentes.',
                style: GoogleFonts.publicSans(
                  color: isDark ? Colors.grey[400] : Colors.grey[600],
                ),
              ),
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: ConstrainedBox(
                constraints: BoxConstraints(
                    minWidth: MediaQuery.of(context).size.width - 64),
                child: DataTable(
                  headingRowColor: WidgetStateProperty.all(headerBgColor),
                  headingTextStyle: GoogleFonts.publicSans(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                  ),
                  dataTextStyle: GoogleFonts.publicSans(
                    fontSize: 14,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                  dividerThickness: 1,
                  columns: const [
                    DataColumn(label: Text('ID PEDIDO')),
                    DataColumn(label: Text('CLIENTE')),
                    DataColumn(label: Text('ITENS')),
                    DataColumn(label: Text('TOTAL')),
                    DataColumn(label: Text('STATUS')),
                    DataColumn(label: Text('AÇÃO')),
                  ],
                  rows:
                      _buildMockedOrRealRows(), // Using real rows mixed with HTML mocked data logic
                ),
              ),
            )
        ],
      ),
    );
  }

  List<DataRow> _buildMockedOrRealRows() {
    if (pedidos.isNotEmpty) {
      return pedidos.map((p) {
        return DataRow(
          cells: [
            DataCell(Text(
                '#${p['numero_pedido'] ?? p['id'].toString().substring(0, 4)}',
                style: const TextStyle(fontWeight: FontWeight.w500))),
            DataCell(
                Text(p['clientes']?['nome_completo_fantasia'] ?? 'Cliente')),
            DataCell(Text('Vários Itens',
                style:
                    TextStyle(color: Colors.grey[500]))), // Mocking items text
            DataCell(Text(
                NumberFormat.currency(locale: 'pt_BR', symbol: 'R\$')
                    .format(p['total']),
                style: const TextStyle(fontWeight: FontWeight.bold))),
            DataCell(_buildStatusBadge(p['status'] as String? ?? 'pendente')),
            DataCell(
              IconButton(
                icon: const Icon(Icons.visibility,
                    color: DashboardColors.primary, size: 20),
                onPressed: () {},
              ),
            ),
          ],
        );
      }).toList();
    }
    return [];
  }

  Widget _buildStatusBadge(String status) {
    Color bgColor;
    Color textColor;
    String label;

    switch (status) {
      case 'pendente':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[600]!;
        label = 'Pendente';
        break;
      case 'preparando':
        bgColor = Colors.orange[100]!;
        textColor = Colors.orange[600]!;
        label = 'Preparando';
        break;
      case 'pronto':
      case 'em_entrega':
        bgColor = Colors.blue[100]!;
        textColor = Colors.blue[600]!;
        label = 'Pronto';
        break;
      case 'entregue':
        bgColor = Colors.green[100]!;
        textColor = Colors.green[600]!;
        label = 'Entregue';
        break;
      case 'cancelado_cliente':
      case 'cancelado_estab':
      case 'cancelado_sistema':
        bgColor = Colors.red[100]!;
        textColor = Colors.red[600]!;
        label = 'Cancelado';
        break;
      default:
        bgColor = Colors.grey[200]!;
        textColor = Colors.grey[800]!;
        label = status;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label.toUpperCase(),
        style: GoogleFonts.publicSans(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: textColor,
        ),
      ),
    );
  }
}
