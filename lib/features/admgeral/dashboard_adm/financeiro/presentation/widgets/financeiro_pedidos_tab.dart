import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';
import '../../models/financeiro_adm_models.dart';
import 'financeiro_shared_widgets.dart';

class FinanceiroPedidosTab extends ConsumerWidget {
  const FinanceiroPedidosTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );
    final filtroMetodo = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.filtroMetodo),
    );
    final filtroPgtoStatus = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.filtroPgtoStatus),
    );
    final filtroSplit = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.filtroSplit),
    );

    final pedidos = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.pedidosFiltrados),
    );

    final notifier = ref.read(financeiroAdmControllerProvider.notifier);

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
          // ── Filtros ────────────────────────────────────────────────────────
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              FinanceiroDropdown(
                label: 'Método',
                value: filtroMetodo,
                items: const {
                  'todos': 'Todos os métodos',
                  'pix': 'PIX',
                  'cartao_credito': 'Crédito',
                  'cartao_debito': 'Débito',
                  'dinheiro': 'Dinheiro',
                  'boleto': 'Boleto',
                },
                onChanged: notifier.setFiltroMetodo,
              ),
              FinanceiroDropdown(
                label: 'Status Pgto',
                value: filtroPgtoStatus,
                items: const {
                  'todos': 'Todos os status',
                  'pago': 'Pago',
                  'confirmed': 'Confirmado',
                  'pendente': 'Pendente',
                  'refunded': 'Reembolsado',
                  'overdue': 'Vencido',
                },
                onChanged: notifier.setFiltroPgtoStatus,
              ),
              FinanceiroDropdown(
                label: 'Split',
                value: filtroSplit,
                items: const {
                  'todos': 'Todos',
                  'processado': 'Split processado',
                  'nao_processado': 'Pendente split',
                },
                onChanged: notifier.setFiltroSplit,
              ),
            ],
          ),
          const SizedBox(height: 16),

          // ── Tabela ─────────────────────────────────────────────────────────
          if (isLoading)
            const _PedidosShimmer()
          else if (pedidos.isEmpty)
            FinanceiroEmptyState(
              icon: Icons.receipt_long_outlined,
              mensagem: 'Nenhum pedido encontrado com os filtros selecionados.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _PedidosTable(pedidos: pedidos),
            ),
        ],
      ),
    );
  }
}

class _PedidosTable extends StatelessWidget {
  final List<PedidoFinanceiro> pedidos;

  const _PedidosTable({required this.pedidos});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(60),   // #
        1: FixedColumnWidth(100),  // Data
        2: FixedColumnWidth(130),  // Cliente
        3: FixedColumnWidth(120),  // Loja
        4: FixedColumnWidth(90),   // Método
        5: FixedColumnWidth(90),   // Total
        6: FixedColumnWidth(110),  // Status Pgto
        7: FixedColumnWidth(100),  // Split
      },
      children: [
        _headerRow(),
        ...pedidos.map(_dataRow),
      ],
    );
  }

  TableRow _headerRow() {
    const cols = ['#', 'Data', 'Cliente', 'Loja', 'Método', 'Total', 'Status Pgto', 'Split'];
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      children: cols
          .map(
            (c) => Padding(
              padding: const EdgeInsets.only(bottom: 8, right: 8),
              child: Text(
                c,
                style: GoogleFonts.dmSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF9CA3AF),
                ),
              ),
            ),
          )
          .toList(),
    );
  }

  TableRow _dataRow(PedidoFinanceiro p) {
    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      children: [
        _cell('#${p.numeroPedido}'),
        _cell(_fmtDT(p.createdAt)),
        _cell(p.clienteNome ?? '—'),
        _cell(p.estabNome ?? '—'),
        _metodoCell(p.pagamentoMetodo),
        _cell(_fmtBrl(p.total), bold: true),
        _pgtoStatusCell(p.pagamentoStatus),
        _splitCell(p.splitProcessado),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 0),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 12,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF374151),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _metodoCell(String metodo) {
    const icons = {
      'pix': '⚡',
      'cartao_credito': '💳',
      'cartao_debito': '💳',
      'dinheiro': '💵',
      'boleto': '🧾',
    };
    const labels = {
      'pix': 'PIX',
      'cartao_credito': 'Crédito',
      'cartao_debito': 'Débito',
      'dinheiro': 'Dinheiro',
      'boleto': 'Boleto',
    };
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        '${icons[metodo] ?? ''} ${labels[metodo] ?? metodo}',
        style: GoogleFonts.dmSans(fontSize: 11, color: const Color(0xFF374151)),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _pgtoStatusCell(String status) {
    const cfg = {
      'confirmed': (label: 'Confirmado', c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'pago':      (label: 'Pago',       c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'pendente':  (label: 'Pendente',   c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
      'refunded':  (label: 'Reembolsado',c: Color(0xFF8B5CF6), bg: Color(0xFFF5F3FF)),
      'overdue':   (label: 'Vencido',    c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
    };
    final s = cfg[status];
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: s == null
          ? Text(status, style: GoogleFonts.dmSans(fontSize: 11))
          : Container(
              padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
              decoration: BoxDecoration(
                color: s.bg,
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text(
                s.label,
                style: GoogleFonts.dmSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: s.c,
                ),
              ),
            ),
    );
  }

  Widget _splitCell(bool processado) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
        decoration: BoxDecoration(
          color: processado ? const Color(0xFFECFDF5) : const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          processado ? 'Processado' : 'Pendente',
          style: GoogleFonts.dmSans(
            fontSize: 10,
            fontWeight: FontWeight.w600,
            color: processado ? const Color(0xFF10B981) : const Color(0xFFF59E0B),
          ),
        ),
      ),
    );
  }
}

class _PedidosShimmer extends StatelessWidget {
  const _PedidosShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: List.generate(
          5,
          (_) => Container(
            margin: const EdgeInsets.only(bottom: 8),
            height: 36,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
            ),
          ),
        ),
      ),
    );
  }
}

String _fmtBrl(double v) =>
    'R\$ ${v.toStringAsFixed(2).replaceAll('.', ',').replaceAllMapped(RegExp(r'(\d)(?=(\d{3})+,)'), (m) => '${m[1]}.')}';

String _fmtDT(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} '
    '${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}';
