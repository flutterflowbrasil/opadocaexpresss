import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final esqueceuSenhaRepositoryProvider = Provider<EsqueceuSenhaRepository>((ref) {
  return EsqueceuSenhaRepository(Supabase.instance.client);
});

class EsqueceuSenhaRepository {
  final SupabaseClient _supabase;

  EsqueceuSenhaRepository(this._supabase);

  Future<void> sendResetEmail(String email) async {
    // Redireciona o usuário para o app com a rota deep link
    // Usa localhost para testes Web ou native scheme para mobile.
    // Em produção Web, deve usar a URL de produção (ex: https://padoca.com/reset-password).
    final redirectUrl = kIsWeb
        ? '${Uri.base.origin}/reset-password'
        : 'com.opadocaexpress.app://reset-password';

    await _supabase.auth.resetPasswordForEmail(
      email,
      redirectTo: redirectUrl,
    );
  }
}
