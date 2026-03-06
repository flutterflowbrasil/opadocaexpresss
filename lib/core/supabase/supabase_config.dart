import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class SupabaseConfig {
  /// URL do Supabase
  /// - Mobile/Desktop: lida do .env via flutter_dotenv
  /// - Web (produção): injetada via --dart-define=SUPABASE_URL=...
  static String get url {
    const dartDefineUrl = String.fromEnvironment('SUPABASE_URL');
    if (dartDefineUrl.isNotEmpty) return dartDefineUrl;

    if (dotenv.isInitialized) {
      return dotenv.get('SUPABASE_URL', fallback: '');
    }
    return '';
  }

  /// Publishable Key do Supabase (substitui a antiga anon key JWT)
  /// Formato novo: sb_publishable_...
  /// - Mobile/Desktop: lida do .env via flutter_dotenv
  /// - Web (produção): injetada via --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static String get anonKey {
    // Tenta a nova publishable key via --dart-define primeiro
    const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
    if (publishableKey.isNotEmpty) return publishableKey;

    // Fallback para variável legada via --dart-define
    const legacyKey = String.fromEnvironment('SUPABASE_ANON_KEY');
    if (legacyKey.isNotEmpty) return legacyKey;

    if (dotenv.isInitialized) {
      // Tenta nova chave no .env, depois legada
      final envPublishableKey = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY');
      if (envPublishableKey != null && envPublishableKey.isNotEmpty) {
        return envPublishableKey;
      }
      return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
    }
    return '';
  }

  static Future<void> initialize() async {
    assert(url.isNotEmpty, 'SUPABASE_URL não configurada!');
    assert(
      anonKey.isNotEmpty,
      'SUPABASE_PUBLISHABLE_KEY (ou SUPABASE_ANON_KEY) não configurada!',
    );

    await Supabase.initialize(url: url, anonKey: anonKey);
  }
}

/// Provider para o cliente do Supabase
final supabaseClientProvider = Provider<SupabaseClient>((ref) {
  return Supabase.instance.client;
});
