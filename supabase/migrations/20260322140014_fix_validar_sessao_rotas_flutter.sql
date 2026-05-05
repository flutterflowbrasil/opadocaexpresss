
CREATE OR REPLACE FUNCTION public.validar_sessao_e_rota()
 RETURNS jsonb
 LANGUAGE plpgsql
 STABLE SECURITY DEFINER
AS $function$
DECLARE
  v_usuario   record;
  v_rota      text;
  v_extra     jsonb;
BEGIN
  SELECT
    u.id,
    u.tipo_usuario,
    u.status,
    u.nome_completo_fantasia,
    u.email_verificado
  INTO v_usuario
  FROM public.usuarios u
  WHERE u.id = auth.uid();

  IF NOT FOUND THEN
    RETURN jsonb_build_object(
      'autorizado', false,
      'rota',       '/login',
      'erro',       'perfil_nao_encontrado'
    );
  END IF;

  IF v_usuario.status != 'ativo' THEN
    RETURN jsonb_build_object(
      'autorizado', false,
      'rota',       '/login',
      'erro',       'conta_suspensa'
    );
  END IF;

  CASE v_usuario.tipo_usuario

    WHEN 'admin' THEN
      v_rota  := '/admin/dashboard';
      v_extra := jsonb_build_object('perfil', 'admin');

    WHEN 'estabelecimento' THEN
      DECLARE
        v_status_estab text;
      BEGIN
        SELECT status_cadastro INTO v_status_estab
        FROM public.estabelecimentos
        WHERE usuario_id = v_usuario.id;

        -- Rotas alinhadas com o Flutter router
        v_rota := CASE v_status_estab
          WHEN 'aprovado'  THEN '/dashboard_estabelecimento'
          WHEN 'pendente'  THEN '/dashboard_estabelecimento/aguardando'
          WHEN 'suspenso'  THEN '/dashboard_estabelecimento/suspenso'
          ELSE '/dashboard_estabelecimento/aguardando'
        END;
        v_extra := jsonb_build_object('status_cadastro', v_status_estab);
      END;

    WHEN 'entregador' THEN
      DECLARE
        v_status_entregador text;
      BEGIN
        SELECT status_cadastro INTO v_status_entregador
        FROM public.entregadores
        WHERE usuario_id = v_usuario.id;

        -- Rotas alinhadas com o Flutter router
        v_rota := CASE v_status_entregador
          WHEN 'aprovado'  THEN '/dashboard_entregador'
          WHEN 'pendente'  THEN '/dashboard_entregador/aguardando'
          WHEN 'suspenso'  THEN '/dashboard_entregador/suspenso'
          ELSE '/dashboard_entregador/aguardando'
        END;
        v_extra := jsonb_build_object('status_cadastro', v_status_entregador);
      END;

    WHEN 'cliente' THEN
      v_rota  := '/home';
      v_extra := jsonb_build_object('perfil', 'cliente');

    ELSE
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
$function$;
;
