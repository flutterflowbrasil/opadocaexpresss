class UsuarioAdmModel {
  final String id;
  final String nome;
  final String email;
  final String? telefone;
  final String tipoUsuario; // cliente | entregador | estabelecimento | admin
  final String status;      // ativo | inativo | suspenso | banido
  final bool emailVerificado;
  final bool telefoneVerificado;
  final DateTime? ultimoLogin;
  final DateTime? createdAt;

  // Dados extras — cliente
  final int? totalPedidos;
  final double? valorTotalGasto;
  final int? pontosFidelidade;

  // Dados extras — entregador
  final String? entregadorStatusCadastro;
  final int? totalEntregas;
  final double? entregadorAvaliacaoMedia;

  // Dados extras — estabelecimento
  final String? estabStatusCadastro;
  final String? nomeFantasia;
  final int? estabTotalPedidos;

  const UsuarioAdmModel({
    required this.id,
    required this.nome,
    required this.email,
    this.telefone,
    required this.tipoUsuario,
    required this.status,
    required this.emailVerificado,
    required this.telefoneVerificado,
    this.ultimoLogin,
    this.createdAt,
    this.totalPedidos,
    this.valorTotalGasto,
    this.pontosFidelidade,
    this.entregadorStatusCadastro,
    this.totalEntregas,
    this.entregadorAvaliacaoMedia,
    this.estabStatusCadastro,
    this.nomeFantasia,
    this.estabTotalPedidos,
  });

  bool get isAdmin => tipoUsuario == 'admin';

  factory UsuarioAdmModel.fromJson(
    Map<String, dynamic> json, {
    Map<String, dynamic>? clienteData,
    Map<String, dynamic>? entregadorData,
    Map<String, dynamic>? estabelecimentoData,
  }) {
    return UsuarioAdmModel(
      id: json['id'] as String,
      nome: (json['nome_completo_fantasia'] as String?) ?? '—',
      email: (json['email'] as String?) ?? '—',
      telefone: json['telefone'] as String?,
      tipoUsuario: (json['tipo_usuario'] as String?) ?? 'cliente',
      status: (json['status'] as String?) ?? 'ativo',
      emailVerificado: (json['email_verificado'] as bool?) ?? false,
      telefoneVerificado: (json['telefone_verificado'] as bool?) ?? false,
      ultimoLogin: json['ultimo_login'] != null
          ? DateTime.tryParse(json['ultimo_login'] as String)
          : null,
      createdAt: json['created_at'] != null
          ? DateTime.tryParse(json['created_at'] as String)
          : null,
      // Cliente
      totalPedidos: clienteData?['total_pedidos'] as int?,
      valorTotalGasto:
          (clienteData?['valor_total_gasto'] as num?)?.toDouble(),
      pontosFidelidade: clienteData?['pontos_fidelidade'] as int?,
      // Entregador
      entregadorStatusCadastro:
          entregadorData?['status_cadastro'] as String?,
      totalEntregas: entregadorData?['total_entregas'] as int?,
      entregadorAvaliacaoMedia:
          (entregadorData?['avaliacao_media'] as num?)?.toDouble(),
      // Estabelecimento
      estabStatusCadastro:
          estabelecimentoData?['status_cadastro'] as String?,
      nomeFantasia: estabelecimentoData?['nome_fantasia'] as String?,
      estabTotalPedidos: estabelecimentoData?['total_pedidos'] as int?,
    );
  }

  UsuarioAdmModel copyWith({String? status}) {
    return UsuarioAdmModel(
      id: id,
      nome: nome,
      email: email,
      telefone: telefone,
      tipoUsuario: tipoUsuario,
      status: status ?? this.status,
      emailVerificado: emailVerificado,
      telefoneVerificado: telefoneVerificado,
      ultimoLogin: ultimoLogin,
      createdAt: createdAt,
      totalPedidos: totalPedidos,
      valorTotalGasto: valorTotalGasto,
      pontosFidelidade: pontosFidelidade,
      entregadorStatusCadastro: entregadorStatusCadastro,
      totalEntregas: totalEntregas,
      entregadorAvaliacaoMedia: entregadorAvaliacaoMedia,
      estabStatusCadastro: estabStatusCadastro,
      nomeFantasia: nomeFantasia,
      estabTotalPedidos: estabTotalPedidos,
    );
  }
}
