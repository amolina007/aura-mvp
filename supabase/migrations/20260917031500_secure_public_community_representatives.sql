-- Aísla los datos autorizados del representante en una tabla pública.
-- La migración mueve solamente filas que ya tienen consentimiento explícito;
-- no contiene datos personales literales.
create table if not exists public.comunidad_representantes_publicos (
  comunidad_id uuid primary key references public.comunidades(id) on delete cascade,
  nombre text not null,
  email text,
  telefono text,
  instagram_url text,
  whatsapp_url text,
  actualizado_en timestamptz not null default now()
);

alter table public.comunidad_representantes_publicos enable row level security;

drop policy if exists "Representantes de comunidades visibles"
  on public.comunidad_representantes_publicos;

create policy "Representantes de comunidades visibles"
  on public.comunidad_representantes_publicos
  for select
  to anon, authenticated
  using (
    exists (
      select 1
      from public.comunidades c
      where c.id = comunidad_representantes_publicos.comunidad_id
        and c.visible_publicamente is true
        and c.estado_convergencia is distinct from 'rechazado'
    )
  );

grant select on public.comunidad_representantes_publicos to anon, authenticated;

insert into public.comunidad_representantes_publicos (
  comunidad_id, nombre, email, telefono, instagram_url, whatsapp_url
)
select id,
       representante_nombre_publico,
       representante_email_publico,
       representante_telefono_publico,
       representante_instagram_publico,
       representante_whatsapp_publico
from public.comunidades
where representante_contacto_publico is true
  and representante_nombre_publico is not null
on conflict (comunidad_id) do update
set nombre = excluded.nombre,
    email = excluded.email,
    telefono = excluded.telefono,
    instagram_url = excluded.instagram_url,
    whatsapp_url = excluded.whatsapp_url,
    actualizado_en = now();

create or replace view public.comunidades_publicas
with (security_invoker = true)
as
select
  c.id,
  c.nombre,
  c.tipo,
  c.descripcion,
  c.vision,
  c.mision,
  c.publico_objetivo,
  c.logo_url,
  c.horario,
  c.precio_clase,
  c.precio_combo,
  c.incluye_social,
  c.estilos,
  c.estado_convergencia,
  c.locacion_id,
  c.contacto_oficial_url,
  c.instagram_url,
  c.whatsapp_link,
  c.es_afiliado_auraritmos,
  c.visible_publicamente,
  l.nombre as locacion_nombre,
  l.mapa_url as locacion_mapa_url,
  l.comuna as locacion_comuna,
  l.referencia_url as locacion_referencia_url,
  l.lat as locacion_lat,
  l.lng as locacion_lng,
  r.nombre as representante_nombre,
  r.email as representante_email,
  r.telefono as representante_telefono,
  r.instagram_url as representante_instagram,
  r.whatsapp_url as representante_whatsapp
from public.comunidades c
left join public.locaciones l on l.id = c.locacion_id
left join public.comunidad_representantes_publicos r on r.comunidad_id = c.id
where c.visible_publicamente is true
  and c.estado_convergencia is distinct from 'rechazado';

update public.comunidades
set representante_nombre_publico = null,
    representante_email_publico = null,
    representante_telefono_publico = null,
    representante_instagram_publico = null,
    representante_whatsapp_publico = null,
    representante_contacto_publico = false
where representante_contacto_publico is true;
