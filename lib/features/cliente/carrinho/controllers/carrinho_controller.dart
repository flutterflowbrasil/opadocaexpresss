import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:padoca_express/features/cliente/carrinho/data/carrinho_repository.dart';
import 'package:padoca_express/features/cliente/carrinho/data/cupom_repository.dart';
import 'package:padoca_express/features/cliente/carrinho/models/cupom_model.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

class CarrinhoState {
  final List<ItemCarrinhoModel> itens;
  final EstabelecimentoModel? estabelecimento;
  final CupomModel? cupomAplicado;
  final bool isValidandoCupom;
  final String? cupomErro;
  final String? observacaoGeral;

  const CarrinhoState({
    this.itens = const [],
    this.estabelecimento,
    this.cupomAplicado,
    this.isValidandoCupom = false,
    this.cupomErro,
    this.observacaoGeral,
  });

  CarrinhoState copyWith({
    List<ItemCarrinhoModel>? itens,
    EstabelecimentoModel? estabelecimento,
    CupomModel? cupomAplicado,
    bool clearCupom = false,
    bool? isValidandoCupom,
    String? cupomErro,
    bool clearCupomErro = false,
    String? observacaoGeral,
    bool clearObservacaoGeral = false,
  }) {
    return CarrinhoState(
      itens: itens ?? this.itens,
      estabelecimento: estabelecimento ?? this.estabelecimento,
      cupomAplicado: clearCupom ? null : (cupomAplicado ?? this.cupomAplicado),
      isValidandoCupom: isValidandoCupom ?? this.isValidandoCupom,
      cupomErro: clearCupomErro ? null : (cupomErro ?? this.cupomErro),
      observacaoGeral: clearObservacaoGeral
          ? null
          : (observacaoGeral ?? this.observacaoGeral),
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
      observacaoGeral: json['observacao_geral'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'itens': itens.map((i) => i.toJson()).toList(),
      'estabelecimento': estabelecimento?.toJson(),
      if (observacaoGeral != null && observacaoGeral!.isNotEmpty)
        'observacao_geral': observacaoGeral,
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

class CarrinhoController extends StateNotifier<CarrinhoState> {
  static const _storageKey = 'padoca_carrinho_state';
  static const _storage = FlutterSecureStorage(
    aOptions: AndroidOptions(encryptedSharedPreferences: true),
  );

  final CupomRepository _cupomRepo;
  final CarrinhoRepository? _carrinhoRepo;

  CarrinhoController(this._cupomRepo, [this._carrinhoRepo])
      : super(const CarrinhoState()) {
    _loadState();
  }

  Future<void> _loadState() async {
    try {
      final data = await _storage.read(key: _storageKey);
      if (data != null) {
        state = CarrinhoState.fromJson(jsonDecode(data));
      }
    } catch (_) {}

    final repo = _carrinhoRepo;
    if (repo == null) return;

    await repo.trySync(() async {
      final remoto = await repo.buscarCarrinhoAtual();
      if (remoto == null) return;
      await _updateState(state.copyWith(
        itens: remoto.itens,
        estabelecimento: remoto.estabelecimento,
      ));
    });
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

  void adicionarProduto(
    ProdutoModel produto,
    int quantidade, {
    String? observacao,
    EstabelecimentoModel? estabelecimento,
    double? precoBaseProduto,
    double? precoUnitario,
    List<Map<String, dynamic>> opcoesSelecionadas = const [],
    String? tamanhoProdutoId,
    String? tamanhoProdutoNome,
  }) {
    if (state.estabelecimento != null &&
        estabelecimento != null &&
        state.estabelecimento!.id != estabelecimento.id) {
      unawaited(limparCarrinho());
    }

    final index = state.itens.indexWhere((item) => _sameCartEntry(
          item,
          produto,
          observacao,
          opcoesSelecionadas,
          tamanhoProdutoId,
        ));

    if (index >= 0) {
      final item = state.itens[index];
      final atualizado =
          item.copyWith(quantidade: item.quantidade + quantidade);
      final novaLista = List<ItemCarrinhoModel>.from(state.itens)
        ..[index] = atualizado;
      unawaited(_updateState(state.copyWith(
        itens: novaLista,
        estabelecimento: estabelecimento ?? state.estabelecimento,
      )));
      _salvarItemRemoto(atualizado, estabelecimento ?? state.estabelecimento);
      return;
    }

    final novoItem = ItemCarrinhoModel(
      produto: produto,
      quantidade: quantidade,
      precoBaseProduto: precoBaseProduto ?? produto.precoAtual,
      precoUnitario: precoUnitario ?? produto.precoAtual,
      opcoesSelecionadas: opcoesSelecionadas,
      observacao: observacao?.trim().isEmpty == true ? null : observacao,
      tamanhoProdutoId: tamanhoProdutoId,
      tamanhoProdutoNome: tamanhoProdutoNome,
    );
    final novaLista = List<ItemCarrinhoModel>.from(state.itens)..add(novoItem);
    unawaited(_updateState(state.copyWith(
      itens: novaLista,
      estabelecimento: estabelecimento ?? state.estabelecimento,
    )));
    _salvarItemRemoto(novoItem, estabelecimento ?? state.estabelecimento);
  }

  void removerProduto(
    ProdutoModel produto, {
    String? observacao,
    List<Map<String, dynamic>> opcoesSelecionadas = const [],
    String? tamanhoProdutoId,
  }) {
    final index = state.itens.indexWhere((item) => _sameCartEntry(
          item,
          produto,
          observacao,
          opcoesSelecionadas,
          tamanhoProdutoId,
        ));

    if (index < 0) return;

    final novaLista = List<ItemCarrinhoModel>.from(state.itens);
    final removido = novaLista.removeAt(index);
    final repo = _carrinhoRepo;
    if (repo != null) {
      unawaited(repo.trySync(() => repo.removerItem(removido.id)));
    }

    if (novaLista.isEmpty) {
      unawaited(limparCarrinho());
      return;
    }

    unawaited(_updateState(state.copyWith(
      itens: novaLista,
      estabelecimento: state.estabelecimento,
    )));
  }

  void atualizarQuantidade(
    ProdutoModel produto,
    int novaQuantidade, {
    String? observacao,
    List<Map<String, dynamic>> opcoesSelecionadas = const [],
    String? tamanhoProdutoId,
  }) {
    if (novaQuantidade <= 0) {
      removerProduto(
        produto,
        observacao: observacao,
        opcoesSelecionadas: opcoesSelecionadas,
        tamanhoProdutoId: tamanhoProdutoId,
      );
      return;
    }

    final index = state.itens.indexWhere((item) => _sameCartEntry(
          item,
          produto,
          observacao,
          opcoesSelecionadas,
          tamanhoProdutoId,
        ));

    if (index < 0) return;

    final atualizado = state.itens[index].copyWith(quantidade: novaQuantidade);
    final novaLista = List<ItemCarrinhoModel>.from(state.itens)
      ..[index] = atualizado;
    unawaited(_updateState(state.copyWith(itens: novaLista)));
    _salvarItemRemoto(atualizado, state.estabelecimento);
  }

  void atualizarObservacao(
    ProdutoModel produto,
    String? observacaoAntiga,
    String novaObservacao, {
    List<Map<String, dynamic>> opcoesSelecionadas = const [],
    String? tamanhoProdutoId,
  }) {
    final observacaoNormalizada =
        novaObservacao.trim().isEmpty ? null : novaObservacao.trim();
    final index = state.itens.indexWhere((item) => _sameCartEntry(
          item,
          produto,
          observacaoAntiga,
          opcoesSelecionadas,
          tamanhoProdutoId,
        ));

    if (index < 0) return;

    final item = state.itens[index];
    final novaLista = List<ItemCarrinhoModel>.from(state.itens);
    final existingIndex = state.itens.indexWhere((i) =>
        i != item &&
        _sameCartEntry(i, produto, observacaoNormalizada, opcoesSelecionadas, tamanhoProdutoId));

    if (existingIndex >= 0) {
      final atualizado = novaLista[existingIndex].copyWith(
        quantidade: novaLista[existingIndex].quantidade + item.quantidade,
      );
      novaLista[existingIndex] = atualizado;
      novaLista.removeAt(index);
      _salvarItemRemoto(atualizado, state.estabelecimento);
      final repo = _carrinhoRepo;
      if (repo != null) {
        unawaited(repo.trySync(() => repo.removerItem(item.id)));
      }
    } else {
      final atualizado = item.copyWith(
        observacao: observacaoNormalizada,
        clearObservacao: observacaoNormalizada == null,
      );
      novaLista[index] = atualizado;
      _salvarItemRemoto(atualizado, state.estabelecimento);
    }

    unawaited(_updateState(state.copyWith(itens: novaLista)));
  }

  void atualizarObservacaoGeral(String obs) {
    unawaited(_updateState(state.copyWith(
      observacaoGeral: obs.trim().isEmpty ? null : obs.trim(),
      clearObservacaoGeral: obs.trim().isEmpty,
    )));
  }

  Future<void> limparCarrinho() async {
    final estabelecimentoId = state.estabelecimento?.id;
    state = const CarrinhoState();
    try {
      await _storage.delete(key: _storageKey);
    } catch (_) {}
    final repo = _carrinhoRepo;
    if (repo == null) return;
    await repo.trySync(
      () => repo.limparCarrinhoRemoto(
        estabelecimentoId: estabelecimentoId,
      ),
    );
  }

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

  bool _sameCartEntry(
    ItemCarrinhoModel item,
    ProdutoModel produto,
    String? observacao,
    List<Map<String, dynamic>> opcoesSelecionadas,
    String? tamanhoProdutoId,
  ) {
    return item.produto.id == produto.id &&
        (item.observacao ?? '') == (observacao ?? '') &&
        item.tamanhoProdutoId == tamanhoProdutoId &&
        _optionsKey(item.opcoesSelecionadas) == _optionsKey(opcoesSelecionadas);
  }

  String _optionsKey(List<Map<String, dynamic>> opcoes) => jsonEncode(opcoes);

  void _salvarItemRemoto(
    ItemCarrinhoModel item,
    EstabelecimentoModel? estabelecimento,
  ) {
    if (estabelecimento == null) return;
    final repo = _carrinhoRepo;
    if (repo == null) return;
    unawaited(repo.trySync(
      () => repo.salvarItem(
        estabelecimentoId: estabelecimento.id,
        item: item,
      ),
    ));
  }
}

final carrinhoControllerProvider =
    StateNotifierProvider<CarrinhoController, CarrinhoState>((ref) {
  final cupomRepo = ref.watch(cupomRepositoryProvider);
  final carrinhoRepo = ref.watch(carrinhoRepositoryProvider);
  return CarrinhoController(cupomRepo, carrinhoRepo);
});
