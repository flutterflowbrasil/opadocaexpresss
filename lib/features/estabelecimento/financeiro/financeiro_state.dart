import 'models/financeiro_models.dart';

class FinanceiroState {
  final bool isLoading;
  final String? error;

  // Dados Brutos
  final EstabelecimentoFinanceiro? estabelecimento;
  final List<PedidoFinanceiro> pedidos;
  final List<SplitFinanceiro> splits;

  // Filtro
  final String periodoAtual; // 'hoje', 'semana', 'mes', 'trimestre', 'ano'

  FinanceiroState({
    this.isLoading = false,
    this.error,
    this.estabelecimento,
    this.pedidos = const [],
    this.splits = const [],
    this.periodoAtual = 'mes',
  });

  FinanceiroState copyWith({
    bool? isLoading,
    String? error,
    EstabelecimentoFinanceiro? estabelecimento,
    List<PedidoFinanceiro>? pedidos,
    List<SplitFinanceiro>? splits,
    String? periodoAtual,
  }) {
    return FinanceiroState(
      isLoading: isLoading ?? this.isLoading,
      error: error, // se não passar error, vira nulo (limpa erros por padrão)
      estabelecimento: estabelecimento ?? this.estabelecimento,
      pedidos: pedidos ?? this.pedidos,
      splits: splits ?? this.splits,
      periodoAtual: periodoAtual ?? this.periodoAtual,
    );
  }

  // --- GETTERS COMPUTADOS (Mesma lógica do React financeiro.md) ---

  List<PedidoFinanceiro> get entregues =>
      pedidos.where((p) => p.status == 'entregue').toList();

  List<PedidoFinanceiro> get cancelados =>
      pedidos.where((p) => p.status.startsWith('cancelado')).toList();

  List<PedidoFinanceiro> get emAndamento => pedidos
      .where((p) => !p.status.startsWith('cancelado') && p.status != 'entregue')
      .toList();

  double get faturamentoBruto => entregues.fold(0.0, (sum, p) => sum + p.total);

  double get receitaProdutos =>
      entregues.fold(0.0, (sum, p) => sum + p.subtotalProdutos);

  double get taxasEntrega =>
      entregues.fold(0.0, (sum, p) => sum + p.taxaEntrega);

  double get taxasApp =>
      entregues.fold(0.0, (sum, p) => sum + p.taxaServicoApp);

  double get descontosCupom =>
      entregues.fold(0.0, (sum, p) => sum + p.descontoCupom);

  double get ticketMedio =>
      entregues.isEmpty ? 0 : faturamentoBruto / entregues.length;

  double get taxaCancelamento =>
      pedidos.isEmpty ? 0 : (cancelados.length / pedidos.length) * 100;

  // Receita Líquida Estimada: se há splits, usa o split correto, senão tira 15%
  double get receitaLiquida {
    if (splits.isNotEmpty) {
      return splits.fold(0.0, (sum, s) => sum + s.estabelecimentoValor);
    }
    return faturamentoBruto * 0.85;
  }

  double get taxaPlataformaEstimativa {
    if (splits.isNotEmpty) {
      return splits.fold(0.0, (sum, s) => sum + s.plataformaValor);
    }
    return faturamentoBruto * 0.05; // app fica com 5%? Depende do Padoca
  }

  double get repasseEntregadores {
    if (splits.isNotEmpty) {
      return splits.fold(0.0, (sum, s) => sum + s.entregadorValorTotal);
    }
    return taxasEntrega * 0.8;
  }
}
