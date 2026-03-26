class PedidoDisponivelModel {
  final String id;
  final int numero;
  final String enderecoCliente;
  final String clienteNome;
  final String nomeEstabelecimento;
  final String enderecoEstabelecimento;
  final double total;
  final double taxaEntrega;
  final DateTime at;

  const PedidoDisponivelModel({
    required this.id,
    required this.numero,
    required this.enderecoCliente,
    required this.clienteNome,
    required this.nomeEstabelecimento,
    required this.enderecoEstabelecimento,
    required this.total,
    required this.taxaEntrega,
    required this.at,
  });

  factory PedidoDisponivelModel.fromMap(Map<String, dynamic> map) {
    // Handling foreign key relational payload from Supabase
    final cliente = map['clientes'] ?? {};
    final estab = map['estabelecimentos'] ?? {};

    return PedidoDisponivelModel(
      id: map['id']?.toString() ?? '',
      numero: map['numero_pedido'] ?? 0,
      enderecoCliente: map['endereco_entrega_snapshot'] ?? '',
      clienteNome: cliente['nome'] ?? 'Cliente',
      nomeEstabelecimento: estab['nome_fantasia'] ?? '',
      enderecoEstabelecimento: estab['endereco'] ?? '',
      total: (map['total'] ?? 0).toDouble(),
      taxaEntrega: (map['taxa_entrega'] ?? 0).toDouble(),
      at: map['created_at'] != null
          ? DateTime.parse(map['created_at'])
          : DateTime.now(),
    );
  }
}
