import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/features/cliente/carrinho/models/item_carrinho_model.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';

class CarrinhoRemoto {
  final String id;
  final EstabelecimentoModel estabelecimento;
  final List<ItemCarrinhoModel> itens;

  const CarrinhoRemoto({
    required this.id,
    required this.estabelecimento,
    required this.itens,
  });
}

class CarrinhoRepository {
  final SupabaseClient _client;

  CarrinhoRepository(this._client);

  String? get userId => _client.auth.currentUser?.id;

  Future<String?> getClienteId() async {
    final uid = userId;
    if (uid == null) return null;

    final row = await _client
        .from('clientes')
        .select('id')
        .eq('usuario_id', uid)
        .maybeSingle();

    return row?['id'] as String?;
  }

  Future<CarrinhoRemoto?> buscarCarrinhoAtual() async {
    final clienteId = await getClienteId();
    if (clienteId == null) return null;

    final carrinhos = await _client
        .from('carrinhos')
        .select('''
          id,
          estabelecimento_id,
          updated_at,
          estabelecimentos(
            id,
            razao_social,
            nome_fantasia,
            descricao,
            logo_url,
            banner_url,
            avaliacao_media,
            total_avaliacoes,
            status_aberto,
            latitude,
            longitude,
            config_entrega,
            endereco,
            categoria_estabelecimento_id
          )
        ''')
        .eq('cliente_id', clienteId)
        .order('updated_at', ascending: false)
        .limit(1);

    if (carrinhos.isEmpty) return null;
    final carrinho = Map<String, dynamic>.from(carrinhos.first);
    final itens = await buscarItens(carrinho['id'] as String);
    if (itens.isEmpty) return null;

    final estabelecimentoJson =
        Map<String, dynamic>.from(carrinho['estabelecimentos'] as Map);
    if (estabelecimentoJson['nome_fantasia'] != null) {
      estabelecimentoJson['razao_social'] =
          estabelecimentoJson['nome_fantasia'];
    }

    return CarrinhoRemoto(
      id: carrinho['id'] as String,
      estabelecimento: EstabelecimentoModel.fromJson(estabelecimentoJson),
      itens: itens,
    );
  }

  Future<List<ItemCarrinhoModel>> buscarItens(String carrinhoId) async {
    final rows = await _client.from('itens_carrinho').select('''
          id,
          quantidade,
          preco_unitario,
          opcoes_selecionadas,
          observacao,
          subtotal,
          tamanho_produto_id,
          tamanho_produto_nome,
          produtos(
            id,
            estabelecimento_id,
            nome,
            descricao,
            preco,
            preco_promocional,
            foto_principal_url,
            ativo,
            disponivel,
            permite_observacao,
            categoria_cardapio_id,
            tipo_produto,
            opcoes
          )
        ''').eq('carrinho_id', carrinhoId).order('created_at', ascending: true);

    return rows.map((raw) {
      final row = Map<String, dynamic>.from(raw);
      final produto = Map<String, dynamic>.from(row['produtos'] as Map);
      final precoBase = (produto['preco_promocional'] as num?)?.toDouble() ??
          (produto['preco'] as num?)?.toDouble() ??
          0.0;

      return ItemCarrinhoModel.fromJson({
        ...row,
        'produto': produto,
        'preco_base_produto': precoBase,
      });
    }).toList();
  }

  Future<String?> buscarOuCriarCarrinho({
    required String estabelecimentoId,
  }) async {
    final clienteId = await getClienteId();
    if (clienteId == null) return null;

    final existente = await _client
        .from('carrinhos')
        .select('id')
        .eq('cliente_id', clienteId)
        .eq('estabelecimento_id', estabelecimentoId)
        .order('updated_at', ascending: false)
        .limit(1)
        .maybeSingle();

    if (existente != null) return existente['id'] as String;

    final criado = await _client
        .from('carrinhos')
        .insert({
          'cliente_id': clienteId,
          'estabelecimento_id': estabelecimentoId,
        })
        .select('id')
        .single();

    return criado['id'] as String;
  }

