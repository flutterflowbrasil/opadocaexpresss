import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entregador_adm_model.dart';

final entregadoresAdmRepositoryProvider =
    Provider<EntregadoresAdmRepository>((ref) {
  return EntregadoresAdmRepository(Supabase.instance.client);
});

class EntregadoresAdmRepository {
  final SupabaseClient _client;

  EntregadoresAdmRepository(this._client);

  Future<List<EntregadorAdmModel>> listarEntregadores() async {
    final response = await _client
        .from('entregadores')
        .select(
          'id, status_cadastro, status_online, status_despacho, '
          'tipo_veiculo, veiculo_modelo, veiculo_placa, veiculo_cor, '
          'total_entregas, total_avaliacoes, avaliacao_media, '
          'ganhos_total, ganhos_disponiveis, asaas_wallet_id, '
          'created_at, data_nascimento, motivo_rejeicao, '
          'cpf, cnh_numero, cnh_categoria, cnh_validade, '
          'usuario_id, '
          'usuarios(nome_completo_fantasia, email, telefone), '
          'entregador_documentos(tipo, status_validacao), '
          'entregador_kyc(status, foto_selfie_url, observacao_admin, revisado_em, provider)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    return (response as List)
        .map((json) =>
            EntregadorAdmModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  Future<void> atualizarStatus(
    String id,
    String novoStatus, {
    String? motivo,
  }) async {
    final body = <String, dynamic>{'status_cadastro': novoStatus};
    if (motivo != null && motivo.isNotEmpty) {
      body['motivo_rejeicao'] = motivo;
    }
    if (novoStatus == 'aprovado') {
      body['motivo_rejeicao'] = null;
    }
    await _client.from('entregadores').update(body).eq('id', id);
  }

  /// Chama a RPC `revisar_selfie_entregador` (SECURITY DEFINER no banco)
  /// pois `entregador_kyc` é bloqueado para escrita direta pelo client.
  Future<void> revisarSelfie(
    String entregadorId,
    String status, {
    String? observacao,
  }) async {
    await _client.rpc('revisar_selfie_entregador', params: {
      'p_entregador_id': entregadorId,
      'p_status': status,
      'p_observacao': (observacao != null && observacao.isNotEmpty)
          ? observacao
          : null,
    });
  }
}
