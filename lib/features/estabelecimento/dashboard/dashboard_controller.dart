import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_repository.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/components/period_filter_bar.dart';

class DashboardState {
  final bool isLoading;
  final String? error;

  // Estabelecimento Auth Info
  final String? estabelecimentoNome;
  final String? estabelecimentoId;
  final bool isLojaAberta;

  // Filtros
  final DashboardPeriodo periodoAtual;
  final DateTime? dataCustomizada;

  // Metrics
  final double vendasTotal;
  final int totalPedidos;
  final int pedidosAtivos;
  final double ticketMedio;
  final double avaliacaoMedia;

  // KPIs de comparação (mock)
  final double deltaVendas;
  final int deltaPedidos;
  final double deltaTicket;
  final double deltaAvaliacao;

  // Funil
  final int pendentes;
  final int confirmados;
  final int preparando;
  final int prontos;
  final int emEntrega;
  final int entregues;

  // Lists
  final List<Map<String, dynamic>> ranking;
  final Map<String, double> vendasPorDia;
  final int clientesUnicos;
  final int clientesNovos;
  final int clientesRecorrentes;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.estabelecimentoNome,
    this.estabelecimentoId,
    this.isLojaAberta = true,
    this.periodoAtual = DashboardPeriodo.hoje,
    this.dataCustomizada,
    this.vendasTotal = 0.0,
    this.totalPedidos = 0,
    this.pedidosAtivos = 0,
    this.ticketMedio = 0.0,
    this.avaliacaoMedia = 0.0,
    this.deltaVendas = 0.0,
    this.deltaPedidos = 0,
    this.deltaTicket = 0.0,
    this.deltaAvaliacao = 0.0,
    this.pendentes = 0,
    this.confirmados = 0,
    this.preparando = 0,
    this.prontos = 0,
    this.emEntrega = 0,
    this.entregues = 0,
    this.ranking = const [],
    this.vendasPorDia = const {},
    this.clientesUnicos = 0,
    this.clientesNovos = 0,
    this.clientesRecorrentes = 0,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    String? estabelecimentoNome,
    String? estabelecimentoId,
    bool? isLojaAberta,
    DashboardPeriodo? periodoAtual,
    DateTime? dataCustomizada,
    double? vendasTotal,
    int? totalPedidos,
    int? pedidosAtivos,
    double? ticketMedio,
    double? avaliacaoMedia,
    double? deltaVendas,
    int? deltaPedidos,
    double? deltaTicket,
    double? deltaAvaliacao,
    int? pendentes,
    int? confirmados,
    int? preparando,
    int? prontos,
    int? emEntrega,
    int? entregues,
    List<Map<String, dynamic>>? ranking,
    Map<String, double>? vendasPorDia,
    int? clientesUnicos,
    int? clientesNovos,
    int? clientesRecorrentes,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // se não for nulo na chamada, o CopyWith substitui e vice versa para Error
      estabelecimentoNome: estabelecimentoNome ?? this.estabelecimentoNome,
      estabelecimentoId: estabelecimentoId ?? this.estabelecimentoId,
      isLojaAberta: isLojaAberta ?? this.isLojaAberta,
      periodoAtual: periodoAtual ?? this.periodoAtual,
      dataCustomizada: dataCustomizada ??
          this.dataCustomizada, // Cuidado aqui, para limpar pode ser necessário um approach diferente, mas pra MVVM isso serve
      vendasTotal: vendasTotal ?? this.vendasTotal,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      pedidosAtivos: pedidosAtivos ?? this.pedidosAtivos,
      ticketMedio: ticketMedio ?? this.ticketMedio,
      avaliacaoMedia: avaliacaoMedia ?? this.avaliacaoMedia,
      deltaVendas: deltaVendas ?? this.deltaVendas,
      deltaPedidos: deltaPedidos ?? this.deltaPedidos,
      deltaTicket: deltaTicket ?? this.deltaTicket,
      deltaAvaliacao: deltaAvaliacao ?? this.deltaAvaliacao,
      pendentes: pendentes ?? this.pendentes,
      confirmados: confirmados ?? this.confirmados,
      preparando: preparando ?? this.preparando,
      prontos: prontos ?? this.prontos,
      emEntrega: emEntrega ?? this.emEntrega,
      entregues: entregues ?? this.entregues,
      ranking: ranking ?? this.ranking,
      vendasPorDia: vendasPorDia ?? this.vendasPorDia,
      clientesUnicos: clientesUnicos ?? this.clientesUnicos,
      clientesNovos: clientesNovos ?? this.clientesNovos,
      clientesRecorrentes: clientesRecorrentes ?? this.clientesRecorrentes,
    );
  }
}

