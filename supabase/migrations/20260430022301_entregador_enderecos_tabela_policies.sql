-- Enderecos dos entregadores para cadastro operacional e subconta Asaas.
-- Mantem tambem public.entregadores.endereco como snapshot usado pelas Edge Functions.

alter table public.entregadores
  add column if not exists endereco jsonb default '{}'::jsonb;

create table if not exists public.entregador_enderecos (
  id uuid primary key default gen_random_uuid(),
  entregador_id uuid not null references public.entregadores(id) on delete cascade,
  apelido text default 'Principal',
  cep text not null,
  logradouro text not null,
  numero text not null,
  complemento text,
  bairro text not null,
  cidade text not null,
  estado text not null,
  latitude double precision,a
  longitude double precision,
  is_principal boolean not null default true,
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  constraint entregador_enderecos_cep_digits_check
    check (cep ~ '^[0-9]{8}$'),
  constraint entregador_enderecos_estado_check
    check (estado ~ '^[A-Z]{2}$')
);

create unique index if not exists entregador_enderecos_entregador_unique
  on public.entregador_enderecos (entregador_id);

create index if not exists entregador_enderecos_entregador_idx
  on public.entregador_enderecos (entregador_id);

create or replace function public.set_entregador_enderecos_updated_at()
returns trigger
language plpgsql
as $$
begin
  new.updated_at = now();
  return new;
end;
$$;

drop trigger if exists trg_entregador_enderecos_updated_at
  on public.entregador_enderecos;

create trigger trg_entregador_enderecos_updated_at
before update on public.entregador_enderecos
for each row
execute function public.set_entregador_enderecos_updated_at();

insert into public.entregador_enderecos (
  entregador_id,
  cep,
  logradouro,
  numero,
  complemento,
  bairro,
  cidade,
  estado,
  is_principal
)
select
  e.id,
  regexp_replace(coalesce(e.endereco->>'cep', ''), '\D', '', 'g'),
  trim(e.endereco->>'logradouro'),
  trim(e.endereco->>'numero'),
  nullif(trim(coalesce(e.endereco->>'complemento', '')), ''),
  trim(e.endereco->>'bairro'),
  trim(e.endereco->>'cidade'),
  upper(trim(e.endereco->>'estado')),
  true
from public.entregadores e
where e.endereco is not null
  and e.endereco <> '{}'::jsonb
  and length(regexp_replace(coalesce(e.endereco->>'cep', ''), '\D', '', 'g')) = 8
  and nullif(trim(coalesce(e.endereco->>'logradouro', '')), '') is not null
  and nullif(trim(coalesce(e.endereco->>'numero', '')), '') is not null
  and nullif(trim(coalesce(e.endereco->>'bairro', '')), '') is not null
  and nullif(trim(coalesce(e.endereco->>'cidade', '')), '') is not null
  and length(upper(trim(coalesce(e.endereco->>'estado', '')))) = 2
on conflict (entregador_id) do update
set
  cep = excluded.cep,
  logradouro = excluded.logradouro,
  numero = excluded.numero,
  complemento = excluded.complemento,
  bairro = excluded.bairro,
  cidade = excluded.cidade,
  estado = excluded.estado,
  is_principal = true,
  updated_at = now();

alter table public.entregador_enderecos enable row level security;

drop policy if exists "Entregador le proprio endereco"
  on public.entregador_enderecos;
drop policy if exists "Entregador insere proprio endereco"
  on public.entregador_enderecos;
drop policy if exists "Entregador atualiza proprio endereco"
  on public.entregador_enderecos;
drop policy if exists "Admin gerencia enderecos entregadores"
  on public.entregador_enderecos;

create policy "Entregador le proprio endereco"
on public.entregador_enderecos
for select
to authenticated
using (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_enderecos.entregador_id
      and e.usuario_id = auth.uid()
  )
);

create policy "Entregador insere proprio endereco"
on public.entregador_enderecos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_enderecos.entregador_id
      and e.usuario_id = auth.uid()
  )
);

create policy "Entregador atualiza proprio endereco"
on public.entregador_enderecos
for update
to authenticated
using (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_enderecos.entregador_id
      and e.usuario_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_enderecos.entregador_id
      and e.usuario_id = auth.uid()
  )
);

create policy "Admin gerencia enderecos entregadores"
on public.entregador_enderecos
for all
to authenticated
using (
  exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
)
with check (
  exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
);
