import 'package:supabase_flutter/supabase_flutter.dart';

import 'account_uniqueness_validator.dart';

class SupabaseErrorHandler {
  static String parseError(Object error) {
    if (error is DuplicateAccountException) {
      return error.message;
    } else if (error is AuthException) {
      return _parseAuthError(error);
    } else if (error is PostgrestException) {
      return _parsePostgrestError(error);
    } else if (error is StorageException ||
        error.toString().contains('StorageException')) {
      return _parseStorageError(error);
    } else if (error.toString().contains('FunctionException')) {
      return 'Erro em servico externo. O cadastro foi processado, mas uma etapa secundaria falhou.';
    } else if (error.toString().contains('network_error') ||
        error.toString().contains('SocketException')) {
      return 'Erro de conexao. Verifique sua internet.';
    }

    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  static String _parseAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('user already registered') ||
        message.contains('already exists') ||
        message.contains('already registered')) {
      return 'Este e-mail ja esta cadastrado.';
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Por favor, confirme seu e-mail antes de entrar.';
    }
    if (message.contains('password is too short')) {
      return 'A senha e muito curta.';
    }

    return 'Erro na autenticacao: ${error.message}';
  }

  static String _parsePostgrestError(PostgrestException error) {
    switch (error.code) {
      case '23505':
        return _parseUniqueViolation(error);
      case '42501':
        if (error.message.contains('categorias_cardapio')) {
          return 'Esta categoria é gerenciada pela plataforma ou você não tem permissão para alterá-la.';
        }
        return 'Erro de permissao no banco de dados. Contate o suporte.';
      case '23503':
        return 'Erro de referencia: dados relacionados nao encontrados.';
      default:
        return 'Erro no banco de dados. Tente novamente ou contate o suporte.';
    }
  }

  static String _parseUniqueViolation(PostgrestException error) {
    final detail = '${error.message} ${error.details ?? ''}'.toLowerCase();

    if (detail.contains('email') || detail.contains('usuarios_email')) {
      return 'Este e-mail ja esta cadastrado.';
    }
    if (detail.contains('cpf') ||
        detail.contains('clientes_cpf') ||
        detail.contains('entregadores_cpf') ||
        detail.contains('responsavel_cpf')) {
      return 'Este CPF ja esta cadastrado.';
    }
    if (detail.contains('cnpj') || detail.contains('estabelecimentos_cnpj')) {
      return 'Este CNPJ ja esta cadastrado.';
    }

    return 'E-mail, CPF ou CNPJ ja cadastrado no sistema.';
  }

  static String _parseStorageError(Object error) {
    final message = error.toString().toLowerCase();

    if (message.contains('bucket not found') ||
        message.contains('the resource was not found')) {
      return 'Bucket de documentos nao encontrado no Storage.';
    }
    if (message.contains('permission') ||
        message.contains('unauthorized') ||
        message.contains('row-level security')) {
      return 'Sem permissao para enviar documentos. Verifique as politicas do Storage.';
    }
    if (message.contains('payload too large') || message.contains('too large')) {
      return 'Arquivo muito grande para envio.';
    }

    return 'Erro ao enviar documento. Tente novamente.';
  }
}
