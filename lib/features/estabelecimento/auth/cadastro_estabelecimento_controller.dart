import 'dart:io';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:padoca_express/features/estabelecimento/auth/cadastro_estabelecimento_state.dart';
export 'package:padoca_express/features/estabelecimento/auth/cadastro_estabelecimento_state.dart';

class CadastroEstabelecimentoController
    extends StateNotifier<CadastroEstabelecimentoState> {
  CadastroEstabelecimentoController() : super(CadastroEstabelecimentoState());

  void updateStep1({
    required String nomeFantasia,
    required String cnpj,
    required String telefone,
    required String email,
    required String senha,
    File? imagemCapa,
  }) {
    state = state.copyWith(
      nomeFantasia: nomeFantasia,
      cnpj: cnpj,
      telefone: telefone,
      email: email,
      senha: senha,
      imagemCapa: imagemCapa,
    );
  }

  void updateStep2({
    required String cep,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    required Map<String, dynamic> horarioFuncionamento,
  }) {
    state = state.copyWith(
      cep: cep,
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      horarioFuncionamento: horarioFuncionamento,
    );
  }

  void updateStep3({
    required String banco,
    required String agencia,
    required String conta,
    required String contaDigito,
    required String tipoConta,
    required String titularNome,
    required String titularCpfCnpj,
  }) {
    state = state.copyWith(
      banco: banco,
      agencia: agencia,
      conta: conta,
      contaDigito: contaDigito,
      tipoConta: tipoConta,
      titularNome: titularNome,
      titularCpfCnpj: titularCpfCnpj,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final cadastroEstabelecimentoProvider =
    StateNotifierProvider<
      CadastroEstabelecimentoController,
      CadastroEstabelecimentoState
    >((ref) {
      return CadastroEstabelecimentoController();
    });
