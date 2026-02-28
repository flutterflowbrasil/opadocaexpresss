import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/features/estabelecimento/dashboard/dashboard_repository.dart';

class DashboardState {
  final bool isLoading;
  final String? error;

  // Metrics
  final double vendasHoje;
  final int pedidosAtivos;
  final double ticketMedio;
  final double avaliacaoMedia;

  // Lists
  final List<Map<String, dynamic>> maisVendidos;
  final List<Map<String, dynamic>> pedidosRecentes;

  // Estabelecimento Auth Info
  final String? estabelecimentoNome;
  final String? estabelecimentoId;

  DashboardState({
    this.isLoading = false,
    this.error,
    this.vendasHoje = 0.0,
    this.pedidosAtivos = 0,
    this.ticketMedio = 0.0,
    this.avaliacaoMedia = 0.0,
    this.maisVendidos = const [],
    this.pedidosRecentes = const [],
    this.estabelecimentoNome,
    this.estabelecimentoId,
  });

  DashboardState copyWith({
    bool? isLoading,
    String? error,
    double? vendasHoje,
    int? pedidosAtivos,
    double? ticketMedio,
    double? avaliacaoMedia,
    List<Map<String, dynamic>>? maisVendidos,
    List<Map<String, dynamic>>? pedidosRecentes,
    String? estabelecimentoNome,
    String? estabelecimentoId,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      error:
          error, // Clear error if null is passed? Actually for copyWith usually we don't clear error if null, but let's assume we do if we pass null explicitly. Well, standard copyWith idiom:
      vendasHoje: vendasHoje ?? this.vendasHoje,
      pedidosAtivos: pedidosAtivos ?? this.pedidosAtivos,
      ticketMedio: ticketMedio ?? this.ticketMedio,
      avaliacaoMedia: avaliacaoMedia ?? this.avaliacaoMedia,
      maisVendidos: maisVendidos ?? this.maisVendidos,
      pedidosRecentes: pedidosRecentes ?? this.pedidosRecentes,
      estabelecimentoNome: estabelecimentoNome ?? this.estabelecimentoNome,
      estabelecimentoId: estabelecimentoId ?? this.estabelecimentoId,
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
            isLoading: false, error: 'Estabelecimento não encontrado');
        return;
      }

      final estabId = authEstab['id'] as String;
      final nome = authEstab['nome_fantasia'] ??
          authEstab['razao_social'] ??
          'Meu Estabelecimento';

      // Here we would run the queries. For now, we mock some dashboard data,
      // but we will implement the real queries in the repository.
      final metricas = await _repository.getMetricasHoje(estabId);
      final maisVendidos = await _repository.getMaisVendidos(estabId);
      final recentes = await _repository.getPedidosRecentes(estabId);

      state = state.copyWith(
        isLoading: false,
        estabelecimentoId: estabId,
        estabelecimentoNome: nome,
        vendasHoje: metricas['vendasHoje'] ?? 0.0,
        pedidosAtivos: metricas['pedidosAtivos'] ?? 0,
        ticketMedio: metricas['ticketMedio'] ?? 0.0,
        avaliacaoMedia:
            (authEstab['avaliacao_media'] as num?)?.toDouble() ?? 5.0,
        maisVendidos: maisVendidos,
        pedidosRecentes: recentes,
      );
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  Future<void> recarregar() async {
    await _init();
  }
}

final dashboardControllerProvider =
    StateNotifierProvider<DashboardController, DashboardState>((ref) {
  final repository = ref.watch(dashboardRepositoryProvider);
  return DashboardController(repository);
});
