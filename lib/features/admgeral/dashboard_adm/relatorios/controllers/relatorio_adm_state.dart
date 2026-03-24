import '../models/relatorio_adm_model.dart';

class RelatorioAdmState {
  final bool isLoading;
  final String? errorMessage;
  final RelatorioSnapshot? snapshot;
  final String periodo; // '7d' | '30d' | '12m'
  final String abaAtiva; // 'visao_geral' | 'financeiro' | 'operacional' | 'usuarios' | 'qualidade'
  final DateTime? lastSync;

  const RelatorioAdmState({
    this.isLoading = true,
    this.errorMessage,
    this.snapshot,
    this.periodo = '12m',
    this.abaAtiva = 'visao_geral',
    this.lastSync,
  });

  bool get hasData => snapshot != null;

  RelatorioAdmState copyWith({
    bool? isLoading,
    String? errorMessage,
    RelatorioSnapshot? snapshot,
    String? periodo,
    String? abaAtiva,
    DateTime? lastSync,
    bool clearError = false,
  }) =>
      RelatorioAdmState(
        isLoading: isLoading ?? this.isLoading,
        errorMessage: clearError ? null : errorMessage ?? this.errorMessage,
        snapshot: snapshot ?? this.snapshot,
        periodo: periodo ?? this.periodo,
        abaAtiva: abaAtiva ?? this.abaAtiva,
        lastSync: lastSync ?? this.lastSync,
      );
}
