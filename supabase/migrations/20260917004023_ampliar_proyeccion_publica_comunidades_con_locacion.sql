create or replace view public.comunidades_publicas
with (security_invoker = true)
as
select
  c.id, c.nombre, c.tipo, c.descripcion, c.vision, c.mision,
  c.publico_objetivo, c.logo_url, c.horario, c.precio_clase,
  c.precio_combo, c.incluye_social, c.estilos, c.estado_convergencia,
  c.locacion_id, c.contacto_oficial_url, c.instagram_url, c.whatsapp_link,
  c.es_afiliado_auraritmos, c.visible_publicamente,
  l.nombre as locacion_nombre,
  l.mapa_url as locacion_mapa_url,
  l.comuna as locacion_comuna,
  l.referencia_url as locacion_referencia_url,
  l.lat as locacion_lat,
  l.lng as locacion_lng
from public.comunidades c
left join public.locaciones l on l.id = c.locacion_id
where c.visible_publicamente is true
  and c.estado_convergencia is distinct from 'rechazado';

grant select on public.comunidades_publicas to anon, authenticated;
