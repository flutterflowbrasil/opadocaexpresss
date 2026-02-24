import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:padoca_express/features/cliente/padarias/models/padaria_model.dart';

class PadariaRepository {
  final SupabaseClient _client;

  PadariaRepository(this._client);

  /// Busca todos os estabelecimentos com categoria 'padaria'.
  /// Retorna os estabelecimentos com status_cadastro 'aprovado' ou todos
  /// para casos onde ainda não há aprovação (MVP).
  Future<List<PadariaModel>> fetchPadarias() async {
    try {
      final response = await _client
          .from('estabelecimentos')
          .select(
            'id, razao_social, descricao, logo_url, banner_url, '
            'avaliacao_media, total_avaliacoes, status_aberto, '
            'latitude, longitude, config_entrega, endereco, categoria',
          )
          .or('categoria.ilike.%padaria%,categoria.ilike.%padoca%')
          .order('avaliacao_media', ascending: false);

      return (response as List)
          .map((json) => PadariaModel.fromJson(json as Map<String, dynamic>))
          .toList();
    } catch (e) {
      // Retorna lista vazia em caso de erro (sem dados cadastrados ainda)
      return [];
    }
  }

  /// Busca padarias com join na tabela usuarios para obter o nome fantasia.
  Future<List<PadariaModel>> fetchPadariaComNomeFantasia() async {
    try {
      final response = await _client
          .from('estabelecimentos')
          .select(
            'id, razao_social, descricao, logo_url, banner_url, '
            'avaliacao_media, total_avaliacoes, status_aberto, '
            'latitude, longitude, config_entrega, endereco, categoria, '
            'usuarios!usuario_id(nome_completo_fantasia)',
          )
          .or('categoria.ilike.%padaria%,categoria.ilike.%padoca%')
          .order('avaliacao_media', ascending: false);

      return (response as List).map((json) {
        // Flatten nome_completo_fantasia do join
        final flatJson = Map<String, dynamic>.from(json);
        final usuario = flatJson.remove('usuarios');
        if (usuario != null && usuario is Map) {
          flatJson['nome_completo_fantasia'] =
              usuario['nome_completo_fantasia'];
        }
        return PadariaModel.fromJson(flatJson);
      }).toList();
    } catch (_) {
      // Fallback para query simples se join falhar
      return fetchPadarias();
    }
  }
}

// Provider do repositório
final padariaRepositoryProvider = Provider<PadariaRepository>((ref) {
  return PadariaRepository(Supabase.instance.client);
});

// Provider de estado assíncrono das padarias
final padariaListProvider = FutureProvider<List<PadariaModel>>((ref) async {
  final repo = ref.watch(padariaRepositoryProvider);
  return repo.fetchPadariaComNomeFantasia();
});
