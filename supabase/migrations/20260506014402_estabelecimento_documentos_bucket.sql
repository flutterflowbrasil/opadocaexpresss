-- Documentos de estabelecimento: bucket privado, tabela e policies.

insert into storage.buckets (id, name, public, file_size_limit, allowed_mime_types)
values (
  'documentos',
  'documentos',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  public = excluded.public,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

create table if not exists public.estabelecimento_documentos (
  id uuid primary key default uuid_generate_v4(),
  estabelecimento_id uuid not null references public.estabelecimentos(id) on delete cascade,
  tipo text not null,
  url text not null,
  status_validacao text not null default 'pendente',
  motivo_rejeicao text,
  validado_por uuid references public.usuarios(id),
  validado_em timestamptz,
  created_at timestamptz default timezone('utc'::text, now()),
  updated_at timestamptz default timezone('utc'::text, now())
);

alter table public.estabelecimento_documentos
  add column if not exists id uuid default uuid_generate_v4(),
  add column if not exists estabelecimento_id uuid,
  add column if not exists tipo text,
  add column if not exists url text,
  add column if not exists status_validacao text default 'pendente',
  add column if not exists motivo_rejeicao text,
  add column if not exists validado_por uuid,
  add column if not exists validado_em timestamptz,
  add column if not exists created_at timestamptz default timezone('utc'::text, now()),
  add column if not exists updated_at timestamptz default timezone('utc'::text, now());

alter table public.estabelecimento_documentos
  alter column estabelecimento_id set not null,
  alter column tipo set not null,
  alter column url set not null,
  alter column status_validacao set default 'pendente',
  alter column status_validacao set not null;

do $$
begin
  if not exists (
    select 1
    from pg_constraint
    where conname = 'estabelecimento_documentos_estabelecimento_fkey'
      and conrelid = 'public.estabelecimento_documentos'::regclass
  ) then
    alter table public.estabelecimento_documentos
      add constraint estabelecimento_documentos_estabelecimento_fkey
      foreign key (estabelecimento_id)
      references public.estabelecimentos(id)
      on delete cascade;
  end if;

  if not exists (
    select 1
    from pg_constraint
    where conname = 'estabelecimento_documentos_validado_por_fkey'
      and conrelid = 'public.estabelecimento_documentos'::regclass
  ) then
    alter table public.estabelecimento_documentos
      add constraint estabelecimento_documentos_validado_por_fkey
      foreign key (validado_por)
      references public.usuarios(id);
  end if;
end $$;

alter table public.estabelecimento_documentos
  drop constraint if exists estabelecimento_documentos_tipo_check,
  add constraint estabelecimento_documentos_tipo_check
  check (
    tipo = any (
      array[
        'cartao_cnpj',
        'contrato_social',
        'alvara_funcionamento',
        'comprovante_endereco',
        'documento_responsavel_frente',
        'documento_responsavel_verso',
        'identidade_responsavel_frente',
        'identidade_responsavel_verso',
        'cnh_responsavel_frente',
        'cnh_responsavel_verso',
        'selfie_responsavel',
        'inscricao_estadual',
        'inscricao_municipal',
        'fachada_estabelecimento',
        'outro'
      ]
    )
  );

alter table public.estabelecimento_documentos
  drop constraint if exists estabelecimento_documentos_status_validacao_check,
  add constraint estabelecimento_documentos_status_validacao_check
  check (status_validacao = any (array['pendente', 'aprovado', 'reprovado']));

create index if not exists idx_estabelecimento_documentos_estabelecimento
  on public.estabelecimento_documentos(estabelecimento_id);

create index if not exists idx_estabelecimento_documentos_tipo
  on public.estabelecimento_documentos(estabelecimento_id, tipo);

alter table public.estabelecimento_documentos enable row level security;

grant select, insert, update, delete on public.estabelecimento_documentos to authenticated;

drop policy if exists "Estabelecimento le seus documentos" on public.estabelecimento_documentos;
create policy "Estabelecimento le seus documentos"
on public.estabelecimento_documentos
for select
to authenticated
using (
  exists (
    select 1
    from public.estabelecimentos e
    where e.id = estabelecimento_documentos.estabelecimento_id
      and e.usuario_id = auth.uid()
  )
  or exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
);

drop policy if exists "Estabelecimento insere seus documentos" on public.estabelecimento_documentos;
create policy "Estabelecimento insere seus documentos"
on public.estabelecimento_documentos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.estabelecimentos e
    where e.id = estabelecimento_documentos.estabelecimento_id
      and e.usuario_id = auth.uid()
  )
);

drop policy if exists "Estabelecimento atualiza seus documentos" on public.estabelecimento_documentos;
create policy "Estabelecimento atualiza seus documentos"
on public.estabelecimento_documentos
for update
to authenticated
using (
  exists (
    select 1
    from public.estabelecimentos e
    where e.id = estabelecimento_documentos.estabelecimento_id
      and e.usuario_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.estabelecimentos e
    where e.id = estabelecimento_documentos.estabelecimento_id
      and e.usuario_id = auth.uid()
  )
);

drop policy if exists "Admin gerencia documentos de estabelecimentos" on public.estabelecimento_documentos;
create policy "Admin gerencia documentos de estabelecimentos"
on public.estabelecimento_documentos
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

drop policy if exists "Estabelecimento le arquivos de documentos" on storage.objects;
create policy "Estabelecimento le arquivos de documentos"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and (
    exists (
      select 1
      from public.estabelecimentos e
      where e.id::text = split_part(storage.objects.name, '/', 2)
        and e.usuario_id = auth.uid()
    )
    or exists (
      select 1
      from public.usuarios u
      where u.id = auth.uid()
        and u.tipo_usuario = 'admin'
    )
  )
);

drop policy if exists "Estabelecimento envia arquivos de documentos" on storage.objects;
create policy "Estabelecimento envia arquivos de documentos"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and exists (
    select 1
    from public.estabelecimentos e
    where e.id::text = split_part(storage.objects.name, '/', 2)
      and e.usuario_id = auth.uid()
  )
);

drop policy if exists "Estabelecimento atualiza arquivos de documentos" on storage.objects;
create policy "Estabelecimento atualiza arquivos de documentos"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and exists (
    select 1
    from public.estabelecimentos e
    where e.id::text = split_part(storage.objects.name, '/', 2)
      and e.usuario_id = auth.uid()
  )
)
with check (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and exists (
    select 1
    from public.estabelecimentos e
    where e.id::text = split_part(storage.objects.name, '/', 2)
      and e.usuario_id = auth.uid()
  )
);

drop policy if exists "Admin gerencia arquivos de documentos estabelecimento" on storage.objects;
create policy "Admin gerencia arquivos de documentos estabelecimento"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
)
with check (
  bucket_id = 'documentos'
  and split_part(name, '/', 1) = 'estabelecimentos'
  and exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
);
