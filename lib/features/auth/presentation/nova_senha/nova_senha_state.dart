class NovaSenhaState {
  final bool isLoading;
  final String? error;
  final bool sucesso;

  const NovaSenhaState({
    this.isLoading = false,
    this.error,
    this.sucesso = false,
  });

  NovaSenhaState copyWith({
    bool? isLoading,
    String? error,
    bool? sucesso,
  }) {
    return NovaSenhaState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      sucesso: sucesso ?? this.sucesso,
    );
  }
}
