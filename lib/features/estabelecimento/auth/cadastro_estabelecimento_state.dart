import 'dart:io';

class CadastroEstabelecimentoState {
  final String? nomeFantasia;
  final String? cnpj;
  final String? telefone;
  final String? email;
  final String? senha;

  final File? imagemCapa;

  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final Map<String, dynamic>? horarioFuncionamento;

  final String? banco;
  final String? agencia;
  final String? conta;
  final String? contaDigito;
  final String? tipoConta;
  final String? titularNome;
  final String? titularCpfCnpj;

  final bool isLoading;
  final String? error;

  CadastroEstabelecimentoState({
    this.nomeFantasia,
    this.cnpj,
    this.telefone,
    this.email,
    this.senha,

    this.imagemCapa,
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.horarioFuncionamento,
    this.banco,
    this.agencia,
    this.conta,
    this.contaDigito,
    this.tipoConta,
    this.titularNome,
    this.titularCpfCnpj,
    this.isLoading = false,
    this.error,
  });

  CadastroEstabelecimentoState copyWith({
    String? nomeFantasia,
    String? cnpj,
    String? telefone,
    String? email,
    String? senha,

    File? imagemCapa,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    Map<String, dynamic>? horarioFuncionamento,
    String? banco,
    String? agencia,
    String? conta,
    String? contaDigito,
    String? tipoConta,
    String? titularNome,
    String? titularCpfCnpj,
    bool? isLoading,
    String? error,
  }) {
    return CadastroEstabelecimentoState(
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      senha: senha ?? this.senha,

      imagemCapa: imagemCapa ?? this.imagemCapa,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      horarioFuncionamento: horarioFuncionamento ?? this.horarioFuncionamento,
      banco: banco ?? this.banco,
      agencia: agencia ?? this.agencia,
      conta: conta ?? this.conta,
      contaDigito: contaDigito ?? this.contaDigito,
      tipoConta: tipoConta ?? this.tipoConta,
      titularNome: titularNome ?? this.titularNome,
      titularCpfCnpj: titularCpfCnpj ?? this.titularCpfCnpj,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
