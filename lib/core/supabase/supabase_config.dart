import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseConfig {
  /// URL do Supabase
  /// - Mobile/Desktop: lida do .env via flutter_dotenv
  /// - Web (produção): injetada via --dart-define=SUPABASE_URL=...
  static String get url {
    if (kIsWeb) {
      // Na Web, usa --dart-define (variáveis de ambiente de build da Vercel)
      const webUrl = String.fromEnvironment('SUPABASE_URL');
      if (webUrl.isNotEmpty) return webUrl;
    }
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  /// Chave Anon do Supabase
  /// - Mobile/Desktop: lida do .env via flutter_dotenv
  /// - Web (produção): injetada via --dart-define=SUPABASE_ANON_KEY=...
  static String get anonKey {
    if (kIsWeb) {
      const webKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      if (webKey.isNotEmpty) return webKey;
    }
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
  }

  static Future<void> initialize() async {
    assert(url.isNotEmpty, 'SUPABASE_URL não configurada!');
    assert(anonKey.isNotEmpty, 'SUPABASE_ANON_KEY não configurada!');

    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

/// Provider para o cliente do Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
