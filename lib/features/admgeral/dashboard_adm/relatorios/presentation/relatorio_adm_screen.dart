import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../controllers/relatorio_adm_controller.dart';
import '../controllers/relatorio_adm_state.dart';
import '../models/relatorio_adm_model.dart';
import 'widgets/exportar_relatorio_modal.dart';
import 'widgets/relatorio_adm_widgets.dart';

// ─────────────────────────────────────────────────────────────────────────────
//  Tela principal
// ─────────────────────────────────────────────────────────────────────────────

class RelatorioAdmScreen extends ConsumerWidget {
  const RelatorioAdmScreen({super.key});

  static const _abas = [
    ('visao_geral', 'Visão Geral'),
    ('financeiro', 'Financeiro'),
    ('operacional', 'Operacional'),
    ('usuarios', 'Usuários'),
    ('qualidade', 'Qualidade'),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen(
      relatorioAdmControllerProvider.select((s) => s.errorMessage),
      (_, msg) {
        if (msg != null && context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(
            content: Text(msg, style: GoogleFonts.dmSans(fontSize: 13)),
            backgroundColor: const Color(0xFFEF4444),
            action: SnackBarAction(
              label: 'Tentar novamente',
              textColor: Colors.white,
              onPressed: () =>
                  ref.read(relatorioAdmControllerProvider.notifier).fetch(),
            ),
          ));
        }
      },
    );

    return Column(
      children: [
        const _RelatorioHeader(),
        _RelatorioTabBar(abas: _abas),
        Expanded(child: _RelatorioContent(abas: _abas)),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Header da Seção de Relatórios
// ─────────────────────────────────────────────────────────────────────────────

class _RelatorioHeader extends ConsumerWidget {
  const _RelatorioHeader();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lastSync =
        ref.watch(relatorioAdmControllerProvider.select((s) => s.lastSync));
    final isLoading =
        ref.watch(relatorioAdmControllerProvider.select((s) => s.isLoading));
    final periodo =
        ref.watch(relatorioAdmControllerProvider.select((s) => s.periodo));
    final snapshot =
        ref.watch(relatorioAdmControllerProvider.select((s) => s.snapshot));

    final syncLabel = isLoading
        ? 'Carregando...'
        : lastSync != null
            ? 'Atualizado às ${lastSync.hour.toString().padLeft(2, '0')}:${lastSync.minute.toString().padLeft(2, '0')}'
            : 'Dados em tempo real';

    return Container(
      padding: const EdgeInsets.fromLTRB(22, 14, 22, 14),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios',
                  style: GoogleFonts.publicSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A0910),
                  ),
                ),
                Text(
                  syncLabel,
                  style: GoogleFonts.publicSans(
                      fontSize: 11, color: const Color(0xFF9CA3AF)),
                ),
              ],
            ),
          ),
          RelatorioFilterBar(
            periodo: periodo,
            onChanged: (p) =>
                ref.read(relatorioAdmControllerProvider.notifier).setPeriodo(p),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Atualizar',
            child: InkWell(
              onTap: isLoading
                  ? null
                  : () =>
                      ref.read(relatorioAdmControllerProvider.notifier).fetch(),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(9),
                  border:
                      Border.all(color: const Color(0xFFEAE8E4), width: 1.5),
                ),
                child: isLoading
                    ? const SizedBox(
                        width: 14,
                        height: 14,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Color(0xFF9CA3AF)),
                      )
                    : const Icon(Icons.refresh_rounded,
                        size: 14, color: Color(0xFF6B7280)),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Tooltip(
            message: 'Exportar Relatório',
            child: InkWell(
              onTap: () => showDialog(
                context: context,
                builder: (_) => ExportarRelatorioModal(snapshot: snapshot),
              ),
              borderRadius: BorderRadius.circular(9),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                decoration: BoxDecoration(
                  color: const Color(0xFF8B5CF6),
                  borderRadius: BorderRadius.circular(9),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.download_rounded,
                        size: 14, color: Colors.white),
                    const SizedBox(width: 6),
                    Text(
                      'Exportar',
                      style: GoogleFonts.dmSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Tab bar
// ─────────────────────────────────────────────────────────────────────────────

class _RelatorioTabBar extends ConsumerWidget {
  final List<(String, String)> abas;
  const _RelatorioTabBar({required this.abas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final abaAtiva =
        ref.watch(relatorioAdmControllerProvider.select((s) => s.abaAtiva));

    return Container(
      width: double.infinity,
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFEAE8E4))),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 6),
        child: Row(
          children: abas.map((a) {
            final isActive = a.$1 == abaAtiva;
            return GestureDetector(
              onTap: () => ref
                  .read(relatorioAdmControllerProvider.notifier)
                  .setAba(a.$1),
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive
                          ? const Color(0xFF8B5CF6)
                          : Colors.transparent,
                      width: 2,
                    ),
                  ),
                ),
                child: Text(
                  a.$2,
                  style: GoogleFonts.dmSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isActive
                        ? const Color(0xFF8B5CF6)
                        : const Color(0xFF9CA3AF),
                  ),
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  Conteúdo da aba ativa
// ─────────────────────────────────────────────────────────────────────────────

class _RelatorioContent extends ConsumerWidget {
  final List<(String, String)> abas;
  const _RelatorioContent({required this.abas});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(relatorioAdmControllerProvider);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(18),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 220),
        child: _buildAba(state),
      ),
    );
  }

  Widget _buildAba(RelatorioAdmState state) => switch (state.abaAtiva) {
        'financeiro' => _TabFinanceiro(state: state),
        'operacional' => _TabOperacional(state: state),
        'usuarios' => _TabUsuarios(state: state),
        'qualidade' => _TabQualidade(state: state),
        _ => _TabVisaoGeral(state: state),
      };
}

