import '../../data/admin_dashboard_repository.dart';

class AdminDashboardState {
  final bool isLoading;
  final bool hasError;
  final String? errorMessage;

  // Período selecionado
  final DashboardPeriod selectedPeriod;

  // KPIs reais — período atual
  final int totalEstab;
  final int estabAtivos;
  final int estabPendentesCount;
  final int totalEntregadores;
  final int entregOnline;
  final int entregPendentesCount;
  final int totalUsuarios;          // usuários cadastrados no período
  final int totalClientes;          // clientes no período
  final int totalPedidos;
  final int pedidosConcluidos;
  final double receitaBruta;
  final double receitaPlataforma;
  final int chamadosAbertosCount;
  final double? avaliacaoMedia;     // null = nenhuma avaliação real ainda

  // Deltas calculados vs período anterior.
  // null = sem dados anteriores para comparar (exibe "—").
  final double? deltaReceitaPlataforma;  // ex: 50.0 = +50%
  final double? deltaReceitaBruta;
  final double? deltaUsuarios;

  // Listas
  final List<Map<String, dynamic>> estabPendentes;
  final List<Map<String, dynamic>> entregPendentes;
  final List<Map<String, dynamic>> chamadosRecentes;

  final DateTime? lastSync;

  const AdminDashboardState({
    this.isLoading = false,
    this.hasError = false,
    this.errorMessage,
    this.selectedPeriod = DashboardPeriod.mes,
    this.totalEstab = 0,
    this.estabAtivos = 0,
    this.estabPendentesCount = 0,
    this.totalEntregadores = 0,
    this.entregOnline = 0,
    this.entregPendentesCount = 0,
    this.totalUsuarios = 0,
    this.totalClientes = 0,
    this.totalPedidos = 0,
    this.pedidosConcluidos = 0,
    this.receitaBruta = 0.0,
    this.receitaPlataforma = 0.0,
    this.chamadosAbertosCount = 0,
    this.avaliacaoMedia,
    this.deltaReceitaPlataforma,
    this.deltaReceitaBruta,
    this.deltaUsuarios,
    this.estabPendentes = const [],
    this.entregPendentes = const [],
    this.chamadosRecentes = const [],
    this.lastSync,
  });

  AdminDashboardState copyWith({
    bool? isLoading,
    bool? hasError,
    String? errorMessage,
    DashboardPeriod? selectedPeriod,
    int? totalEstab,
    int? estabAtivos,
    int? estabPendentesCount,
    int? totalEntregadores,
    int? entregOnline,
    int? entregPendentesCount,
    int? totalUsuarios,
    int? totalClientes,
    int? totalPedidos,
    int? pedidosConcluidos,
    double? receitaBruta,
    double? receitaPlataforma,
    int? chamadosAbertosCount,
    // nullable fields: use Object? sentinel to distinguish "set to null" vs "keep"
    Object? avaliacaoMedia = _keep,
    Object? deltaReceitaPlataforma = _keep,
    Object? deltaReceitaBruta = _keep,
    Object? deltaUsuarios = _keep,
    List<Map<String, dynamic>>? estabPendentes,
    List<Map<String, dynamic>>? entregPendentes,
    List<Map<String, dynamic>>? chamadosRecentes,
    DateTime? lastSync,
  }) {
    return AdminDashboardState(
      isLoading: isLoading ?? this.isLoading,
      hasError: hasError ?? this.hasError,
      errorMessage: errorMessage,
      selectedPeriod: selectedPeriod ?? this.selectedPeriod,
      totalEstab: totalEstab ?? this.totalEstab,
      estabAtivos: estabAtivos ?? this.estabAtivos,
      estabPendentesCount: estabPendentesCount ?? this.estabPendentesCount,
      totalEntregadores: totalEntregadores ?? this.totalEntregadores,
      entregOnline: entregOnline ?? this.entregOnline,
      entregPendentesCount: entregPendentesCount ?? this.entregPendentesCount,
      totalUsuarios: totalUsuarios ?? this.totalUsuarios,
      totalClientes: totalClientes ?? this.totalClientes,
      totalPedidos: totalPedidos ?? this.totalPedidos,
      pedidosConcluidos: pedidosConcluidos ?? this.pedidosConcluidos,
      receitaBruta: receitaBruta ?? this.receitaBruta,
      receitaPlataforma: receitaPlataforma ?? this.receitaPlataforma,
      chamadosAbertosCount: chamadosAbertosCount ?? this.chamadosAbertosCount,
      avaliacaoMedia: avaliacaoMedia == _keep ? this.avaliacaoMedia : avaliacaoMedia as double?,
      deltaReceitaPlataforma: deltaReceitaPlataforma == _keep ? this.deltaReceitaPlataforma : deltaReceitaPlataforma as double?,
      deltaReceitaBruta: deltaReceitaBruta == _keep ? this.deltaReceitaBruta : deltaReceitaBruta as double?,
      deltaUsuarios: deltaUsuarios == _keep ? this.deltaUsuarios : deltaUsuarios as double?,
      estabPendentes: estabPendentes ?? this.estabPendentes,
      entregPendentes: entregPendentes ?? this.entregPendentes,
      chamadosRecentes: chamadosRecentes ?? this.chamadosRecentes,
      lastSync: lastSync ?? this.lastSync,
    );
  }
}

// Sentinel para distinguir "não passou" de "passou null" no copyWith
const _keep = Object();
