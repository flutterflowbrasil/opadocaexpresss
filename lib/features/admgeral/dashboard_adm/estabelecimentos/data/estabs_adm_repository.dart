import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estab_adm_model.dart';

final estabsAdmRepositoryProvider = Provider<EstabsAdmRepository>((ref) {
  return EstabsAdmRepository(Supabase.instance.client);
});

class EstabsAdmRepository {
  final SupabaseClient _client;

  EstabsAdmRepository(this._client);

  Future<List<EstabAdmModel>> listarEstabelecimentos() async {
    final response = await _client
        .from('estabelecimentos')
        .select(
          'id,nome_fantasia,razao_social,cnpj,status_cadastro,status_aberto,'
          'faturamento_total,total_pedidos,avaliacao_media,total_avaliacoes,'
          'created_at,responsavel_nome,responsavel_cpf,telefone_comercial,'
          'email_comercial,asaas_account_id,motivo_suspensao,destaque,'
          'documentos,dados_bancarios,categoria_estabelecimento_id,tempo_medio_entrega_min',
        )
        .order('created_at', ascending: false)
        .limit(200);

    return (response as List)
        .map((json) => EstabAdmModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> atualizarStatus(
    String id,
    String novoStatus, {
    String? motivo,
  }) async {
    final body = <String, dynamic>{'status_cadastro': novoStatus};
    if (motivo != null && motivo.isNotEmpty) {
      body['motivo_suspensao'] = motivo;
    }
    if (novoStatus == 'aprovado') {
      body['motivo_suspensao'] = null;
    }
    await _client.from('estabelecimentos').update(body).eq('id', id);
  }
}
