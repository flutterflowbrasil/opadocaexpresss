import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';
import '../../models/financeiro_adm_models.dart';
import 'financeiro_shared_widgets.dart';

class FinanceiroSplitsTab extends ConsumerWidget {
  const FinanceiroSplitsTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );
    final splits = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.splits),
    );

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
                'Splits são gerados automaticamente pela Edge Function processar-split '
                'ao confirmar pagamento via Asaas. INSERT/UPDATE bloqueados para o client.',
          ),
          if (isLoading)
            const _SplitsShimmer()
          else if (splits.isEmpty)
            FinanceiroEmptyState(
              icon: Icons.call_split_rounded,
              mensagem:
                  'Nenhum split processado ainda.\nAguardando a Edge Function processar-split.',
            )
          else ...[
            _SplitsTotais(splits: splits),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _SplitsTable(splits: splits),
            ),
          ],
        ],
      ),
    );
  }
}

class _SplitsTotais extends StatelessWidget {
  final List<SplitPagamento> splits;

  const _SplitsTotais({required this.splits});

  @override
  Widget build(BuildContext context) {
    final totalEstab = splits.fold(0.0, (a, s) => a + s.estabValor);
    final totalEntregador = splits.fold(0.0, (a, s) => a + s.entregadorValor);
    final totalPlataforma = splits.fold(0.0, (a, s) => a + s.plataformaValor);

    return Wrap(
      spacing: 10,
      runSpacing: 10,
      children: [
        _TotalChip(
          label: 'Estabelecimentos',
          valor: totalEstab,
          color: const Color(0xFFF97316),
          bg: const Color(0xFFFFF7ED),
        ),
        _TotalChip(
          label: 'Entregadores',
          valor: totalEntregador,
          color: const Color(0xFF10B981),
          bg: const Color(0xFFECFDF5),
        ),
        _TotalChip(
          label: 'Plataforma',
          valor: totalPlataforma,
          color: const Color(0xFF3B82F6),
          bg: const Color(0xFFEFF6FF),
        ),
      ],
    );
  }
}

class _TotalChip extends StatelessWidget {
  final String label;
  final double valor;
  final Color color, bg;

  const _TotalChip({
    required this.label,
    required this.valor,
    required this.color,
    required this.bg,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.dmSans(
              fontSize: 11,
              color: const Color(0xFF6B7280),
            ),
          ),
          Text(
            _fmtBrl(valor),
            style: GoogleFonts.dmSans(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _SplitsTable extends StatelessWidget {
  final List<SplitPagamento> splits;

  const _SplitsTable({required this.splits});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(100),
        1: FixedColumnWidth(90),
        2: FixedColumnWidth(90),
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(90),
        5: FixedColumnWidth(100),
        6: FixedColumnWidth(100),
      },
      children: [
        _header(),
        ...splits.map(_row),
      ],
    );
  }

  TableRow _header() {
    const cols = [
      'Pedido',
      'Total',
      'Estabelec.',
      'Entregador',
      'Plataforma',
      'Status',
      'Data',
    ];
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

  TableRow _row(SplitPagamento s) {
    const statusCfg = {
      'processado': (l: 'Processado', c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'pendente': (l: 'Pendente', c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
      'falhou': (l: 'Falhou', c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
    };
    final cfg = statusCfg[s.status];

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      children: [
        _cell(s.pedidoId.substring(0, 8)),
        _cell(_fmtBrl(s.valorTotal), bold: true),
        _cell(_fmtBrl(s.estabValor)),
        _cell(_fmtBrl(s.entregadorValor)),
        _cell(_fmtBrl(s.plataformaValor)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: cfg == null
              ? Text(s.status,
                  style: GoogleFonts.dmSans(fontSize: 11))
              : StatusBadge(label: cfg.l, color: cfg.c, bg: cfg.bg),
        ),
        _cell(_fmtDate(s.createdAt)),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 0),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          fontWeight: bold ? FontWeight.w600 : FontWeight.w400,
          color: const Color(0xFF374151),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _SplitsShimmer extends StatelessWidget {
  const _SplitsShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: List.generate(
          4,
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

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
