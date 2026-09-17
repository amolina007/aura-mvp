-- Mantiene abierto el registro de experiencias, pero impide que el cliente
-- establezca identidad, temporada, verificación o XP.
-- Esos campos quedan bajo control de trg_puntuar_registro.

revoke insert on table public.registro_experiencia from anon, authenticated;

grant insert (
  fecha,
  tipo_asistencia,
  tipos_asistencia,
  comunidad_id,
  locacion_id,
  clase_id,
  evento_id,
  nivel_clase,
  niveles,
  como_se_sintio,
  necesidades,
  comentarios,
  calif_docencia,
  calif_precio,
  calif_ambiente_social,
  whatsapp,
  instagram,
  anonimo,
  consentimiento_etico
) on table public.registro_experiencia to anon, authenticated;

drop policy if exists "Cualquiera puede enviar un registro"
  on public.registro_experiencia;

create policy "Registro abierto con consentimiento"
  on public.registro_experiencia
  for insert
  to anon, authenticated
  with check (
    consentimiento_etico is true
    and fecha <= current_date
  );
