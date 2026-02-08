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
      data: {'nome': nome},
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
      'nome_completo_fantasia': nome,
    });

    // 3. Inserir na tabela public.clientes
    await _supabase.from('clientes').insert({
      'usuario_id': userId,
      // 'nome_completo': nome, // Removido pois não existe na tabela clientes
    });
  }

  Future<AuthResponse> signIn({
    required String email,
    required String password,
  }) async {
    return await _supabase.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<String?> getUserType(String userId) async {
    final response = await _supabase
        .from('usuarios')
        .select('tipo_usuario')
        .eq('id', userId)
        .single();

    return response['tipo_usuario'] as String?;
  }

  Future<void> signOut() async {
    await _supabase.auth.signOut();
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('usuarios')
          .select('nome_completo_fantasia')
          .eq('id', userId)
          .maybeSingle();

      return {
        'nome': response?['nome_completo_fantasia'] ?? 'Usuário',
        'email': user.email,
        'id': userId,
      };
    } catch (e) {
      return null;
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});
