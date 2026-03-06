import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'financeiro_controller.dart';
import 'models/financeiro_models.dart';
import 'componentes_financeiro.dart';
import 'financeiro_state.dart';

// Import local do sidebar para manter a navegação padrão
import '../dashboard/componentes_dash/sidebar_menu.dart';

class FinanceiroScreen extends ConsumerStatefulWidget {
  const FinanceiroScreen({super.key});

  @override
  ConsumerState<FinanceiroScreen> createState() => _FinanceiroScreenState();
}

class _FinanceiroScreenState extends ConsumerState<FinanceiroScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  String _tabExtra = 'metodos'; // metodos | splits | transacoes
  int _txPage = 0;
  static const int _txPerPage = 12;

  @override
  void initState() {
    super.initState();
    // O controller carrega sozinho no provider initial, mas se precisar forçar:
    // Future.microtask(() => ref.read(financeiroControllerProvider.notifier).carregarDadosIniciais());
  }

  void _mudaPeriodo(String p) {
    ref.read(financeiroControllerProvider.notifier).buscarDadosPorPeriodo(p);
    setState(() => _txPage = 0);
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(financeiroControllerProvider);
    final isMobile = MediaQuery.of(context).size.width < 900;

    // Filtros visuais de páginação da lista de transações
    final validTx = state.pedidos
        .where(
            (p) => p.status == 'entregue' || p.status.startsWith('cancelado'))
        .toList();
    final txPages = (validTx.length / _txPerPage).ceil();
    final txList = validTx.skip(_txPage * _txPerPage).take(_txPerPage).toList();

    // Map de Métodos
    final Map<String, double> metodosVal = {};
    for (var p in state.entregues) {
      final m = p.pagamentoMetodo ?? 'outro';
      metodosVal[m] = (metodosVal[m] ?? 0.0) + p.total;
    }

    final metodosTotal = metodosVal.values.fold(0.0, (s, v) => s + v) == 0
        ? 1.0
        : metodosVal.values.fold(0.0, (s, v) => s + v);
    final metodosArray = metodosVal.entries.map((e) {
      final color = _getPgtoColor(e.key);
      final label = _getPgtoLabel(e.key);
      return {
        'key': e.key,
        'label': label,
        'value': e.value,
        'color': color,
        'pct': (e.value / metodosTotal) * 100
      };
    }).toList()
      ..sort((a, b) => (b['value'] as double).compareTo(a['value'] as double));

    // Evolução Gráfico de Barras
    final buckets = <String, double>{};
    final isSemanal =
        state.periodoAtual == 'trimestre' || state.periodoAtual == 'ano';
    for (var p in state.entregues) {
      final d = p.createdAt;
      final k =
          isSemanal ? 'S\${(d.day/7).ceil()}-\${d.month}' : fmtDataShort(d);
      buckets[k] = (buckets[k] ?? 0.0) + p.total;
    }
    // Pega as últimas 14 instâncias pro gráfico
    final barData = buckets.entries
        .skip(buckets.length > 14 ? buckets.length - 14 : 0)
        .map((e) => BarChartItem(e.key, e.value))
        .toList();
    final sparkData = barData.map((e) => e.value).toList();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: const Color(0xFFF5F4F1), // Cor base painel
      drawer: isMobile
          ? SidebarMenu(activeId: 'finance', onItemSelected: (_) {})
          : null,
      body: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isMobile)
            SidebarMenu(activeId: 'finance', onItemSelected: (_) {}),
          Expanded(
            child: Column(
              children: [
                // TopBar
                Container(
                  height: 60,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    border:
                        Border(bottom: BorderSide(color: Color(0xFFEBEBEB))),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          if (isMobile) ...[
                            IconButton(
                              icon: const Icon(Icons.menu,
                                  color: Color(0xFF111827)),
                              onPressed: () =>
                                  _scaffoldKey.currentState?.openDrawer(),
                            ),
                            const SizedBox(width: 8),
                          ],
                          Container(
                            padding: const EdgeInsets.all(6),
                            decoration: BoxDecoration(
                                color: const Color(0xFFECFDF5),
                                borderRadius: BorderRadius.circular(8)),
                            child: const Icon(Icons.attach_money,
                                color: Color(0xFF10B981), size: 18),
                          ),
                          const SizedBox(width: 10),
                          Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Financeiro',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.bold,
                                      color: const Color(0xFF111827))),
                              Text(
                                  state.isLoading
                                      ? 'Carregando...'
                                      : '\${fmtNum(state.entregues.length)} pedidos entregues',
                                  style: GoogleFonts.publicSans(
                                      fontSize: 11,
                                      color: const Color(0xFF9CA3AF))),
                            ],
                          ),
                        ],
                      ),
                      Row(
                        children: [
                          // Botões de Período
                          if (!isMobile)
                            Container(
                              padding: const EdgeInsets.all(4),
                              decoration: BoxDecoration(
                                color: const Color(0xFFF9FAFB),
                                borderRadius: BorderRadius.circular(24),
                                border:
                                    Border.all(color: const Color(0xFFEBEBEB)),
                              ),
                              child: Row(
                                children: [
                                  _buildPeriodBtn('hoje', 'Hoje', state),
                                  _buildPeriodBtn('semana', '7 dias', state),
                                  _buildPeriodBtn('mes', 'Mês', state),
                                  _buildPeriodBtn('trimestre', 'Tri', state),
                                  _buildPeriodBtn('ano', 'Ano', state),
                                ],
                              ),
                            ),

                          const SizedBox(width: 8),
                          InkWell(
                            onTap: () => ref
                                .read(financeiroControllerProvider.notifier)
                                .carregarDadosIniciais(),
                            borderRadius: BorderRadius.circular(9),
                            child: Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border.all(
                                      color: const Color(0xFFE5E7EB)),
                                  borderRadius: BorderRadius.circular(9)),
                              child: state.isLoading
                                  ? const Padding(
                                      padding: EdgeInsets.all(8),
                                      child: CircularProgressIndicator(
                                          strokeWidth: 2))
                                  : const Icon(Icons.refresh,
                                      size: 16, color: Color(0xFF6B7280)),
                            ),
                          )
                        ],
                      ),
                    ],
                  ),
                ),

                // Filtro período mobile fallback
                if (isMobile)
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 20, vertical: 10),
                    alignment: Alignment.center,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF9FAFB),
                          borderRadius: BorderRadius.circular(24),
                          border: Border.all(color: const Color(0xFFEBEBEB)),
                        ),
                        child: Row(
                          children: [
                            _buildPeriodBtn('hoje', 'Hoje', state),
                            _buildPeriodBtn('semana', '7 dias', state),
                            _buildPeriodBtn('mes', 'Mês', state),
                            _buildPeriodBtn('trimestre', 'Tri', state),
                            _buildPeriodBtn('ano', 'Ano', state),
                          ],
                        ),
                      ),
                    ),
                  ),

                // Body content
                Expanded(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.all(22),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        if (state.error != null)
                          Container(
                            padding: const EdgeInsets.all(12),
                            margin: const EdgeInsets.only(bottom: 16),
                            color: Colors.red.shade50,
                            child: Text(state.error!,
                                style: const TextStyle(color: Colors.red)),
                          ),

                        // --- 1. KPIs ROW ---
                        ConstrainedBox(
                          constraints: const BoxConstraints(maxHeight: 400),
                          child: GridView.count(
                            crossAxisCount: isMobile ? 2 : 5,
                            childAspectRatio: isMobile ? 1.5 : 1.3,
                            crossAxisSpacing: 12,
                            mainAxisSpacing: 12,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            children: [
                              KpiCard(
                                loading: state.isLoading,
                                label: 'Faturamento bruto',
                                value: fmtMoeda(state.faturamentoBruto),
                                color: const Color(0xFF10B981),
                                bg: const Color(0xFFECFDF5),
                                icon: Icons.attach_money,
                                sparkData: sparkData,
                              ),
                              KpiCard(
                                loading: state.isLoading,
                                label: 'Receita líquida',
                                value: fmtMoeda(state.receitaLiquida),
                                sub: state.splits.isNotEmpty
                                    ? 'via splits reais'
                                    : 'estimativa 85%',
                                color: const Color(0xFF3B82F6),
                                bg: const Color(0xFFEFF6FF),
                                icon: Icons.account_balance_wallet_outlined,
                              ),
                              KpiCard(
                                loading: state.isLoading,
                                label: 'Ticket médio',
                                value: fmtMoeda(state.ticketMedio),
                                color: const Color(0xFF8B5CF6),
                                bg: const Color(0xFFF5F3FF),
                                icon: Icons.receipt_long_outlined,
                              ),
                              KpiCard(
                                loading: state.isLoading,
                                label: 'Taxa cancelamento',
                                value:
                                    '\${state.taxaCancelamento.toStringAsFixed(1)}%',
                                color: state.taxaCancelamento > 10
                                    ? const Color(0xFFEF4444)
                                    : const Color(0xFFF59E0B),
                                bg: state.taxaCancelamento > 10
                                    ? const Color(0xFFFEF2F2)
                                    : const Color(0xFFFFFBEB),
                                icon: Icons.info_outline,
                              ),
                              KpiCard(
                                loading: state.isLoading,
                                label: 'Total histórico',
                                value: fmtMoeda(
                                    state.estabelecimento?.faturamentoTotal ??
                                        0),
                                sub:
                                    '\${fmtNum(state.estabelecimento?.totalPedidos ?? 0)} pedidos',
                                color: const Color(0xFFF97316),
                                bg: const Color(0xFFFFF7ED),
                                icon: Icons.trending_up,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // --- 2. BREAKDOWN & GRAFICOS ---
                        if (isMobile)
                          Column(
                            children: [
                              _buildReceitaBreakdown(state),
                              const SizedBox(height: 14),
                              _buildGraficoEvolucao(state, barData),
                            ],
                          )
                        else
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              SizedBox(
                                  width: 320,
                                  child: _buildReceitaBreakdown(state)),
                              const SizedBox(width: 14),
                              Expanded(
                                  child: _buildGraficoEvolucao(state, barData)),
                            ],
                          ),

                        const SizedBox(height: 14),

                        // --- 3. TABS: METODOS, SPLITS, TRANSACOES ---
                        CardContainer(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              // Tab Header
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 16, vertical: 10),
                                decoration: const BoxDecoration(
                                    border: Border(
                                        bottom: BorderSide(
                                            color: Color(0xFFF3F4F6)))),
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Row(
                                      children: [
                                        _buildTabBtn(
                                            'metodos', 'Métodos de pagamento'),
                                        _buildTabBtn(
                                            'splits', 'Splits & repasses'),
                                        _buildTabBtn(
                                            'transacoes', 'Transações'),
                                      ],
                                    ),
                                    if (_tabExtra == 'transacoes' &&
                                        !state.isLoading)
                                      Text('\${validTx.length} transações',
                                          style: GoogleFonts.publicSans(
                                              fontSize: 11,
                                              color: const Color(0xFF9CA3AF))),
                                  ],
                                ),
                              ),

                              // Tab Content: Métodos
                              if (_tabExtra == 'metodos')
                                _buildMetodosTab(state, metodosArray),

                              // Tab Content: Splits
                              if (_tabExtra == 'splits') _buildSplitsTab(state),

                              // Tab Content: Transações
                              if (_tabExtra == 'transacoes')
                                _buildTransacoesTab(state, txList, txPages),
                            ],
                          ),
                        ),

                        const SizedBox(height: 14),

                        // --- 4. DADOS BANCARIOS ---
                        _buildDadosBancarios(state),

                        const SizedBox(height: 40), // spacer final
                      ],
                    ),
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  // --- BUILDERS METODOS AUXILIARES ---

  Widget _buildPeriodBtn(String key, String label, FinanceiroState state) {
    final active = state.periodoAtual == key;
    return InkWell(
      onTap: () => _mudaPeriodo(key),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        decoration: BoxDecoration(
          color: active ? const Color(0xFF111827) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: active ? const Color(0xFF111827) : const Color(0xFFE5E7EB),
              width: 1.5),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: active ? Colors.white : const Color(0xFF6B7280)),
        ),
      ),
    );
  }

  Widget _buildTabBtn(String key, String label) {
    final active = _tabExtra == key;
    return InkWell(
      onTap: () => setState(() => _tabExtra = key),
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: active ? const Color(0xFFFFF7ED) : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          label,
          style: GoogleFonts.publicSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color:
                  active ? const Color(0xFFF97316) : const Color(0xFF9CA3AF)),
        ),
      ),
    );
  }

  Widget _buildReceitaBreakdown(FinanceiroState state) {
    final denom = state.faturamentoBruto > 0 ? state.faturamentoBruto : 1.0;

    return CardContainer(
      child: Column(
        children: [
          CardHead(
              title: 'Composição da receita',
              icon: Icons.call_split_outlined,
              sub: state.periodoAtual.toUpperCase()),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                _buildBreakdownRow(
                    'Produtos',
                    state.receitaProdutos,
                    const Color(0xFF10B981),
                    (state.receitaProdutos / denom) * 100),
                _buildBreakdownRow(
                    'Taxa de entrega',
                    state.taxasEntrega,
                    const Color(0xFF3B82F6),
                    (state.taxasEntrega / denom) * 100),
                _buildBreakdownRow('Taxa do app', state.taxasApp,
                    const Color(0xFFF59E0B), (state.taxasApp / denom) * 100),
                _buildBreakdownRow(
                    'Descontos (cupons)',
                    -state.descontosCupom,
                    const Color(0xFFEF4444),
                    (state.descontosCupom / denom) * 100,
                    isNeg: true),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF0FDF4),
                    borderRadius: BorderRadius.circular(11),
                    border: Border.all(color: const Color(0xFFA7F3D0)),
                  ),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Receita líquida estimada',
                              style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: const Color(0xFF065F46))),
                          Text(fmtMoeda(state.receitaLiquida),
                              style: GoogleFonts.publicSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: const Color(0xFF10B981))),
                        ],
                      ),
                      if (state.splits.isEmpty)
                        Container(
                          width: double.infinity,
                          margin: const EdgeInsets.only(top: 4),
                          child: Text(
                              'Baseado em 85% do bruto (sem splits registrados)',
                              style: GoogleFonts.publicSans(
                                  fontSize: 10,
                                  color: const Color(0xFF6EE7B7))),
                        ),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFFFF7ED),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFFED7AA))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.hub_outlined,
                            size: 14, color: Color(0xFFF97316)),
                        const SizedBox(width: 6),
                        Text('Plataforma',
                            style: GoogleFonts.publicSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF92400E)))
                      ]),
                      Text(fmtMoeda(state.taxaPlataformaEstimativa),
                          style: GoogleFonts.publicSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFFF97316))),
                    ],
                  ),
                ),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                      color: const Color(0xFFEFF6FF),
                      borderRadius: BorderRadius.circular(11),
                      border: Border.all(color: const Color(0xFFBFDBFE))),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(children: [
                        const Icon(Icons.local_shipping_outlined,
                            size: 14, color: Color(0xFF3B82F6)),
                        const SizedBox(width: 6),
                        Text('Repasse entregadores',
                            style: GoogleFonts.publicSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF1E40AF)))
                      ]),
                      Text(fmtMoeda(state.repasseEntregadores),
                          style: GoogleFonts.publicSans(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: const Color(0xFF3B82F6))),
                    ],
                  ),
                ),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildBreakdownRow(String label, double val, Color color, double pct,
      {bool isNeg = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                          color: color,
                          borderRadius: BorderRadius.circular(2))),
                  const SizedBox(width: 7),
                  Text(label,
                      style: GoogleFonts.publicSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: const Color(0xFF374151))),
                ],
              ),
              Text(
                  isNeg && val != 0
                      ? '- \${fmtMoeda(val.abs())}'
                      : fmtMoeda(val),
                  style: GoogleFonts.publicSans(
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: isNeg
                          ? const Color(0xFFEF4444)
                          : const Color(0xFF111827))),
            ],
          ),
          const SizedBox(height: 5),
          Stack(
            children: [
              Container(
                  width: double.infinity,
                  height: 4,
                  decoration: BoxDecoration(
                      color: const Color(0xFFF3F4F6),
                      borderRadius: BorderRadius.circular(2))),
              AnimatedContainer(
                duration: const Duration(milliseconds: 400),
                width: MediaQuery.of(context).size.width *
                    (pct.clamp(0.0, 100.0) / 100.0) *
                    0.25, // approx width visually
                height: 4,
                decoration: BoxDecoration(
                    color: color, borderRadius: BorderRadius.circular(2)),
              ),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildGraficoEvolucao(
      FinanceiroState state, List<BarChartItem> barData) {
    return CardContainer(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          CardHead(
            title: 'Evolução do faturamento',
            icon: Icons.show_chart,
            sub: '\${barData.length} períodos no intervalo',
            right: Text(fmtMoeda(state.faturamentoBruto),
                style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: const Color(0xFF10B981))),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              children: [
                if (state.isLoading)
                  const SizedBox(
                      height: 130,
                      child: Center(child: CircularProgressIndicator()))
                else if (barData.isEmpty)
                  SizedBox(
                    height: 130,
                    child: Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text('📊', style: TextStyle(fontSize: 28)),
                          const SizedBox(height: 8),
                          Text('Sem dados no período',
                              style: GoogleFonts.publicSans(
                                  fontSize: 12,
                                  color: const Color(0xFF9CA3AF))),
                        ],
                      ),
                    ),
                  )
                else
                  BarChartWidget(
                      data: barData,
                      color: const Color(0xFF10B981),
                      height: 130),
                if (!state.isLoading)
                  Container(
                    margin: const EdgeInsets.only(top: 16),
                    padding: const EdgeInsets.only(top: 12),
                    decoration: const BoxDecoration(
                        border:
                            Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
                    child: Row(
                      children: [
                        _buildMiniResumo('Pedidos', state.pedidos.length,
                            const Color(0xFF374151)),
                        const SizedBox(width: 8),
                        _buildMiniResumo('Entregues', state.entregues.length,
                            const Color(0xFF10B981)),
                        const SizedBox(width: 8),
                        _buildMiniResumo('Cancelados', state.cancelados.length,
                            const Color(0xFFEF4444)),
                        const SizedBox(width: 8),
                        _buildMiniResumo('Em curso', state.emAndamento.length,
                            const Color(0xFFF97316)),
                      ],
                    ),
                  )
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildMiniResumo(String label, int val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            borderRadius: BorderRadius.circular(9)),
        child: Column(
          children: [
            Text(fmtNum(val),
                style: GoogleFonts.publicSans(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label.toUpperCase(),
                style: GoogleFonts.publicSans(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF),
                    letterSpacing: 0.4)),
          ],
        ),
      ),
    );
  }

  Widget _buildMetodosTab(
      FinanceiroState state, List<Map<String, dynamic>> metodosArray) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 140,
            height: 140,
            child: Stack(
              alignment: Alignment.center,
              children: [
                if (metodosArray.isNotEmpty)
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: DonutChartPainter(metodosArray
                        .map((e) => DonutSlice(
                            e['value'] as double, e['color'] as Color))
                        .toList()),
                  )
                else
                  CustomPaint(
                    size: const Size(120, 120),
                    painter: DonutChartPainter(
                        [DonutSlice(1, const Color(0xFFF3F4F6))]),
                  ),
                if (metodosArray.isEmpty)
                  Text('Vazio',
                      style: GoogleFonts.publicSans(
                          fontSize: 10, color: const Color(0xFF9CA3AF))),
              ],
            ),
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Column(
              children: metodosArray.isEmpty
                  ? [
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Text('Nenhum pagamento no período',
                            style: GoogleFonts.publicSans(
                                fontSize: 12, color: const Color(0xFF9CA3AF))),
                      )
                    ]
                  : metodosArray.map((m) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Container(
                                width: 10,
                                height: 10,
                                decoration: BoxDecoration(
                                    color: m['color'] as Color,
                                    borderRadius: BorderRadius.circular(3))),
                            const SizedBox(width: 10),
                            Expanded(
                                child: Text(m['label'] as String,
                                    style: GoogleFonts.publicSans(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: const Color(0xFF374151)))),
                            Text(fmtMoeda(m['value'] as double),
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827))),
                            SizedBox(
                                width: 48,
                                child: Text(
                                    "\${(m['pct'] as double).toStringAsFixed(1)}%",
                                    textAlign: TextAlign.right,
                                    style: GoogleFonts.publicSans(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: m['color'] as Color))),
                          ],
                        ),
                      );
                    }).toList(),
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSplitsTab(FinanceiroState state) {
    if (state.isLoading)
      return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()));

    if (state.splits.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Column(
          children: [
            const Text('🔀', style: TextStyle(fontSize: 32)),
            const SizedBox(height: 10),
            Text('Sem splits registrados no período',
                style: GoogleFonts.publicSans(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF374151))),
            Text('Os splits são criados automaticamente via pagamento online.',
                style: GoogleFonts.publicSans(
                    fontSize: 11, color: const Color(0xFF9CA3AF))),
          ],
        ),
      );
    }

    final sEst = state.splits.fold(0.0, (s, x) => s + x.estabelecimentoValor);
    final sPlat = state.splits.fold(0.0, (s, x) => s + x.plataformaValor);
    final sEnt = state.splits.fold(0.0, (s, x) => s + x.entregadorValorTotal);
    final sTotal = state.splits.fold(0.0, (s, x) => s + x.valorTotal);

    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        children: [
          Row(
            children: [
              _buildSplitMetric(
                  'Estabelecimento', sEst, const Color(0xFF10B981)),
              const SizedBox(width: 10),
              _buildSplitMetric('Plataforma', sPlat, const Color(0xFFF97316)),
              const SizedBox(width: 10),
              _buildSplitMetric('Entregadores', sEnt, const Color(0xFF3B82F6)),
              const SizedBox(width: 10),
              _buildSplitMetric(
                  'Total splits', sTotal, const Color(0xFF8B5CF6)),
            ],
          ),
          const SizedBox(height: 16),
          // Simulação de tabela
          Container(
            decoration: BoxDecoration(
                border: Border.all(color: const Color(0xFFEBEBEB)),
                borderRadius: BorderRadius.circular(12)),
            child: Column(
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                  decoration: const BoxDecoration(
                      color: Color(0xFFF9FAFB),
                      border:
                          Border(bottom: BorderSide(color: Color(0xFFEBEBEB)))),
                  child: Row(
                    children: [
                      SizedBox(
                          width: 80,
                          child: Text('PEDIDO', style: _tbHeadStyle())),
                      Expanded(child: Text('STATUS', style: _tbHeadStyle())),
                      SizedBox(
                          width: 80,
                          child: Text('ESTABELEC.', style: _tbHeadStyle())),
                      SizedBox(
                          width: 80,
                          child: Text('PLATAFORMA', style: _tbHeadStyle())),
                      SizedBox(
                          width: 80,
                          child: Text('TOTAL', style: _tbHeadStyle())),
                    ],
                  ),
                ),
                ...state.splits.take(10).map((s) {
                  return Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 14, vertical: 10),
                    decoration: const BoxDecoration(
                        border: Border(
                            bottom: BorderSide(color: Color(0xFFF9FAFB)))),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        SizedBox(
                            width: 80,
                            child: Text("#\${s.numeroPedido ?? '-'}",
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827)))),
                        Expanded(child: _buildStatusChip(s.status)),
                        SizedBox(
                            width: 80,
                            child: Text(fmtMoeda(s.estabelecimentoValor),
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF10B981)))),
                        SizedBox(
                            width: 80,
                            child: Text(fmtMoeda(s.plataformaValor),
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFFF97316)))),
                        SizedBox(
                            width: 80,
                            child: Text(fmtMoeda(s.valorTotal),
                                style: GoogleFonts.publicSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF111827)))),
                      ],
                    ),
                  );
                }),
              ],
            ),
          )
        ],
      ),
    );
  }

  Widget _buildSplitMetric(String label, double val, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
            color: const Color(0xFFF9FAFB),
            border: Border.all(color: const Color(0xFFEBEBEB)),
            borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label,
                style: GoogleFonts.publicSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF9CA3AF))),
            const SizedBox(height: 4),
            Text(fmtMoeda(val),
                style: GoogleFonts.publicSans(
                    fontSize: 17, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      ),
    );
  }

  Widget _buildTransacoesTab(
      FinanceiroState state, List<PedidoFinanceiro> txList, int txPages) {
    if (state.isLoading)
      return const Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()));
    if (txList.isEmpty)
      return Padding(
          padding: const EdgeInsets.all(40),
          child: Center(
              child: Text('Nenhuma transação no período',
                  style:
                      GoogleFonts.publicSans(color: const Color(0xFF9CA3AF)))));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          decoration: const BoxDecoration(
              color: Color(0xFFF9FAFB),
              border: Border(bottom: BorderSide(color: Color(0xFFEBEBEB)))),
          child: Row(
            children: [
              SizedBox(width: 80, child: Text('PEDIDO', style: _tbHeadStyle())),
              Expanded(flex: 2, child: Text('DATA', style: _tbHeadStyle())),
              Expanded(child: Text('STATUS', style: _tbHeadStyle())),
              Expanded(child: Text('MÉTODO', style: _tbHeadStyle())),
              Expanded(child: Text('DESCONTO', style: _tbHeadStyle())),
              SizedBox(
                  width: 80,
                  child: Text('TOTAL',
                      style: _tbHeadStyle(), textAlign: TextAlign.right)),
            ],
          ),
        ),
        ...txList.map((p) {
          final isCancelado = p.status.startsWith('cancelado');
          return Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: const BoxDecoration(
                border: Border(bottom: BorderSide(color: Color(0xFFF9FAFB)))),
            child: Row(
              children: [
                SizedBox(
                    width: 80,
                    child: Text('#\${p.numeroPedido}',
                        style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: const Color(0xFF374151)))),
                Expanded(
                    flex: 2,
                    child: Text(fmtDataShort(p.createdAt),
                        style: GoogleFonts.publicSans(
                            fontSize: 12, color: const Color(0xFF9CA3AF)))),
                Expanded(
                    child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildStatusChip(
                            isCancelado ? 'Cancelado' : 'Entregue'))),
                Expanded(
                    child: Text(_getPgtoLabel(p.pagamentoMetodo ?? ''),
                        style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getPgtoColor(p.pagamentoMetodo ?? '')))),
                Expanded(
                    child: Text(
                        p.descontoCupom > 0
                            ? '- \${fmtMoeda(p.descontoCupom)}'
                            : '—',
                        style: GoogleFonts.publicSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: p.descontoCupom > 0
                                ? const Color(0xFFEF4444)
                                : const Color(0xFFD1D5DB)))),
                SizedBox(
                    width: 80,
                    child: Text(fmtMoeda(p.total),
                        textAlign: TextAlign.right,
                        style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w800,
                            decoration:
                                isCancelado ? TextDecoration.lineThrough : null,
                            color: isCancelado
                                ? const Color(0xFF9CA3AF)
                                : const Color(0xFF111827)))),
              ],
            ),
          );
        }),
        if (txPages > 1)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: const BoxDecoration(
                border: Border(top: BorderSide(color: Color(0xFFF3F4F6)))),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                OutlinedButton(
                  onPressed:
                      _txPage > 0 ? () => setState(() => _txPage--) : null,
                  child: const Text('← Anterior'),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text('\${_txPage + 1} / \$txPages',
                      style: GoogleFonts.publicSans(
                          fontSize: 12, color: const Color(0xFF9CA3AF))),
                ),
                OutlinedButton(
                  onPressed: _txPage < txPages - 1
                      ? () => setState(() => _txPage++)
                      : null,
                  child: const Text('Próxima →'),
                ),
              ],
            ),
          )
      ],
    );
  }

  Widget _buildDadosBancarios(FinanceiroState state) {
    return CardContainer(
      child: Column(
        children: [
          const CardHead(
              title: 'Dados bancários cadastrados',
              icon: Icons.account_balance_outlined,
              sub: 'Usados para repasse financeiro'),
          Padding(
            padding: const EdgeInsets.all(18),
            child: state.isLoading
                ? const LinearProgressIndicator()
                : state.estabelecimento?.dadosBancarios == null ||
                        state.estabelecimento!.dadosBancarios!.isEmpty
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 20),
                        child: Column(
                          children: [
                            const Text('🏦', style: TextStyle(fontSize: 32)),
                            const SizedBox(height: 8),
                            Text('Nenhum dado bancário cadastrado',
                                style: GoogleFonts.publicSans(
                                    fontSize: 13,
                                    fontWeight: FontWeight.bold,
                                    color: const Color(0xFF374151))),
                            Text('Cadastre sua conta para receber repasses.',
                                style: GoogleFonts.publicSans(
                                    fontSize: 11,
                                    color: const Color(0xFF9CA3AF))),
                          ],
                        ),
                      )
                    : Wrap(
                        spacing: 12,
                        runSpacing: 12,
                        children: [
                          _buildBankField('Banco',
                              state.estabelecimento!.dadosBancarios!['banco']),
                          _buildBankField(
                              'Titular',
                              state
                                  .estabelecimento!.dadosBancarios!['titular']),
                          _buildBankField(
                              'Agência',
                              state
                                  .estabelecimento!.dadosBancarios!['agencia']),
                          _buildBankField('Conta',
                              "\${state.estabelecimento!.dadosBancarios!['conta'] ?? ''}-\${state.estabelecimento!.dadosBancarios!['conta_digito'] ?? ''}"),
                          _buildBankField(
                              'Tipo',
                              state.estabelecimento!
                                  .dadosBancarios!['tipo_conta']),
                          _buildBankField(
                              'Chave Pix',
                              state.estabelecimento!
                                  .dadosBancarios!['pix_chave']),
                          _buildBankField(
                              'CPF/CNPJ',
                              state.estabelecimento!
                                  .dadosBancarios!['cpf_cnpj_titular']),
                        ],
                      ),
          )
        ],
      ),
    );
  }

  Widget _buildBankField(String label, dynamic val) {
    if (val == null ||
        val.toString().trim() == '-' ||
        val.toString().trim().isEmpty) return const SizedBox.shrink();
    return Container(
      width: 160,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
          color: const Color(0xFFF9FAFB),
          border: Border.all(color: const Color(0xFFEBEBEB)),
          borderRadius: BorderRadius.circular(10)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(),
              style: GoogleFonts.publicSans(
                  fontSize: 9,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFF9CA3AF),
                  letterSpacing: 0.5)),
          const SizedBox(height: 4),
          Text(val.toString(),
              style: GoogleFonts.publicSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF111827))),
        ],
      ),
    );
  }

  // --- HELPERS CORE ---
  TextStyle _tbHeadStyle() => GoogleFonts.publicSans(
      fontSize: 10,
      fontWeight: FontWeight.bold,
      color: const Color(0xFF9CA3AF),
      letterSpacing: 0.5);

  Color _getPgtoColor(String m) {
    switch (m) {
      case 'pix':
        return const Color(0xFF10B981);
      case 'cartao_credito':
        return const Color(0xFF3B82F6);
      case 'cartao_debito':
        return const Color(0xFF8B5CF6);
      case 'boleto':
        return const Color(0xFFF59E0B);
      default:
        return const Color(0xFF6B7280);
    }
  }

  String _getPgtoLabel(String m) {
    switch (m) {
      case 'pix':
        return 'Pix';
      case 'cartao_credito':
        return 'Crédito';
      case 'cartao_debito':
        return 'Débito';
      case 'boleto':
        return 'Boleto';
      default:
        return 'Dinheiro/Local';
    }
  }

  Widget _buildStatusChip(String status) {
    final lower = status.toLowerCase();
    Color bg = const Color(0xFFFEF2F2);
    Color fg = const Color(0xFFEF4444);
    if (lower == 'entregue' || lower == 'processado') {
      bg = const Color(0xFFECFDF5);
      fg = const Color(0xFF10B981);
    } else if (lower == 'pendente') {
      bg = const Color(0xFFFFFBEB);
      fg = const Color(0xFFF59E0B);
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(status,
          style: GoogleFonts.publicSans(
              fontSize: 10, fontWeight: FontWeight.bold, color: fg)),
    );
  }
}
