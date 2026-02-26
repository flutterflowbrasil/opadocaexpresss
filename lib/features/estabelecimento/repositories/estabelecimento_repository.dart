import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/home/models/estabelecimento_model.dart';
import 'package:padoca_express/features/estabelecimento/models/categoria_cardapio_model.dart';
import 'package:padoca_express/features/estabelecimento/models/produto_model.dart';

final estabelecimentoRepositoryProvider = Provider((ref) {
  return EstabelecimentoRepository(Supabase.instance.client);
});

class EstabelecimentoRepository {
  final SupabaseClient _client;

  EstabelecimentoRepository(this._client);

  Future<EstabelecimentoModel> getDetalhes(String estabelecimentoId) async {
    final response = await _client
        .from('estabelecimentos')
        .select(
            'id, razao_social, nome_fantasia, descricao, logo_url, banner_url, avaliacao_media, total_avaliacoes, status_aberto, latitude, longitude, config_entrega, endereco, categoria_estabelecimento_id, tempo_medio_entrega_min')
        .eq('id', estabelecimentoId)
        .single();

    // Vamos dar um fallback para nome_fantasia, se ele existir, na hora de criar o model
    final mapForModel = Map<String, dynamic>.from(response);
    if (mapForModel['nome_fantasia'] != null) {
      mapForModel['razao_social'] = mapForModel['nome_fantasia'];
    }

    return EstabelecimentoModel.fromJson(mapForModel);
  }

  Future<List<CategoriaCardapioModel>> getCategoriasCardapio(
      String estabelecimentoId) async {
    final response = await _client
        .from('categorias_cardapio')
        .select()
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('ativa', true)
        .order('ordem_exibicao', ascending: true);

    return (response as List)
        .map((json) => CategoriaCardapioModel.fromJson(json))
        .toList();
  }

  Future<List<ProdutoModel>> getProdutos(String estabelecimentoId) async {
    final response = await _client
        .from('produtos')
        .select()
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('disponivel', true);

    return (response as List)
        .map((json) => ProdutoModel.fromJson(json))
        .toList();
  }
}
