import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:padoca_express/core/supabase/supabase_config.dart';
import 'package:padoca_express/core/utils/account_uniqueness_validator.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';

/// Lê, valida e grava o CPF do cliente.
///
/// Validação: checksum mod-11 + RPC `check_account_identifier_exists`
/// (a mesma usada no cadastro de padaria e entregador).
class ClienteCpfService {
  ClienteCpfService(this._supabase);

  final SupabaseClient _supabase;

  Future<String?> getCpfDigits(String userId) async {
    final row = await _supabase
        .from('clientes')
        .select('cpf')
        .eq('usuario_id', userId)
        .maybeSingle();
    final raw = row?['cpf'] as String?;
    if (raw == null || raw.trim().isEmpty) return null;
    final digits = BrazilianDocumentValidator.onlyDigits(raw);
    return digits.isEmpty ? null : digits;
  }

  /// Checksum + unicidade. Lança [DuplicateAccountException] se já existir.
  Future<String> validateCpf(String cpf, {required String userId}) async {
    final digits = BrazilianDocumentValidator.onlyDigits(cpf);
    if (!BrazilianDocumentValidator.isValidCpf(digits)) {
      throw Exception(BrazilianDocumentValidator.invalidCpfMessage);
    }
    await AccountUniquenessValidator(_supabase).ensureCpfAvailable(
      digits,
      ignoreUserId: userId,
    );
    return digits;
  }

  Future<String> validateAndSave(String cpf, {required String userId}) async {
    final digits = await validateCpf(cpf, userId: userId);

    final existing = await _supabase
        .from('clientes')
        .select('id')
        .eq('usuario_id', userId)
        .maybeSingle();

    if (existing == null) {
      await _supabase.from('clientes').insert({
        'usuario_id': userId,
        'cpf': digits,
      });
    } else {
      await _supabase
          .from('clientes')
          .update({'cpf': digits})
          .eq('usuario_id', userId);
    }
    return digits;
  }
}

final clienteCpfServiceProvider = Provider<ClienteCpfService>((ref) {
  return ClienteCpfService(ref.watch(supabaseClientProvider));
});
