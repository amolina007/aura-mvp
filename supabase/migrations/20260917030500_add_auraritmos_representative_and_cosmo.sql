-- Añade campos de representante público a las agrupaciones.
-- Los valores personales y su consentimiento se gestionan como datos operativos
-- en Supabase y no se versionan en este repositorio público.

alter table public.comunidades
  add column if not exists representante_nombre_publico text,
  add column if not exists representante_email_publico text,
  add column if not exists representante_telefono_publico text,
  add column if not exists representante_instagram_publico text,
  add column if not exists representante_whatsapp_publico text,
  add column if not exists representante_contacto_publico boolean not null default false;

comment on column public.comunidades.representante_contacto_publico is
  'Consentimiento explícito para publicar nombre y canales de contacto del representante.';

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
  case when c.representante_contacto_publico then c.representante_nombre_publico end as representante_nombre,
  case when c.representante_contacto_publico then c.representante_email_publico end as representante_email,
  case when c.representante_contacto_publico then c.representante_telefono_publico end as representante_telefono,
  case when c.representante_contacto_publico then c.representante_instagram_publico end as representante_instagram,
  case when c.representante_contacto_publico then c.representante_whatsapp_publico end as representante_whatsapp
from public.comunidades c
left join public.locaciones l on l.id = c.locacion_id
where c.visible_publicamente is true
  and c.estado_convergencia is distinct from 'rechazado';

do $migration$
begin
  if (select count(*) from public.comunidades where nombre = 'AuraRitmos') <> 1 then
    raise exception 'Se esperaba exactamente una comunidad AuraRitmos';
  end if;
  if (select count(*) from public.docentes where nombre_publico = 'Cosmo Garrido') <> 1 then
    raise exception 'Se esperaba exactamente un docente Cosmo Garrido';
  end if;

  insert into public.docentes_comunidades (docente_id, comunidad_id)
  select d.id, c.id
  from public.docentes d
  cross join public.comunidades c
  where d.nombre_publico = 'Cosmo Garrido'
    and c.nombre = 'AuraRitmos'
  on conflict (docente_id, comunidad_id) do nothing;
end
$migration$;
