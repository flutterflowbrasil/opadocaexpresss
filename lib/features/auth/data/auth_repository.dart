import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase;

  AuthRepository(this._supabase);

  final _googleSignIn = GoogleSignIn(
    clientId: '330398810543-noqpc71p7c0jo5k5mt2udkp9k3hhjb0s.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

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
    await _supabase.from('clientes').insert({'usuario_id': userId});
  }

  Future<void> signUpEstabelecimento({
    required CadastroEstabelecimentoState dadosCadastro,
    required dynamic storageService,
  }) async {
    // 1. Criar usuário no Auth
    final authResponse = await _supabase.auth.signUp(
      email: dadosCadastro.email!,
      password: dadosCadastro.senha!,
      data: {'nome': dadosCadastro.nomeFantasia},
    );

    if (authResponse.user == null) {
      throw const AuthException('Erro ao criar usuário');
    }

    final userId = authResponse.user!.id;
    String? imageUrl;

    // 2. Upload da Imagem (se houver)
    if (dadosCadastro.imagemCapaPath != null) {
      imageUrl = await storageService.uploadCoverImage(
        dadosCadastro.imagemCapaPath!,
        userId,
      );
    }

    // 3. Inserir na tabela public.usuarios
    await _supabase.from('usuarios').insert({
      'id': userId,
      'email': dadosCadastro.email,
      'telefone': dadosCadastro.telefone,
      'tipo_usuario': 'estabelecimento',
      'nome_completo_fantasia': dadosCadastro.nomeFantasia,
      'foto_url': imageUrl,
      'cpf_cnpj': dadosCadastro.cnpj,
    });

    // 4. Inserir na tabela public.estabelecimentos
    await _supabase.from('estabelecimentos').insert({
      'usuario_id': userId,
      'cnpj': dadosCadastro.cnpj,
      'razao_social': dadosCadastro
          .nomeFantasia, // Usando Fantasia como Razão por enquanto ou adicionar campo
      'cep': dadosCadastro.cep,
      'logradouro': dadosCadastro.logradouro,
      'numero': dadosCadastro.numero,
      'bairro': dadosCadastro.bairro,
      'cidade': dadosCadastro.cidade,
      'estado': dadosCadastro.estado,
      'horario_funcionamento':
          dadosCadastro.horarioFuncionamento, // JSONB no banco?
      'taxa_entrega_fixa': 0.0, // Default
      'tempo_entrega_min': 30, // Default
      'tempo_entrega_max': 60, // Default
      'aberto': false, // Default
      // Dados Bancários e Responsável (se houver colunas para isso ou tabela separada)
      // Ajuste conforme SQL.md. Se não houver, salvar o que der.
      // Assumindo que dados bancários podem ir para uma tabela `dados_bancarios` futura ou JSON.
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

  /// Retorna a rota após login com Google, ou lança exceção com código de erro.
  Future<String> loginComGoogle() async {
    if (kIsWeb) {
      return _loginComGoogleWeb();
    }
    return _loginComGoogleMobile();
  }

  Future<String> _loginComGoogleWeb() async {
    // Web não suporta signIn() nativo — usa OAuth popup do Supabase.
    // redirectTo usa a origem atual para funcionar tanto em localhost quanto em produção.
    await _supabase.auth.signInWithOAuth(
      OAuthProvider.google,
      redirectTo: Uri.base.origin,
    );

    // Aguarda o evento signedIn no stream (popup fecha e Supabase seta sessão).
    final event = await _supabase.auth.onAuthStateChange
        .where((e) => e.event == AuthChangeEvent.signedIn)
        .first
        .timeout(
          const Duration(minutes: 2),
          onTimeout: () => throw Exception('cancelado'),
        );

    if (event.session == null) throw Exception('google_auth_falhou');

    await _supabase.rpc('sincronizar_perfil_oauth');
    return validateSessionAndRoute();
  }

  Future<String> _loginComGoogleMobile() async {
    final googleUser = await _googleSignIn.signIn();
    if (googleUser == null) throw Exception('cancelado');

    final googleAuth = await googleUser.authentication;
    final idToken = googleAuth.idToken;
    final accessToken = googleAuth.accessToken;
    if (idToken == null || accessToken == null) throw Exception('tokens_invalidos');

    final response = await _supabase.auth.signInWithIdToken(
      provider: OAuthProvider.google,
      idToken: idToken,
      accessToken: accessToken,
    );
    if (response.user == null) throw Exception('google_auth_falhou');

    await _supabase.rpc('sincronizar_perfil_oauth');
    return validateSessionAndRoute();
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
    await _googleSignIn.signOut();
    await _supabase.auth.signOut();
    // M1: Limpar todos os dados locais criptografados ao fazer logout
    const storage = FlutterSecureStorage(
      aOptions: AndroidOptions(encryptedSharedPreferences: true),
    );
    await storage.deleteAll();
  }

  Future<Map<String, dynamic>?> getProfile(String userId) async {
    try {
      final user = _supabase.auth.currentUser;
      if (user == null) return null;

      final response = await _supabase
          .from('usuarios')
          .select('nome_completo_fantasia, clientes(foto_perfil_url)')
          .eq('id', userId)
          .maybeSingle();

      String? fotoPerfilUrl;
      if (response != null && response['clientes'] != null) {
        // Handle array or single object representation of the join
        final clientesData = response['clientes'];
        if (clientesData is List && clientesData.isNotEmpty) {
          fotoPerfilUrl = clientesData.first['foto_perfil_url'];
        } else if (clientesData is Map) {
          fotoPerfilUrl = clientesData['foto_perfil_url'];
        }
      }

      return {
        'nome': response?['nome_completo_fantasia'] ?? 'Usuário',
        'email': user.email,
        'id': userId,
        'foto_perfil_url': fotoPerfilUrl,
      };
    } catch (e) {
      return null;
    }
  }

  /// Retorna o ID do estabelecimento vinculado a um usuário autenticado.
  /// Extraído do AuthRepository para permitir mocking em testes unitários.
  Future<String?> getEstabelecimentoId(String userId) async {
    final result = await _supabase
        .from('estabelecimentos')
        .select('id')
        .eq('usuario_id', userId)
        .maybeSingle();
    return result?['id'] as String?;
  }

  /// Chama a RPC SECURITY DEFINER — a rota é determinada pelo banco via auth.uid().
  Future<String> validateSessionAndRoute() async {
    final result = await _supabase.rpc('validar_sessao_e_rota');
    return (result as Map<String, dynamic>)['rota'] as String? ?? '/home';
  }

  User? get currentUser => _supabase.auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

/// Chama a RPC SECURITY DEFINER `validar_sessao_e_rota()`.
/// A rota é determinada pelo banco (via auth.uid()), não pelo cliente.
/// autoDispose garante re-busca após logout/novo login.
final sessionRouteProvider = FutureProvider.autoDispose<String>((ref) async {
  final repo = ref.watch(authRepositoryProvider);
  if (repo.currentUser == null) return '/login';
  return repo.validateSessionAndRoute();
});
