import 'package:padoca_express/features/cliente/pagamento/models/cobranca_asaas_model.dart';

enum PagamentoStatus {
  idle,
  submitting,
  aguardandoPix,
  confirmado,
  expirado,
  erro,
}

class PagamentoState {
  final bool isSubmitting;
  final String? errorMessage;
  final String? pedidoCriadoId;
  final CobrancaAsaasModel? cobranca;
  final PagamentoStatus status;
  /// Segundos restantes quando um PIX pendente é retomado.
  final int? segundosRestantes;

  const PagamentoState({
    this.isSubmitting = false,
    this.errorMessage,
    this.pedidoCriadoId,
    this.cobranca,
    this.status = PagamentoStatus.idle,
    this.segundosRestantes,
  });

  PagamentoState copyWith({
    bool? isSubmitting,
    String? errorMessage,
    bool clearError = false,
    String? pedidoCriadoId,
    CobrancaAsaasModel? cobranca,
    PagamentoStatus? status,
    int? segundosRestantes,
  }) {
    return PagamentoState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      pedidoCriadoId: pedidoCriadoId ?? this.pedidoCriadoId,
      cobranca: cobranca ?? this.cobranca,
      status: status ?? this.status,
      segundosRestantes: segundosRestantes ?? this.segundosRestantes,
    );
  }
}
