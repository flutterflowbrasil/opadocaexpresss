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
      const webUrl = String.fromEnvironment('SUPABASE_URL');
      if (webUrl.isNotEmpty) return webUrl;
    }
    return dotenv.get('SUPABASE_URL', fallback: '');
  }

  /// Publishable Key do Supabase (substitui a antiga anon key JWT)
  /// Formato novo: sb_publishable_...
  /// - Mobile/Desktop: lida do .env via flutter_dotenv
  /// - Web (produção): injetada via --dart-define=SUPABASE_PUBLISHABLE_KEY=...
  static String get anonKey {
    if (kIsWeb) {
      // Tenta a nova publishable key primeiro
      const publishableKey = String.fromEnvironment('SUPABASE_PUBLISHABLE_KEY');
      if (publishableKey.isNotEmpty) return publishableKey;

      // Fallback para variável legada (compatibilidade)
      const legacyKey = String.fromEnvironment('SUPABASE_ANON_KEY');
      if (legacyKey.isNotEmpty) return legacyKey;
    }

    // Mobile/Desktop: tenta nova chave, depois legada
    final publishableKey = dotenv.maybeGet('SUPABASE_PUBLISHABLE_KEY');
    if (publishableKey != null && publishableKey.isNotEmpty) {
      return publishableKey;
    }
    return dotenv.get('SUPABASE_ANON_KEY', fallback: '');
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
