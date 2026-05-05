import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../componentes_dash/sidebar_menu.dart';
import '../components/period_filter_bar.dart';
import '../dashboard_controller.dart';
import 'widgets/download_helper.dart';

class RelatoriosScreen extends ConsumerWidget {
  const RelatoriosScreen({super.key});

  static const _primary = Color(0xFFF97316);
  static const _green = Color(0xFF10B981);
  static const _blue = Color(0xFF3B82F6);
  static const _purple = Color(0xFF8B5CF6);
  static const _red = Color(0xFFEF4444);
  static const _text = Color(0xFF111827);
  static const _muted = Color(0xFF6B7280);
  static const _border = Color(0xFFE5E7EB);
  static const _surface = Color(0xFFF5F4F1);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardControllerProvider);
    final notifier = ref.read(dashboardControllerProvider.notifier);
    final isMobile = MediaQuery.of(context).size.width < 900;

    final reports = _reportsFor(state);

    return Scaffold(
      backgroundColor: _surface,
      drawer: isMobile
          ? SidebarMenu(activeId: 'reports', onItemSelected: (_) {})
          : null,
      body: Builder(
        builder: (scaffoldContext) {
          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (!isMobile)
                SidebarMenu(activeId: 'reports', onItemSelected: (_) {}),
              Expanded(
                child: Column(
                  children: [
                    _Header(
                      isMobile: isMobile,
                      state: state,
                      onMenu: () => Scaffold.of(scaffoldContext).openDrawer(),
                      onRefresh: () => notifier.recarregar(),
                      onPeriod: (period) =>
                          notifier.mudarPeriodo(period, null),
                    ),
                    Expanded(
                      child: state.isLoading && state.totalPedidos == 0
                          ? const Center(child: CircularProgressIndicator())
                          : ListView(
                              padding: const EdgeInsets.all(24),
                              children: [
                                if (state.error != null)
                                  _ErrorBox(message: state.error!),
                                _SummaryGrid(state: state),
                                const SizedBox(height: 18),
                                _SectionTitle(
                                  title: 'Opções de exportação',
                                  subtitle:
                                      'Relatórios com informações do estabelecimento logado.',
                                ),
                                const SizedBox(height: 12),
                                LayoutBuilder(
                                  builder: (context, constraints) {
                                    final columns =
                                        constraints.maxWidth > 1180
                                            ? 3
                                            : constraints.maxWidth > 760
                                                ? 2
                                                : 1;
                                    return GridView.builder(
                                      shrinkWrap: true,
                                      physics:
                                          const NeverScrollableScrollPhysics(),
                                      itemCount: reports.length,
                                      gridDelegate:
                                          SliverGridDelegateWithFixedCrossAxisCount(
                                        crossAxisCount: columns,
                                        crossAxisSpacing: 14,
                                        mainAxisSpacing: 14,
                                        mainAxisExtent: 260,
                                      ),
                                      itemBuilder: (context, index) {
                                        final report = reports[index];
                                        return _ReportCard(
                                          report: report,
                                          enabled: !state.isLoading,
                                          onCsv: () => _exportCsv(
                                            context,
                                            report,
                                            state,
                                          ),
                                          onPdf: () => _exportPdf(
                                            context,
                                            report,
                                            state,
                                          ),
                                        );
                                      },
                                    );
                                  },
                                ),
                                const SizedBox(height: 18),
                                _PreviewCard(state: state),
                              ],
                            ),
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  List<_ReportDefinition> _reportsFor(DashboardState state) {
    return [
      _ReportDefinition(
        type: _ReportType.geral,
        title: 'Resumo geral',
        description:
            'Visão executiva com faturamento, pedidos, ticket médio, clientes e funil.',
        icon: Icons.dashboard_customize_rounded,
        color: _primary,
        rows: [
          'Faturamento, ticket médio e pedidos',
          'Clientes únicos, novos e recorrentes',
          'Status operacional dos pedidos',
        ],
      ),
      _ReportDefinition(
        type: _ReportType.financeiro,
        title: 'Financeiro do período',
        description:
            'Valores do estabelecimento por período, sem dados externos à loja.',
        icon: Icons.payments_rounded,
        color: _green,
        rows: [
          'Faturamento total',
          'Ticket médio',
          'Vendas agrupadas por data ou hora',
        ],
      ),
      _ReportDefinition(
        type: _ReportType.pedidos,
        title: 'Pedidos e operação',
        description:
            'Quantidade de pedidos por etapa para acompanhar preparo e conclusão.',
        icon: Icons.receipt_long_rounded,
        color: _blue,
        rows: [
          'Pendentes, confirmados e preparando',
          'Prontos, em entrega e entregues',
          'Cancelamentos do período',
        ],
      ),
      _ReportDefinition(
        type: _ReportType.produtos,
        title: 'Produtos mais vendidos',
        description:
            'Ranking de itens vendidos pelo estabelecimento no período selecionado.',
        icon: Icons.inventory_2_rounded,
        color: _purple,
        rows: [
          'Nome do produto',
          'Quantidade vendida',
          'Receita gerada por produto',
        ],
      ),
      _ReportDefinition(
        type: _ReportType.clientes,
        title: 'Clientes',
        description:
            'Indicadores de clientes únicos, novos e recorrentes do estabelecimento.',
        icon: Icons.people_alt_rounded,
        color: const Color(0xFF0EA5E9),
        rows: [
          'Clientes únicos',
          'Novos clientes',
          'Clientes recorrentes',
        ],
      ),
      _ReportDefinition(
        type: _ReportType.avaliacoes,
        title: 'Avaliações',
        description:
            'Resumo da avaliação média atual do estabelecimento para acompanhamento.',
        icon: Icons.star_rounded,
        color: _red,
        rows: [
          'Avaliação média',
          'Comparação simples no período',
          'Campo preparado para histórico futuro',
        ],
      ),
    ];
  }

  void _exportCsv(
    BuildContext context,
    _ReportDefinition report,
    DashboardState state,
  ) {
    if (!_canExport(context)) return;
    final filename = _filename(report, 'csv');
    downloadBytes(
      utf8.encode(_buildCsv(report, state)),
      'text/csv;charset=utf-8',
      filename,
    );
    _showSnack(context, 'CSV exportado: $filename');
  }

  void _exportPdf(
    BuildContext context,
    _ReportDefinition report,
    DashboardState state,
  ) {
    if (!_canExport(context)) return;
    final filename = _filename(report, 'pdf');
    downloadBytes(
      _SimplePdf.build(
        title: report.title,
        lines: _buildPdfLines(report, state),
      ),
      'application/pdf',
      filename,
    );
    _showSnack(context, 'PDF exportado: $filename');
  }

  bool _canExport(BuildContext context) {
    if (kIsWeb) return true;
    _showSnack(
      context,
      'Exportação direta disponível apenas no navegador por enquanto.',
    );
    return false;
  }

  String _filename(_ReportDefinition report, String ext) {
    final stamp = DateTime.now()
        .toIso8601String()
        .replaceAll(RegExp(r'[:.]'), '-')
        .substring(0, 19);
    return 'relatorio_estabelecimento_${report.type.name}_$stamp.$ext';
  }

  String _buildCsv(_ReportDefinition report, DashboardState state) {
    final rows = _reportRows(report.type, state);
    final buffer = StringBuffer()
      ..writeln('Relatório,${_csv(report.title)}')
      ..writeln('Estabelecimento,${_csv(state.estabelecimentoNome ?? '')}')
      ..writeln('Período,${_csv(_periodLabel(state.periodoAtual))}')
      ..writeln('Gerado em,${DateTime.now().toIso8601String()}')
      ..writeln()
      ..writeln('Indicador,Valor');

    for (final row in rows) {
      buffer.writeln('${_csv(row.label)},${_csv(row.value)}');
    }
    return buffer.toString();
  }

  List<String> _buildPdfLines(_ReportDefinition report, DashboardState state) {
    return [
      'Estabelecimento: ${state.estabelecimentoNome ?? '-'}',
      'Período: ${_periodLabel(state.periodoAtual)}',
      'Gerado em: ${DateTime.now().toIso8601String().substring(0, 16)}',
      '',
      ..._reportRows(report.type, state)
          .map((row) => '${row.label}: ${row.value}'),
    ];
  }

  List<_ReportRow> _reportRows(_ReportType type, DashboardState state) {
    switch (type) {
      case _ReportType.geral:
        return [
          _ReportRow('Faturamento', _money(state.vendasTotal)),
          _ReportRow('Total de pedidos', '${state.totalPedidos}'),
          _ReportRow('Pedidos ativos', '${state.pedidosAtivos}'),
          _ReportRow('Ticket médio', _money(state.ticketMedio)),
          _ReportRow('Avaliação média', state.avaliacaoMedia.toStringAsFixed(1)),
          _ReportRow('Clientes únicos', '${state.clientesUnicos}'),
          _ReportRow('Clientes novos', '${state.clientesNovos}'),
          _ReportRow('Clientes recorrentes', '${state.clientesRecorrentes}'),
        ];
      case _ReportType.financeiro:
        return [
          _ReportRow('Faturamento', _money(state.vendasTotal)),
          _ReportRow('Ticket médio', _money(state.ticketMedio)),
          _ReportRow('Variação de vendas', '${state.deltaVendas.toStringAsFixed(1)}%'),
          ...state.vendasPorDia.entries.map(
            (entry) => _ReportRow('Vendas ${entry.key}', _money(entry.value)),
          ),
        ];
      case _ReportType.pedidos:
        final cancelados = math.max(
          0,
          state.totalPedidos -
              state.pendentes -
              state.confirmados -
              state.preparando -
              state.prontos -
              state.emEntrega -
              state.entregues,
        );
        return [
          _ReportRow('Total de pedidos', '${state.totalPedidos}'),
          _ReportRow('Pedidos ativos', '${state.pedidosAtivos}'),
          _ReportRow('Pendentes', '${state.pendentes}'),
          _ReportRow('Confirmados', '${state.confirmados}'),
          _ReportRow('Preparando', '${state.preparando}'),
          _ReportRow('Prontos', '${state.prontos}'),
          _ReportRow('Em entrega', '${state.emEntrega}'),
          _ReportRow('Entregues', '${state.entregues}'),
          _ReportRow('Cancelados', '$cancelados'),
        ];
      case _ReportType.produtos:
        if (state.ranking.isEmpty) {
          return [_ReportRow('Produtos', 'Sem produtos vendidos no período')];
        }
        return state.ranking.map((item) {
          final nome = item['nome']?.toString() ?? 'Produto';
          final vendidos = item['vendidos']?.toString() ?? '0';
          final receita = (item['receita'] as num?)?.toDouble() ?? 0;
          return _ReportRow(nome, '$vendidos vendidos | ${_money(receita)}');
        }).toList();
      case _ReportType.clientes:
        return [
          _ReportRow('Clientes únicos', '${state.clientesUnicos}'),
          _ReportRow('Clientes novos', '${state.clientesNovos}'),
          _ReportRow('Clientes recorrentes', '${state.clientesRecorrentes}'),
        ];
      case _ReportType.avaliacoes:
        return [
          _ReportRow('Avaliação média atual', state.avaliacaoMedia.toStringAsFixed(1)),
          _ReportRow('Variação de avaliação', '${state.deltaAvaliacao.toStringAsFixed(1)}%'),
        ];
    }
  }

  String _csv(String value) {
    final escaped = value.replaceAll('"', '""');
    return '"$escaped"';
  }

  static String _money(double value) {
    return 'R\$ ${value.toStringAsFixed(2).replaceAll('.', ',')}';
  }

  static String _periodLabel(DashboardPeriodo periodo) {
    switch (periodo) {
      case DashboardPeriodo.hoje:
        return 'Hoje';
      case DashboardPeriodo.semana:
        return 'Semana';
      case DashboardPeriodo.mes:
        return 'Mês';
      case DashboardPeriodo.custom:
        return 'Personalizado';
    }
  }

  void _showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }
}

class _Header extends StatelessWidget {
  final bool isMobile;
  final DashboardState state;
  final VoidCallback onMenu;
  final VoidCallback onRefresh;
  final ValueChanged<DashboardPeriodo> onPeriod;

  const _Header({
    required this.isMobile,
    required this.state,
    required this.onMenu,
    required this.onRefresh,
    required this.onPeriod,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(bottom: BorderSide(color: Color(0xFFE5E7EB))),
      ),
      child: Row(
        children: [
          if (isMobile) ...[
            IconButton(
              onPressed: onMenu,
              icon: const Icon(Icons.menu_rounded),
            ),
            const SizedBox(width: 8),
          ],
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFFFF7ED),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.bar_chart_rounded, color: RelatoriosScreen._primary),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Relatórios',
                  style: GoogleFonts.publicSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    color: RelatoriosScreen._text,
                  ),
                ),
                Text(
                  state.estabelecimentoNome ?? 'Dados do estabelecimento',
                  style: GoogleFonts.publicSans(
                    fontSize: 12,
                    color: RelatoriosScreen._muted,
                  ),
                ),
              ],
            ),
          ),
          if (!isMobile)
            Wrap(
              spacing: 8,
              children: [
                _PeriodButton(
                  label: 'Hoje',
                  active: state.periodoAtual == DashboardPeriodo.hoje,
                  onTap: () => onPeriod(DashboardPeriodo.hoje),
                ),
                _PeriodButton(
                  label: 'Semana',
                  active: state.periodoAtual == DashboardPeriodo.semana,
                  onTap: () => onPeriod(DashboardPeriodo.semana),
                ),
                _PeriodButton(
                  label: 'Mês',
                  active: state.periodoAtual == DashboardPeriodo.mes,
                  onTap: () => onPeriod(DashboardPeriodo.mes),
                ),
              ],
            ),
          const SizedBox(width: 12),
          IconButton(
            onPressed: onRefresh,
            tooltip: 'Atualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
    );
  }
}

