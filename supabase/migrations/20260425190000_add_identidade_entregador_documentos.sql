alter table public.entregador_documentos
  drop constraint if exists entregador_documentos_tipo_check;

alter table public.entregador_documentos
  add constraint entregador_documentos_tipo_check
  check (
    tipo = any (
      array[
        'cnh_frente'::text,
        'cnh_verso'::text,
        'identidade_frente'::text,
        'identidade_verso'::text,
        'veiculo'::text,
        'residencia'::text,
        'selfie'::text
      ]
    )
  );
