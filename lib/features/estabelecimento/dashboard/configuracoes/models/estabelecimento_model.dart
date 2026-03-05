import 'package:flutter/foundation.dart';

@immutable
class EstabelecimentoModel {
  final String id;
  final String? usuarioId;
  final String? razaoSocial;
  final String? cnpj;
  final String? inscricaoEstadual;
  final String? inscricaoMunicipal;
  final String? descricao;
  final String? logoUrl;
  final String? bannerUrl;
  final List<String> fotosEstabelecimento;
  final String? telefoneComercial;
  final String? whatsapp;
  final String? emailComercial;
  final EnderecoModel endereco;
  final Map<String, dynamic> horarioFuncionamento; // JSONB
  final ConfigEntregaModel configEntrega;
  final ConfigAvancadaModel configAvancada;
  final String? statusCadastro;
  final bool statusAberto;
  final DadosBancariosModel dadosBancarios;
  final double? latitude;
  final double? longitude;
  final String? categoriaEstabelecimentoId;
  final String? nomeFantasia;
  final String? slug;
  final int tempoMedioEntregaMin;
  final bool destaque;
  final List<String> tags;
  final String? responsavelNome;
  final String? responsavelCpf;

  const EstabelecimentoModel({
    required this.id,
    this.usuarioId,
    this.razaoSocial,
    this.cnpj,
    this.inscricaoEstadual,
    this.inscricaoMunicipal,
    this.descricao,
    this.logoUrl,
    this.bannerUrl,
    this.fotosEstabelecimento = const [],
    this.telefoneComercial,
    this.whatsapp,
    this.emailComercial,
    required this.endereco,
    this.horarioFuncionamento = const {},
    required this.configEntrega,
    required this.configAvancada,
    this.statusCadastro,
    this.statusAberto = false,
    required this.dadosBancarios,
    this.latitude,
    this.longitude,
    this.categoriaEstabelecimentoId,
    this.nomeFantasia,
    this.slug,
    this.tempoMedioEntregaMin = 40,
    this.destaque = false,
    this.tags = const [],
    this.responsavelNome,
    this.responsavelCpf,
  });

