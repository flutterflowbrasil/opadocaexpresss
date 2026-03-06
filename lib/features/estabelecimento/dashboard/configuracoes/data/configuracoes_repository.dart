import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estabelecimento_model.dart';

final configuracoesRepositoryProvider = Provider((ref) {
  return ConfiguracoesRepository(Supabase.instance.client);
});

class ConfiguracoesRepository {
  final SupabaseClient _client;

  ConfiguracoesRepository(this._client);

  Future<EstabelecimentoModel> getEstabelecimento(String id) async {
    final response =
        await _client.from('estabelecimentos').select().eq('id', id).single();

    return EstabelecimentoModel.fromJson(response);
  }

  Future<String?> getEstabelecimentoIdByUserId(String userId) async {
    final response = await _client
        .from('estabelecimentos')
        .select('id')
        .eq('usuario_id', userId)
        .maybeSingle();

    return response != null ? response['id'] as String : null;
  }

  Future<void> saveEstabelecimento(EstabelecimentoModel model) async {
    await _client
        .from('estabelecimentos')
        .update(model.toJson())
        .eq('id', model.id);
  }

  // Futuro: Adicionar upload de imagens para Storage
  Future<String> uploadImagem(
      String path, List<int> bytes, String fileName) async {
    final storagePath = 'estabelecimentos/$path/$fileName';
    await _client.storage
        .from('imagens')
        .uploadBinary(storagePath, bytes as dynamic);
    return _client.storage.from('imagens').getPublicUrl(storagePath);
  }
}
