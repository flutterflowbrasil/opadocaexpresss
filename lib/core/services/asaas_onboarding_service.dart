import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final asaasOnboardingServiceProvider = Provider<AsaasOnboardingService>((ref) {
  return AsaasOnboardingService(Supabase.instance.client);
});

enum AsaasEntityType {
  estabelecimento('estabelecimento'),
  entregador('entregador');

  const AsaasEntityType(this.value);

  final String value;
}

class AsaasOnboardingResult {
  const AsaasOnboardingResult({
    required this.entityType,
    required this.entityId,
    this.accountId,
    this.walletId,
    this.status,
    this.alreadyExists = false,
    this.raw = const <String, dynamic>{},
  });

  factory AsaasOnboardingResult.fromJson(
    Map<String, dynamic> json, {
    required AsaasEntityType entityType,
    required String entityId,
  }) {
    return AsaasOnboardingResult(
      entityType: entityType,
      entityId: entityId,
      accountId: (json['accountId'] ??
              json['account_id'] ??
              json['asaas_account_id'] ??
              json['id'])
          ?.toString(),
      walletId: (json['walletId'] ??
              json['wallet_id'] ??
              json['asaas_wallet_id'])
          ?.toString(),
      status: (json['status'] ?? json['status_conta'])?.toString(),
      alreadyExists: json['alreadyExists'] == true ||
          json['already_exists'] == true ||
          json['ja_existia'] == true,
      raw: json,
    );
  }

  final AsaasEntityType entityType;
  final String entityId;
  final String? accountId;
  final String? walletId;
  final String? status;
  final bool alreadyExists;
  final Map<String, dynamic> raw;
}

class AsaasOnboardingService {
  AsaasOnboardingService(this._supabase);

  final SupabaseClient _supabase;

  /// Cria ou garante a subconta Asaas da entidade.
  ///
  /// A chave raiz do Asaas e a apiKey da subconta devem ficar somente na Edge
  /// Function. O app Flutter apenas solicita a criacao e recebe metadados nao
  /// sensiveis, como accountId, walletId e status.
  Future<AsaasOnboardingResult> ensureSubaccount({
    required AsaasEntityType entityType,
    required String entityId,
  }) async {
    try {
      final response = await _supabase.functions.invoke(
        'asaas-criar-subconta',
        body: {
          'entidade_tipo': entityType.value,
          'entidade_id': entityId,
        },
      );

      final data = response.data;
      if (response.status >= 400) {
        throw Exception(_extractErrorMessage(data));
      }

      if (data is Map<String, dynamic>) {
        return AsaasOnboardingResult.fromJson(
          data,
          entityType: entityType,
          entityId: entityId,
        );
      }

      if (data is Map) {
        return AsaasOnboardingResult.fromJson(
          data.cast<String, dynamic>(),
          entityType: entityType,
          entityId: entityId,
        );
      }

      return AsaasOnboardingResult(
        entityType: entityType,
        entityId: entityId,
      );
    } on FunctionException catch (e) {
      debugPrint('[AsaasOnboarding] FunctionException: ${e.details}');
      throw Exception(_extractErrorMessage(e.details));
    } catch (e) {
      debugPrint('[AsaasOnboarding] erro: $e');
      rethrow;
    }
  }

  String _extractErrorMessage(Object? data) {
    if (data is Map) {
      // Mensagem principal
      final mainMsg = (data['error'] ?? data['message'] ?? data['erro'] ?? data['reason'])
          ?.toString()
          .trim();

      // Detalhes do Asaas (payload 'details' contém a resposta bruta do Asaas)
      final details = data['details'];
      String? detailMsg;
      if (details is Map) {
        // Asaas retorna lista de erros no campo 'errors'
        final errors = details['errors'];
        if (errors is List && errors.isNotEmpty) {
          detailMsg = errors
              .whereType<Map>()
              .map((e) => e['description']?.toString() ?? e['code']?.toString())
              .whereType<String>()
              .join('; ');
        }
        // Ou um campo 'description' direto
        if (detailMsg == null || detailMsg.isEmpty) {
          detailMsg = (details['description'] ?? details['message'])?.toString();
        }
      }

      if (mainMsg != null && mainMsg.isNotEmpty) {
        if (detailMsg != null && detailMsg.isNotEmpty) {
          return '$mainMsg — $detailMsg';
        }
        return mainMsg;
      }
    }

    if (data != null && data.toString().trim().isNotEmpty) {
      return data.toString();
    }

    return 'Nao foi possivel criar a subconta Asaas.';
  }
}
