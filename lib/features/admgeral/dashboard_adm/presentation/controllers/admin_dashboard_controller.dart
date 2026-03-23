import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../data/admin_dashboard_repository.dart';
import 'admin_dashboard_state.dart';

final adminDashboardRepositoryProvider = Provider<AdminDashboardRepository>((ref) {
  return AdminDashboardRepository(Supabase.instance.client);
});

final adminDashboardControllerProvider =
    StateNotifierProvider.autoDispose<AdminDashboardController, AdminDashboardState>((ref) {
  final repository = ref.watch(adminDashboardRepositoryProvider);
  return AdminDashboardController(repository);
});

class AdminDashboardController extends StateNotifier<AdminDashboardState> {
  final AdminDashboardRepository _repository;

  AdminDashboardController(this._repository) : super(const AdminDashboardState()) {
    fetchData();
  }

  Future<void> changePeriod(DashboardPeriod period) async {
    state = state.copyWith(selectedPeriod: period);
    await _fetchWithPeriod(period);
  }

  Future<void> fetchData() async {
    await _fetchWithPeriod(state.selectedPeriod);
  }

  Future<void> _fetchWithPeriod(DashboardPeriod period) async {
    if (!mounted) return;
    state = state.copyWith(isLoading: true, hasError: false, errorMessage: null);

    try {
      final data = await _repository.fetchDashboardStats(period);

      final estabs = _castList(data['estabelecimentos']);
      final entregadores = _castList(data['entregadores']);
      final usuarios = _castList(data['usuarios']);
      final pedidos = _castList(data['pedidos']);
      final splits = _castList(data['splits']);
      final chamados = _castList(data['chamados']);
      final pedidosPrev = _castList(data['pedidos_prev']);
      final splitsPrev = _castList(data['splits_prev']);
      final usuariosPrev = _castList(data['usuarios_prev']);

      // ── Estabelecimentos ────────────────────────────────────────────────
      final estabAtivos = estabs
          .where((e) => e['status_cadastro'] == 'aprovado' && e['status_aberto'] == true)
          .length;
      final estabPendentesList = estabs.where((e) => e['status_cadastro'] == 'pendente').toList();

      // ── Entregadores ─────────────────────────────────────────────────────
      final entregOnline = entregadores.where((e) => e['status_online'] == true).length;
      final entregPendentesList = entregadores.where((e) => e['status_cadastro'] == 'pendente').toList();

      // ── Usuários (período filtrado) ───────────────────────────────────────
      final totalClientes = usuarios.where((u) => u['tipo_usuario'] == 'cliente').length;

      // ── Pedidos ───────────────────────────────────────────────────────────
      final pedidosConcluidos = pedidos.where((p) => p['status'] == 'entregue').length;

      final receitaBruta = _somaField(
        pedidos.where((p) => p['status'] == 'entregue').toList(),
        'total',
      );

      // ── Splits / Receita plataforma ───────────────────────────────────────
      final receitaPlataforma = _somaField(splits, 'plataforma_valor');

      // ── Avaliação média real (null se nenhum estab tem avaliação > 0) ─────
      // avaliacao_media no banco pode ser default 5.0 sem avaliações reais;
      // consideramos válido apenas se algum estab tem avaliacoes reais.
      // Por ora: campo é nullable — retornamos null se todos os valores == 5.0 
      // com 0 reviews (não há tabela de avaliações sem dados). 
      // Melhor abordagem: somente exibir se houver COUNT de avaliações > 0.
      // Como não buscamos avaliacoes no momento, usamos null para indicar "sem dados".
      const double? avaliacaoMedia = null;

      // ── Deltas ────────────────────────────────────────────────────────────
      final receitaBrutaPrev = _somaField(
        pedidosPrev.where((p) => p['status'] == 'entregue').toList(),
        'total',
      );
      final receitaPlataformaPrev = _somaField(splitsPrev, 'plataforma_valor');
      final usuariosPrevCount = usuariosPrev.length;

      final deltaReceitaBruta = _calcDelta(receitaBruta, receitaBrutaPrev);
      final deltaReceitaPlataforma = _calcDelta(receitaPlataforma, receitaPlataformaPrev);
      final deltaUsuarios = _calcDelta(usuarios.length.toDouble(), usuariosPrevCount.toDouble());

      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        totalEstab: estabs.length,
        estabAtivos: estabAtivos,
        estabPendentesCount: estabPendentesList.length,
        totalEntregadores: entregadores.length,
        entregOnline: entregOnline,
        entregPendentesCount: entregPendentesList.length,
        totalUsuarios: usuarios.length,
        totalClientes: totalClientes,
        totalPedidos: pedidos.length,
        pedidosConcluidos: pedidosConcluidos,
        receitaBruta: receitaBruta,
        receitaPlataforma: receitaPlataforma,
        chamadosAbertosCount: chamados.length,
        avaliacaoMedia: avaliacaoMedia,
        deltaReceitaPlataforma: deltaReceitaPlataforma,
        deltaReceitaBruta: deltaReceitaBruta,
        deltaUsuarios: deltaUsuarios,
        estabPendentes: estabPendentesList,
        entregPendentes: entregPendentesList,
        chamadosRecentes: chamados.take(3).toList(),
        lastSync: DateTime.now(),
      );
    } catch (e) {
      if (!mounted) return;
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Não foi possível carregar os dados. Verifique sua conexão.',
      );
    }
  }

  // ── Helpers ────────────────────────────────────────────────────────────────

  List<Map<String, dynamic>> _castList(dynamic value) =>
      (value as List?)?.cast<Map<String, dynamic>>() ?? [];

  double _somaField(List<Map<String, dynamic>> list, String field) =>
      list.fold(0.0, (sum, item) => sum + ((item[field] as num?)?.toDouble() ?? 0.0));

  /// Retorna o delta percentual entre atual e anterior.
  /// Retorna null se não houver dado anterior (evita divisão por zero e badges mentirosos).
  double? _calcDelta(double current, double previous) {
    if (previous == 0) {
      // Sem dados anteriores — exibe "—" no card
      return null;
    }
    return ((current - previous) / previous) * 100;
  }
}
