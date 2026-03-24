import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:shimmer/shimmer.dart';
import '../../controllers/financeiro_adm_controller.dart';
import '../../models/financeiro_adm_models.dart';
import 'financeiro_shared_widgets.dart';

class FinanceiroSubcontasTab extends ConsumerWidget {
  const FinanceiroSubcontasTab({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isLoading = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.isLoading),
    );
    final subcontas = ref.watch(
      financeiroAdmControllerProvider.select((s) => s.subcontas),
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
                'Subcontas são criadas via Edge Function criar-wallet-asaas quando o admin aprova '
                'o cadastro de um estabelecimento ou entregador. INSERT/UPDATE bloqueados para o client.',
          ),
          if (isLoading)
            const _SubcontasShimmer()
          else if (subcontas.isEmpty)
            FinanceiroEmptyState(
              icon: Icons.account_balance_wallet_outlined,
              mensagem:
                  'Nenhuma subconta Asaas criada ainda.\n'
                  'Aprove um estabelecimento ou entregador para gerar a subconta.',
            )
          else
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: _SubcontasTable(subcontas: subcontas),
            ),
        ],
      ),
    );
  }
}

class _SubcontasTable extends StatelessWidget {
  final List<AsaasSubconta> subcontas;

  const _SubcontasTable({required this.subcontas});

  @override
  Widget build(BuildContext context) {
    return Table(
      columnWidths: const {
        0: FixedColumnWidth(110),
        1: FixedColumnWidth(120),
        2: FixedColumnWidth(100),
        3: FixedColumnWidth(160),
        4: FixedColumnWidth(100),
        5: FixedColumnWidth(110),
      },
      children: [
        _header(),
        ...subcontas.map(_row),
      ],
    );
  }

  TableRow _header() {
    const cols = [
      'Tipo',
      'Entidade ID',
      'Status',
      'Asaas Account ID',
      'Criado em',
      '',
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

  TableRow _row(AsaasSubconta s) {
    const statusCfg = {
      'active':   (l: 'Ativa',     c: Color(0xFF10B981), bg: Color(0xFFECFDF5)),
      'pending':  (l: 'Pendente',  c: Color(0xFFF59E0B), bg: Color(0xFFFFFBEB)),
      'blocked':  (l: 'Bloqueada', c: Color(0xFFEF4444), bg: Color(0xFFFEF2F2)),
      'rejected': (l: 'Rejeitada', c: Color(0xFF6B7280), bg: Color(0xFFF9FAFB)),
    };
    final cfg = statusCfg[s.statusConta];

    return TableRow(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB))),
      ),
      children: [
        _tipoCell(s.entidadeTipo),
        _cell(s.entidadeId.substring(0, 8)),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 7),
          child: cfg == null
              ? Text(s.statusConta, style: GoogleFonts.dmSans(fontSize: 11))
              : StatusBadge(label: cfg.l, color: cfg.c, bg: cfg.bg),
        ),
        _cell(s.asaasAccountId ?? '—'),
        _cell(_fmtDate(s.createdAt)),
        // Coluna vazia para espaçamento
        const SizedBox.shrink(),
      ],
    );
  }

  Widget _cell(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 9),
      child: Text(
        text,
        style: GoogleFonts.dmSans(
          fontSize: 11,
          color: const Color(0xFF374151),
        ),
        overflow: TextOverflow.ellipsis,
      ),
    );
  }

  Widget _tipoCell(String tipo) {
    final isEstab = tipo == 'estabelecimento';
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isEstab ? Icons.store_outlined : Icons.directions_bike_outlined,
            size: 13,
            color: isEstab
                ? const Color(0xFFF97316)
                : const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 4),
          Text(
            isEstab ? 'Estab.' : 'Entregador',
            style: GoogleFonts.dmSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: isEstab
                  ? const Color(0xFFF97316)
                  : const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }
}

class _SubcontasShimmer extends StatelessWidget {
  const _SubcontasShimmer();

  @override
  Widget build(BuildContext context) {
    return Shimmer.fromColors(
      baseColor: const Color(0xFFF3F4F6),
      highlightColor: const Color(0xFFE5E7EB),
      child: Column(
        children: List.generate(
          3,
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

String _fmtDate(DateTime d) =>
    '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')}/${d.year}';
