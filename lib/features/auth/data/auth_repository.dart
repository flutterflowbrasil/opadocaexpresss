import 'dart:typed_data';

import 'package:flutter/foundation.dart';
import 'package:padoca_express/core/utils/account_uniqueness_validator.dart';
import 'package:padoca_express/core/utils/brazilian_document_validator.dart';
import 'package:padoca_express/features/auth/presentation/cadastro_estabelecimento/cadastro_estabelecimento_state.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:padoca_express/core/supabase/supabase_config.dart';

class AuthRepository {
  final SupabaseClient _supabase;
  late final AccountUniquenessValidator _uniquenessValidator;

  AuthRepository(this._supabase) {
    _uniquenessValidator = AccountUniquenessValidator(_supabase);
  }

  final _googleSignIn = GoogleSignIn(
    clientId:
        '330398810543-noqpc71p7c0jo5k5mt2udkp9k3hhjb0s.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  Future<void> signUpCliente({
    required String email,
    required String password,
    required String nome,
    required String telefone,
  }) async {
    await _uniquenessValidator.ensureEmailAvailable(email);

    // 1. Criar usuário no Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: password,
      data: {
        'nome': nome,
        'tipo_usuario': 'cliente',
      },
    );

    if (authResponse.user == null) {
      throw const AuthException('Erro ao criar usuário');
    }

    final userId = authResponse.user!.id;

    // 2. Atualizar na tabela public.usuarios (criado pelo trigger)
    await _supabase.from('usuarios').update({
      'telefone': telefone,
    }).eq('id', userId);
  }

  Future<void> signUpEstabelecimento({
    required CadastroEstabelecimentoState dadosCadastro,
    required dynamic storageService,
  }) async {
    final email = dadosCadastro.email!.trim().toLowerCase();
    final senha = dadosCadastro.senha!;
    String? userIdParaRetry;

    try {
      await _uniquenessValidator.ensureEmailAvailable(email);
    } on DuplicateAccountException catch (e) {
      if (e.field != DuplicateAccountField.email) rethrow;
      userIdParaRetry = await _trySignInForEstabelecimentoRetry(email, senha);
      if (userIdParaRetry == null) rethrow;
    }

    if (dadosCadastro.tipoPessoa == 'fisica') {
      await _uniquenessValidator.ensureCpfAvailable(
        dadosCadastro.cnpj ?? '',
        ignoreUserId: userIdParaRetry,
      );
    } else {
      await _uniquenessValidator.ensureCnpjAvailable(
        dadosCadastro.cnpj ?? '',
        ignoreUserId: userIdParaRetry,
      );
    }

    final userId = userIdParaRetry ??
        await _createAndSignInEstabelecimentoUser(
          email: email,
          senha: senha,
          nomeFantasia: dadosCadastro.nomeFantasia,
        );

    // 2. Garante a linha em public.usuarios antes de referenciar o perfil.
    final usuarioExistente = await _supabase
        .from('usuarios')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (usuarioExistente == null) {
      await _supabase.from('usuarios').insert({
        'id': userId,
        'email': email,
        'telefone': dadosCadastro.telefone,
        'tipo_usuario': 'estabelecimento',
        'nome_completo_fantasia': dadosCadastro.nomeFantasia,
      });
    } else {
      await _supabase.from('usuarios').update({
        'telefone': dadosCadastro.telefone,
        'nome_completo_fantasia': dadosCadastro.nomeFantasia,
      }).eq('id', userId);
    }

    // 3. Garante/atualiza o estabelecimento para obter o id usado no Storage.
    final estabelecimentoPayload = {
      'usuario_id': userId,
      'nome_fantasia': dadosCadastro.nomeFantasia,
      'razao_social': dadosCadastro.nomeFantasia,
      'cnpj': BrazilianDocumentValidator.onlyDigits(
        dadosCadastro.cnpj ?? '',
      ),
      'responsavel_nome': dadosCadastro.nomeFantasia,
      'responsavel_cpf': dadosCadastro.tipoPessoa == 'fisica'
          ? BrazilianDocumentValidator.onlyDigits(dadosCadastro.cnpj ?? '')
          : null,
      'telefone_comercial': dadosCadastro.telefone,
      'whatsapp': dadosCadastro.telefone,
      'email_comercial': email,
      'endereco': {
        'cep': dadosCadastro.cep,
        'logradouro': dadosCadastro.logradouro,
        'numero': dadosCadastro.numero,
        'bairro': dadosCadastro.bairro,
        'cidade': dadosCadastro.cidade,
        'estado': dadosCadastro.estado,
        'latitude': dadosCadastro.latitude,
        'longitude': dadosCadastro.longitude,
      },
      'latitude': dadosCadastro.latitude,
      'longitude': dadosCadastro.longitude,
      'horario_funcionamento': dadosCadastro.horarioFuncionamento,
      'status_aberto': false,
      'status_cadastro': 'pendente',
      'verificacao_manual_status': 'em_analise',
    };

    final estabelecimentoExistente = await _supabase
        .from('estabelecimentos')
        .select('id')
        .eq('usuario_id', userId)
        .maybeSingle();
    final estabelecimentoResponse = estabelecimentoExistente == null
        ? await _supabase
            .from('estabelecimentos')
            .insert(estabelecimentoPayload)
            .select('id')
            .single()
        : await _supabase
            .from('estabelecimentos')
            .update(estabelecimentoPayload)
            .eq('id', estabelecimentoExistente['id'])
            .select('id')
            .single();
    final estabelecimentoId = estabelecimentoResponse['id'] as String;

    final imageUpdate = <String, dynamic>{};
    if (dadosCadastro.imagemLogoBytes != null) {
      imageUpdate['logo_url'] = await storageService.uploadStoreLogo(
        bytes: dadosCadastro.imagemLogoBytes!,
        estabelecimentoId: estabelecimentoId,
      );
    }
    if (dadosCadastro.imagemCapaBytes != null) {
      imageUpdate['banner_url'] = await storageService.uploadStoreBanner(
        bytes: dadosCadastro.imagemCapaBytes!,
        estabelecimentoId: estabelecimentoId,
      );
    }
    if (imageUpdate.isNotEmpty) {
      await _supabase
          .from('estabelecimentos')
          .update(imageUpdate)
          .eq('id', estabelecimentoId);
    }

    await _salvarDocumentosEstabelecimento(
      estabelecimentoId: estabelecimentoId,
      dadosCadastro: dadosCadastro,
    );

    await _supabase.from('estabelecimentos').update({
      'status_cadastro': 'pendente',
      'verificacao_manual_status': 'em_analise',
    }).eq('id', estabelecimentoId);

  }

  Future<String?> _trySignInForEstabelecimentoRetry(
    String email,
    String senha,
  ) async {
    try {
      final response = await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );
      final user = response.user;
      if (user == null || user.email?.toLowerCase() != email) return null;
      final perfil = await _supabase
          .from('usuarios')
          .select('tipo_usuario')
          .eq('id', user.id)
          .maybeSingle();
      if (perfil != null && perfil['tipo_usuario'] != 'estabelecimento') {
        await _supabase.auth.signOut();
        return null;
      }
      return user.id;
    } on AuthException {
      return null;
    }
  }

  Future<String> _createAndSignInEstabelecimentoUser({
    required String email,
    required String senha,
    required String? nomeFantasia,
  }) async {
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: senha,
      data: {
        'nome': nomeFantasia,
        'tipo_usuario': 'estabelecimento',
      },
    );

    if (authResponse.user == null) {
      throw const AuthException('Erro ao criar usuário');
    }

    final userId = authResponse.user!.id;
    if (_supabase.auth.currentUser?.id != userId) {
      await _supabase.auth.signInWithPassword(
        email: email,
        password: senha,
      );
    }

    return userId;
  }

  Future<void> _salvarDocumentosEstabelecimento({
    required String estabelecimentoId,
    required CadastroEstabelecimentoState dadosCadastro,
  }) async {
    final usaCnh = dadosCadastro.documentoResponsavelTipo == 'cnh';

    Future<void> salvarDocumento({
      required String tipo,
      required Uint8List? bytes,
      required String? fileName,
    }) async {
      if (bytes == null || fileName == null) {
        throw AuthException('Documento obrigatório ausente: $tipo');
      }

      final path = await _uploadEstabelecimentoDocumento(
        estabelecimentoId: estabelecimentoId,
        tipo: tipo,
        bytes: bytes,
        fileName: fileName,
        contentType: _contentTypeFor(fileName),
      );

      final payload = {
        'estabelecimento_id': estabelecimentoId,
        'tipo': tipo,
        'url': path,
        'status_validacao': 'pendente',
        'motivo_rejeicao': null,
        'validado_em': null,
        'validado_por': null,
      };

      final existingRows = await _supabase
          .from('estabelecimento_documentos')
          .select('id')
          .eq('estabelecimento_id', estabelecimentoId)
          .eq('tipo', tipo)
          .limit(1);
      final existing = existingRows is List && existingRows.isNotEmpty
          ? existingRows.first
          : null;

      if (existing == null) {
        await _supabase.from('estabelecimento_documentos').insert(payload);
      } else {
        await _supabase
            .from('estabelecimento_documentos')
            .update(payload)
            .eq('id', existing['id']);
      }
    }

    if (usaCnh) {
      await salvarDocumento(
        tipo: 'cnh_responsavel_frente',
        bytes: dadosCadastro.cnhResponsavelFrenteBytes,
        fileName: dadosCadastro.cnhResponsavelFrenteFileName,
      );
      await salvarDocumento(
        tipo: 'cnh_responsavel_verso',
        bytes: dadosCadastro.cnhResponsavelVersoBytes,
        fileName: dadosCadastro.cnhResponsavelVersoFileName,
      );
    } else {
      await salvarDocumento(
        tipo: 'identidade_responsavel_frente',
        bytes: dadosCadastro.identidadeResponsavelFrenteBytes,
        fileName: dadosCadastro.identidadeResponsavelFrenteFileName,
      );
      await salvarDocumento(
        tipo: 'identidade_responsavel_verso',
        bytes: dadosCadastro.identidadeResponsavelVersoBytes,
        fileName: dadosCadastro.identidadeResponsavelVersoFileName,
      );
    }

    await salvarDocumento(
      tipo: 'comprovante_endereco',
      bytes: dadosCadastro.comprovanteEnderecoBytes,
      fileName: dadosCadastro.comprovanteEnderecoFileName,
    );
  }

  Future<String> _uploadEstabelecimentoDocumento({
    required String estabelecimentoId,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final safeExt = ext.length <= 5 ? ext : 'jpg';
    final path =
        'estabelecimentos/$estabelecimentoId/${tipo}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _supabase.storage.from('documentos').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  Future<void> signUpEntregador({
    required String nome,
    required String telefone,
    required String cpf,
    required String dataNascimento,
    required String tipoVeiculo,
    required String placaVeiculo,
    required String modeloVeiculo,
    required String email,
    required String senha,
    required Map<String, dynamic> endereco,
    Uint8List? identidadeFrenteBytes,
    String? identidadeFrenteFileName,
    Uint8List? identidadeVersoBytes,
    String? identidadeVersoFileName,
    Uint8List? cnhFrenteBytes,
    String? cnhFrenteFileName,
    Uint8List? cnhVersoBytes,
    String? cnhVersoFileName,
    required Uint8List fotoPerfilBytes,
    required String fotoPerfilFileName,
  }) async {
    await _uniquenessValidator.ensureEmailAvailable(email);
    await _uniquenessValidator.ensureCpfAvailable(cpf);

    // 1. Criar usuário no Auth
    final authResponse = await _supabase.auth.signUp(
      email: email,
      password: senha,
      data: {
        'nome': nome,
        'tipo_usuario': 'entregador',
      },
    );

    if (authResponse.user == null) {
      throw const AuthException('Erro ao criar usuário');
    }

    final userId = authResponse.user!.id;

    // 2. Garante sessão JWT ativa antes de qualquer operação de Storage.
    // O token retornado pelo signUp pode estar em estado transitório (role anon),
    // causando 403 nas policies de Storage que exigem 'authenticated'.
    // O signInWithPassword garante um token 'authenticated' completo.
    await _supabase.auth.signInWithPassword(
      email: email,
      password: senha,
    );

    // 3. Garante a linha em public.usuarios antes de referenciar em entregadores.
    final usuarioExistente = await _supabase
        .from('usuarios')
        .select('id')
        .eq('id', userId)
        .maybeSingle();
    if (usuarioExistente == null) {
      await _supabase.from('usuarios').insert({
        'id': userId,
        'email': email.trim().toLowerCase(),
        'telefone': telefone,
        'tipo_usuario': 'entregador',
        'nome_completo_fantasia': nome,
      });
    } else {
      await _supabase.from('usuarios').update({
        'telefone': telefone,
        'nome_completo_fantasia': nome,
      }).eq('id', userId);
    }

    // 4. Garante o registro em public.entregadores.
    final entregadorResponse = await _supabase
        .from('entregadores')
        .upsert({
          'usuario_id': userId,
          'cpf': BrazilianDocumentValidator.onlyDigits(cpf),
          'data_nascimento': dataNascimento,
          'tipo_veiculo': tipoVeiculo,
          'veiculo_placa': placaVeiculo,
          'veiculo_modelo': modeloVeiculo,
          'endereco': endereco,
        }, onConflict: 'usuario_id')
        .select('id')
        .single();
    final entregadorId = entregadorResponse['id'] as String;

    await _supabase.from('entregador_enderecos').upsert({
      'entregador_id': entregadorId,
      'cep': (endereco['cep'] ?? '').toString().replaceAll(RegExp(r'\D'), ''),
      'logradouro': endereco['logradouro'],
      'numero': endereco['numero'],
      'complemento': endereco['complemento'],
      'bairro': endereco['bairro'],
      'cidade': endereco['cidade'],
      'estado': (endereco['estado'] ?? '').toString().toUpperCase(),
      'is_principal': true,
    }, onConflict: 'entregador_id');

    final fotoPerfilPath = await _uploadEntregadorDocumento(
      entregadorId: entregadorId,
      tipo: 'selfie',
      bytes: fotoPerfilBytes,
      fileName: fotoPerfilFileName,
      contentType: _contentTypeFor(fotoPerfilFileName),
    );
    final fotoPerfilUrl = await _uploadFotoPerfilEntregador(
      userId: userId,
      bytes: fotoPerfilBytes,
      fileName: fotoPerfilFileName,
      contentType: _contentTypeFor(fotoPerfilFileName),
    );

    final identidadeFrentePath =
        identidadeFrenteBytes != null && identidadeFrenteFileName != null
            ? await _uploadEntregadorDocumento(
                entregadorId: entregadorId,
                tipo: 'identidade_frente',
                bytes: identidadeFrenteBytes,
                fileName: identidadeFrenteFileName,
                contentType: _contentTypeFor(identidadeFrenteFileName),
              )
            : null;
    final identidadeVersoPath =
        identidadeVersoBytes != null && identidadeVersoFileName != null
            ? await _uploadEntregadorDocumento(
                entregadorId: entregadorId,
                tipo: 'identidade_verso',
                bytes: identidadeVersoBytes,
                fileName: identidadeVersoFileName,
                contentType: _contentTypeFor(identidadeVersoFileName),
              )
            : null;
    final cnhFrentePath = cnhFrenteBytes != null && cnhFrenteFileName != null
        ? await _uploadEntregadorDocumento(
            entregadorId: entregadorId,
            tipo: 'cnh_frente',
            bytes: cnhFrenteBytes,
            fileName: cnhFrenteFileName,
            contentType: _contentTypeFor(cnhFrenteFileName),
          )
        : null;
    final cnhVersoPath = cnhVersoBytes != null && cnhVersoFileName != null
        ? await _uploadEntregadorDocumento(
            entregadorId: entregadorId,
            tipo: 'cnh_verso',
            bytes: cnhVersoBytes,
            fileName: cnhVersoFileName,
            contentType: _contentTypeFor(cnhVersoFileName),
          )
        : null;

    await _supabase.from('entregadores').update({
      'foto_perfil_url': fotoPerfilUrl,
    }).eq('id', entregadorId);

    final documentos = <Map<String, dynamic>>[
      {
        'entregador_id': entregadorId,
        'tipo': 'selfie',
        'url': fotoPerfilPath,
        'status_validacao': 'pendente',
      },
      if (identidadeFrentePath != null)
        {
          'entregador_id': entregadorId,
          'tipo': 'identidade_frente',
          'url': identidadeFrentePath,
          'status_validacao': 'pendente',
        },
      if (identidadeVersoPath != null)
        {
          'entregador_id': entregadorId,
          'tipo': 'identidade_verso',
          'url': identidadeVersoPath,
          'status_validacao': 'pendente',
        },
      if (cnhFrentePath != null)
        {
          'entregador_id': entregadorId,
          'tipo': 'cnh_frente',
          'url': cnhFrentePath,
          'status_validacao': 'pendente',
        },
      if (cnhVersoPath != null)
        {
          'entregador_id': entregadorId,
          'tipo': 'cnh_verso',
          'url': cnhVersoPath,
          'status_validacao': 'pendente',
        },
    ];

    await _supabase.from('entregador_documentos').insert(documentos);

  }

  Future<String> _uploadEntregadorDocumento({
    required String entregadorId,
    required String tipo,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final safeExt = ext.length <= 5 ? ext : 'jpg';
    final path =
        '$entregadorId/${tipo}_${DateTime.now().millisecondsSinceEpoch}.$safeExt';

    await _supabase.storage.from('documentos-entregador').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType),
        );
    return path;
  }

  Future<String> _uploadFotoPerfilEntregador({
    required String userId,
    required Uint8List bytes,
    required String fileName,
    required String contentType,
  }) async {
    final ext = fileName.split('.').last.toLowerCase();
    final safeExt = ext.length <= 5 ? ext : 'jpg';
    // Path usa userId (= auth.uid()) para satisfazer a policy de UPDATE/DELETE
    // do bucket 'imagens': name LIKE '%' || auth.uid() || '%'
    final path = 'perfil_entregadores/$userId.$safeExt';

    await _supabase.storage.from('imagens').uploadBinary(
          path,
          bytes,
          fileOptions: FileOptions(contentType: contentType, upsert: true),
        );
    return _supabase.storage.from('imagens').getPublicUrl(path);
  }

  String _contentTypeFor(String fileName) {
    final ext = fileName.split('.').last.toLowerCase();
    return switch (ext) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      'pdf' => 'application/pdf',
      _ => 'image/jpeg',
    };
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
    if (idToken == null || accessToken == null)
      throw Exception('tokens_invalidos');

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

  Future<Map<String, dynamic>?> getMeuCadastroEntregador() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _supabase
        .from('entregadores')
        .select(
          'id, status_cadastro, motivo_rejeicao, tipo_veiculo, '
          'entregador_documentos(id, tipo, status_validacao, motivo_rejeicao)',
        )
        .eq('usuario_id', user.id)
        .maybeSingle();
  }

  Future<void> reenviarDocumentoEntregador({
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Sessao expirada.');

    final entregador = await _supabase
        .from('entregadores')
        .select('id')
        .eq('usuario_id', user.id)
        .single();
    final entregadorId = entregador['id'] as String;
    final path = await _uploadEntregadorDocumento(
      entregadorId: entregadorId,
      tipo: tipo,
      bytes: bytes,
      fileName: fileName,
      contentType: _contentTypeFor(fileName),
    );

    final existing = await _supabase
        .from('entregador_documentos')
        .select('id')
        .eq('entregador_id', entregadorId)
        .eq('tipo', tipo)
        .maybeSingle();

    final payload = {
      'entregador_id': entregadorId,
      'tipo': tipo,
      'url': path,
      'status_validacao': 'pendente',
      'motivo_rejeicao': null,
      'revisado_em': null,
      'revisado_por': null,
    };

    if (existing == null) {
      await _supabase.from('entregador_documentos').insert(payload);
    } else {
      await _supabase
          .from('entregador_documentos')
          .update(payload)
          .eq('id', existing['id']);
    }

    await _supabase.from('entregadores').update({
      'status_cadastro': 'pendente',
      'motivo_rejeicao': null,
    }).eq('id', entregadorId);
  }

  /// Retorna o ID do entregador vinculado a um usuário autenticado.
  Future<String?> getEntregadorId(String userId) async {
    final result = await _supabase
        .from('entregadores')
        .select('id')
        .eq('usuario_id', userId)
        .maybeSingle();
    return result?['id'] as String?;
  }

  Future<Map<String, dynamic>?> getMeuCadastroEstabelecimento() async {
    final user = _supabase.auth.currentUser;
    if (user == null) return null;
    return await _supabase
        .from('estabelecimentos')
        .select(
          'id, status_cadastro, motivo_suspensao, '
          'verificacao_manual_status, verificacao_manual_observacao, '
          'estabelecimento_documentos(id, tipo, status_validacao, motivo_rejeicao)',
        )
        .eq('usuario_id', user.id)
        .maybeSingle();
  }

  Future<void> reenviarDocumentoEstabelecimento({
    required String tipo,
    required Uint8List bytes,
    required String fileName,
  }) async {
    final user = _supabase.auth.currentUser;
    if (user == null) throw const AuthException('Sessao expirada.');

    final estabelecimento = await _supabase
        .from('estabelecimentos')
        .select('id')
        .eq('usuario_id', user.id)
        .single();
    final estabelecimentoId = estabelecimento['id'] as String;
    final path = await _uploadEstabelecimentoDocumento(
      estabelecimentoId: estabelecimentoId,
      tipo: tipo,
      bytes: bytes,
      fileName: fileName,
      contentType: _contentTypeFor(fileName),
    );

    final existingRows = await _supabase
        .from('estabelecimento_documentos')
        .select('id')
        .eq('estabelecimento_id', estabelecimentoId)
        .eq('tipo', tipo)
        .limit(1);
    final existing = existingRows is List && existingRows.isNotEmpty
        ? existingRows.first
        : null;

    final payload = {
      'estabelecimento_id': estabelecimentoId,
      'tipo': tipo,
      'url': path,
      'status_validacao': 'pendente',
      'motivo_rejeicao': null,
      'validado_em': null,
      'validado_por': null,
    };

    if (existing == null) {
      await _supabase.from('estabelecimento_documentos').insert(payload);
    } else {
      await _supabase
          .from('estabelecimento_documentos')
          .update(payload)
          .eq('id', existing['id']);
    }

    await _supabase.from('estabelecimentos').update({
      'status_cadastro': 'pendente',
      'verificacao_manual_status': 'em_analise',
      'verificacao_manual_observacao': null,
      'motivo_suspensao': null,
    }).eq('id', estabelecimentoId);
  }

  /// Chama a RPC SECURITY DEFINER — a rota é determinada pelo banco via auth.uid().
  Future<String> validateSessionAndRoute() async {
    final result = await _supabase.rpc('validar_sessao_e_rota');
    final route =
        (result as Map<String, dynamic>)['rota'] as String? ?? '/home';

    if (route.startsWith('/dashboard_entregador')) {
      // Entregador nunca pode usar o painel pelo navegador web
      if (kIsWeb) return '/baixar_app_entregador';
      final entregador = await _supabase
          .from('entregadores')
          .select('status_cadastro')
          .eq('usuario_id', _supabase.auth.currentUser!.id)
          .maybeSingle();
      if (entregador?['status_cadastro'] != 'aprovado') {
        return '/entregador/cadastro-pendente';
      }
    } else if (route.startsWith('/dashboard_estabelecimento')) {
      final estabelecimento = await _supabase
          .from('estabelecimentos')
          .select('status_cadastro')
          .eq('usuario_id', _supabase.auth.currentUser!.id)
          .maybeSingle();
      if (estabelecimento?['status_cadastro'] != 'aprovado') {
        return '/estabelecimento/cadastro-pendente';
      }
    }

    return route;
  }

  User? get currentUser => _supabase.auth.currentUser;
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  final supabase = ref.watch(supabaseClientProvider);
  return AuthRepository(supabase);
});

/// Cache da rota obtida durante o login. Evita uma segunda chamada RPC
/// quando o redirect do router lê o [sessionRouteProvider] logo após o login.
/// Limpo no início de cada novo login para não reutilizar rota de sessão anterior.
final sessionRouteCacheProvider = StateProvider<String?>((ref) => null);

/// Chama a RPC SECURITY DEFINER `validar_sessao_e_rota()`.
/// A rota é determinada pelo banco (via auth.uid()), não pelo cliente.
/// Usa o cache do [sessionRouteCacheProvider] quando disponível para evitar
/// dupla chamada RPC (controller + router redirect) e a race condition associada.
final sessionRouteProvider = FutureProvider.autoDispose<String>((ref) async {
  // Usa rota já buscada pelo login controller (sem nova chamada RPC)
  final cached = ref.watch(sessionRouteCacheProvider);
  if (cached != null) return cached;

  final repo = ref.watch(authRepositoryProvider);
  if (repo.currentUser == null) return '/login';
  return repo.validateSessionAndRoute();
});
