import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseErrorHandler {
  static String parseError(Object error) {
    if (error is AuthException) {
      return _parseAuthError(error);
    } else if (error is PostgrestException) {
      return _parsePostgrestError(error);
    } else if (error.toString().contains('network_error') ||
        error.toString().contains('SocketException')) {
      return 'Erro de conexão. Verifique sua internet.';
    }

    return 'Ocorreu um erro inesperado. Tente novamente.';
  }

  static String _parseAuthError(AuthException error) {
    final message = error.message.toLowerCase();

    if (message.contains('user already registered') ||
        message.contains('already exists')) {
      return 'Este e-mail já está cadastrado.';
    }
    if (message.contains('invalid login credentials') ||
        message.contains('invalid credentials')) {
      return 'E-mail ou senha incorretos.';
    }
    if (message.contains('email not confirmed')) {
      return 'Por favor, confirme seu e-mail antes de entrar.';
    }
    if (message.contains('password is too short')) {
      return 'A senha é muito curta.';
    }

    return 'Erro na autenticação: ${error.message}';
  }

  static String _parsePostgrestError(PostgrestException error) {
    // Códigos SQL comuns
    switch (error.code) {
      case '23505':
        return 'Este registro já existe no sistema.';
      case '42501':
        return 'Erro de permissão no banco de dados. Contate o suporte.';
      case '23503':
        return 'Erro de referência: dados relacionados não encontrados.';
      default:
        return 'Erro no banco de dados: ${error.message}';
    }
  }
}
