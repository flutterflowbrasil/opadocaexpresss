
-- ================================================================
-- REGRA: Google OAuth só permitido para clientes
-- Admin e entregador: só podem usar Google se o email do Google
-- for idêntico ao email já cadastrado via email/senha
-- ================================================================

CREATE OR REPLACE FUNCTION public.criar_perfil_usuario()
RETURNS trigger
LANGUAGE plpgsql
SECURITY DEFINER
AS $$
DECLARE
  v_tipo        text;
  v_nome        text;
  v_provider    text;
  v_email_existente text;
  v_tipo_existente  text;
BEGIN
  v_provider := COALESCE(NEW.raw_app_meta_data->>'provider', 'email');

  v_nome := COALESCE(
    NEW.raw_user_meta_data->>'full_name',
    NEW.raw_user_meta_data->>'name',
    split_part(NEW.email, '@', 1)
  );

  -- Tipo via metadata (cadastro manual) ou 'cliente' como default OAuth
  v_tipo := COALESCE(
    NEW.raw_user_meta_data->>'tipo_usuario',
    'cliente'
  );

  -- ── REGRA DE NEGÓCIO CENTRAL ────────────────────────────────
  -- Se o login veio via Google (ou qualquer OAuth):
  --   • Verifica se esse email já existe em public.usuarios
  --   • Se existe e é admin/entregador → permite (mesmo email = OK)
  --   • Se não existe → cria como 'cliente' (Google só cria cliente)
  --   • Admin NUNCA é criado via OAuth por nenhum motivo
  -- ────────────────────────────────────────────────────────────
  IF v_provider != 'email' THEN

    -- Verifica se email já existe com outro tipo
    SELECT tipo_usuario INTO v_tipo_existente
    FROM public.usuarios
    WHERE email = NEW.email
    LIMIT 1;

    IF v_tipo_existente IS NOT NULL THEN
      -- Usuário já existe: mantém o tipo original (admin/entregador/estab)
      -- Apenas atualiza email_verificado e nome
      UPDATE public.usuarios SET
        email_verificado = true,
        nome_completo_fantasia = CASE
          WHEN nome_completo_fantasia = '' OR nome_completo_fantasia IS NULL
          THEN v_nome
          ELSE nome_completo_fantasia
        END,
        updated_at = NOW()
      WHERE email = NEW.email;

      RETURN NEW;
    ELSE
      -- Email novo via OAuth → sempre vira cliente
      v_tipo := 'cliente';
    END IF;

  END IF;

  -- Garante proteção dupla: admin nunca via OAuth
  IF v_tipo = 'admin' AND v_provider != 'email' THEN
    v_tipo := 'cliente';
  END IF;

  -- Insere perfil em public.usuarios
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
      INSERT INTO public.estabelecimentos (usuario_id, endereco)
      VALUES (NEW.id, '{"latitude": 0, "longitude": 0}'::jsonb)
      ON CONFLICT (usuario_id) DO NOTHING;

    ELSE
      NULL;
  END CASE;

  RETURN NEW;

EXCEPTION WHEN OTHERS THEN
  RAISE LOG 'criar_perfil_usuario erro para %: %', NEW.id, SQLERRM;
  RETURN NEW;
END;
$$;
;