  factory EstabelecimentoModel.fromJson(Map<String, dynamic> json) {
    return EstabelecimentoModel(
      id: json['id'] as String,
      usuarioId: json['usuario_id'] as String?,
      razaoSocial: json['razao_social'] as String?,
      cnpj: json['cnpj'] as String?,
      inscricaoEstadual: json['inscricao_estadual'] as String?,
      inscricaoMunicipal: json['inscricao_municipal'] as String?,
      descricao: json['descricao'] as String?,
      logoUrl: json['logo_url'] as String?,
      bannerUrl: json['banner_url'] as String?,
      fotosEstabelecimento:
          (json['fotos_estabelecimento'] as List?)?.cast<String>() ?? [],
      telefoneComercial: json['telefone_comercial'] as String?,
      whatsapp: json['whatsapp'] as String?,
      emailComercial: json['email_comercial'] as String?,
      endereco: EnderecoModel.fromJson(
          json['endereco'] as Map<String, dynamic>? ?? {}),
      horarioFuncionamento:
          json['horario_funcionamento'] as Map<String, dynamic>? ?? {},
      configEntrega: ConfigEntregaModel.fromJson(
          json['config_entrega'] as Map<String, dynamic>? ?? {}),
      configAvancada: ConfigAvancadaModel.fromJson(
          json['config_avancada'] as Map<String, dynamic>? ?? {}),
      statusCadastro: json['status_cadastro'] as String?,
      statusAberto: json['status_aberto'] as bool? ?? false,
      dadosBancarios: DadosBancariosModel.fromJson(
          json['dados_bancarios'] as Map<String, dynamic>? ?? {}),
      latitude: (json['latitude'] as num?)?.toDouble(),
      longitude: (json['longitude'] as num?)?.toDouble(),
      categoriaEstabelecimentoId:
          json['categoria_estabelecimento_id'] as String?,
      nomeFantasia: json['nome_fantasia'] as String?,
      slug: json['slug'] as String?,
      tempoMedioEntregaMin:
          (json['tempo_medio_entrega_min'] as num?)?.toInt() ?? 40,
      destaque: json['destaque'] as bool? ?? false,
      tags: (json['tags'] as List?)?.cast<String>() ?? [],
      responsavelNome: json['responsavel_nome'] as String?,
      responsavelCpf: json['responsavel_cpf'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'razao_social': razaoSocial,
      'cnpj': cnpj,
      'inscricao_estadual': inscricaoEstadual,
      'inscricao_municipal': inscricaoMunicipal,
      'descricao': descricao,
      'logo_url': logoUrl,
      'banner_url': bannerUrl,
      'fotos_estabelecimento': fotosEstabelecimento,
      'telefone_comercial': telefoneComercial,
      'whatsapp': whatsapp,
      'email_comercial': emailComercial,
      'endereco': endereco.toJson(),
      'horario_funcionamento': horarioFuncionamento,
      'config_entrega': configEntrega.toJson(),
      'config_avancada': configAvancada.toJson(),
      'dados_bancarios': dadosBancarios.toJson(),
      'latitude': latitude,
      'longitude': longitude,
      'categoria_estabelecimento_id': categoriaEstabelecimentoId,
      'nome_fantasia': nomeFantasia,
      'slug': slug,
      'tempo_medio_entrega_min': tempoMedioEntregaMin,
      'destaque': destaque,
      'tags': tags,
      'responsavel_nome': responsavelNome,
      'responsavel_cpf': responsavelCpf,
    };
  }

  EstabelecimentoModel copyWith({
    String? razaoSocial,
    String? cnpj,
    String? inscricaoEstadual,
    String? inscricaoMunicipal,
    String? descricao,
    String? logoUrl,
    String? bannerUrl,
    List<String>? fotosEstabelecimento,
    String? telefoneComercial,
    String? whatsapp,
    String? emailComercial,
    EnderecoModel? endereco,
    Map<String, dynamic>? horarioFuncionamento,
    ConfigEntregaModel? configEntrega,
    ConfigAvancadaModel? configAvancada,
    DadosBancariosModel? dadosBancarios,
    double? latitude,
    double? longitude,
    String? categoriaEstabelecimentoId,
    String? nomeFantasia,
    String? slug,
    int? tempoMedioEntregaMin,
    bool? destaque,
    List<String>? tags,
    String? responsavelNome,
    String? responsavelCpf,
    bool? statusAberto,
  }) {
    return EstabelecimentoModel(
      id: id,
      usuarioId: usuarioId,
      razaoSocial: razaoSocial ?? this.razaoSocial,
      cnpj: cnpj ?? this.cnpj,
      inscricaoEstadual: inscricaoEstadual ?? this.inscricaoEstadual,
      inscricaoMunicipal: inscricaoMunicipal ?? this.inscricaoMunicipal,
      descricao: descricao ?? this.descricao,
      logoUrl: logoUrl ?? this.logoUrl,
      bannerUrl: bannerUrl ?? this.bannerUrl,
      fotosEstabelecimento: fotosEstabelecimento ?? this.fotosEstabelecimento,
      telefoneComercial: telefoneComercial ?? this.telefoneComercial,
      whatsapp: whatsapp ?? this.whatsapp,
      emailComercial: emailComercial ?? this.emailComercial,
      endereco: endereco ?? this.endereco,
      horarioFuncionamento: horarioFuncionamento ?? this.horarioFuncionamento,
      configEntrega: configEntrega ?? this.configEntrega,
      configAvancada: configAvancada ?? this.configAvancada,
      dadosBancarios: dadosBancarios ?? this.dadosBancarios,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      categoriaEstabelecimentoId:
          categoriaEstabelecimentoId ?? this.categoriaEstabelecimentoId,
      nomeFantasia: nomeFantasia ?? this.nomeFantasia,
      slug: slug ?? this.slug,
      tempoMedioEntregaMin: tempoMedioEntregaMin ?? this.tempoMedioEntregaMin,
      destaque: destaque ?? this.destaque,
      tags: tags ?? this.tags,
      responsavelNome: responsavelNome ?? this.responsavelNome,
      responsavelCpf: responsavelCpf ?? this.responsavelCpf,
      statusAberto: statusAberto ?? this.statusAberto,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EstabelecimentoModel &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          razaoSocial == other.razaoSocial &&
          cnpj == other.cnpj &&
          inscricaoEstadual == other.inscricaoEstadual &&
          inscricaoMunicipal == other.inscricaoMunicipal &&
          descricao == other.descricao &&
          logoUrl == other.logoUrl &&
          bannerUrl == other.bannerUrl &&
          listEquals(fotosEstabelecimento, other.fotosEstabelecimento) &&
          telefoneComercial == other.telefoneComercial &&
          whatsapp == other.whatsapp &&
          emailComercial == other.emailComercial &&
          endereco == other.endereco &&
          mapEquals(horarioFuncionamento, other.horarioFuncionamento) &&
          configEntrega == other.configEntrega &&
          configAvancada == other.configAvancada &&
          dadosBancarios == other.dadosBancarios &&
          latitude == other.latitude &&
          longitude == other.longitude &&
          categoriaEstabelecimentoId == other.categoriaEstabelecimentoId &&
          nomeFantasia == other.nomeFantasia &&
          slug == other.slug &&
          tempoMedioEntregaMin == other.tempoMedioEntregaMin &&
          destaque == other.destaque &&
          listEquals(tags, other.tags) &&
          responsavelNome == other.responsavelNome &&
          responsavelCpf == other.responsavelCpf &&
          statusAberto == other.statusAberto;

  @override
  int get hashCode =>
      id.hashCode ^
      razaoSocial.hashCode ^
      cnpj.hashCode ^
      inscricaoEstadual.hashCode ^
      inscricaoMunicipal.hashCode ^
      descricao.hashCode ^
      logoUrl.hashCode ^
      bannerUrl.hashCode ^
      fotosEstabelecimento.hashCode ^
      telefoneComercial.hashCode ^
      whatsapp.hashCode ^
      emailComercial.hashCode ^
      endereco.hashCode ^
      horarioFuncionamento.hashCode ^
      configEntrega.hashCode ^
      configAvancada.hashCode ^
      dadosBancarios.hashCode ^
      latitude.hashCode ^
      longitude.hashCode ^
      categoriaEstabelecimentoId.hashCode ^
      nomeFantasia.hashCode ^
      slug.hashCode ^
      tempoMedioEntregaMin.hashCode ^
      destaque.hashCode ^
      tags.hashCode ^
      responsavelNome.hashCode ^
      responsavelCpf.hashCode ^
      statusAberto.hashCode;
}

@immutable
class EnderecoModel {
  final String? cep;
  final String? logradouro;
  final String? numero;
  final String? complemento;
  final String? bairro;
  final String? cidade;
  final String? estado;

  const EnderecoModel({
    this.cep,
    this.logradouro,
    this.numero,
    this.complemento,
    this.bairro,
    this.cidade,
    this.estado,
  });

  factory EnderecoModel.fromJson(Map<String, dynamic> json) {
    return EnderecoModel(
      cep: json['cep'] as String?,
      logradouro: json['logradouro'] as String?,
      numero: json['numero'] as String?,
      complemento: json['complemento'] as String?,
      bairro: json['bairro'] as String?,
      cidade: json['cidade'] as String?,
      estado: json['estado'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'cep': cep,
      'logradouro': logradouro,
      'numero': numero,
      'complemento': complemento,
      'bairro': bairro,
      'cidade': cidade,
      'estado': estado,
    };
  }

  EnderecoModel copyWith({
    String? cep,
    String? logradouro,
    String? numero,
    String? complemento,
    String? bairro,
    String? cidade,
    String? estado,
  }) {
    return EnderecoModel(
      cep: cep ?? this.cep,
      logradouro: logradouro ?? this.logradouro,
      numero: numero ?? this.numero,
      complemento: complemento ?? this.complemento,
      bairro: bairro ?? this.bairro,
      cidade: cidade ?? this.cidade,
      estado: estado ?? this.estado,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EnderecoModel &&
          runtimeType == other.runtimeType &&
          cep == other.cep &&
          logradouro == other.logradouro &&
          numero == other.numero &&
          complemento == other.complemento &&
          bairro == other.bairro &&
          cidade == other.cidade &&
          estado == other.estado;

  @override
  int get hashCode =>
      cep.hashCode ^
      logradouro.hashCode ^
      numero.hashCode ^
      complemento.hashCode ^
      bairro.hashCode ^
      cidade.hashCode ^
      estado.hashCode;
}

@immutable
class ConfigEntregaModel {
  final double taxaPorKm;
  final double pedidoMinimo;
  final int raioMaximoKm;
  final double gratisAcimaDe;
  final double taxaEntregaFixa;
  final int tempoMedioPreparoMin;

  const ConfigEntregaModel({
    this.taxaPorKm = 0,
    this.pedidoMinimo = 0,
    this.raioMaximoKm = 0,
    this.gratisAcimaDe = 0,
    this.taxaEntregaFixa = 0,
    this.tempoMedioPreparoMin = 0,
  });

  factory ConfigEntregaModel.fromJson(Map<String, dynamic> json) {
    return ConfigEntregaModel(
      taxaPorKm: (json['taxa_por_km'] as num?)?.toDouble() ?? 0,
      pedidoMinimo: (json['pedido_minimo'] as num?)?.toDouble() ?? 0,
      raioMaximoKm: (json['raio_maximo_km'] as num?)?.toInt() ?? 0,
      gratisAcimaDe: (json['gratis_acima_de'] as num?)?.toDouble() ?? 0,
      taxaEntregaFixa: (json['taxa_entrega_fixa'] as num?)?.toDouble() ?? 0,
      tempoMedioPreparoMin:
          (json['tempo_medio_preparo_min'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'taxa_por_km': taxaPorKm,
      'pedido_minimo': pedidoMinimo,
      'raio_maximo_km': raioMaximoKm,
      'gratis_acima_de': gratisAcimaDe,
      'taxa_entrega_fixa': taxaEntregaFixa,
      'tempo_medio_preparo_min': tempoMedioPreparoMin,
    };
  }

  ConfigEntregaModel copyWith({
    double? taxaPorKm,
    double? pedidoMinimo,
    int? raioMaximoKm,
    double? gratisAcimaDe,
    double? taxaEntregaFixa,
    int? tempoMedioPreparoMin,
  }) {
    return ConfigEntregaModel(
      taxaPorKm: taxaPorKm ?? this.taxaPorKm,
      pedidoMinimo: pedidoMinimo ?? this.pedidoMinimo,
      raioMaximoKm: raioMaximoKm ?? this.raioMaximoKm,
      gratisAcimaDe: gratisAcimaDe ?? this.gratisAcimaDe,
      taxaEntregaFixa: taxaEntregaFixa ?? this.taxaEntregaFixa,
      tempoMedioPreparoMin: tempoMedioPreparoMin ?? this.tempoMedioPreparoMin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigEntregaModel &&
          runtimeType == other.runtimeType &&
          taxaPorKm == other.taxaPorKm &&
          pedidoMinimo == other.pedidoMinimo &&
          raioMaximoKm == other.raioMaximoKm &&
          gratisAcimaDe == other.gratisAcimaDe &&
          taxaEntregaFixa == other.taxaEntregaFixa &&
          tempoMedioPreparoMin == other.tempoMedioPreparoMin;

  @override
  int get hashCode =>
      taxaPorKm.hashCode ^
      pedidoMinimo.hashCode ^
      raioMaximoKm.hashCode ^
      gratisAcimaDe.hashCode ^
      taxaEntregaFixa.hashCode ^
      tempoMedioPreparoMin.hashCode;
}

@immutable
class DadosBancariosModel {
  final String? banco;
  final String? agencia;
  final String? conta;
  final String? contaDigito;
  final String? titular;
  final String? cpfCnpjTitular;
  final String? tipoConta;
  final DateTime? ultimoUpdate;
  final String? statusValidacao;

  const DadosBancariosModel({
    this.banco,
    this.agencia,
    this.conta,
    this.contaDigito,
    this.titular,
    this.cpfCnpjTitular,
    this.tipoConta,
    this.ultimoUpdate,
    this.statusValidacao,
  });

  factory DadosBancariosModel.fromJson(Map<String, dynamic> json) {
    return DadosBancariosModel(
      banco: json['banco'] as String?,
      agencia: json['agencia'] as String?,
      conta: json['conta'] as String?,
      contaDigito: json['conta_digito'] as String?,
      titular: json['titular'] as String?,
      cpfCnpjTitular: json['cpf_cnpj_titular'] as String?,
      tipoConta: json['tipo_conta'] as String?,
      ultimoUpdate: json['ultimo_update'] != null
          ? DateTime.parse(json['ultimo_update'] as String)
          : null,
      statusValidacao: json['status_validacao'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'banco': banco,
      'agencia': agencia,
      'conta': conta,
      'conta_digito': contaDigito,
      'titular': titular,
      'cpf_cnpj_titular': cpfCnpjTitular,
      'tipo_conta': tipoConta,
      'ultimo_update': ultimoUpdate?.toIso8601String(),
      'status_validacao': statusValidacao,
    };
  }

  DadosBancariosModel copyWith({
    String? banco,
    String? agencia,
    String? conta,
    String? contaDigito,
    String? titular,
    String? cpfCnpjTitular,
    String? tipoConta,
    DateTime? ultimoUpdate,
    String? statusValidacao,
  }) {
    return DadosBancariosModel(
      banco: banco ?? this.banco,
      agencia: agencia ?? this.agencia,
      conta: conta ?? this.conta,
      contaDigito: contaDigito ?? this.contaDigito,
      titular: titular ?? this.titular,
      cpfCnpjTitular: cpfCnpjTitular ?? this.cpfCnpjTitular,
      tipoConta: tipoConta ?? this.tipoConta,
      ultimoUpdate: ultimoUpdate ?? this.ultimoUpdate,
      statusValidacao: statusValidacao ?? this.statusValidacao,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DadosBancariosModel &&
          runtimeType == other.runtimeType &&
          banco == other.banco &&
          agencia == other.agencia &&
          conta == other.conta &&
          contaDigito == other.contaDigito &&
          titular == other.titular &&
          cpfCnpjTitular == other.cpfCnpjTitular &&
          tipoConta == other.tipoConta &&
          ultimoUpdate == other.ultimoUpdate &&
          statusValidacao == other.statusValidacao;

  @override
  int get hashCode =>
      banco.hashCode ^
      agencia.hashCode ^
      conta.hashCode ^
      contaDigito.hashCode ^
      titular.hashCode ^
      cpfCnpjTitular.hashCode ^
      tipoConta.hashCode ^
      ultimoUpdate.hashCode ^
      statusValidacao.hashCode;
}

@immutable
class ConfigAvancadaModel {
  final bool aceitaAgendamento;
  final int tempoMaximoEntregaMin;
  final int tempoMinimoEntregaMin;
  final int intervaloAtualizacaoEstoqueMin;
  final int tempoAntecedenciaAgendamentoMin;

  const ConfigAvancadaModel({
    this.aceitaAgendamento = false,
    this.tempoMaximoEntregaMin = 60,
    this.tempoMinimoEntregaMin = 15,
    this.intervaloAtualizacaoEstoqueMin = 5,
    this.tempoAntecedenciaAgendamentoMin = 60,
  });

  factory ConfigAvancadaModel.fromJson(Map<String, dynamic> json) {
    return ConfigAvancadaModel(
      aceitaAgendamento: json['aceita_agendamento'] as bool? ?? false,
      tempoMaximoEntregaMin:
          (json['tempo_maximo_entrega_min'] as num?)?.toInt() ?? 60,
      tempoMinimoEntregaMin:
          (json['tempo_minimo_entrega_min'] as num?)?.toInt() ?? 15,
      intervaloAtualizacaoEstoqueMin:
          (json['intervalo_atualizacao_estoque_min'] as num?)?.toInt() ?? 5,
      tempoAntecedenciaAgendamentoMin:
          (json['tempo_antecedencia_agendamento_min'] as num?)?.toInt() ?? 60,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'aceita_agendamento': aceitaAgendamento,
      'tempo_maximo_entrega_min': tempoMaximoEntregaMin,
      'tempo_minimo_entrega_min': tempoMinimoEntregaMin,
      'intervalo_atualizacao_estoque_min': intervaloAtualizacaoEstoqueMin,
      'tempo_antecedencia_agendamento_min': tempoAntecedenciaAgendamentoMin,
    };
  }

  ConfigAvancadaModel copyWith({
    bool? aceitaAgendamento,
    int? tempoMaximoEntregaMin,
    int? tempoMinimoEntregaMin,
    int? intervaloAtualizacaoEstoqueMin,
    int? tempoAntecedenciaAgendamentoMin,
  }) {
    return ConfigAvancadaModel(
      aceitaAgendamento: aceitaAgendamento ?? this.aceitaAgendamento,
      tempoMaximoEntregaMin:
          tempoMaximoEntregaMin ?? this.tempoMaximoEntregaMin,
      tempoMinimoEntregaMin:
          tempoMinimoEntregaMin ?? this.tempoMinimoEntregaMin,
      intervaloAtualizacaoEstoqueMin:
          intervaloAtualizacaoEstoqueMin ?? this.intervaloAtualizacaoEstoqueMin,
      tempoAntecedenciaAgendamentoMin: tempoAntecedenciaAgendamentoMin ??
          this.tempoAntecedenciaAgendamentoMin,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ConfigAvancadaModel &&
          runtimeType == other.runtimeType &&
          aceitaAgendamento == other.aceitaAgendamento &&
          tempoMaximoEntregaMin == other.tempoMaximoEntregaMin &&
          tempoMinimoEntregaMin == other.tempoMinimoEntregaMin &&
          intervaloAtualizacaoEstoqueMin ==
              other.intervaloAtualizacaoEstoqueMin &&
          tempoAntecedenciaAgendamentoMin ==
              other.tempoAntecedenciaAgendamentoMin;

  @override
  int get hashCode =>
      aceitaAgendamento.hashCode ^
      tempoMaximoEntregaMin.hashCode ^
      tempoMinimoEntregaMin.hashCode ^
      intervaloAtualizacaoEstoqueMin.hashCode ^
      tempoAntecedenciaAgendamentoMin.hashCode;
}
