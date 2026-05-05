create or replace function public.check_account_identifier_exists(
  p_email text default null,
  p_cpf text default null,
  p_cnpj text default null,
  p_ignore_user_id uuid default null
)
returns jsonb
language plpgsql
security definer
set search_path = public
as $$
declare
  v_email text := nullif(lower(trim(coalesce(p_email, ''))), '');
  v_cpf text := nullif(regexp_replace(coalesce(p_cpf, ''), '\D', '', 'g'), '');
  v_cnpj text := nullif(regexp_replace(coalesce(p_cnpj, ''), '\D', '', 'g'), '');
  v_email_exists boolean := false;
  v_cpf_exists boolean := false;
  v_cnpj_exists boolean := false;
begin
  if v_email is not null then
    select exists(
      select 1
      from public.usuarios u
      where lower(u.email) = v_email
        and (p_ignore_user_id is null or u.id <> p_ignore_user_id)
    ) into v_email_exists;
  end if;

  if v_cpf is not null then
    select exists(
      select 1
      from public.clientes c
      where regexp_replace(coalesce(c.cpf, ''), '\D', '', 'g') = v_cpf
        and (p_ignore_user_id is null or c.usuario_id <> p_ignore_user_id)
      union all
      select 1
      from public.entregadores e
      where regexp_replace(coalesce(e.cpf, ''), '\D', '', 'g') = v_cpf
        and (p_ignore_user_id is null or e.usuario_id <> p_ignore_user_id)
      union all
      select 1
      from public.estabelecimentos est
      where regexp_replace(coalesce(est.responsavel_cpf, ''), '\D', '', 'g') = v_cpf
        and (p_ignore_user_id is null or est.usuario_id <> p_ignore_user_id)
      union all
      select 1
      from public.estabelecimentos est
      where regexp_replace(coalesce(est.cnpj, ''), '\D', '', 'g') = v_cpf
        and (p_ignore_user_id is null or est.usuario_id <> p_ignore_user_id)
    ) into v_cpf_exists;
  end if;

  if v_cnpj is not null then
    select exists(
      select 1
      from public.estabelecimentos est
      where regexp_replace(coalesce(est.cnpj, ''), '\D', '', 'g') = v_cnpj
        and (p_ignore_user_id is null or est.usuario_id <> p_ignore_user_id)
    ) into v_cnpj_exists;
  end if;

  return jsonb_build_object(
    'email', v_email_exists,
    'cpf', v_cpf_exists,
    'cnpj', v_cnpj_exists
  );
end;
$$;

grant execute on function public.check_account_identifier_exists(text, text, text, uuid) to anon;
grant execute on function public.check_account_identifier_exists(text, text, text, uuid) to authenticated;
