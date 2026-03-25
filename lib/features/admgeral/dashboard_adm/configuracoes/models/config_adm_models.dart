class ConfigItem {
  final String id;
  final String secao;
  final String chave;
  final String valor;
  final String tipo; // 'number' | 'boolean' | 'text' | 'select'
  final String label;
  final String? descricao;
  final bool editavel;
  final DateTime updatedAt;
  final String? updatedBy;

  const ConfigItem({
    required this.id,
    required this.secao,
    required this.chave,
    required this.valor,
    required this.tipo,
    required this.label,
    this.descricao,
    required this.editavel,
    required this.updatedAt,
    this.updatedBy,
  });

  factory ConfigItem.fromJson(Map<String, dynamic> json) {
    return ConfigItem(
      id: json['id'] as String,
      secao: json['secao'] as String,
      chave: json['chave'] as String,
      valor: json['valor'] as String,
      tipo: json['tipo'] as String,
      label: json['label'] as String,
      descricao: json['descricao'] as String?,
      editavel: json['editavel'] as bool? ?? true,
      updatedAt: DateTime.parse(json['updated_at'] as String),
      updatedBy: json['updated_by'] as String?,
    );
  }

  ConfigItem copyWith({String? valor}) {
    return ConfigItem(
      id: id,
      secao: secao,
      chave: chave,
      valor: valor ?? this.valor,
      tipo: tipo,
      label: label,
      descricao: descricao,
      editavel: editavel,
      updatedAt: updatedAt,
      updatedBy: updatedBy,
    );
  }
}
