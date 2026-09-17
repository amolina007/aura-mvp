
begin;

create table public.pasaporte_estilos (
  pasaporte_id uuid not null references public.pasaportes(id) on delete cascade,
  estilo text not null check (char_length(btrim(estilo)) between 1 and 80),
  created_at timestamptz not null default now(),
  primary key (pasaporte_id, estilo)
);

comment on table public.pasaporte_estilos is
  'Estilos activados por cada Pasaporte para su progresión RPG privada.';

create table public.pasaporte_pasos (
  pasaporte_id uuid not null references public.pasaportes(id) on delete cascade,
  paso_id uuid not null references public.pasos(id) on delete cascade,
  estado text not null default 'practicando'
    check (estado in ('practicando', 'dominado')),
  origen text not null default 'autodeclarado'
    check (origen in ('autodeclarado', 'docente', 'sistema')),
  created_at timestamptz not null default now(),
  updated_at timestamptz not null default now(),
  primary key (pasaporte_id, paso_id)
);

comment on table public.pasaporte_pasos is
  'Progreso privado y autodeclarado de pasos del RPG; no entrega XP por sí solo.';

create index pasaporte_pasos_paso_id_idx
  on public.pasaporte_pasos (paso_id);

alter table public.pasaporte_estilos enable row level security;
alter table public.pasaporte_pasos enable row level security;

revoke all on public.pasaporte_estilos from anon;
revoke all on public.pasaporte_pasos from anon;
grant select, insert, delete on public.pasaporte_estilos to authenticated;
grant select, insert, update, delete on public.pasaporte_pasos to authenticated;

create policy "pasaporte_estilos_lectura_propia"
on public.pasaporte_estilos
for select
to authenticated
using (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_estilos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
);

create policy "pasaporte_estilos_insercion_propia"
on public.pasaporte_estilos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_estilos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
  and exists (
    select 1
    from public.pasos paso
    where paso.estilo = pasaporte_estilos.estilo
  )
);

create policy "pasaporte_estilos_borrado_propio"
on public.pasaporte_estilos
for delete
to authenticated
using (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_estilos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
);

create policy "pasaporte_pasos_lectura_propia"
on public.pasaporte_pasos
for select
to authenticated
using (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_pasos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
);

create policy "pasaporte_pasos_insercion_propia"
on public.pasaporte_pasos
for insert
to authenticated
with check (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_pasos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
  and exists (
    select 1
    from public.pasos paso
    join public.pasaporte_estilos pe
      on pe.pasaporte_id = pasaporte_pasos.pasaporte_id
     and pe.estilo = paso.estilo
    where paso.id = pasaporte_pasos.paso_id
  )
);

create policy "pasaporte_pasos_actualizacion_propia"
on public.pasaporte_pasos
for update
to authenticated
using (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_pasos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
)
with check (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_pasos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
  and exists (
    select 1
    from public.pasos paso
    join public.pasaporte_estilos pe
      on pe.pasaporte_id = pasaporte_pasos.pasaporte_id
     and pe.estilo = paso.estilo
    where paso.id = pasaporte_pasos.paso_id
  )
);

create policy "pasaporte_pasos_borrado_propio"
on public.pasaporte_pasos
for delete
to authenticated
using (
  exists (
    select 1
    from public.pasaportes p
    where p.id = pasaporte_pasos.pasaporte_id
      and p.auth_user_id = (select auth.uid())
  )
);

insert into public.pasaporte_estilos (pasaporte_id, estilo)
select distinct p.id, catalogo.estilo
from public.pasaportes p
cross join lateral unnest(p.ritmos) as ritmo(nombre)
join (
  select distinct estilo
  from public.pasos
  where estilo is not null
) catalogo on lower(catalogo.estilo) = lower(ritmo.nombre)
on conflict do nothing;

commit;
