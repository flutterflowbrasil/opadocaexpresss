// ── Models ───────────────────────────────────────────────────────────────────

class EntregaRecente {
  final String id;
  final int? numeroPedido;
  final String nomeEstabelecimento;
  final String? logoUrl;
  final double valorEntregador;
  final DateTime? entregueEm;

  const EntregaRecente({
    required this.id,
    this.numeroPedido,
    required this.nomeEstabelecimento,
    this.logoUrl,
    required this.valorEntregador,
    this.entregueEm,
  });

  factory EntregaRecente.fromJson(Map<String, dynamic> json) {
    final estab = json['estabelecimentos'] as Map<String, dynamic>?;
    final splits = json['splits_pagamento'] as Map<String, dynamic>?;
    return EntregaRecente(
      id: json['id'] as String,
      numeroPedido: json['numero_pedido'] as int?,
      nomeEstabelecimento:
          estab?['nome_fantasia'] as String? ??
          estab?['razao_social'] as String? ??
          'Estabelecimento',
      logoUrl: estab?['logo_url'] as String?,
      valorEntregador:
          (splits?['entregador_valor_total'] as num?)?.toDouble() ??
          (json['taxa_entrega'] as num?)?.toDouble() ??
          0.0,
      entregueEm: json['entregue_em'] != null
          ? DateTime.tryParse(json['entregue_em'] as String)
          : null,
    );
  }
}

class PedidoAtivo {
  final String id;
  final int? numeroPedido;
  final String status;
  final String nomeEstabelecimento;
  final String enderecoEntrega;
  final double total;

  const PedidoAtivo({
    required this.id,
    this.numeroPedido,
    required this.status,
    required this.nomeEstabelecimento,
    required this.enderecoEntrega,
    required this.total,
  });

  factory PedidoAtivo.fromJson(Map<String, dynamic> json) {
    final estab = json['estabelecimentos'] as Map<String, dynamic>?;
    final end = json['endereco_entrega_snapshot'] as Map<String, dynamic>?;
    final logradouro = end?['logradouro'] as String? ?? '';
    final numero = end?['numero'] as String? ?? '';
    final bairro = end?['bairro'] as String? ?? '';
    return PedidoAtivo(
      id: json['id'] as String,
      numeroPedido: json['numero_pedido'] as int?,
      status: json['status'] as String? ?? 'em_entrega',
      nomeEstabelecimento:
          estab?['nome_fantasia'] as String? ??
          estab?['razao_social'] as String? ??
          'Estabelecimento',
      enderecoEntrega: '$logradouro, $numero - $bairro'.trim(),
      total: (json['total'] as num?)?.toDouble() ?? 0.0,
    );
  }
}

class DespachoRecebido {
  final String id;
  final String pedidoId;
  final double distanciaKm;
  final double valorEntrega;
  final DateTime expiraEm;

  const DespachoRecebido({
    required this.id,
    required this.pedidoId,
    required this.distanciaKm,
    required this.valorEntrega,
    required this.expiraEm,
  });
}

// ── State ────────────────────────────────────────────────────────────────────

class DashboardState {
  final bool isLoading;
  final bool isTogglingStatus;
  final bool isRespondingDespacho;
  final String? error;

  // Profile
  final String driverId;
  final String driverName;
  final String vehicleType;
  final String? fotoPerfilUrl;
  final bool isOnline;
  final double searchRadius;
  final String statusDespacho; // 'livre' | 'aguardando_aceite' | 'em_pedido'
  final String? pedidoAtualId;

  // Stats
  final double rating;
  final int totalRatings;
  final int todaysDeliveries;
  final double todaysEarnings;
  final double weeklyEarnings;
  final double weeklyGoal;
  final int totalEntregas;

  // Financeiro
  final double saldoDisponivel;
  final double saldoBloqueado;

  // Active order
  final PedidoAtivo? pedidoAtivo;

  // Incoming dispatch
  final DespachoRecebido? despachoRecebido;

  // Recent deliveries
  final List<EntregaRecente> recentDeliveries;
  final bool isLoadingDeliveries;

  bool get isEmpty =>
      !isLoading && recentDeliveries.isEmpty && error == null;

  const DashboardState({
    this.isLoading = true,
    this.isTogglingStatus = false,
    this.isRespondingDespacho = false,
    this.error,
    this.driverId = '',
    this.driverName = '',
    this.vehicleType = 'Moto',
    this.fotoPerfilUrl,
    this.isOnline = false,
    this.searchRadius = 6.0,
    this.statusDespacho = 'livre',
    this.pedidoAtualId,
    this.rating = 5.0,
    this.totalRatings = 0,
    this.todaysDeliveries = 0,
    this.todaysEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.weeklyGoal = 1000.0,
    this.totalEntregas = 0,
    this.saldoDisponivel = 0.0,
    this.saldoBloqueado = 0.0,
    this.pedidoAtivo,
    this.despachoRecebido,
    this.recentDeliveries = const [],
    this.isLoadingDeliveries = false,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isTogglingStatus,
    bool? isRespondingDespacho,
    String? error,
    bool clearError = false,
    String? driverId,
    String? driverName,
    String? vehicleType,
    String? fotoPerfilUrl,
    bool? isOnline,
    double? searchRadius,
    String? statusDespacho,
    String? pedidoAtualId,
    bool clearPedidoAtualId = false,
    double? rating,
    int? totalRatings,
    int? todaysDeliveries,
    double? todaysEarnings,
    double? weeklyEarnings,
    double? weeklyGoal,
    int? totalEntregas,
    double? saldoDisponivel,
    double? saldoBloqueado,
    PedidoAtivo? pedidoAtivo,
    bool clearPedidoAtivo = false,
    DespachoRecebido? despachoRecebido,
    bool clearDespacho = false,
    List<EntregaRecente>? recentDeliveries,
    bool? isLoadingDeliveries,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      isRespondingDespacho: isRespondingDespacho ?? this.isRespondingDespacho,
      error: clearError ? null : (error ?? this.error),
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      fotoPerfilUrl: fotoPerfilUrl ?? this.fotoPerfilUrl,
      isOnline: isOnline ?? this.isOnline,
      searchRadius: searchRadius ?? this.searchRadius,
      statusDespacho: statusDespacho ?? this.statusDespacho,
      pedidoAtualId:
          clearPedidoAtualId ? null : (pedidoAtualId ?? this.pedidoAtualId),
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      todaysDeliveries: todaysDeliveries ?? this.todaysDeliveries,
      todaysEarnings: todaysEarnings ?? this.todaysEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
      totalEntregas: totalEntregas ?? this.totalEntregas,
      saldoDisponivel: saldoDisponivel ?? this.saldoDisponivel,
      saldoBloqueado: saldoBloqueado ?? this.saldoBloqueado,
      pedidoAtivo: clearPedidoAtivo ? null : (pedidoAtivo ?? this.pedidoAtivo),
      despachoRecebido:
          clearDespacho ? null : (despachoRecebido ?? this.despachoRecebido),
      recentDeliveries: recentDeliveries ?? this.recentDeliveries,
      isLoadingDeliveries: isLoadingDeliveries ?? this.isLoadingDeliveries,
    );
  }
}
