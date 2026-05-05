
-- ================================================================
-- GOOGLE OAUTH — Suporte completo
-- 1. Corrige criar_perfil_usuario para lidar com Google
-- 2. Cria trigger on_auth_user_created (faltava!)
-- 3. Cria função handle_google_user para usuários Google já existentes
-- ================================================================

-- ----------------------------------------------------------------
-- 1. Atualiza criar_perfil_usuario para suportar Google OAuth
--    Problema anterior: função esperava tipo_usuario no INSERT manual
--    Google não passa tipo_usuario — precisamos de um default seguro
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.criar_perfil_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tipo        text;
  v_nome        text;
  v_provider    text;
BEGIN
  -- Detecta o provider (email, google, apple, etc.)
  v_provider := COALESCE(
    NEW.raw_app_meta_data->>'provider',
    'email'
  );

  -- Nome: pega do Google metadata ou usa o email como fallback
  v_nome := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  -- Tipo: pega do metadata (cadastro manual) ou default 'cliente' (Google/OAuth)
  -- Admin NUNCA pode ser criado via OAuth — só via inserção direta no banco
  v_tipo := COALESCE(
    NEW.raw_user_meta_data->>'tipo_usuario',
    'cliente'  -- Google login sempre cria cliente por padrão
  );

  -- Garante que ninguém vira admin via OAuth
  IF v_tipo = 'admin' AND v_provider != 'email' THEN
    v_tipo := 'cliente';
  END IF;

  -- Insere em public.usuarios (tabela central de perfis)
  INSERT INTO public.usuarios (
    id,
    email,
    nome_completo_fantasia,
    tipo_usuario,
    status,
    email_verificado,
    created_at,
    updated_at
  ) VALUES (
    NEW.id,
    NEW.email,
    v_nome,
    v_tipo,
    'ativo',
    CASE WHEN v_provider != 'email' THEN true ELSE false END,
    NOW(),
    NOW()
  )
  ON CONFLICT (id) DO UPDATE SET
    -- Se usuário já existe (ex: fez login com email antes do Google)
    -- apenas atualiza email_verificado e nome se estava vazio
    email_verificado = true,
    nome_completo_fantasia = CASE
      WHEN public.usuarios.nome_completo_fantasia = '' OR
           public.usuarios.nome_completo_fantasia IS NULL
      THEN v_nome
      ELSE public.usuarios.nome_completo_fantasia
    END,
    updated_at = NOW();

  -- Cria perfil específico por tipo
  CASE v_tipo
    WHEN 'cliente' THEN
      INSERT INTO public.clientes (usuario_id)
      VALUES (NEW.id)
      ON CONFLICT (usuario_id) DO NOTHING;

    WHEN 'entregador' THEN
      INSERT INTO public.entregadores (usuario_id, cpf)
      VALUES (NEW.id, '')
      ON CONFLICT (usuario_id) DO NOTHING;

    WHEN 'estabelecimento' THEN
      INSERT INTO public.estabelecimentos (
        usuario_id,
        endereco
      ) VALUES (
        NEW.id,
        '{"latitude": 0, "longitude": 0}'::jsonb
      )
      ON CONFLICT (usuario_id) DO NOTHING;

    ELSE
      -- 'admin' e tipos desconhecidos: não cria perfil específico
      NULL;
  END CASE;

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  -- Log do erro sem quebrar o login
  RAISE LOG 'criar_perfil_usuario erro para %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;

-- ----------------------------------------------------------------
-- 2. Cria o trigger on_auth_user_created (estava FALTANDO no projeto!)
--    Dispara sempre que um novo usuário é criado no Supabase Auth
--    Funciona para email/senha E para Google OAuth
-- ----------------------------------------------------------------
DROP TRIGGER IF EXISTS on_auth_user_created ON auth.users;

CREATE TRIGGER on_auth_user_created
  AFTER INSERT ON auth.users
  FOR EACH ROW
  EXECUTE FUNCTION public.criar_perfil_usuario();

-- ----------------------------------------------------------------
-- 3. Função para lidar com login Google de usuário já existente
--    (quando o email já existe mas veio de provider diferente)
--    Chamada via validar_sessao_e_rota — não precisa de trigger
-- ----------------------------------------------------------------
CREATE OR REPLACE FUNCTION public.sincronizar_perfil_oauth()
RETURNS jsonb
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_user      record;
  v_perfil    record;
  v_provider  text;
  v_nome      text;
BEGIN
  -- Busca dados do usuário autenticado
  SELECT
    au.id,
    au.email,
    au.raw_app_meta_data->>'provider'    AS provider,
    au.raw_user_meta_data->>'full_name'  AS nome_google,
    au.raw_user_meta_data->>'name'       AS nome_google2,
    au.raw_user_meta_data->>'avatar_url' AS avatar_url,
    u.tipo_usuario,
    u.status,
    u.nome_completo_fantasia
  INTO v_user
  FROM auth.users au
  LEFT JOIN public.usuarios u ON u.id = au.id
  WHERE au.id = auth.uid();

  IF NOT FOUND THEN
    RETURN jsonb_build_object('ok', false, 'erro', 'usuario_nao_encontrado');
  END IF;

  v_provider := COALESCE(v_user.provider, 'email');
  v_nome := COALESCE(
    v_user.nome_google,
    v_user.nome_google2,
    split_part(v_user.email, '@', 1)
  );

  -- Se perfil não existe em public.usuarios (caso raro), cria agora
  IF v_user.tipo_usuario IS NULL THEN
    INSERT INTO public.usuarios (
      id, email, nome_completo_fantasia,
      tipo_usuario, status, email_verificado
    ) VALUES (
      v_user.id, v_user.email, v_nome,
      'cliente', 'ativo', true
    )
    ON CONFLICT (id) DO NOTHING;

    INSERT INTO public.clientes (usuario_id)
    VALUES (v_user.id)
    ON CONFLICT (usuario_id) DO NOTHING;

    RETURN jsonb_build_object(
      'ok',       true,
      'criado',   true,
      'provider', v_provider
    );
  END IF;

  -- Atualiza foto de perfil se veio do Google e campo estava vazio
  IF v_provider = 'google' AND v_user.avatar_url IS NOT NULL THEN
    UPDATE public.clientes
    SET foto_perfil_url = v_user.avatar_url
    WHERE usuario_id = v_user.id
      AND (foto_perfil_url IS NULL OR foto_perfil_url = '');
  END IF;

  RETURN jsonb_build_object(
    'ok',       true,
    'criado',   false,
    'provider', v_provider
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object('ok', false, 'erro', SQLERRM);
END;
$$;
;
