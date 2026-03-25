import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

final novaSenhaRepositoryProvider = Provider<NovaSenhaRepository>((ref) {
  return NovaSenhaRepository(Supabase.instance.client);
});

class NovaSenhaRepository {
  final SupabaseClient _supabase;

  NovaSenhaRepository(this._supabase);

  Future<void> updatePassword(String novaSenha) async {
    // Altera a senha do usuário que está logado (na sessão reativa ao link)
    await _supabase.auth.updateUser(
      UserAttributes(password: novaSenha),
    );
  }
}
