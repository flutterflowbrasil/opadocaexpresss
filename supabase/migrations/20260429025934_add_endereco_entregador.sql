-- Endereco residencial/comercial do entregador usado no cadastro Asaas.

alter table public.entregadores
  add column if not exists endereco jsonb default '{}'::jsonb;;
