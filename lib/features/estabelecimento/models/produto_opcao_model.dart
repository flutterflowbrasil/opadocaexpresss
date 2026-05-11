class ProdutoOpcaoItemModel {
  final String? id;
  final String nome;
  final String? descricao;
  final double? precoAdicional;
  final bool ativo;
  final int ordem;

  ProdutoOpcaoItemModel({
    this.id,
    required this.nome,
    this.descricao,
    this.precoAdicional,
    this.ativo = true,
    this.ordem = 0,
  });

  factory ProdutoOpcaoItemModel.fromJson(Map<String, dynamic> json) {
    return ProdutoOpcaoItemModel(
      id: json['id'] as String?,
      nome: json['nome'] as String? ?? '',
      descricao: json['descricao'] as String?,
      precoAdicional: _toDouble(json['preco'] ?? json['preco_adicional']),
      ativo: json['ativo'] as bool? ?? true,
      ordem: _toInt(json['ordem'], 0),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'descricao': descricao,
      'preco': precoAdicional ?? 0,
      'ativo': ativo,
      'ordem': ordem,
    };
  }
}

class ProdutoOpcaoModel {
  final String? id;
  final String nome;
  final String tipo;
  final bool obrigatorio;
  final int minimo;
  final int maximo;
  final bool ativo;
  final int ordem;
  final List<ProdutoOpcaoItemModel> itens;

  ProdutoOpcaoModel({
    this.id,
    required this.nome,
    this.tipo = 'multipla',
    required this.obrigatorio,
    required this.minimo,
    required this.maximo,
    this.ativo = true,
    this.ordem = 0,
    required this.itens,
  });

  factory ProdutoOpcaoModel.fromJson(Map<String, dynamic> json) {
    var itensList = json['itens'] as List? ?? [];
    final tipo = json['tipo'] == 'unica' ? 'unica' : 'multipla';
    final maximo = tipo == 'unica'
        ? 1
        : _toInt(json['max_selecoes'] ?? json['maximo'], 1);

    return ProdutoOpcaoModel(
      id: json['id'] as String?,
      nome: json['nome'] as String? ?? '',
      tipo: tipo,
      obrigatorio: json['obrigatorio'] as bool? ?? false,
      minimo: _toInt(json['min_selecoes'] ?? json['minimo'], 0),
      maximo: maximo,
      ativo: json['ativo'] as bool? ?? true,
      ordem: _toInt(json['ordem'], 0),
      itens: itensList
          .map((i) => ProdutoOpcaoItemModel.fromJson(i as Map<String, dynamic>))
          .where((item) => item.ativo && item.nome.trim().isNotEmpty)
          .toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem)),
    );
  }

  bool get isEscolhaUnica => tipo == 'unica' || maximo == 1;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nome': nome,
      'tipo': tipo,
      'obrigatorio': obrigatorio,
      'min_selecoes': minimo,
      'max_selecoes': maximo,
      'ativo': ativo,
      'ordem': ordem,
      'itens': itens.map((i) => i.toJson()).toList(),
    };
  }
}

int _toInt(dynamic value, int fallback) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value?.toString() ?? '') ?? fallback;
}

double? _toDouble(dynamic value) {
  if (value == null) return null;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString().replaceAll(',', '.'));
}
