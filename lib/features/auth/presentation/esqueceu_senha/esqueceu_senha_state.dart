class EsqueceuSenhaState {
  final bool isLoading;
  final String? error;
  final bool emailSent;

  const EsqueceuSenhaState({
    this.isLoading = false,
    this.error,
    this.emailSent = false,
  });

  EsqueceuSenhaState copyWith({
    bool? isLoading,
    String? error,
    bool? emailSent,
  }) {
    return EsqueceuSenhaState(
      isLoading: isLoading ?? this.isLoading,
      // Se mandar error explicitamente 'null', ele apaga a msg
      error: error,
      emailSent: emailSent ?? this.emailSent,
    );
  }
}
