import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'financeiro_shared_widgets.dart';

class FinanceiroConciliacaoTab extends StatefulWidget {
  const FinanceiroConciliacaoTab({super.key});

  @override
  State<FinanceiroConciliacaoTab> createState() =>
      _FinanceiroConciliacaoTabState();
}

class _FinanceiroConciliacaoTabState extends State<FinanceiroConciliacaoTab> {
  bool _loading = true;
  String? _error;
  List<Map<String, dynamic>> _rows = const [];

  @override
  void initState() {
    super.initState();
    _carregar();
  }

  Future<void> _carregar() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final data = await Supabase.instance.client
          .from('v_conciliacao_asaas')
          .select()
          .order('created_at', ascending: false)
          .limit(80);
      if (!mounted) return;
      setState(() {
        _rows = List<Map<String, dynamic>>.from(data as List);
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível carregar a conciliação Asaas.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFEAE8E4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const FinanceiroEdgeFunctionBanner(
            mensagem:
                'Conciliação read-only da view v_conciliacao_asaas. Saques internos foram descontinuados — use o portal Asaas.',
          ),
          if (_loading)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(child: CircularProgressIndicator()),
            )
          else if (_error != null)
            FinanceiroEmptyState(icon: Icons.error_outline, mensagem: _error!)
          else if (_rows.isEmpty)
            const FinanceiroEmptyState(
              icon: Icons.sync_alt,
              mensagem: 'Nenhum pagamento Asaas para conciliar ainda.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: DataTable(
                headingTextStyle: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF6B7280),
                ),
                dataTextStyle: GoogleFonts.dmSans(fontSize: 12),
                columns: const [
                  DataColumn(label: Text('Pedido')),
                  DataColumn(label: Text('Status')),
                  DataColumn(label: Text('Total')),
                  DataColumn(label: Text('Líquido')),
                  DataColumn(label: Text('Taxa Asaas')),
                  DataColumn(label: Text('Webhook')),
                ],
                rows: [
                  for (final r in _rows)
                    DataRow(cells: [
                      DataCell(Text('${r['asaas_payment_id'] ?? '—'}')),
                      DataCell(Text('${r['pagamento_status'] ?? '—'}')),
                      DataCell(Text(_brl(r['pedido_total']))),
                      DataCell(Text(_brl(r['pedido_valor_liquido']))),
                      DataCell(Text(_brl(r['taxa_asaas_valor']))),
                      DataCell(Text(
                        r['webhook_confirmado'] == true ? 'sim' : 'não',
                      )),
                    ]),
                ],
              ),
            ),
        ],
      ),
    );
  }

  String _brl(dynamic v) {
    final n = (v as num?)?.toDouble() ?? 0;
    return 'R\$ ${n.toStringAsFixed(2).replaceAll('.', ',')}';
  }
}
