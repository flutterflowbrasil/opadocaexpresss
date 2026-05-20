-- A fila de notificacoes e operacional e nao deve ser exposta aos destinatarios.
-- Estabelecimentos/clientes/entregadores recebem notificacoes pelo app, mas
-- nao leem a fila FCM nem detalhes de erro/tentativas.

alter table public.notificacoes_fila enable row level security;

revoke all on public.notificacoes_fila from anon, authenticated;
grant select on public.notificacoes_fila to authenticated;

drop policy if exists "notif_fila_select" on public.notificacoes_fila;
create policy "notif_fila_select"
on public.notificacoes_fila
for select
to authenticated
using (is_admin());

drop policy if exists "notif_fila_insert_bloqueado" on public.notificacoes_fila;
create policy "notif_fila_insert_bloqueado"
on public.notificacoes_fila
for insert
to anon, authenticated
with check (false);
