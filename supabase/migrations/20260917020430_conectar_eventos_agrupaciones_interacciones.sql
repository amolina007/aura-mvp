-- Conecta cada evento con la agrupación que lo organiza o promociona.
-- También permite interacción autenticada antes y después de la fecha del evento.

alter table public.eventos
  add column if not exists comunidad_id uuid;

do $$
begin
  if not exists (
    select 1 from pg_constraint
    where conrelid = 'public.eventos'::regclass
      and conname = 'eventos_comunidad_id_fkey'
  ) then
    alter table public.eventos
      add constraint eventos_comunidad_id_fkey
      foreign key (comunidad_id) references public.comunidades(id)
      on delete set null;
  end if;
end $$;

create index if not exists eventos_comunidad_id_idx
  on public.eventos(comunidad_id);

update public.eventos e
set comunidad_id = c.id
from public.comunidades c
where e.comunidad_id is null
  and (
    (e.nombre = 'Social La Unión' and c.nombre = 'La Unión')
    or
    (e.nombre = 'Social Rumba Maipú (RDC)' and c.nombre = 'Rumba Maipú')
  );

create or replace function public.fn_alternar_like_evento(p_evento_id uuid)
returns boolean
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_pasaporte_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Se requiere sesión iniciada';
  end if;

  select id into v_pasaporte_id
  from public.pasaportes
  where auth_user_id = auth.uid();

  if v_pasaporte_id is null then
    raise exception 'Necesitas tener un Pasaporte Aura para dar like';
  end if;

  if not exists (select 1 from public.eventos where id = p_evento_id) then
    raise exception 'Evento no encontrado';
  end if;

  if exists (
    select 1 from public.likes_evento
    where evento_id = p_evento_id and pasaporte_id = v_pasaporte_id
  ) then
    delete from public.likes_evento
    where evento_id = p_evento_id and pasaporte_id = v_pasaporte_id;
    return false;
  end if;

  insert into public.likes_evento(evento_id, pasaporte_id)
  values (p_evento_id, v_pasaporte_id);
  return true;
end;
$function$;

create or replace function public.fn_comentar_evento(p_evento_id uuid, p_comentario text)
returns uuid
language plpgsql
security definer
set search_path = public, pg_temp
as $function$
declare
  v_pasaporte record;
  v_id uuid;
begin
  if auth.uid() is null then
    raise exception 'Se requiere sesión iniciada';
  end if;

  select id, alias_publico into v_pasaporte
  from public.pasaportes
  where auth_user_id = auth.uid();

  if v_pasaporte.id is null then
    raise exception 'Necesitas tener un Pasaporte Aura para comentar';
  end if;

  if not exists (select 1 from public.eventos where id = p_evento_id) then
    raise exception 'Evento no encontrado';
  end if;

  if p_comentario is null or char_length(trim(p_comentario)) = 0 then
    raise exception 'El comentario no puede estar vacío';
  end if;
  if char_length(p_comentario) > 280 then
    raise exception 'El comentario no puede superar los 280 caracteres';
  end if;
  if public.fn_contiene_lenguaje_ofensivo(p_comentario) then
    raise exception 'Tu comentario contiene lenguaje que no podemos publicar. Por favor revísalo e inténtalo de nuevo.';
  end if;

  insert into public.comentarios_evento(evento_id, pasaporte_id, comentario, autor_alias)
  values (p_evento_id, v_pasaporte.id, trim(p_comentario), coalesce(v_pasaporte.alias_publico,'Sin alias'))
  returning id into v_id;

  return v_id;
end;
$function$;

revoke all on function public.fn_alternar_like_evento(uuid) from public, anon;
revoke all on function public.fn_comentar_evento(uuid,text) from public, anon;
grant execute on function public.fn_alternar_like_evento(uuid) to authenticated;
grant execute on function public.fn_comentar_evento(uuid,text) to authenticated;

comment on column public.eventos.comunidad_id is
  'Agrupación que organiza o promociona el evento, cuando existe.';
comment on function public.fn_alternar_like_evento(uuid) is
  'Permite a un usuario autenticado con Pasaporte marcar o desmarcar interés en cualquier evento publicado.';
comment on function public.fn_comentar_evento(uuid,text) is
  'Permite a un usuario autenticado con Pasaporte comentar antes o después de un evento.';
