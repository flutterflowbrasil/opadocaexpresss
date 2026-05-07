import 'dart:typed_data';

class CadastroEstabelecimentoState {
  final String? nomeFantasia;
  final String? cnpj;
  final String? telefone;
  final String? email;
  final String? senha;

  final String? imagemLogoPath;
  final Uint8List? imagemLogoBytes;
  final String? imagemLogoFileName;
  final String? imagemCapaPath;
  final Uint8List? imagemCapaBytes;
  final String? imagemCapaFileName;

  final String? tipoPessoa; // 'fisica' ou 'juridica'

  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? bairro;
  final String? cidade;
  final String? estado;
  final double? latitude;
  final double? longitude;
  final Map<String, dynamic>? horarioFuncionamento;

  final String? documentoResponsavelTipo;
  final Uint8List? identidadeResponsavelFrenteBytes;
  final String? identidadeResponsavelFrenteFileName;
  final Uint8List? identidadeResponsavelVersoBytes;
  final String? identidadeResponsavelVersoFileName;
  final Uint8List? cnhResponsavelFrenteBytes;
  final String? cnhResponsavelFrenteFileName;
  final Uint8List? cnhResponsavelVersoBytes;
  final String? cnhResponsavelVersoFileName;
  final Uint8List? comprovanteEnderecoBytes;
  final String? comprovanteEnderecoFileName;

  final bool isLoading;
  final String? error;

  CadastroEstabelecimentoState({
    this.nomeFantasia,
    this.cnpj,
    this.telefone,
    this.email,
    this.senha,

    this.imagemLogoPath,
    this.imagemLogoBytes,
    this.imagemLogoFileName,
    this.imagemCapaPath,
    this.imagemCapaBytes,
    this.imagemCapaFileName,
    this.tipoPessoa = 'juridica',
    this.cep,
    this.logradouro,
    this.numero,
    this.bairro,
    this.cidade,
    this.estado,
    this.latitude,
    this.longitude,
    this.horarioFuncionamento,
    this.documentoResponsavelTipo = 'identidade',
    this.identidadeResponsavelFrenteBytes,
    this.identidadeResponsavelFrenteFileName,
    this.identidadeResponsavelVersoBytes,
    this.identidadeResponsavelVersoFileName,
    this.cnhResponsavelFrenteBytes,
    this.cnhResponsavelFrenteFileName,
    this.cnhResponsavelVersoBytes,
    this.cnhResponsavelVersoFileName,
    this.comprovanteEnderecoBytes,
    this.comprovanteEnderecoFileName,
    this.isLoading = false,
    this.error,
  });

  CadastroEstabelecimentoState copyWith({
    String? nomeFantasia,
    String? cnpj,
    String? telefone,
    String? email,
    String? senha,

    String? imagemLogoPath,
    Uint8List? imagemLogoBytes,
    String? imagemLogoFileName,
    String? imagemCapaPath,
    Uint8List? imagemCapaBytes,
    String? imagemCapaFileName,
    String? tipoPessoa,
    String? cep,
    String? logradouro,
    String? numero,
    String? bairro,
    String? cidade,
    String? estado,
    double? latitude,
    double? longitude,
    Map<String, dynamic>? horarioFuncionamento,
    String? documentoResponsavelTipo,
    Uint8List? identidadeResponsavelFrenteBytes,
    String? identidadeResponsavelFrenteFileName,
    Uint8List? identidadeResponsavelVersoBytes,
    String? identidadeResponsavelVersoFileName,
    Uint8List? cnhResponsavelFrenteBytes,
    String? cnhResponsavelFrenteFileName,
    Uint8List? cnhResponsavelVersoBytes,
    String? cnhResponsavelVersoFileName,
    Uint8List? comprovanteEnderecoBytes,
    String? comprovanteEnderecoFileName,
    bool? isLoading,
    String? error,
  }) {
    return CadastroEstabelecimentoState(
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      cnpj: cnpj ?? this.cnpj,
      telefone: telefone ?? this.telefone,
      email: email ?? this.email,
      senha: senha ?? this.senha,

      imagemLogoPath: imagemLogoPath ?? this.imagemLogoPath,
      imagemLogoBytes: imagemLogoBytes ?? this.imagemLogoBytes,
      imagemLogoFileName: imagemLogoFileName ?? this.imagemLogoFileName,
      imagemCapaPath: imagemCapaPath ?? this.imagemCapaPath,
      imagemCapaBytes: imagemCapaBytes ?? this.imagemCapaBytes,
      imagemCapaFileName: imagemCapaFileName ?? this.imagemCapaFileName,
      tipoPessoa: tipoPessoa ?? this.tipoPessoa,
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      horarioFuncionamento: horarioFuncionamento ?? this.horarioFuncionamento,
      documentoResponsavelTipo:
          documentoResponsavelTipo ?? this.documentoResponsavelTipo,
      identidadeResponsavelFrenteBytes: identidadeResponsavelFrenteBytes ??
          this.identidadeResponsavelFrenteBytes,
      identidadeResponsavelFrenteFileName:
          identidadeResponsavelFrenteFileName ??
              this.identidadeResponsavelFrenteFileName,
      identidadeResponsavelVersoBytes:
          identidadeResponsavelVersoBytes ?? this.identidadeResponsavelVersoBytes,
      identidadeResponsavelVersoFileName:
          identidadeResponsavelVersoFileName ??
              this.identidadeResponsavelVersoFileName,
      cnhResponsavelFrenteBytes:
          cnhResponsavelFrenteBytes ?? this.cnhResponsavelFrenteBytes,
      cnhResponsavelFrenteFileName:
          cnhResponsavelFrenteFileName ?? this.cnhResponsavelFrenteFileName,
      cnhResponsavelVersoBytes:
          cnhResponsavelVersoBytes ?? this.cnhResponsavelVersoBytes,
      cnhResponsavelVersoFileName:
          cnhResponsavelVersoFileName ?? this.cnhResponsavelVersoFileName,
      comprovanteEnderecoBytes:
          comprovanteEnderecoBytes ?? this.comprovanteEnderecoBytes,
      comprovanteEnderecoFileName:
          comprovanteEnderecoFileName ?? this.comprovanteEnderecoFileName,
      isLoading: isLoading ?? this.isLoading,
      error: error ?? this.error,
    );
  }
}
