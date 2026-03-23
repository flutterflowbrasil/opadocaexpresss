import '../models/estab_adm_model.dart';

class EstabsAdmState {
  final bool isLoading;
  final bool isSubmitting;
  final String? errorMessage;
  final List<EstabAdmModel> estabelecimentos;
  final String filtroStatus;
  final String termoBusca;

  const EstabsAdmState({
    this.isLoading = true,
    this.isSubmitting = false,
    this.errorMessage,
    this.estabelecimentos = const [],
    this.filtroStatus = 'todos',
    this.termoBusca = '',
  });

  List<EstabAdmModel> get filtered {
    var lista = estabelecimentos;
    if (filtroStatus != 'todos') {
      lista = lista.where((e) => e.statusCadastro == filtroStatus).toList();
    }
    if (termoBusca.isNotEmpty) {
      final q = termoBusca.toLowerCase();
      lista = lista.where((e) {
        return e.nomeFantasia.toLowerCase().contains(q) ||
            (e.razaoSocial.toLowerCase().contains(q)) ||
            (e.cnpj?.contains(q) ?? false) ||
            (e.responsavelNome?.toLowerCase().contains(q) ?? false);
      }).toList();
    }
    return lista;
  }

  int get totalCount => estabelecimentos.length;
  int get aprovadosCount =>
      estabelecimentos.where((e) => e.statusCadastro == 'aprovado').length;
  int get pendentesCount =>
      estabelecimentos.where((e) => e.statusCadastro == 'pendente').length;
  int get suspensosCount =>
      estabelecimentos.where((e) => e.statusCadastro == 'suspenso').length;
  int get rejeitadosCount =>
      estabelecimentos.where((e) => e.statusCadastro == 'rejeitado').length;
  int get abertosCount =>
      estabelecimentos.where((e) => e.statusAberto).length;
  double get faturamentoTotal =>
      estabelecimentos.fold(0.0, (sum, e) => sum + (e.faturamentoTotal ?? 0));

  EstabsAdmState copyWith({
    bool? isLoading,
    bool? isSubmitting,
    String? errorMessage,
    List<EstabAdmModel>? estabelecimentos,
    String? filtroStatus,
    String? termoBusca,
    bool clearError = false,
  }) {
    return EstabsAdmState(
      isLoading: isLoading ?? this.isLoading,
      isSubmitting: isSubmitting ?? this.isSubmitting,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
      estabelecimentos: estabelecimentos ?? this.estabelecimentos,
      filtroStatus: filtroStatus ?? this.filtroStatus,
      termoBusca: termoBusca ?? this.termoBusca,
    );
  }
}
