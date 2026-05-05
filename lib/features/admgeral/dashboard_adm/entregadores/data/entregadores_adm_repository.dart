import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/services/asaas_onboarding_service.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../models/entregador_adm_model.dart';

final entregadoresAdmRepositoryProvider =
    Provider<EntregadoresAdmRepository>((ref) {
  return EntregadoresAdmRepository(Supabase.instance.client);
});

class EntregadoresAdmRepository {
  final SupabaseClient _client;
  final AsaasOnboardingService _asaasOnboarding;

  EntregadoresAdmRepository(this._client)
      : _asaasOnboarding = AsaasOnboardingService(_client);

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
          'usuario_id, endereco, '
          'usuarios!entregadores_usuario_id_fkey(nome_completo_fantasia, email, telefone), '
          'entregador_documentos(tipo, status_validacao, url, motivo_rejeicao, revisado_em), '
          'entregador_kyc(status, foto_selfie_url, observacao_admin, revisado_em, provider)',
        )
        .order('created_at', ascending: false)
        .limit(200);

    final rows = await Future.wait((response as List).map((json) async {
      final row = Map<String, dynamic>.from(json as Map);
      row['entregador_documentos'] =
          await _assinarUrlsDocumentos(row['entregador_documentos'] as List?);
      return EntregadorAdmModel.fromJson(row);
    }));
    return rows;
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
      await _validarDocumentacaoAprovada(id);
      await _validarEnderecoAsaas(id);
      body['motivo_rejeicao'] = null;
      await _asaasOnboarding.ensureSubaccount(
        entityType: AsaasEntityType.entregador,
        entityId: id,
      );
    }
    await _client.from('entregadores').update(body).eq('id', id);
  }

  Future<EntregadorEnderecoInfo> salvarEndereco(
    String entregadorId,
    EntregadorEnderecoInfo endereco,
  ) async {
    final cep = endereco.cep.replaceAll(RegExp(r'\D'), '');
    final payload = {
      'entregador_id': entregadorId,
      'cep': cep,
      'logradouro': endereco.logradouro.trim(),
      'numero': endereco.numero.trim(),
      'complemento': endereco.complemento?.trim().isEmpty == true
          ? null
          : endereco.complemento?.trim(),
      'bairro': endereco.bairro.trim(),
      'cidade': endereco.cidade.trim(),
      'estado': endereco.estado.trim().toUpperCase(),
      'is_principal': true,
    };

    final saved = await _client
        .from('entregador_enderecos')
        .upsert(payload, onConflict: 'entregador_id')
        .select(
            'id, cep, logradouro, numero, complemento, bairro, cidade, estado')
        .single();

    final enderecoSalvo =
        EntregadorEnderecoInfo.fromJson((saved as Map).cast<String, dynamic>());
    await _client
        .from('entregadores')
        .update({'endereco': enderecoSalvo.toJson()}).eq('id', entregadorId);

    return enderecoSalvo;
  }

  Future<void> revisarDocumento(
    String entregadorId,
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
      'revisado_em': DateTime.now().toIso8601String(),
      'revisado_por': _client.auth.currentUser?.id,
    };

    await _client
        .from('entregador_documentos')
        .update(payload)
        .eq('entregador_id', entregadorId)
        .eq('tipo', tipo);
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
      'p_observacao':
          (observacao != null && observacao.isNotEmpty) ? observacao : null,
    });

    await revisarDocumento(
      entregadorId,
      'selfie',
      status == 'aprovado' ? 'aprovado' : 'reprovado',
      motivo: observacao,
    );
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
              .from('documentos-entregador')
              .createSignedUrl(path, 60 * 60);
        } catch (_) {
          doc['signed_url'] = null;
        }
      }
      signedDocs.add(doc);
    }
    return signedDocs;
  }

  Future<void> _validarDocumentacaoAprovada(String entregadorId) async {
    final entregador = await _client
        .from('entregadores')
        .select('tipo_veiculo')
        .eq('id', entregadorId)
        .single();
    final tipoVeiculo = entregador['tipo_veiculo'] as String?;
    final obrigatorios = tipoVeiculo == 'moto' || tipoVeiculo == 'carro'
        ? const ['cnh_frente', 'cnh_verso', 'selfie']
        : const ['identidade_frente', 'identidade_verso', 'selfie'];

    final docs = await _client
        .from('entregador_documentos')
        .select('tipo, status_validacao')
        .eq('entregador_id', entregadorId);
    final statusPorTipo = {
      for (final doc in (docs as List).cast<Map>())
        doc['tipo'] as String: doc['status_validacao'] as String?
    };

    final faltantes = obrigatorios
        .where((tipo) => statusPorTipo[tipo] != 'aprovado')
        .toList();
    if (faltantes.isNotEmpty) {
      throw Exception(
        'Aprove todos os documentos obrigatorios antes de aprovar o entregador.',
      );
    }

    final kyc = await _client
        .from('entregador_kyc')
        .select('status')
        .eq('entregador_id', entregadorId)
        .eq('provider', 'manual')
        .maybeSingle();
    if (kyc?['status'] != 'aprovado') {
      throw Exception(
        'A selfie precisa estar aprovada na verificacao manual antes da aprovacao final.',
      );
    }
  }

  Future<void> _validarEnderecoAsaas(String entregadorId) async {
    // 1. Tenta buscar o endereço na tabela dedicada (fonte primária — novos cadastros)
    final enderecoRelRow = await _client
        .from('entregador_enderecos')
        .select('cep, logradouro, numero, bairro, cidade, estado')
        .eq('entregador_id', entregadorId)
        .eq('is_principal', true)
        .maybeSingle();

    if (enderecoRelRow != null) {
      final endereco = EntregadorEnderecoInfo.fromJson(
        (enderecoRelRow as Map).cast<String, dynamic>(),
      );
      if (!endereco.isComplete) {
        throw Exception(
          'Endereco incompleto para criar subconta Asaas. Preencha CEP, logradouro, numero, bairro, cidade e UF.',
        );
      }
      // Sincroniza o snapshot JSONB para manter retrocompatibilidade
      await _client
          .from('entregadores')
          .update({'endereco': endereco.toJson()}).eq('id', entregadorId);
      return;
    }

    // 2. Fallback: tenta o campo JSONB legado (entregadores antigos)
    final entregador = await _client
        .from('entregadores')
        .select('endereco')
        .eq('id', entregadorId)
        .single();

    final enderecoJson = entregador['endereco'] is Map
        ? (entregador['endereco'] as Map).cast<String, dynamic>()
        : null;

    if (enderecoJson == null || enderecoJson.isEmpty) {
      throw Exception(
        'Preencha o endereco do entregador antes de aprovar e criar a subconta Asaas.',
      );
    }

    final endereco = EntregadorEnderecoInfo.fromJson(enderecoJson);
    if (!endereco.isComplete) {
      throw Exception(
        'Endereco incompleto para criar subconta Asaas. Preencha CEP, logradouro, numero, bairro, cidade e UF.',
      );
    }

    await _client
        .from('entregadores')
        .update({'endereco': endereco.toJson()}).eq('id', entregadorId);
  }
}
