import 'package:padoca_express/features/estabelecimento/models/produto_opcao_model.dart';

class ProdutoModel {
  final String id;
  final String estabelecimentoId;
  final String nome;
  final String? descricao;
  final double preco;
  final double? precoPromocional;
  final String? imagemUrl;
  final bool isAtivo;
  final bool permiteObservacoes;
  final String? categoriaCardapioId;
  final String tipoProduto;
  final List<ProdutoOpcaoModel> opcoes;

  ProdutoModel({
    required this.id,
    required this.estabelecimentoId,
    required this.nome,
    this.descricao,
    required this.preco,
    this.precoPromocional,
    this.imagemUrl,
    required this.isAtivo,
    required this.permiteObservacoes,
    this.categoriaCardapioId,
    this.tipoProduto = 'simples',
    this.opcoes = const [],
  });

  factory ProdutoModel.fromJson(Map<String, dynamic> json) {
    return ProdutoModel(
      id: json['id'] as String,
      estabelecimentoId: json['estabelecimento_id'] as String,
      nome: json['nome'] as String,
      descricao: json['descricao'] as String?,
      preco: (json['preco'] as num).toDouble(),
      precoPromocional: json['preco_promocional'] != null
          ? (json['preco_promocional'] as num).toDouble()
          : null,
      imagemUrl: json['foto_principal_url'] as String?,
      isAtivo: json['ativo'] ?? true,
      permiteObservacoes: json['permite_observacao'] ?? true,
      categoriaCardapioId: json['categoria_cardapio_id'] as String?,
      tipoProduto: json['tipo_produto'] as String? ?? 'simples',
      opcoes: (json['opcoes'] as List? ?? [])
          .map((opcao) =>
              ProdutoOpcaoModel.fromJson(opcao as Map<String, dynamic>))
          .where((opcao) =>
              opcao.ativo &&
              opcao.nome.trim().isNotEmpty &&
              opcao.itens.isNotEmpty)
          .toList()
        ..sort((a, b) => a.ordem.compareTo(b.ordem)),
    );
  }

  double get precoAtual => precoPromocional ?? preco;

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'estabelecimento_id': estabelecimentoId,
      'nome': nome,
      'descricao': descricao,
      'preco': preco,
      'preco_promocional': precoPromocional,
      'foto_principal_url': imagemUrl,
      'is_ativo': isAtivo,
      'permite_observacao': permiteObservacoes,
      'categoria_cardapio_id': categoriaCardapioId,
      'tipo_produto': tipoProduto,
      'opcoes': opcoes.map((o) => o.toJson()).toList(),
    };
  }

  /// Verifica se o produto permite adicionar observações.
  /// Baseado na flag do BD e em palavras-chave do nome do produto/categoria.
  bool get aceitaObservacaoCategoria {
    if (!permiteObservacoes) return false;
    
    final nomeLower = nome.toLowerCase();
    
    // Categorias/Nomes que NÃO devem aceitar observações no carrinho
    final List<String> excluidos = [
      'bebida', 'refrigerante', 'suco', 'água', 'agua', 'energético', 'energetico', 'cerveja', 'long neck',
      'coca', 'lata',
      'molho', 'adicional', 'ketchup', 'maionese',
      'bala', 'chocolate', 'doce', 'embalado', 'pronto',
      'pão', 'pao', 'pães', 'paes',
    ];

    for (final excluido in excluidos) {
      if (nomeLower.contains(excluido)) {
        return false;
      }
    }

    return true;
  }
}
