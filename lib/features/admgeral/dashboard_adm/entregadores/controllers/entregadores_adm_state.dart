import '../models/entregador_adm_model.dart';

class EntregadoresAdmState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<EntregadorAdmModel> entregadores;
  final String filtroStatus;
  final String filtroVeiculo;
  final String termoBusca;

  const EntregadoresAdmState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.entregadores = const [],
    this.filtroStatus = 'todos',
    this.filtroVeiculo = 'todos',
    this.termoBusca = '',
  });

  List<EntregadorAdmModel> get filtered {
    var lista = entregadores;

    if (filtroStatus != 'todos') {
      lista = lista.where((e) => e.statusCadastro == filtroStatus).toList();
    }
    if (filtroVeiculo != 'todos') {
      lista = lista.where((e) => e.tipoVeiculo == filtroVeiculo).toList();
    }
    if (termoBusca.isNotEmpty) {
      final q = termoBusca.toLowerCase();
      lista = lista.where((e) {
        return e.nome.toLowerCase().contains(q) ||
            (e.email?.toLowerCase().contains(q) ?? false) ||
            (e.cpf?.contains(q) ?? false) ||
            (e.veiculoPlaca?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return lista;
  }

  // ── KPIs ─────────────────────────────────────────────────────────────────

  int get totalCount => entregadores.length;

  int get pendentesCount =>
      entregadores.where((e) => e.statusCadastro == 'pendente').length;

  int get aprovadosCount =>
      entregadores.where((e) => e.statusCadastro == 'aprovado').length;

  int get suspensosCount =>
      entregadores.where((e) => e.statusCadastro == 'suspenso').length;

  int get rejeitadosCount =>
      entregadores.where((e) => e.statusCadastro == 'rejeitado').length;

  int get onlineCount => entregadores.where((e) => e.statusOnline).length;

  int get selfiePendenteCount =>
      entregadores.where((e) => e.selfiePendente).length;

  bool get isEmpty => !isLoading && entregadores.isEmpty && errorMessage == null;

  EntregadoresAdmState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<EntregadorAdmModel>? entregadores,
    String? filtroStatus,
    String? filtroVeiculo,
    String? termoBusca,
    bool clearError = false,
  }) {
    return EntregadoresAdmState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage:
          clearError ? null : (errorMessage ?? this.errorMessage),
      entregadores: entregadores ?? this.entregadores,
      filtroStatus: filtroStatus ?? this.filtroStatus,
      filtroVeiculo: filtroVeiculo ?? this.filtroVeiculo,
      termoBusca: termoBusca ?? this.termoBusca,
    );
  }
}
