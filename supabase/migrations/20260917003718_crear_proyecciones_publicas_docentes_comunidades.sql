-- Proyecciones públicas con seguridad del usuario invocante.
create or replace view public.comunidades_publicas
with (security_invoker = true)
as
select
  id, nombre, tipo, descripcion, vision, mision, publico_objetivo,
  logo_url, horario, precio_clase, precio_combo, incluye_social,
  estilos, estado_convergencia, locacion_id, contacto_oficial_url,
  instagram_url, whatsapp_link, es_afiliado_auraritmos,
  visible_publicamente
from public.comunidades
where visible_publicamente is true
  and estado_convergencia is distinct from 'rechazado';

create or replace view public.docentes_publicos
with (security_invoker = true)
as
select
  d.id, d.nombre_publico, d.foto_url, d.rol_principal, d.biografia,
  d.anio_inicio_baile, d.anio_inicio_docencia, d.profesion,
  d.estado_verificacion, d.especialidades, d.participacion,
  d.instagram, d.facebook, d.tiktok, d.youtube,
  d.visible_publicamente, d.ultima_actualizacion,
  d.comunidad_principal_id,
  c.nombre as comunidad_principal_nombre,
  c.horario as comunidad_principal_horario
from public.docentes d
left join public.comunidades c on c.id = d.comunidad_principal_id
where d.visible_publicamente is true;

create or replace view public.docentes_comunidades_publicas
with (security_invoker = true)
as
select dc.docente_id, dc.comunidad_id
from public.docentes_comunidades dc
join public.docentes d
  on d.id = dc.docente_id and d.visible_publicamente is true
join public.comunidades c
  on c.id = dc.comunidad_id and c.visible_publicamente is true;

grant select on public.comunidades_publicas,
  public.docentes_publicos,
  public.docentes_comunidades_publicas
to anon, authenticated;

create or replace function private.fn_mi_docente_impl()
returns jsonb
language sql
stable
security definer
set search_path = pg_catalog, public, auth, pg_temp
as $$
  select case when auth.uid() is null then null else (
    select jsonb_build_object(
      'id', d.id,
      'nombre_publico', d.nombre_publico,
      'comunidad_principal_id', d.comunidad_principal_id
    )
    from public.docentes d
    where d.auth_user_id = auth.uid()
    limit 1
  ) end;
$$;

revoke all on function private.fn_mi_docente_impl() from public;
grant usage on schema private to authenticated;
grant execute on function private.fn_mi_docente_impl() to authenticated;

create or replace function public.fn_mi_docente()
returns jsonb
language sql
stable
security invoker
set search_path = pg_catalog, public, private, pg_temp
as $$ select private.fn_mi_docente_impl(); $$;

revoke all on function public.fn_mi_docente() from public, anon;
grant execute on function public.fn_mi_docente() to authenticated;
