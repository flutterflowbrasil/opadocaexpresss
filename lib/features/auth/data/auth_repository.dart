import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  Future<void> signUpCliente({
    required String email,
    required String password,
    required String nome,
    required String telefone,
  }) async {
    // 1. Criar usuário no Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nome': nome, // Metadados opcionais
      },
    );

    if (authResponse.user == null) {
      throw const AuthException('Erro ao criar usuário');
    }

    final userId = authResponse.user!.id;

    // 2. Inserir na tabela public.usuarios
    await _supabase.from('usuarios').insert({
      'id': userId,
      'email': email,
      'telefone': telefone,
      'tipo_usuario': 'cliente',
    });

    // 3. Inserir na tabela public.clientes
    await _supabase.from('clientes').insert({
      'usuario_id': userId,
      'nome_completo': nome,
      // Outros campos opcionais podem ser adicionados depois
    });
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});
