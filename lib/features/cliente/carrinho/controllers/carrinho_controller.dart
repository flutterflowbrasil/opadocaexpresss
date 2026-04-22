import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:padoca_express/features/cliente/carrinho/data/cupom_repository.dart';
import 'package:padoca_express/features/cliente/carrinho/models/cupom_model.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Estado do Carrinho
// ─────────────────────────────────────────────────────────────────────────────
class CarrinhoState {
  final List<ItemCarrinhoModel> itens;
  final EstabelecimentoModel? estabelecimento;
  final CupomModel? cupomAplicado;
  final bool isValidandoCupom;
  final String? cupomErro;

  const CarrinhoState({
    this.itens = const [],
    this.estabelecimento,
    this.cupomAplicado,
    this.isValidandoCupom = false,
    this.cupomErro,
  });

  CarrinhoState copyWith({
    List<ItemCarrinhoModel>? itens,
    EstabelecimentoModel? estabelecimento,
    CupomModel? cupomAplicado,
    bool clearCupom = false,
    bool? isValidandoCupom,
    String? cupomErro,
    bool clearCupomErro = false,
  }) {
    return CarrinhoState(
      itens: itens ?? this.itens,
      estabelecimento: estabelecimento ?? this.estabelecimento,
      cupomAplicado: clearCupom ? null : (cupomAplicado ?? this.cupomAplicado),
      isValidandoCupom: isValidandoCupom ?? this.isValidandoCupom,
      cupomErro: clearCupomErro ? null : (cupomErro ?? this.cupomErro),
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
      // Cupom NÃO é persistido localmente por segurança — re-validado sempre
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
      itens.fold(0.0, (total, item) => total + item.subtotal);

  double get desconto {
    if (cupomAplicado == null) return 0;
    final taxaEntrega = estabelecimento?.taxaEntregaValor ?? 0;
    return cupomAplicado!
        .calcularDesconto(valorTotalProdutos, taxaEntrega: taxaEntrega);
  }

  double get valorTotal {
    final base =
        valorTotalProdutos + (estabelecimento?.taxaEntregaValor ?? 0.0);
    return (base - desconto).clamp(0, double.infinity);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Controller
// ─────────────────────────────────────────────────────────────────────────────
class CarrinhoController extends StateNotifier<CarrinhoState> {
  static const _storageKey = 'padoca_carrinho_state';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final CupomRepository _cupomRepo;

  CarrinhoController(this._cupomRepo) : super(const CarrinhoState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data != null) {
        state = CarrinhoState.fromJson(jsonDecode(data));
      }
    } catch (_) {}
  }

  Future<void> _updateState(CarrinhoState newState) async {
    state = newState;
    try {
      await _storage.write(
        key: _storageKey,
        value: jsonEncode(newState.toJson()),
      );
    } catch (_) {}
  }

  // ── Produtos ───────────────────────────────────────────────────────────────

  void adicionarProduto(ProdutoModel produto, int quantidade,
      {String? observacao, EstabelecimentoModel? estabelecimento}) {
    if (state.estabelecimento != null &&
        estabelecimento != null &&
        state.estabelecimento!.id != estabelecimento.id) {
      limparCarrinho();
    }

    final index = state.itens.indexWhere((item) =>
        item.produto.id == produto.id && item.observacao == observacao);

    if (index >= 0) {
      final item = state.itens[index];
      final novaLista = List<ItemCarrinhoModel>.from(state.itens);
      novaLista[index] =
          item.copyWith(quantidade: item.quantidade + quantidade);
      _updateState(state.copyWith(
          itens: novaLista,
          estabelecimento: estabelecimento ?? state.estabelecimento));
    } else {
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

      if (novaLista.isEmpty) {
        limparCarrinho();
        return;
      }

      _updateState(state.copyWith(
        itens: novaLista,
        estabelecimento: state.estabelecimento,
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

  Future<void> limparCarrinho() async {
    state = const CarrinhoState();
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
  }

  // ── Cupom ──────────────────────────────────────────────────────────────────

  /// Tenta aplicar um cupom pelo código digitado.
  Future<void> aplicarCupom(String codigo) async {
    if (codigo.trim().isEmpty) return;

    state = state.copyWith(
      isValidandoCupom: true,
      clearCupomErro: true,
    );

    final resultado = await _cupomRepo.validarCupom(
      codigo: codigo,
      subtotalProdutos: state.valorTotalProdutos,
      estabelecimentoId: state.estabelecimento?.id,
    );

    if (resultado is CupomValido) {
      state = state.copyWith(
        cupomAplicado: resultado.cupom,
        isValidandoCupom: false,
        clearCupomErro: true,
      );
    } else if (resultado is CupomInvalido) {
      state = state.copyWith(
        clearCupom: true,
        isValidandoCupom: false,
        cupomErro: resultado.mensagem,
      );
    }
  }

  void removerCupom() {
    state = state.copyWith(clearCupom: true, clearCupomErro: true);
    debugPrint('[Carrinho] Cupom removido');
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Provider
// ─────────────────────────────────────────────────────────────────────────────
final carrinhoControllerProvider =
    StateNotifierProvider<CarrinhoController, CarrinhoState>((ref) {
  final cupomRepo = ref.watch(cupomRepositoryProvider);
  return CarrinhoController(cupomRepo);
});
