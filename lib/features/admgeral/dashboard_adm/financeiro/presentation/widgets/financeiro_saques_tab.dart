import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';
import '../../models/financeiro_adm_models.dart';
import 'financeiro_shared_widgets.dart';

class FinanceiroSaquesTab extends ConsumerWidget {
  const FinanceiroSaquesTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );
    final saques = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.saques),
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
                'Saques são solicitados pelo app do entregador via Edge Function solicitar-saque. '
                'Status atualizado automaticamente via webhook Asaas. Mín: R\$ 10,00 — Máx: 3 por dia.',
          ),
          if (isLoading)
            const _SaquesShimmer()
          else if (saques.isEmpty)
            FinanceiroEmptyState(
              icon: Icons.pix_outlined,
              mensagem:
                  'Nenhum saque PIX registrado ainda.\nAguardando entregadores com saldo disponível.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _SaquesTable(saques: saques),
            ),
        ],
      ),
    );
  }
}

class _SaquesTable extends StatelessWidget {
  final List<EntregadorSaque> saques;

  const _SaquesTable({required this.saques});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(110),
        1: FixedColumnWidth(90),
        2: FixedColumnWidth(160),
        3: FixedColumnWidth(90),
        4: FixedColumnWidth(100),
        5: FixedColumnWidth(110),
        6: FixedColumnWidth(110),
      },
      children: [
        _header(),
        ...saques.map(_row),
      ],
    );
  }

  TableRow _header() {
    const cols = [
      'Entregador',
      'Valor',
      'Chave PIX',
      'Tipo',
      'Status',
      'Solicitado',
      'Processado',
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

  TableRow _row(EntregadorSaque s) {
    const statusCfg = {
      'concluido':   (l: 'Concluído',   c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'processando': (l: 'Processando', c: Color(0xFF3B82F6), bg: Color(0xFFEFF6FF)),
      'pendente':    (l: 'Pendente',    c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
      'falhou':      (l: 'Falhou',      c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
    };
    final cfg = statusCfg[s.status];

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      children: [
        _cell(s.entregadorId.substring(0, 8)),
        _cell(_fmtBrl(s.valor), bold: true),
        _cell(s.pixChave),
        _cell(_tipoLabel(s.pixTipo)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: cfg == null
              ? Text(s.status, style: GoogleFonts.dmSans(fontSize: 11))
              : StatusBadge(label: cfg.l, color: cfg.c, bg: cfg.bg),
        ),
        _cell(_fmtDate(s.solicitadoEm)),
        _cell(s.processadoEm != null ? _fmtDate(s.processadoEm!) : '—'),
      ],
    );
  }

  Widget _cell(String text, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
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

  String _tipoLabel(String tipo) {
    const m = {
      'cpf': 'CPF',
      'cnpj': 'CNPJ',
      'email': 'E-mail',
      'telefone': 'Telefone',
      'aleatoria': 'Aleatória',
    };
    return m[tipo] ?? tipo;
  }
}

class _SaquesShimmer extends StatelessWidget {
  const _SaquesShimmer();

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
