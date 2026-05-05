class CadastroEntregadorState {
  final String? nomeCompleto;
  final String? telefone;
  final String? cpf;
  final String? dataNascimento;
  final String? placaVeiculo;
  final String? dadosPagamentoAsaas;
  final String? email;
  final String? senha;
  final String? confirmarSenha;
  final bool acceptedTerms;
  final bool isLoading;
  final String? error;

  CadastroEntregadorState({
    this.nomeCompleto,
    this.telefone,
    this.cpf,
    this.dataNascimento,
    this.placaVeiculo,
    this.dadosPagamentoAsaas,
    this.email,
    this.senha,
    this.confirmarSenha,
    this.acceptedTerms = false,
    this.isLoading = false,
    this.error,
  });

  CadastroEntregadorState copyWith({
    String? nomeCompleto,
    String? telefone,
    String? cpf,
    String? dataNascimento,
    String? placaVeiculo,
    String? dadosPagamentoAsaas,
    String? email,
    String? senha,
    String? confirmarSenha,
    bool? acceptedTerms,
    bool? isLoading,
    String? error,
  }) {
    return CadastroEntregadorState(
      nomeCompleto: nomeCompleto ?? this.nomeCompleto,
      telefone: telefone ?? this.telefone,
      cpf: cpf ?? this.cpf,
      dataNascimento: dataNascimento ?? this.dataNascimento,
      placaVeiculo: placaVeiculo ?? this.placaVeiculo,
      dadosPagamentoAsaas: dadosPagamentoAsaas ?? this.dadosPagamentoAsaas,
      email: email ?? this.email,
      senha: senha ?? this.senha,
      confirmarSenha: confirmarSenha ?? this.confirmarSenha,
      acceptedTerms: acceptedTerms ?? this.acceptedTerms,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
