-- Fotografías de aportes: solo cuentas autenticadas, cada una en su carpeta.
-- El bucket sigue siendo público para mostrar imágenes incorporadas a aportes
-- aprobados; la escritura queda restringida por propietario lógico.

update storage.buckets
set file_size_limit = 3145728,
    allowed_mime_types = array['image/jpeg','image/png','image/webp']::text[]
where id = 'aportes-fotos';

drop policy if exists "aportes_fotos_subir" on storage.objects;
drop policy if exists "aportes_fotos_subir_autenticado" on storage.objects;
drop policy if exists "aportes_fotos_eliminar_propias" on storage.objects;

create policy "aportes_fotos_subir_autenticado"
on storage.objects
for insert
to authenticated
with check (
  bucket_id = 'aportes-fotos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);

create policy "aportes_fotos_eliminar_propias"
on storage.objects
for delete
to authenticated
using (
  bucket_id = 'aportes-fotos'
  and (storage.foldername(name))[1] = (select auth.uid())::text
);