class _PeriodButton extends StatelessWidget {
  final String label;
  final bool active;
  final VoidCallback onTap;

  const _PeriodButton({
    required this.label,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? RelatoriosScreen._text : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: active ? RelatoriosScreen._text : RelatoriosScreen._border,
          ),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: active ? Colors.white : RelatoriosScreen._muted,
          ),
        ),
      ),
    );
  }
}

class _SummaryGrid extends StatelessWidget {
  final DashboardState state;

  const _SummaryGrid({required this.state});

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Faturamento', RelatoriosScreen._money(state.vendasTotal), Icons.payments_rounded, RelatoriosScreen._green),
      ('Pedidos', '${state.totalPedidos}', Icons.receipt_long_rounded, RelatoriosScreen._blue),
      ('Ticket médio', RelatoriosScreen._money(state.ticketMedio), Icons.trending_up_rounded, RelatoriosScreen._purple),
      ('Clientes', '${state.clientesUnicos}', Icons.people_alt_rounded, const Color(0xFF0EA5E9)),
    ];

    return LayoutBuilder(
      builder: (context, constraints) {
        final columns = constraints.maxWidth > 1000
            ? 4
            : constraints.maxWidth > 680
                ? 2
                : 1;
        return GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: items.length,
          gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: columns,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            mainAxisExtent: 110,
          ),
          itemBuilder: (context, index) {
            final item = items[index];
            return Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: RelatoriosScreen._border),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: item.$4.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(item.$3, color: item.$4),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.$1,
                          style: GoogleFonts.publicSans(
                            fontSize: 12,
                            color: RelatoriosScreen._muted,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          item.$2,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.publicSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: RelatoriosScreen._text,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionTitle({required this.title, required this.subtitle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.publicSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: RelatoriosScreen._text,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: GoogleFonts.publicSans(
            fontSize: 13,
            color: RelatoriosScreen._muted,
          ),
        ),
      ],
    );
  }
}