class DashboardController extends StateNotifier<DashboardState> {
  final DashboardRepository _repository;

  DashboardController(this._repository) : super(DashboardState()) {
    _init();
  }

  Future<void> _init() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final authEstab = await _repository.getEstabelecimentoLogado();
      if (authEstab == null) {
        state = state.copyWith(
            isLoading: false, error: 'Estabelecimento não logado.');
        return;
      }

      final estabId = authEstab['id'] as String;
      final nome = authEstab['nome_fantasia'] ??
          authEstab['razao_social'] ??
          'Meu Estabelecimento';
      final isAberto = authEstab['status_aberto'] as bool? ?? true;
      final avaliacao =
          (authEstab['avaliacao_media'] as num?)?.toDouble() ?? 5.0;

      state = state.copyWith(
        estabelecimentoId: estabId,
        estabelecimentoNome: nome,
        isLojaAberta: isAberto,
        avaliacaoMedia: avaliacao,
      );

      await _fetchMetricsForPeriod();
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> _fetchMetricsForPeriod() async {
    if (state.estabelecimentoId == null) return;

    state = state.copyWith(isLoading: true, error: null);
    try {
      DateTime inicio;
      DateTime fim = DateTime.now();

      if (state.periodoAtual == DashboardPeriodo.custom &&
          state.dataCustomizada != null) {
        inicio = state.dataCustomizada!
            .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
        fim = state.dataCustomizada!.copyWith(hour: 23, minute: 59, second: 59);
      } else {
        switch (state.periodoAtual) {
          case DashboardPeriodo.semana:
            inicio = fim
                .subtract(Duration(days: fim.weekday - 1))
                .copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
            break;
          case DashboardPeriodo.mes:
            inicio = DateTime(fim.year, fim.month, 1);
            break;
          case DashboardPeriodo.hoje:
          default:
            inicio =
                fim.copyWith(hour: 0, minute: 0, second: 0, millisecond: 0);
            break;
        }
      }

      final result = await _repository.getDashboardMetrics(
          state.estabelecimentoId!, inicio, fim);

      state = state.copyWith(
        isLoading: false,
        vendasTotal: result['vendasTotal'],
        pedidosAtivos: result['pedidosAtivos'],
        ticketMedio: result['ticketMedio'],
        totalPedidos: result['totalPedidos'],
        pendentes: result['pendentes'],
        confirmados: result['confirmados'],
        preparando: result['preparando'],
        prontos: result['prontos'],
        emEntrega: result['emEntrega'],
        entregues: result['entregues'],
        vendasPorDia: result['vendasPorDia'],
        ranking: result['ranking'],
        clientesUnicos: result['clientesUnicos'],
        clientesNovos: result['clientesNovos'] ?? 0,
        clientesRecorrentes: result['clientesRecorrentes'] ?? 0,

        // Apply Real Deltas from repository
        deltaVendas: result['deltaVendas'] ?? 0.0,
        deltaPedidos: result['deltaPedidos'] ?? 0,
        deltaTicket: result['deltaTicket'] ?? 0.0,
        deltaAvaliacao:
            0.0, // Avaliacao kept as mock for now, not currently captured historically.
      );
    } catch (e, stacktrace) {
      print('=== ERRO NO DASHBOARD ===');
      print(e);
      print(stacktrace);
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  void mudarPeriodo(DashboardPeriodo periodo, DateTime? date) {
    if (state.periodoAtual == periodo && state.dataCustomizada == date) return;
    state = DashboardState(
      estabelecimentoId: state.estabelecimentoId,
      estabelecimentoNome: state.estabelecimentoNome,
      isLojaAberta: state.isLojaAberta,
      avaliacaoMedia: state.avaliacaoMedia,
      periodoAtual: periodo,
      dataCustomizada: date,
      isLoading: true,
    );
    _fetchMetricsForPeriod();
  }

  Future<void> recarregar() async {
    await _fetchMetricsForPeriod();
  }

  Future<bool> toggleStoreStatus(bool isOpen, {String? motivo}) async {
    if (state.estabelecimentoId == null) return false;

    final previousState = state.isLojaAberta;
    // Update optimistic
    state = state.copyWith(isLojaAberta: isOpen);

    final success = await _repository.updateStoreStatus(
      state.estabelecimentoId!,
      isOpen,
      motivoFechamento: motivo,
    );

    if (!success) {
      // Rollback se falhar
      state = state.copyWith(isLojaAberta: previousState);
      return false;
    }

    return true;
  }
}

// Memory Leak Prevention: Use autoDispose sem keepAlive na Controller principal
final dashboardControllerProvider =
    StateNotifierProvider.autoDispose<DashboardController, DashboardState>(
        (ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});