  Future<ItemCarrinhoModel?> salvarItem({
    required String estabelecimentoId,
    required ItemCarrinhoModel item,
  }) async {
    final carrinhoId =
        await buscarOuCriarCarrinho(estabelecimentoId: estabelecimentoId);
    if (carrinhoId == null) return null;

    final payload = {
      'carrinho_id': carrinhoId,
      'produto_id': item.produto.id,
      'quantidade': item.quantidade,
      'preco_unitario': item.precoUnitario,
      'opcoes_selecionadas': item.opcoesSelecionadas,
      'observacao': item.observacao,
      'updated_at': DateTime.now().toIso8601String(),
      if (item.tamanhoProdutoId != null)
        'tamanho_produto_id': item.tamanhoProdutoId,
      if (item.tamanhoProdutoNome != null)
        'tamanho_produto_nome': item.tamanhoProdutoNome,
    };

    Map<String, dynamic>? row;
    if (item.id != null) {
      row = await _client
          .from('itens_carrinho')
          .update(payload)
          .eq('id', item.id!)
          .eq('carrinho_id', carrinhoId)
          .select('id, preco_unitario, quantidade')
          .maybeSingle();
    } else {
      final existente = await _buscarItemEquivalente(
        carrinhoId: carrinhoId,
        item: item,
      );

      if (existente != null) {
        row = await _client
            .from('itens_carrinho')
            .update(payload)
            .eq('id', existente)
            .select('id, preco_unitario, quantidade')
            .maybeSingle();
      } else {
        row = await _client
            .from('itens_carrinho')
            .insert(payload)
            .select('id, preco_unitario, quantidade')
            .single();
      }
    }

    if (row == null) return null;
    return item.copyWith(
      id: row['id'] as String?,
      precoUnitario:
          (row['preco_unitario'] as num?)?.toDouble() ?? item.precoUnitario,
    );
  }

  Future<void> removerItem(String? itemId) async {
    if (itemId == null) return;
    await _client.from('itens_carrinho').delete().eq('id', itemId);
  }

  Future<void> limparCarrinhoRemoto({String? estabelecimentoId}) async {
    final clienteId = await getClienteId();
    if (clienteId == null) return;

    var query = _client.from('carrinhos').delete().eq('cliente_id', clienteId);
    if (estabelecimentoId != null) {
      query = query.eq('estabelecimento_id', estabelecimentoId);
    }
    await query;
  }

  Future<void> trySync(Future<void> Function() action) async {
    if (userId == null) return;
    try {
      await action();
    } catch (e) {
      debugPrint('[CarrinhoRepository] sync ignorado: $e');
    }
  }

  Future<String?> _buscarItemEquivalente({
    required String carrinhoId,
    required ItemCarrinhoModel item,
  }) async {
    final rows = await _client
        .from('itens_carrinho')
        .select(
            'id, observacao, opcoes_selecionadas, tamanho_produto_id')
        .eq('carrinho_id', carrinhoId)
        .eq('produto_id', item.produto.id);

    final opcoesKey = _opcoesKey(item.opcoesSelecionadas);
    for (final raw in rows) {
      final row = Map<String, dynamic>.from(raw);
      final rowOpcoes = (row['opcoes_selecionadas'] as List? ?? [])
          .whereType<Map>()
          .map((opcao) => Map<String, dynamic>.from(opcao))
          .toList();
      if ((row['observacao'] as String? ?? '') == (item.observacao ?? '') &&
          (row['tamanho_produto_id'] as String?) == item.tamanhoProdutoId &&
          _opcoesKey(rowOpcoes) == opcoesKey) {
        return row['id'] as String?;
      }
    }
    return null;
  }

  String _opcoesKey(List<Map<String, dynamic>> opcoes) => jsonEncode(opcoes);
}

final carrinhoRepositoryProvider = Provider<CarrinhoRepository>((ref) {
  return CarrinhoRepository(ref.watch(supabaseClientProvider));
});
