import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';
export 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';

class CadastroEstabelecimentoController
    extends StateNotifier<CadastroEstabelecimentoState> {
  CadastroEstabelecimentoController() : super(CadastroEstabelecimentoState());

  void updateStep1({
    required String nomeFantasia,
    required String cnpj,
    required String telefone,
    required String email,
    required String senha,
    String? imagemLogoPath,
    Uint8List? imagemLogoBytes,
    String? imagemLogoFileName,
    String? imagemCapaPath,
    Uint8List? imagemCapaBytes,
    String? imagemCapaFileName,
    String? tipoPessoa,
  }) {
    state = state.copyWith(
      nomeFantasia: nomeFantasia,
      cnpj: cnpj,
      telefone: telefone,
      email: email,
      senha: senha,
      imagemLogoPath: imagemLogoPath,
      imagemLogoBytes: imagemLogoBytes,
      imagemLogoFileName: imagemLogoFileName,
      imagemCapaPath: imagemCapaPath,
      imagemCapaBytes: imagemCapaBytes,
      imagemCapaFileName: imagemCapaFileName,
      tipoPessoa: tipoPessoa,
    );
  }

  void updateStep2({
    required String cep,
    required String logradouro,
    required String numero,
    required String bairro,
    required String cidade,
    required String estado,
    double? latitude,
    double? longitude,
    required Map<String, dynamic> horarioFuncionamento,
  }) {
    state = state.copyWith(
      cep: cep,
      logradouro: logradouro,
      numero: numero,
      bairro: bairro,
      cidade: cidade,
      estado: estado,
      latitude: latitude,
      longitude: longitude,
      horarioFuncionamento: horarioFuncionamento,
    );
  }

  void updateStep3({
    required String documentoResponsavelTipo,
    Uint8List? identidadeResponsavelFrenteBytes,
    String? identidadeResponsavelFrenteFileName,
    Uint8List? identidadeResponsavelVersoBytes,
    String? identidadeResponsavelVersoFileName,
    Uint8List? cnhResponsavelFrenteBytes,
    String? cnhResponsavelFrenteFileName,
    Uint8List? cnhResponsavelVersoBytes,
    String? cnhResponsavelVersoFileName,
    required Uint8List comprovanteEnderecoBytes,
    required String comprovanteEnderecoFileName,
  }) {
    state = state.copyWith(
      documentoResponsavelTipo: documentoResponsavelTipo,
      identidadeResponsavelFrenteBytes: identidadeResponsavelFrenteBytes,
      identidadeResponsavelFrenteFileName: identidadeResponsavelFrenteFileName,
      identidadeResponsavelVersoBytes: identidadeResponsavelVersoBytes,
      identidadeResponsavelVersoFileName: identidadeResponsavelVersoFileName,
      cnhResponsavelFrenteBytes: cnhResponsavelFrenteBytes,
      cnhResponsavelFrenteFileName: cnhResponsavelFrenteFileName,
      cnhResponsavelVersoBytes: cnhResponsavelVersoBytes,
      cnhResponsavelVersoFileName: cnhResponsavelVersoFileName,
      comprovanteEnderecoBytes: comprovanteEnderecoBytes,
      comprovanteEnderecoFileName: comprovanteEnderecoFileName,
    );
  }

  void setLoading(bool loading) {
    state = state.copyWith(isLoading: loading);
  }

  void setError(String? error) {
    state = state.copyWith(error: error);
  }
}

final cadastroEstabelecimentoProvider = StateNotifierProvider<
    CadastroEstabelecimentoController, CadastroEstabelecimentoState>((ref) {
  return CadastroEstabelecimentoController();
});
