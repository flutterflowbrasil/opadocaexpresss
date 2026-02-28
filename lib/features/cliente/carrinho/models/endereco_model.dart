class EnderecoClienteModel {
  final String id;
  final String logradouro;
  final String numero;
  final String bairro;
  final String cidade;
  final String estado;

  EnderecoClienteModel({
    required this.id,
    required this.logradouro,
    required this.numero,
    required this.bairro,
    required this.cidade,
    required this.estado,
  });

  factory EnderecoClienteModel.fromJson(Map<String, dynamic> json) {
    return EnderecoClienteModel(
      id: json['id'] as String,
      logradouro: json['logradouro'] as String,
      numero: json['numero'] as String,
      bairro: json['bairro'] as String,
      cidade: json['cidade'] as String,
      estado: json['estado'] as String,
    );
  }
}
