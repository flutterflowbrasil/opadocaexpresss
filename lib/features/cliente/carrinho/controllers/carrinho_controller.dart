import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class CarrinhoState {
  final List<ItemCarrinhoModel> itens;
  final EstabelecimentoModel?
      estabelecimento; // O carrinho atual pertence a qual padaria?

  CarrinhoState({
    this.itens = const [],
    this.estabelecimento,
  });

  CarrinhoState copyWith({
    List<ItemCarrinhoModel>? itens,
    EstabelecimentoModel? estabelecimento,
  }) {
    return CarrinhoState(
      itens: itens ?? this.itens,
      estabelecimento: estabelecimento ?? this.estabelecimento,
    );
  }

  factory CarrinhoState.fromJson(Map<String, dynamic> json) {
    return CarrinhoState(
      itens: (json['itens'] as List? ?? [])
          .map((i) => ItemCarrinhoModel.fromJson(i as Map<String, dynamic>))
          .toList(),
      estabelecimento: json['estabelecimento'] != null
          ? EstabelecimentoModel.fromJson(
              json['estabelecimento'] as Map<String, dynamic>)
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itens': itens.map((i) => i.toJson()).toList(),
      'estabelecimento': estabelecimento?.toJson(),
    };
  }

  int get quantidadeTotal =>
      itens.fold(0, (total, item) => total + item.quantidade);
  double get valorTotalProdutos =>
      itens.fold(0, (total, item) => total + item.subtotal);
  double get valorTotal =>
      valorTotalProdutos +
      (estabelecimento?.configEntrega?['taxa_entrega_fixa'] ?? 0.0);
}

class CarrinhoController extends StateNotifier<CarrinhoState> {
  static const _storageKey = 'padoca_carrinho_state';

  CarrinhoController() : super(CarrinhoState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final data = prefs.getString(_storageKey);
      if (data != null) {
        state = CarrinhoState.fromJson(jsonDecode(data));
      }
    } catch (_) {
      // Ignorar e manter o carrinho vazio em caso de erro na desserialização
    }
  }

  Future<void> _updateState(CarrinhoState newState) async {
    state = newState;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storageKey, jsonEncode(newState.toJson()));
    } catch (_) {
      // Falha ao salvar no storage local
    }
  }

  void adicionarProduto(ProdutoModel produto, int quantidade,
      {String? observacao, EstabelecimentoModel? estabelecimento}) {
    // Se está adicionando de outro estabelecimento, limpa o carrinho atual
    if (state.estabelecimento != null &&
        estabelecimento != null &&
        state.estabelecimento!.id != estabelecimento.id) {
      limparCarrinho();
    }

    final index = state.itens.indexWhere((item) =>
        item.produto.id == produto.id && item.observacao == observacao);

    if (index >= 0) {
      // Produto já existe, apenas incrementa a quantidade
      final item = state.itens[index];
      final novaLista = List<ItemCarrinhoModel>.from(state.itens);
      novaLista[index] =
          item.copyWith(quantidade: item.quantidade + quantidade);

      _updateState(state.copyWith(
          itens: novaLista,
          estabelecimento: estabelecimento ?? state.estabelecimento));
    } else {
      // Novo produto no carrinho
      final novaLista = List<ItemCarrinhoModel>.from(state.itens)
        ..add(ItemCarrinhoModel(
            produto: produto, quantidade: quantidade, observacao: observacao));

      _updateState(state.copyWith(
          itens: novaLista,
          estabelecimento: estabelecimento ?? state.estabelecimento));
    }
  }

  void removerProduto(ProdutoModel produto, {String? observacao}) {
    final index = state.itens.indexWhere((item) =>
        item.produto.id == produto.id && item.observacao == observacao);

    if (index >= 0) {
      final novaLista = List<ItemCarrinhoModel>.from(state.itens);
      novaLista.removeAt(index);

      _updateState(state.copyWith(
        itens: novaLista,
        estabelecimento: novaLista.isEmpty
            ? null
            : state
                .estabelecimento, // Limpa o estabelecimento se o carrinho esvaziar
      ));
    }
  }

  void atualizarQuantidade(ProdutoModel produto, int novaQuantidade,
      {String? observacao}) {
    if (novaQuantidade <= 0) {
      removerProduto(produto, observacao: observacao);
      return;
    }

    final index = state.itens.indexWhere((item) =>
        item.produto.id == produto.id && item.observacao == observacao);

    if (index >= 0) {
      final item = state.itens[index];
      final novaLista = List<ItemCarrinhoModel>.from(state.itens);
      novaLista[index] = item.copyWith(quantidade: novaQuantidade);

      _updateState(state.copyWith(itens: novaLista));
    }
  }

  void limparCarrinho() {
    _updateState(CarrinhoState());
  }
}

// Global Provider para o Carrinho (in-memory)
final carrinhoControllerProvider =
    StateNotifierProvider<CarrinhoController, CarrinhoState>((ref) {
  return CarrinhoController();
});
