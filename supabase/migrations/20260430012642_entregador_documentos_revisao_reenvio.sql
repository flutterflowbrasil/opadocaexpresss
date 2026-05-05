-- Guarda o resultado da revisao manual por documento e permite reenvio pelo entregador.

alter table public.entregador_documentos
  add column if not exists motivo_rejeicao text,
  add column if not exists revisado_em timestamptz,
  add column if not exists revisado_por uuid references public.usuarios(id);

create index if not exists entregador_documentos_entregador_tipo_idx
  on public.entregador_documentos (entregador_id, tipo);

drop policy if exists "Entregador atualiza proprios documentos tabela"
  on public.entregador_documentos;

create policy "Entregador atualiza proprios documentos tabela"
on public.entregador_documentos
for update
to authenticated
using (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_documentos.entregador_id
      and e.usuario_id = auth.uid()
  )
)
with check (
  exists (
    select 1
    from public.entregadores e
    where e.id = entregador_documentos.entregador_id
      and e.usuario_id = auth.uid()
  )
);
