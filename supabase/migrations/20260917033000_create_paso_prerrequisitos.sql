begin;

create table if not exists public.paso_prerrequisitos (
  paso_id uuid not null references public.pasos(id) on delete cascade,
  prerequisito_id uuid not null references public.pasos(id) on delete cascade,
  created_at timestamptz not null default now(),
  primary key (paso_id, prerequisito_id),
  constraint paso_prerrequisito_no_circular check (paso_id <> prerequisito_id)
);

comment on table public.paso_prerrequisitos is
  'Conexiones del repertorio: un paso o figura se construye a partir de uno o más pasos base.';

alter table public.paso_prerrequisitos enable row level security;
grant select on public.paso_prerrequisitos to anon, authenticated;

create policy "paso_prerrequisitos_lectura_publica"
on public.paso_prerrequisitos
for select
to anon, authenticated
using (true);

create index if not exists paso_prerrequisitos_prerequisito_idx
  on public.paso_prerrequisitos (prerequisito_id);

commit;
