import 'endereco_model.dart';

/// Estado imutável do controller de localização.
/// Padrão: Repository → StateNotifier → ConsumerWidget
class LocalizacaoState {
  final bool isLoading;
  final bool isSubmitting;
  final String? error;
  final List<EnderecoCliente> enderecos;

  /// True quando não está carregando, não tem erro e a lista está vazia.
  bool get isEmpty =>
      !isLoading && enderecos.isEmpty && error == null;

  const LocalizacaoState({
    this.isLoading = false,
    this.isSubmitting = false,
    this.error,
    this.enderecos = const [],
  });

  LocalizacaoState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? error,
    List<EnderecoCliente>? enderecos,
    bool clearError = false,
  }) {
    return LocalizacaoState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      enderecos: enderecos ?? this.enderecos,
    );
  }
}
