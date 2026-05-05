import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

enum DuplicateAccountField {
  email,
  cpf,
  cnpj,
}

class DuplicateAccountException implements Exception {
  const DuplicateAccountException(this.field);

  final DuplicateAccountField field;

  String get message {
    return switch (field) {
      DuplicateAccountField.email => 'Este e-mail ja esta cadastrado.',
      DuplicateAccountField.cpf => 'Este CPF ja esta cadastrado.',
      DuplicateAccountField.cnpj => 'Este CNPJ ja esta cadastrado.',
    };
  }

  @override
  String toString() => message;
}

class AccountUniquenessValidator {
  const AccountUniquenessValidator(this._supabase);

  final SupabaseClient _supabase;

  Future<void> ensureEmailAvailable(String email, {String? ignoreUserId}) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty) return;

    final exists = await _exists(
      table: 'usuarios',
      column: 'email',
      value: normalized,
      caseInsensitive: true,
      ignoreColumn: 'id',
      ignoreValue: ignoreUserId,
    );

    if (exists) {
      throw const DuplicateAccountException(DuplicateAccountField.email);
    }
  }

  Future<void> ensureCpfAvailable(String cpf, {String? ignoreUserId}) async {
    final digits = BrazilianDocumentValidator.onlyDigits(cpf);
    if (digits.isEmpty) return;

    final foundInClientes = await _exists(
      table: 'clientes',
      column: 'cpf',
      value: digits,
      ignoreColumn: 'usuario_id',
      ignoreValue: ignoreUserId,
    );
    if (foundInClientes) {
      throw const DuplicateAccountException(DuplicateAccountField.cpf);
    }

    final foundInEntregadores = await _exists(
      table: 'entregadores',
      column: 'cpf',
      value: digits,
      ignoreColumn: 'usuario_id',
      ignoreValue: ignoreUserId,
    );
    if (foundInEntregadores) {
      throw const DuplicateAccountException(DuplicateAccountField.cpf);
    }

    final foundInResponsavel = await _exists(
      table: 'estabelecimentos',
      column: 'responsavel_cpf',
      value: digits,
      ignoreColumn: 'usuario_id',
      ignoreValue: ignoreUserId,
    );
    if (foundInResponsavel) {
      throw const DuplicateAccountException(DuplicateAccountField.cpf);
    }

    final foundInEstabelecimentoDocumento = await _exists(
      table: 'estabelecimentos',
      column: 'cnpj',
      value: digits,
      ignoreColumn: 'usuario_id',
      ignoreValue: ignoreUserId,
    );
    if (foundInEstabelecimentoDocumento) {
      throw const DuplicateAccountException(DuplicateAccountField.cpf);
    }
  }

  Future<void> ensureCnpjAvailable(String cnpj, {String? ignoreUserId}) async {
    final digits = BrazilianDocumentValidator.onlyDigits(cnpj);
    if (digits.isEmpty) return;

    final exists = await _exists(
      table: 'estabelecimentos',
      column: 'cnpj',
      value: digits,
      ignoreColumn: 'usuario_id',
      ignoreValue: ignoreUserId,
    );

    if (exists) {
      throw const DuplicateAccountException(DuplicateAccountField.cnpj);
    }
  }

  Future<bool> _exists({
    required String table,
    required String column,
    required String value,
    bool caseInsensitive = false,
    String? ignoreColumn,
    String? ignoreValue,
  }) async {
    try {
      var query = _supabase.from(table).select('id');
      query = caseInsensitive
          ? query.ilike(column, value)
          : query.eq(column, value);
      if (ignoreColumn != null && ignoreValue != null) {
        query = query.neq(ignoreColumn, ignoreValue);
      }

      final response = await query.limit(1);
      return response is List && response.isNotEmpty;
    } on PostgrestException catch (e) {
      // Se RLS impedir a leitura anonima, o banco ainda garante a unicidade.
      if (e.code == '42501') return false;
      rethrow;
    }
  }

}