// ─────────────────────────────────────────────────────────────────────────────
//  ABA: Visão Geral
// ─────────────────────────────────────────────────────────────────────────────

class _TabVisaoGeral extends StatelessWidget {
  final RelatorioAdmState state;
  const _TabVisaoGeral({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.snapshot;
    final loading = state.isLoading;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            KpiCardRelatorio(
              label: 'Receita Total',
              value: fmtBrl(s?.receitaTotal ?? 0),
              sub: 'pedidos concluídos',
              color: const Color(0xFF10B981),
              bg: const Color(0xFFECFDF5),
              icon: '💰',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Receita Plataforma',
              value: fmtBrl(s?.plataformaTotal ?? 0),
              sub: '5% sobre produtos',
              color: const Color(0xFFF97316),
              bg: const Color(0xFFFFF7ED),
              icon: '🏦',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Total de Pedidos',
              value: fmtN(s?.pedidos.length ?? 0),
              sub: 'no período',
              color: const Color(0xFF3B82F6),
              bg: const Color(0xFFEFF6FF),
              icon: '📦',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Ticket Médio',
              value: fmtBrl(s?.ticketMedio ?? 0),
              sub: 'por pedido entregue',
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFF5F3FF),
              icon: '🧾',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Usuários',
              value: fmtN(s?.totalUsuarios ?? 0),
              sub: '${s?.totalClientes ?? 0} clientes',
              color: const Color(0xFF1A0910),
              bg: Colors.white,
              icon: '👥',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Estabelecimentos',
              value: fmtN(s?.totalEstabs ?? 0),
              sub: 'na plataforma',
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFF5F3FF),
              icon: '🏪',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Entregadores',
              value: fmtN(s?.totalEntregadores ?? 0),
              sub: 'cadastrados',
              color: const Color(0xFFF97316),
              bg: const Color(0xFFFFF7ED),
              icon: '🏍️',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Taxa Conversão',
              value: fmtPct(s?.taxaConversao ?? 0),
              sub: 'pedidos → pago',
              color: const Color(0xFF10B981),
              bg: const Color(0xFFECFDF5),
              icon: '📈',
              loading: loading,
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 2,
              child: SecaoRelatorio(
                titulo: 'Receita mensal',
                sub: 'Volume de pedidos e receita por mês',
                child: Column(
                  children: [
                    SimpleBarChart(
                      data: s?.receitaPorMes ?? [],
                      xKey: 'mes',
                      bars: [
                        (
                          key: 'receita',
                          color: const Color(0xFFF97316),
                          label: 'Receita'
                        ),
                        (
                          key: 'pedidos',
                          color: const Color(0xFF3B82F6),
                          label: 'Pedidos'
                        ),
                        (
                          key: 'cancelados',
                          color: const Color(0xFFEF4444),
                          label: 'Cancelados'
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    SeriesLegend(series: [
                      (color: const Color(0xFFF97316), label: 'Receita'),
                      (color: const Color(0xFF3B82F6), label: 'Pedidos'),
                      (color: const Color(0xFFEF4444), label: 'Cancelados'),
                    ]),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Método de pagamento',
                sub: 'Distribuição de pedidos',
                child: s == null
                    ? const SizedBox(height: 80)
                    : DistribuicaoPagamento(dist: s.distMetodoPagamento),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        SecaoRelatorio(
          titulo: 'Funil de conversão',
          sub: 'Do pedido criado até a entrega concluída',
          child: s == null
              ? const SizedBox(height: 60)
              : FunilConversao(funil: s.funil),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ABA: Financeiro
// ─────────────────────────────────────────────────────────────────────────────

class _TabFinanceiro extends StatelessWidget {
  final RelatorioAdmState state;
  const _TabFinanceiro({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.snapshot;
    final loading = state.isLoading;
    final receita = s?.receitaTotal ?? 0;
    final plataforma = s?.plataformaTotal ?? 0;
    final takeRate = s?.takeRate ?? 5.0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            KpiCardRelatorio(
              label: 'GMV Total',
              value: fmtBrl(receita),
              sub: 'gross merchandise value',
              color: const Color(0xFF10B981),
              bg: const Color(0xFFECFDF5),
              icon: '💰',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Take Rate',
              value: fmtPct(takeRate),
              sub: 'receita / GMV',
              color: const Color(0xFFF97316),
              bg: const Color(0xFFFFF7ED),
              icon: '%',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Receita Plataforma',
              value: fmtBrl(plataforma),
              sub: '5% sobre produtos',
              color: const Color(0xFF8B5CF6),
              bg: const Color(0xFFF5F3FF),
              icon: '🏦',
              loading: loading,
            ),
            KpiCardRelatorio(
              label: 'Splits Pendentes',
              value: fmtN(s?.pedidos
                      .where(
                          (p) => !p.splitProcessado && p.status == 'entregue')
                      .length ??
                  0),
              sub: 'aguardando processamento',
              color: const Color(0xFFF59E0B),
              bg: const Color(0xFFFFFBEB),
              icon: '⚡',
              loading: loading,
            ),
          ],
        ),
        const SizedBox(height: 14),
        SecaoRelatorio(
          titulo: 'Pedidos e receita por mês',
          sub: 'Volume de pedidos vs receita gerada',
          child: Column(
            children: [
              SimpleBarChart(
                data: s?.receitaPorMes ?? [],
                xKey: 'mes',
                height: 200,
                bars: [
                  (
                    key: 'receita',
                    color: const Color(0xFFF97316),
                    label: 'Receita'
                  ),
                  (
                    key: 'pedidos',
                    color: const Color(0xFF3B82F6),
                    label: 'Pedidos'
                  ),
                  (
                    key: 'cancelados',
                    color: const Color(0xFFEF4444),
                    label: 'Cancelados'
                  ),
                ],
              ),
              const SizedBox(height: 10),
              SeriesLegend(series: [
                (color: const Color(0xFFF97316), label: 'Receita'),
                (color: const Color(0xFF3B82F6), label: 'Pedidos'),
                (color: const Color(0xFFEF4444), label: 'Cancelados'),
              ]),
            ],
          ),
        ),
        const SizedBox(height: 14),
        SecaoRelatorio(
          titulo: 'Modelo de split',
          sub: 'Como cada R\$ 100 de produto é distribuído',
          child: GridView.count(
            crossAxisCount: 3,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
            childAspectRatio: 1.6,
            children: [
              _SplitCard(
                  titulo: 'Estabelecimento',
                  pct: 85,
                  cor: const Color(0xFF8B5CF6),
                  bg: const Color(0xFFF5F3FF),
                  valor: 'R\$ 85 / R\$ 100',
                  icon: '🏪'),
              _SplitCard(
                  titulo: 'Entregador',
                  pct: 100,
                  cor: const Color(0xFFF97316),
                  bg: const Color(0xFFFFF7ED),
                  valor: '100% da taxa entrega',
                  icon: '🏍️'),
              _SplitCard(
                  titulo: 'Plataforma',
                  pct: 5,
                  cor: const Color(0xFF10B981),
                  bg: const Color(0xFFECFDF5),
                  valor: 'R\$ 5 / R\$ 100',
                  icon: '🏦'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SplitCard extends StatelessWidget {
  final String titulo;
  final int pct;
  final Color cor;
  final Color bg;
  final String valor;
  final String icon;

  const _SplitCard({
    required this.titulo,
    required this.pct,
    required this.cor,
    required this.bg,
    required this.valor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(11),
          border: Border.all(color: cor.withValues(alpha: 0.3), width: 1.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(icon, style: const TextStyle(fontSize: 20)),
                const SizedBox(width: 8),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('$pct%',
                        style: GoogleFonts.dmSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: cor)),
                    Text(titulo,
                        style: GoogleFonts.dmSans(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF374151))),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(3),
              child: LinearProgressIndicator(
                value: pct / 100,
                minHeight: 6,
                backgroundColor: cor.withValues(alpha: 0.12),
                valueColor: AlwaysStoppedAnimation(cor),
              ),
            ),
            const SizedBox(height: 6),
            Text(valor,
                style: GoogleFonts.dmSans(
                    fontSize: 10, fontWeight: FontWeight.w700, color: cor)),
          ],
        ),
      );
}

// ─────────────────────────────────────────────────────────────────────────────
//  ABA: Operacional
// ─────────────────────────────────────────────────────────────────────────────

class _TabOperacional extends StatelessWidget {
  final RelatorioAdmState state;
  const _TabOperacional({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.snapshot;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Pedidos — últimos 7 dias',
                sub: 'Volume diário de pedidos',
                child: Column(
                  children: [
                    SimpleBarChart(
                      data: s?.pedidosPorDia ?? [],
                      xKey: 'dia',
                      bars: [
                        (
                          key: 'pedidos',
                          color: const Color(0xFFF97316),
                          label: 'Pedidos'
                        )
                      ],
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Estabelecimentos',
                sub: 'Por volume de pedidos',
                child: s == null || s.estabelecimentos.isEmpty
                    ? const RelatorioEmptyState(
                        emoji: '🏪',
                        titulo: 'Nenhum estabelecimento',
                        subtitulo:
                            'Os rankings aparecem assim que pedidos forem realizados',
                      )
                    : Column(
                        children: s.estabelecimentos
                            .take(5)
                            .toList()
                            .asMap()
                            .entries
                            .map(
                              (e) => RankingRow(
                                posicao: e.key,
                                nome: e.value.nomeFantasia,
                                sub:
                                    '${e.value.totalPedidos} pedidos · ${fmtBrl(e.value.faturamentoTotal)}',
                                badge: e.value.statusCadastro == 'aprovado'
                                    ? 'Ativo'
                                    : 'Pendente',
                                badgeColor: e.value.statusCadastro == 'aprovado'
                                    ? const Color(0xFF10B981)
                                    : const Color(0xFFF59E0B),
                                badgeBg: e.value.statusCadastro == 'aprovado'
                                    ? const Color(0xFFECFDF5)
                                    : const Color(0xFFFFFBEB),
                              ),
                            )
                            .toList(),
                      ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Entregadores',
                sub: 'Ranking por entregas realizadas',
                child: s == null || s.entregadores.isEmpty
                    ? const RelatorioEmptyState(
                        emoji: '🏍️',
                        titulo: 'Nenhuma entrega ainda',
                        subtitulo:
                            'Os entregadores aparecem após as primeiras entregas',
                      )
                    : Column(
                        children: (() {
                          final sorted = [...s.entregadores]..sort((a, b) =>
                              b.totalEntregas.compareTo(a.totalEntregas));
                          return sorted
                              .take(5)
                              .toList()
                              .asMap()
                              .entries
                              .map(
                                (e) => RankingRow(
                                  posicao: e.key,
                                  nome: 'Entregador #${e.key + 1}',
                                  sub:
                                      '${e.value.totalEntregas} entregas · ${e.value.tipoVeiculo}',
                                  badge: e.value.statusCadastro == 'aprovado'
                                      ? 'Aprovado'
                                      : 'Pendente',
                                  badgeColor:
                                      e.value.statusCadastro == 'aprovado'
                                          ? const Color(0xFF10B981)
                                          : const Color(0xFFF59E0B),
                                  badgeBg: e.value.statusCadastro == 'aprovado'
                                      ? const Color(0xFFECFDF5)
                                      : const Color(0xFFFFFBEB),
                                ),
                              )
                              .toList();
                        })(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Status operacional',
                sub: 'Situação atual da plataforma',
                child: s == null
                    ? const SizedBox(height: 80)
                    : _StatusOperacional(snapshot: s),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _StatusOperacional extends StatelessWidget {
  final RelatorioSnapshot snapshot;
  const _StatusOperacional({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final items = [
      (
        l: 'Entregadores online',
        v: '${snapshot.entregadoresOnline} / ${snapshot.totalEntregadores}',
        c: snapshot.entregadoresOnline > 0
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        pct: snapshot.totalEntregadores > 0
            ? snapshot.entregadoresOnline / snapshot.totalEntregadores
            : 0.0,
      ),
      (
        l: 'Entregadores aprovados',
        v: '${snapshot.entregadoresAprovados} / ${snapshot.totalEntregadores}',
        c: snapshot.entregadoresAprovados > 0
            ? const Color(0xFF10B981)
            : const Color(0xFFEF4444),
        pct: snapshot.totalEntregadores > 0
            ? snapshot.entregadoresAprovados / snapshot.totalEntregadores
            : 0.0,
      ),
      (
        l: 'Pedidos entregues',
        v: '${snapshot.pedidosEntregues.length} / ${snapshot.pedidos.length}',
        c: snapshot.pedidosEntregues.isNotEmpty
            ? const Color(0xFF10B981)
            : const Color(0xFFF97316),
        pct: snapshot.pedidos.isNotEmpty
            ? snapshot.pedidosEntregues.length / snapshot.pedidos.length
            : 0.0,
      ),
    ];

    return Column(
      children: items.map((item) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(item.l,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: const Color(0xFF6B7280))),
                  Text(item.v,
                      style: GoogleFonts.dmSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: item.c)),
                ],
              ),
              const SizedBox(height: 5),
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: item.pct.clamp(0.0, 1.0),
                  minHeight: 5,
                  backgroundColor: const Color(0xFFF3F1EE),
                  valueColor: AlwaysStoppedAnimation(item.c),
                ),
              ),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ABA: Usuários
// ─────────────────────────────────────────────────────────────────────────────

class _TabUsuarios extends StatelessWidget {
  final RelatorioAdmState state;
  const _TabUsuarios({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.snapshot;
    final total = s?.totalUsuarios ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            KpiCardRelatorio(
                label: 'Total usuários',
                value: fmtN(total),
                sub: 'na plataforma',
                color: const Color(0xFF1A0910),
                bg: Colors.white,
                icon: '👥',
                loading: state.isLoading),
            KpiCardRelatorio(
                label: 'Clientes',
                value: fmtN(s?.totalClientes ?? 0),
                sub: 'cadastrados',
                color: const Color(0xFF3B82F6),
                bg: const Color(0xFFEFF6FF),
                icon: '👤',
                loading: state.isLoading),
            KpiCardRelatorio(
                label: 'Entregadores',
                value: fmtN(s?.totalEntregadores ?? 0),
                sub: 'cadastrados',
                color: const Color(0xFFF97316),
                bg: const Color(0xFFFFF7ED),
                icon: '🏍️',
                loading: state.isLoading),
            KpiCardRelatorio(
                label: 'Estabelecimentos',
                value: fmtN(s?.totalEstabs ?? 0),
                sub: 'cadastrados',
                color: const Color(0xFF8B5CF6),
                bg: const Color(0xFFF5F3FF),
                icon: '🏪',
                loading: state.isLoading),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Crescimento de cadastros',
                sub: 'Novos usuários por mês por tipo',
                child: s == null || s.crescimentoUsuarios.isEmpty
                    ? const RelatorioEmptyState(
                        emoji: '📈',
                        titulo: 'Sem dados de crescimento',
                        subtitulo:
                            'O gráfico é exibido quando há cadastros registrados')
                    : Column(
                        children: [
                          SimpleBarChart(
                            data: s.crescimentoUsuarios,
                            xKey: 'mes',
                            bars: [
                              (
                                key: 'clientes',
                                color: const Color(0xFF3B82F6),
                                label: 'Clientes'
                              ),
                              (
                                key: 'entregadores',
                                color: const Color(0xFFF97316),
                                label: 'Entregadores'
                              ),
                              (
                                key: 'estabelecimentos',
                                color: const Color(0xFF8B5CF6),
                                label: 'Estabelecimentos'
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          SeriesLegend(series: [
                            (color: const Color(0xFF3B82F6), label: 'Clientes'),
                            (
                              color: const Color(0xFFF97316),
                              label: 'Entregadores'
                            ),
                            (
                              color: const Color(0xFF8B5CF6),
                              label: 'Estabelecimentos'
                            ),
                          ]),
                        ],
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Distribuição por tipo',
                sub: 'Composição da base de usuários',
                child: s == null || total == 0
                    ? const RelatorioEmptyState(
                        emoji: '👥',
                        titulo: 'Sem dados ainda',
                        subtitulo:
                            'A distribuição aparece após os primeiros cadastros')
                    : _DistTipo(snapshot: s),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _DistTipo extends StatelessWidget {
  final RelatorioSnapshot snapshot;
  const _DistTipo({required this.snapshot});

  @override
  Widget build(BuildContext context) {
    final total = snapshot.totalUsuarios;
    if (total == 0) return const SizedBox.shrink();
    final items = [
      (l: 'Clientes', v: snapshot.totalClientes, c: const Color(0xFF3B82F6)),
      (
        l: 'Entregadores',
        v: snapshot.totalEntregadores,
        c: const Color(0xFFF97316)
      ),
      (
        l: 'Estabelecimentos',
        v: snapshot.totalEstabs,
        c: const Color(0xFF8B5CF6)
      ),
    ];
    return Column(
      children: items.map((item) {
        final pct = item.v / total;
        return Padding(
          padding: const EdgeInsets.only(bottom: 10),
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                margin: const EdgeInsets.only(right: 8),
                decoration: BoxDecoration(
                    color: item.c, borderRadius: BorderRadius.circular(2)),
              ),
              Expanded(
                  child: Text(item.l,
                      style: GoogleFonts.dmSans(
                          fontSize: 11, color: const Color(0xFF6B7280)))),
              Text('${item.v}',
                  style: GoogleFonts.dmSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF1A0910))),
              const SizedBox(width: 6),
              Text('${(pct * 100).toStringAsFixed(0)}%',
                  style: GoogleFonts.dmSans(
                      fontSize: 10, color: const Color(0xFF9CA3AF))),
            ],
          ),
        );
      }).toList(),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
//  ABA: Qualidade
// ─────────────────────────────────────────────────────────────────────────────

class _TabQualidade extends StatelessWidget {
  final RelatorioAdmState state;
  const _TabQualidade({required this.state});

  @override
  Widget build(BuildContext context) {
    final s = state.snapshot;
    final loading = state.isLoading;

    final avgNota = s == null || s.avaliacoes.isEmpty
        ? 0.0
        : s.avaliacoes
                .map((a) =>
                    ((a.notaEstabelecimento ?? 0) + (a.notaEntregador ?? 0)) /
                    2)
                .fold(0.0, (a, b) => a + b) /
            s.avaliacoes.length;

    final chamadosAbertos =
        s?.chamados.where((c) => c.status == 'aberto').length ?? 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        GridView.count(
          crossAxisCount: 4,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          childAspectRatio: 1.7,
          children: [
            KpiCardRelatorio(
                label: 'Média geral',
                value: s?.avaliacoes.isEmpty ?? true
                    ? '—'
                    : avgNota.toStringAsFixed(1),
                sub: 'nota das avaliações',
                color: const Color(0xFFF59E0B),
                bg: const Color(0xFFFFFBEB),
                icon: '⭐',
                loading: loading),
            KpiCardRelatorio(
                label: 'Total avaliações',
                value: fmtN(s?.avaliacoes.length ?? 0),
                sub: 'registradas',
                color: const Color(0xFF8B5CF6),
                bg: const Color(0xFFF5F3FF),
                icon: '📝',
                loading: loading),
            KpiCardRelatorio(
                label: 'Chamados abertos',
                value: fmtN(chamadosAbertos),
                sub: 'suporte',
                color: chamadosAbertos > 0
                    ? const Color(0xFFEF4444)
                    : const Color(0xFF10B981),
                bg: chamadosAbertos > 0
                    ? const Color(0xFFFEF2F2)
                    : const Color(0xFFECFDF5),
                icon: '💬',
                loading: loading),
            KpiCardRelatorio(
                label: 'Cancelamentos',
                value: fmtPct(s?.taxaCancelamento ?? 0),
                sub: 'taxa de cancelamento',
                color: const Color(0xFFF59E0B),
                bg: const Color(0xFFFFFBEB),
                icon: '❌',
                loading: loading),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Distribuição de notas',
                sub: 'Estabelecimentos vs Entregadores',
                child: s == null || s.avaliacoes.isEmpty
                    ? const RelatorioEmptyState(
                        emoji: '⭐',
                        titulo: 'Nenhuma avaliação ainda',
                        subtitulo:
                            'As avaliações aparecem após os primeiros pedidos entregues')
                    : Column(
                        children: s.distNotas.map((d) {
                          final estab = d['estab'] as int;
                          final entregador = d['entregador'] as int;
                          final max = estab > entregador ? estab : entregador;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Row(
                              children: [
                                Text(d['nota'] as String,
                                    style: GoogleFonts.dmSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: const Color(0xFF374151)),
                                    textAlign: TextAlign.center),
                                const SizedBox(width: 10),
                                Expanded(
                                    child: Column(
                                  children: [
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                            value: max > 0 ? estab / max : 0,
                                            minHeight: 5,
                                            backgroundColor:
                                                const Color(0xFFF3F1EE),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                    Color(0xFF8B5CF6)))),
                                    const SizedBox(height: 3),
                                    ClipRRect(
                                        borderRadius: BorderRadius.circular(3),
                                        child: LinearProgressIndicator(
                                            value:
                                                max > 0 ? entregador / max : 0,
                                            minHeight: 5,
                                            backgroundColor:
                                                const Color(0xFFF3F1EE),
                                            valueColor:
                                                const AlwaysStoppedAnimation(
                                                    Color(0xFFF97316)))),
                                  ],
                                )),
                              ],
                            ),
                          );
                        }).toList(),
                      ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: SecaoRelatorio(
                titulo: 'Chamados por categoria',
                sub: 'Volume e taxa de resolução',
                child: s == null
                    ? const SizedBox(height: 60)
                    : Column(
                        children: [
                          ...s.chamadosPorCategoria.map((c) {
                            final total = c['total'] as int;
                            final res = c['resolvidos'] as int;
                            return Container(
                              margin: const EdgeInsets.only(bottom: 6),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 9),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9F8F7),
                                borderRadius: BorderRadius.circular(9),
                              ),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(c['cat'] as String,
                                        style: GoogleFonts.dmSans(
                                            fontSize: 12,
                                            color: const Color(0xFF374151))),
                                  ),
                                  Text('$total',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF1A0910))),
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                        horizontal: 7, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFECFDF5),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      total == 0
                                          ? '—'
                                          : '$res/$total resolvidos',
                                      style: GoogleFonts.dmSans(
                                          fontSize: 9,
                                          fontWeight: FontWeight.w700,
                                          color: const Color(0xFF10B981)),
                                    ),
                                  ),
                                ],
                              ),
                            );
                          }),
                          if (s.chamados.isEmpty)
                            const RelatorioEmptyState(
                              emoji: '💬',
                              titulo: 'Nenhum chamado registrado',
                              subtitulo:
                                  'Os chamados aparecem quando usuários abrirem tickets',
                            ),
                        ],
                      ),
              ),
            ),
          ],
        ),
      ],
    );
  }
}
