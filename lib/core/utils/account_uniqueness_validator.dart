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

    final rpcResult = await _checkViaRpc(
      email: normalized,
      ignoreUserId: ignoreUserId,
    );
    if (rpcResult?['email'] == true) {
      throw const DuplicateAccountException(DuplicateAccountField.email);
    }
    if (rpcResult != null) return;

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

    final rpcResult = await _checkViaRpc(
      cpf: digits,
      ignoreUserId: ignoreUserId,
    );
    if (rpcResult?['cpf'] == true) {
      throw const DuplicateAccountException(DuplicateAccountField.cpf);
    }
    if (rpcResult != null) return;

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

    final rpcResult = await _checkViaRpc(
      cnpj: digits,
      ignoreUserId: ignoreUserId,
    );
    if (rpcResult?['cnpj'] == true) {
      throw const DuplicateAccountException(DuplicateAccountField.cnpj);
    }
    if (rpcResult != null) return;

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
      return response.isNotEmpty;
    } on PostgrestException catch (e) {
      // Se RLS impedir a leitura anonima, o banco ainda garante a unicidade.
      if (e.code == '42501') return false;
      rethrow;
    }
  }

  Future<Map<String, dynamic>?> _checkViaRpc({
    String? email,
    String? cpf,
    String? cnpj,
    String? ignoreUserId,
  }) async {
    try {
      final response = await _supabase.rpc(
        'check_account_identifier_exists',
        params: {
          'p_email': email,
          'p_cpf': cpf,
          'p_cnpj': cnpj,
          'p_ignore_user_id': ignoreUserId,
        },
      );

      if (response is Map<String, dynamic>) return response;
      if (response is Map) {
        return response.map(
          (key, value) => MapEntry(key.toString(), value),
        );
      }
      return null;
    } on PostgrestException {
      return null;
    }
  }
}
