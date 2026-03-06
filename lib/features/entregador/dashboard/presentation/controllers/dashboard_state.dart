class DashboardState {
  final bool isLoading;
  final bool isTogglingStatus;
  final String? error;

  final String driverId; // ID interno na tabela entregadores
  final String driverName;
  final String vehicleType;
  final bool isOnline;
  final double searchRadius;

  final double rating;
  final int totalRatings;

  final int todaysDeliveries;
  final double todaysEarnings;
  final double weeklyEarnings;
  final double weeklyGoal;

  const DashboardState({
    this.isLoading = false,
    this.isTogglingStatus = false,
    this.error,
    this.driverId = '',
    this.driverName = 'Carregando...',
    this.vehicleType = 'Moto',
    this.isOnline = false,
    this.searchRadius = 6.0,
    this.rating = 5.0,
    this.totalRatings = 0,
    this.todaysDeliveries = 0,
    this.todaysEarnings = 0.0,
    this.weeklyEarnings = 0.0,
    this.weeklyGoal = 1000.0,
  });

  DashboardState copyWith({
    bool? isLoading,
    bool? isTogglingStatus,
    String? error,
    bool clearError = false,
    String? driverId,
    String? driverName,
    String? vehicleType,
    bool? isOnline,
    double? searchRadius,
    double? rating,
    int? totalRatings,
    int? todaysDeliveries,
    double? todaysEarnings,
    double? weeklyEarnings,
    double? weeklyGoal,
  }) {
    return DashboardState(
      isLoading: isLoading ?? this.isLoading,
      isTogglingStatus: isTogglingStatus ?? this.isTogglingStatus,
      error: clearError ? null : (error ?? this.error),
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      vehicleType: vehicleType ?? this.vehicleType,
      isOnline: isOnline ?? this.isOnline,
      searchRadius: searchRadius ?? this.searchRadius,
      rating: rating ?? this.rating,
      totalRatings: totalRatings ?? this.totalRatings,
      todaysDeliveries: todaysDeliveries ?? this.todaysDeliveries,
      todaysEarnings: todaysEarnings ?? this.todaysEarnings,
      weeklyEarnings: weeklyEarnings ?? this.weeklyEarnings,
      weeklyGoal: weeklyGoal ?? this.weeklyGoal,
    );
  }
}
