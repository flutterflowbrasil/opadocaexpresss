import '../models/financeiro_adm_models.dart';

class FinanceiroAdmState {
  final bool isLoading;
  final String? errorMessage;
  final List<PedidoFinanceiro> pedidos;
  final List<SplitPagamento> splits;
  final List<EntregadorSaque> saques;
  final List<AsaasSubconta> subcontas;
  final String abaAtiva;
  final String filtroMetodo;       // todos | pix | cartao_credito | cartao_debito | dinheiro | boleto
  final String filtroPgtoStatus;   // todos | pago | confirmed | pendente | refunded | overdue
  final String filtroSplit;        // todos | processado | nao_processado
  final DateTime? lastSync;

  const FinanceiroAdmState({
    this.isLoading = true,
    this.errorMessage,
    this.pedidos = const [],
    this.splits = const [],
    this.saques = const [],
    this.subcontas = const [],
    this.abaAtiva = 'visao_geral',
    this.filtroMetodo = 'todos',
    this.filtroPgtoStatus = 'todos',
    this.filtroSplit = 'todos',
    this.lastSync,
  });

  // ── KPIs computados ──────────────────────────────────────────────────────────

  double get totalBruto =>
      pedidos.fold(0.0, (acc, p) => acc + p.total);

  double get receitaPlataforma =>
      pedidos.fold(0.0, (acc, p) => acc + p.taxaServico);

  int get splitsPendentes => pedidos
      .where((p) =>
          !p.splitProcessado &&
          (p.pagamentoStatus == 'pago' || p.pagamentoStatus == 'confirmed'))
      .length;

  double get totalSaquesConcluidos => saques
      .where((s) => s.status == 'concluido')
      .fold(0.0, (acc, s) => acc + s.valor);

  // ── Lista de pedidos filtrada ─────────────────────────────────────────────────

  List<PedidoFinanceiro> get pedidosFiltrados {
    return pedidos.where((p) {
      final matchMetodo =
          filtroMetodo == 'todos' || p.pagamentoMetodo == filtroMetodo;
      final matchStatus =
          filtroPgtoStatus == 'todos' || p.pagamentoStatus == filtroPgtoStatus;
      final matchSplit = filtroSplit == 'todos' ||
          (filtroSplit == 'processado' && p.splitProcessado) ||
          (filtroSplit == 'nao_processado' && !p.splitProcessado);
      return matchMetodo && matchStatus && matchSplit;
    }).toList();
  }

  // ── Dados para gráficos ───────────────────────────────────────────────────────

  /// Agrupa pedidos dos últimos 7 dias por dia (índice 0 = mais antigo).
  List<Map<String, dynamic>> get receitaSemanal {
    final agora = DateTime.now();
    final dias = List.generate(7, (i) {
      final d = agora.subtract(Duration(days: 6 - i));
      return {
        'dia': _diaSemana(d.weekday),
        'receita': 0.0,
        'plataforma': 0.0,
        'pedidos': 0,
      };
    });

    for (final p in pedidos) {
      if (p.status != 'entregue') continue;
      final diff = agora.difference(p.createdAt).inDays;
      if (diff < 0 || diff > 6) continue;
      final idx = 6 - diff;
      dias[idx]['receita'] = (dias[idx]['receita'] as double) + p.total;
      dias[idx]['plataforma'] =
          (dias[idx]['plataforma'] as double) + p.taxaServico;
      dias[idx]['pedidos'] = (dias[idx]['pedidos'] as int) + 1;
    }
    return dias;
  }

  /// Agrupa pedidos entregues por método de pagamento.
  Map<String, double> get distribuicaoPorMetodo {
    final mapa = <String, double>{};
    for (final p in pedidos) {
      if (p.status != 'entregue') continue;
      mapa[p.pagamentoMetodo] = (mapa[p.pagamentoMetodo] ?? 0) + p.total;
    }
    return mapa;
  }

  bool get isEmpty =>
      !isLoading && pedidos.isEmpty && errorMessage == null;

  FinanceiroAdmState copyWith({
    bool? isLoading,
    String? errorMessage,
    List<PedidoFinanceiro>? pedidos,
    List<SplitPagamento>? splits,
    List<EntregadorSaque>? saques,
    List<AsaasSubconta>? subcontas,
    String? abaAtiva,
    String? filtroMetodo,
    String? filtroPgtoStatus,
    String? filtroSplit,
    DateTime? lastSync,
    bool clearError = false,
  }) {
    return FinanceiroAdmState(
      isLoading: isLoading ?? this.isLoading,
      errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
      pedidos: pedidos ?? this.pedidos,
      splits: splits ?? this.splits,
      saques: saques ?? this.saques,
      subcontas: subcontas ?? this.subcontas,
      abaAtiva: abaAtiva ?? this.abaAtiva,
      filtroMetodo: filtroMetodo ?? this.filtroMetodo,
      filtroPgtoStatus: filtroPgtoStatus ?? this.filtroPgtoStatus,
      filtroSplit: filtroSplit ?? this.filtroSplit,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

String _diaSemana(int weekday) {
  const nomes = {
    DateTime.monday: 'Seg',
    DateTime.tuesday: 'Ter',
    DateTime.wednesday: 'Qua',
    DateTime.thursday: 'Qui',
    DateTime.friday: 'Sex',
    DateTime.saturday: 'Sáb',
    DateTime.sunday: 'Dom',
  };
  return nomes[weekday] ?? '?';
}
