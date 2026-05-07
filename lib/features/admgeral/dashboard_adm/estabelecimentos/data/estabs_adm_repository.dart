import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/services/asaas_onboarding_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/estab_adm_model.dart';

final estabsAdmRepositoryProvider = Provider<EstabsAdmRepository>((ref) {
  return EstabsAdmRepository(Supabase.instance.client);
});

class EstabsAdmRepository {
  final SupabaseClient _client;
  final AsaasOnboardingService _asaasOnboarding;

  EstabsAdmRepository(this._client)
      : _asaasOnboarding = AsaasOnboardingService(_client);

  Future<List<EstabAdmModel>> listarEstabelecimentos() async {
    final response = await _client
        .from('estabelecimentos')
        .select(
          'id,nome_fantasia,razao_social,cnpj,status_cadastro,status_aberto,'
          'faturamento_total,total_pedidos,avaliacao_media,total_avaliacoes,'
          'created_at,responsavel_nome,responsavel_cpf,telefone_comercial,'
          'email_comercial,asaas_account_id,asaas_wallet_id,motivo_suspensao,'
          'destaque,documentos,dados_bancarios,categoria_estabelecimento_id,'
          'tempo_medio_entrega_min,'
          'estabelecimento_documentos(id,tipo,url,status_validacao,motivo_rejeicao,validado_em)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    final rows = (response as List)
        .map((json) => Map<String, dynamic>.from(json as Map))
        .toList();
    final subcontas = await _subcontasPorEstabelecimento(
      rows.map((row) => row['id'] as String).toList(),
    );

    final signedRows = await Future.wait(rows.map((row) async {
      row['estabelecimento_documentos'] =
          await _assinarUrlsDocumentos(row['estabelecimento_documentos'] as List?);
      final subconta = subcontas[row['id']];
      if (subconta != null) row['asaas_subcontas'] = [subconta];
      return EstabAdmModel.fromJson(row);
    }));
    return signedRows;
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
      await _validarDocumentacaoAprovada(id);
      body['motivo_suspensao'] = null;
      await _asaasOnboarding.ensureSubaccount(
        entityType: AsaasEntityType.estabelecimento,
        entityId: id,
      );
    }
    await _client.from('estabelecimentos').update(body).eq('id', id);
  }

  Future<void> revisarDocumento(
    String estabelecimentoId,
    String tipo,
    String status, {
    String? motivo,
  }) async {
    final payload = <String, dynamic>{
      'status_validacao': status,
      'motivo_rejeicao':
          status == 'reprovado' && motivo != null && motivo.isNotEmpty
              ? motivo
              : null,
      'validado_em': DateTime.now().toIso8601String(),
      'validado_por': _client.auth.currentUser?.id,
    };

    await _client
        .from('estabelecimento_documentos')
        .update(payload)
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('tipo', tipo);
  }

  Future<List<Map<String, dynamic>>> _assinarUrlsDocumentos(List? docs) async {
    final rawDocs = (docs ?? const []).cast<Map>();
    final signedDocs = <Map<String, dynamic>>[];
    for (final raw in rawDocs) {
      final doc = Map<String, dynamic>.from(raw);
      final path = doc['url'] as String?;
      if (path != null && path.isNotEmpty) {
        try {
          doc['signed_url'] = await _client.storage
              .from('documentos')
              .createSignedUrl(path, 60 * 60);
        } catch (_) {
          doc['signed_url'] = null;
        }
      }
      signedDocs.add(doc);
    }
    return signedDocs;
  }

  Future<Map<String, Map<String, dynamic>>> _subcontasPorEstabelecimento(
    List<String> ids,
  ) async {
    if (ids.isEmpty) return {};
    try {
      final response = await _client
          .from('v_asaas_subcontas_app')
          .select(
            'entidade_id,asaas_account_id,asaas_wallet_id,status_conta,'
            'onboarding_url,motivo_rejeicao,ultima_sincronizacao',
          )
          .eq('entidade_tipo', 'estabelecimento')
          .inFilter('entidade_id', ids);
      return {
        for (final row in (response as List).cast<Map>())
          row['entidade_id'] as String: Map<String, dynamic>.from(row)
      };
    } catch (_) {
      return {};
    }
  }

  Future<void> _validarDocumentacaoAprovada(String estabelecimentoId) async {
    final docs = await _client
        .from('estabelecimento_documentos')
        .select('tipo,status_validacao')
        .eq('estabelecimento_id', estabelecimentoId);
    final statusPorTipo = {
      for (final doc in (docs as List).cast<Map>())
        doc['tipo'] as String: doc['status_validacao'] as String?
    };
    final usaCnh = statusPorTipo.keys.any(
      (tipo) => tipo.startsWith('cnh_responsavel'),
    );
    final obrigatorios = usaCnh
        ? const [
            'cnh_responsavel_frente',
            'cnh_responsavel_verso',
            'comprovante_endereco',
          ]
        : const [
            'identidade_responsavel_frente',
            'identidade_responsavel_verso',
            'comprovante_endereco',
          ];
    final faltantes = obrigatorios
        .where((tipo) => statusPorTipo[tipo] != 'aprovado')
        .toList();
    if (faltantes.isNotEmpty) {
      throw Exception(
        'Aprove todos os documentos obrigatorios antes de aprovar o estabelecimento.',
      );
    }
  }
}
