revoke all privileges on table public.docentes from anon, authenticated;
grant select (
  id, nombre_publico, foto_url, rol_principal, biografia,
  anio_inicio_baile, anio_inicio_docencia, profesion,
  estado_verificacion, especialidades, participacion,
  instagram, facebook, tiktok, youtube,
  visible_publicamente, ultima_actualizacion, comunidad_principal_id
) on public.docentes to anon, authenticated;

revoke all privileges on table public.comunidades from anon, authenticated;
grant select (
  id, nombre, tipo, descripcion, vision, mision, publico_objetivo,
  logo_url, horario, precio_clase, precio_combo, incluye_social,
  estilos, estado_convergencia, locacion_id, contacto_oficial_url,
  instagram_url, whatsapp_link, es_afiliado_auraritmos,
  visible_publicamente
) on public.comunidades to anon, authenticated;

revoke all privileges on table public.docentes_comunidades from anon, authenticated;
grant select (docente_id, comunidad_id)
on public.docentes_comunidades to anon, authenticated;

drop policy if exists "Relación docente-comunidad es pública"
on public.docentes_comunidades;

create policy "Relación visible, propia o gestionada por capitán"
on public.docentes_comunidades
for select
to anon, authenticated
using (
  (
    exists (
      select 1 from public.docentes d
      where d.id = docentes_comunidades.docente_id
        and d.visible_publicamente is true
    )
    and exists (
      select 1 from public.comunidades c
      where c.id = docentes_comunidades.comunidad_id
        and c.visible_publicamente is true
        and c.estado_convergencia is distinct from 'rechazado'
    )
  )
  or exists (
    select 1 from public.docentes d
    where d.id = docentes_comunidades.docente_id
      and d.auth_user_id = (select auth.uid())
  )
  or (select public.es_capitan())
);

grant select on public.docentes_publicos,
  public.comunidades_publicas,
  public.docentes_comunidades_publicas
to anon, authenticated;