class _ReportCard extends StatelessWidget {
  final _ReportDefinition report;
  final bool enabled;
  final VoidCallback onCsv;
  final VoidCallback onPdf;

  const _ReportCard({
    required this.report,
    required this.enabled,
    required this.onCsv,
    required this.onPdf,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RelatoriosScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: report.color.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(report.icon, color: report.color, size: 20),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  report.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.publicSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RelatoriosScreen._text,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            report.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.publicSans(
              fontSize: 12,
              height: 1.35,
              color: RelatoriosScreen._muted,
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                for (final row in report.rows.take(3))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 7),
                    child: Row(
                      children: [
                        Icon(Icons.check_rounded,
                            size: 15, color: report.color),
                        const SizedBox(width: 7),
                        Expanded(
                          child: Text(
                            row,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.publicSans(
                              fontSize: 12,
                              color: RelatoriosScreen._text,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: enabled ? onCsv : null,
                  icon: const Icon(Icons.table_chart_rounded, size: 17),
                  label: const Text('CSV'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: enabled ? onPdf : null,
                  icon: const Icon(Icons.picture_as_pdf_rounded, size: 17),
                  label: const Text('PDF'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: report.color,
                    foregroundColor: Colors.white,
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _PreviewCard extends StatelessWidget {
  final DashboardState state;

  const _PreviewCard({required this.state});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RelatoriosScreen._border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Previa dos produtos mais vendidos',
            style: GoogleFonts.publicSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: RelatoriosScreen._text,
            ),
          ),
          const SizedBox(height: 12),
          if (state.ranking.isEmpty)
            Text(
              'Sem produtos vendidos no período selecionado.',
              style: GoogleFonts.publicSans(color: RelatoriosScreen._muted),
            )
          else
            ...state.ranking.take(5).map((item) {
              final nome = item['nome']?.toString() ?? 'Produto';
              final vendidos = item['vendidos']?.toString() ?? '0';
              final receita = (item['receita'] as num?)?.toDouble() ?? 0;
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Row(
                  children: [
                    Expanded(
                      child: Text(
                        nome,
                        style: GoogleFonts.publicSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RelatoriosScreen._text,
                        ),
                      ),
                    ),
                    Text(
                      '$vendidos un.  ${RelatoriosScreen._money(receita)}',
                      style: GoogleFonts.publicSans(
                        fontSize: 13,
                        color: RelatoriosScreen._muted,
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}

class _ErrorBox extends StatelessWidget {
  final String message;

  const _ErrorBox({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFFECACA)),
      ),
      child: Text(
        message,
        style: GoogleFonts.publicSans(color: const Color(0xFFB91C1C)),
      ),
    );
  }
}

enum _ReportType { geral, financeiro, pedidos, produtos, clientes, avaliacoes }

class _ReportDefinition {
  final _ReportType type;
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final List<String> rows;

  const _ReportDefinition({
    required this.type,
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.rows,
  });
}

class _ReportRow {
  final String label;
  final String value;

  const _ReportRow(this.label, this.value);
}

class _SimplePdf {
  static List<int> build({
    required String title,
    required List<String> lines,
  }) {
    const pageWidth = 595;
    const pageHeight = 842;
    const marginX = 48;
    const startY = 790;
    const lineHeight = 16;
    const maxLinesPerPage = 43;

    final cleanTitle = _pdfText(title);
    final cleanLines = lines.map(_pdfText).toList();
    final chunks = <List<String>>[];
    for (var i = 0; i < cleanLines.length; i += maxLinesPerPage) {
      chunks.add(cleanLines.sublist(i, math.min(i + maxLinesPerPage, cleanLines.length)));
    }
    if (chunks.isEmpty) chunks.add(const []);

    final objects = <int, String>{};
    final pageIds = <int>[];
    var nextId = 4;

    for (var pageIndex = 0; pageIndex < chunks.length; pageIndex++) {
      final contentId = nextId++;
      final pageId = nextId++;
      pageIds.add(pageId);

      final content = StringBuffer()
        ..writeln('BT')
        ..writeln('/F1 16 Tf')
        ..writeln('$lineHeight TL')
        ..writeln('1 0 0 1 $marginX $startY Tm')
        ..writeln('(${_escape(cleanTitle)}) Tj')
        ..writeln('T*')
        ..writeln('/F1 10 Tf')
        ..writeln('T*');

      for (final line in chunks[pageIndex]) {
        content.writeln('(${_escape(line)}) Tj');
        content.writeln('T*');
      }
      content.writeln('ET');

      final stream = content.toString();
      objects[contentId] =
          '<< /Length ${latin1.encode(stream).length} >>\nstream\n$stream\nendstream';
      objects[pageId] =
          '<< /Type /Page /Parent 2 0 R /MediaBox [0 0 $pageWidth $pageHeight] /Resources << /Font << /F1 3 0 R >> >> /Contents $contentId 0 R >>';
    }

    objects[1] = '<< /Type /Catalog /Pages 2 0 R >>';
    objects[2] =
        '<< /Type /Pages /Kids [${pageIds.map((id) => '$id 0 R').join(' ')}] /Count ${pageIds.length} >>';
    objects[3] =
        '<< /Type /Font /Subtype /Type1 /BaseFont /Helvetica /Encoding /WinAnsiEncoding >>';

    final buffer = StringBuffer('%PDF-1.4\n');
    final offsets = <int>[0];
    for (var id = 1; id < nextId; id++) {
      offsets.add(latin1.encode(buffer.toString()).length);
      buffer
        ..writeln('$id 0 obj')
        ..writeln(objects[id])
        ..writeln('endobj');
    }

    final xrefOffset = latin1.encode(buffer.toString()).length;
    buffer
      ..writeln('xref')
      ..writeln('0 $nextId')
      ..writeln('0000000000 65535 f ');
    for (var id = 1; id < nextId; id++) {
      buffer.writeln('${offsets[id].toString().padLeft(10, '0')} 00000 n ');
    }
    buffer
      ..writeln('trailer')
      ..writeln('<< /Size $nextId /Root 1 0 R >>')
      ..writeln('startxref')
      ..writeln(xrefOffset)
      ..writeln('%%EOF');

    return latin1.encode(buffer.toString());
  }

  static String _escape(String value) {
    return value
        .replaceAll(r'\', r'\\')
        .replaceAll('(', r'\(')
        .replaceAll(')', r'\)');
  }

  static String _pdfText(String value) {
    final buffer = StringBuffer();
    for (final codeUnit in value.codeUnits) {
      if (codeUnit == 9 || codeUnit == 10 || codeUnit == 13) {
        buffer.write(' ');
      } else if (codeUnit >= 32 && codeUnit <= 255) {
        buffer.writeCharCode(codeUnit);
      } else {
        buffer.write('-');
      }
    }
    return buffer.toString();
  }
}
