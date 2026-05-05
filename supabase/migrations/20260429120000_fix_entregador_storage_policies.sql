insert into storage.buckets (
  id,
  name,
  "public",
  file_size_limit,
  allowed_mime_types
)
values (
  'documentos-entregador',
  'documentos-entregador',
  false,
  10485760,
  array['image/jpeg', 'image/png', 'image/webp', 'application/pdf']
)
on conflict (id) do update
set
  "public" = false,
  file_size_limit = excluded.file_size_limit,
  allowed_mime_types = excluded.allowed_mime_types;

drop policy if exists "Entregador le arquivos proprios" on storage.objects;
drop policy if exists "Entregador envia arquivos proprios" on storage.objects;
drop policy if exists "Entregador atualiza arquivos proprios" on storage.objects;
drop policy if exists "Admin gerencia documentos entregador" on storage.objects;

create policy "Entregador le arquivos proprios"
on storage.objects
for select
to authenticated
using (
  bucket_id = 'documentos-entregador'
  and (
    exists (
      select 1
      from public.entregadores e
      where e.usuario_id = auth.uid()
        and (
          e.id::text = split_part(storage.objects.name, '/', 1)
          or (
            split_part(storage.objects.name, '/', 1) = 'perfil'
            and e.id::text = regexp_replace(
              split_part(storage.objects.name, '/', 2),
              '\.[^.]*$',
              ''
            )
          )
        )
    )
    or exists (
      select 1
      from public.usuarios u
      where u.id = auth.uid()
        and u.tipo_usuario = 'admin'
    )
  )
);

create policy "Entregador envia arquivos proprios"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'documentos-entregador'
  and (
    exists (
      select 1
      from public.entregadores e
      where e.usuario_id = auth.uid()
        and (
          e.id::text = split_part(storage.objects.name, '/', 1)
          or (
            split_part(storage.objects.name, '/', 1) = 'perfil'
            and e.id::text = regexp_replace(
              split_part(storage.objects.name, '/', 2),
              '\.[^.]*$',
              ''
            )
          )
        )
    )
    or exists (
      select 1
      from public.usuarios u
      where u.id = auth.uid()
        and u.tipo_usuario = 'admin'
    )
  )
);

create policy "Entregador atualiza arquivos proprios"
on storage.objects
for update
to authenticated
using (
  bucket_id = 'documentos-entregador'
  and exists (
    select 1
    from public.entregadores e
    where e.usuario_id = auth.uid()
      and (
        e.id::text = split_part(storage.objects.name, '/', 1)
        or (
          split_part(storage.objects.name, '/', 1) = 'perfil'
          and e.id::text = regexp_replace(
            split_part(storage.objects.name, '/', 2),
            '\.[^.]*$',
            ''
          )
        )
      )
  )
)
with check (
  bucket_id = 'documentos-entregador'
  and exists (
    select 1
    from public.entregadores e
    where e.usuario_id = auth.uid()
      and (
        e.id::text = split_part(storage.objects.name, '/', 1)
        or (
          split_part(storage.objects.name, '/', 1) = 'perfil'
          and e.id::text = regexp_replace(
            split_part(storage.objects.name, '/', 2),
            '\.[^.]*$',
            ''
          )
        )
      )
  )
);

create policy "Admin gerencia documentos entregador"
on storage.objects
for all
to authenticated
using (
  bucket_id = 'documentos-entregador'
  and exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
)
with check (
  bucket_id = 'documentos-entregador'
  and exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
);

alter table public.entregador_documentos enable row level security;

drop policy if exists "Entregador le proprios documentos" on public.entregador_documentos;
drop policy if exists "Entregador insere proprios documentos" on public.entregador_documentos;
drop policy if exists "Admin gerencia documentos entregador tabela" on public.entregador_documentos;

create policy "Entregador le proprios documentos"
on public.entregador_documentos
for select
to authenticated
using (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_documentos.entregador_id
      and e.usuario_id = auth.uid()
  )
  or exists (
    select 1
    from public.usuarios u
    where u.id = auth.uid()
      and u.tipo_usuario = 'admin'
  )
);

create policy "Entregador insere proprios documentos"
on public.entregador_documentos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_documentos.entregador_id
      and e.usuario_id = auth.uid()
  )
);

create policy "Admin gerencia documentos entregador tabela"
on public.entregador_documentos
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
