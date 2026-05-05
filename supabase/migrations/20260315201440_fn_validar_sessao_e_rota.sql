
-- ============================================================
-- Função server-side: valida sessão e retorna rota autorizada
-- Chamada pelo Flutter logo após o login
-- NUNCA retorna tipo_usuario direto — só a rota permitida
-- ============================================================
CREATE OR REPLACE FUNCTION public.validar_sessao_e_rota()
RETURNS jsonb
LANGUAGE plpgsql
STABLE
SECURITY DEFINER
AS $$
DECLARE
  v_usuario   record;
  v_rota      text;
  v_extra     jsonb;
BEGIN
  -- Lê direto do banco usando auth.uid() — nunca confia no client
  SELECT
    u.id,
    u.tipo_usuario,
    u.status,
    u.nome_completo_fantasia,
    u.email_verificado
  INTO v_usuario
  FROM public.usuarios u
  WHERE u.id = auth.uid();

  -- Usuário não encontrado na tabela (auth existe mas perfil não)
  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'autorizado', false,
      'rota',       '/login',
      'erro',       'perfil_nao_encontrado'
    );
  END IF;

  -- Conta suspensa ou inativa
  IF v_usuario.status != 'ativo' THEN
    RETURN jsonb_build_object(
      'autorizado', false,
      'rota',       '/login',
      'erro',       'conta_suspensa'
    );
  END IF;

  -- Monta rota e dados extras por tipo de usuário
  CASE v_usuario.tipo_usuario

    WHEN 'admin' THEN
      v_rota  := '/admin/dashboard';
      v_extra := jsonb_build_object('perfil', 'admin');

    WHEN 'estabelecimento' THEN
      -- Verifica se cadastro está aprovado
      DECLARE
        v_status_estab text;
      BEGIN
        SELECT status_cadastro INTO v_status_estab
        FROM public.estabelecimentos
        WHERE usuario_id = v_usuario.id;

        v_rota := CASE v_status_estab
          WHEN 'aprovado'  THEN '/loja/dashboard'
          WHEN 'pendente'  THEN '/loja/aguardando_aprovacao'
          WHEN 'suspenso'  THEN '/loja/conta_suspensa'
          ELSE '/loja/cadastro'
        END;
        v_extra := jsonb_build_object('status_cadastro', v_status_estab);
      END;

    WHEN 'entregador' THEN
      -- Verifica se cadastro está aprovado
      DECLARE
        v_status_entregador text;
      BEGIN
        SELECT status_cadastro INTO v_status_entregador
        FROM public.entregadores
        WHERE usuario_id = v_usuario.id;

        v_rota := CASE v_status_entregador
          WHEN 'aprovado'  THEN '/entregador/home'
          WHEN 'pendente'  THEN '/entregador/aguardando_aprovacao'
          WHEN 'suspenso'  THEN '/entregador/conta_suspensa'
          ELSE '/entregador/cadastro'
        END;
        v_extra := jsonb_build_object('status_cadastro', v_status_entregador);
      END;

    WHEN 'cliente' THEN
      v_rota  := '/home';
      v_extra := jsonb_build_object('perfil', 'cliente');

    ELSE
      -- tipo_usuario inválido ou desconhecido
      RETURN jsonb_build_object(
        'autorizado', false,
        'rota',       '/login',
        'erro',       'tipo_invalido'
      );
  END CASE;

  RETURN jsonb_build_object(
    'autorizado', true,
    'rota',       v_rota,
    'nome',       v_usuario.nome_completo_fantasia,
    'extra',      v_extra
  );

EXCEPTION WHEN OTHERS THEN
  RETURN jsonb_build_object(
    'autorizado', false,
    'rota',       '/login',
    'erro',       'erro_interno'
  );
END;
$$;
;
