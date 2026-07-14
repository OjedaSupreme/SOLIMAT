-- ============================================================
-- SOLIMAT — Fix helpers RLS (si has_rol falla al guardar)
-- Ejecutar en SQL Editor si produccion/almacen no pueden insertar
-- ============================================================

create or replace function public.current_user_rol()
returns text
language sql
stable
security definer
set search_path = public
as $$
  select coalesce(
    (select rol from public.usuarios where auth_id = auth.uid() and activo = true limit 1),
    ''
  );
$$;

create or replace function public.is_authenticated()
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select auth.uid() is not null;
$$;

create or replace function public.has_rol(roles text[])
returns boolean
language sql
stable
security definer
set search_path = public
as $$
  select public.current_user_rol() = any (roles);
$$;

create or replace function public.current_user_profile()
returns json
language plpgsql
stable
security definer
set search_path = public
as $$
declare
  rec public.usuarios%rowtype;
begin
  if auth.uid() is null then
    return null;
  end if;

  select * into rec
    from public.usuarios
   where auth_id = auth.uid()
     and activo = true
   limit 1;

  if not found then
    return null;
  end if;

  return json_build_object(
    'id', rec.id,
    'name', rec.nombre,
    'user', rec.usuario,
    'role', rec.rol,
    'auth_id', rec.auth_id
  );
end;
$$;

revoke all on function public.current_user_rol() from public;
revoke all on function public.is_authenticated() from public;
revoke all on function public.has_rol(text[]) from public;
revoke all on function public.current_user_profile() from public;

grant execute on function public.current_user_rol() to authenticated;
grant execute on function public.is_authenticated() to authenticated;
grant execute on function public.has_rol(text[]) to authenticated;
grant execute on function public.current_user_profile() to authenticated;

-- Diagnostico (ejecutar estando autenticado desde la app es distinto;
-- desde SQL Editor auth.uid() suele ser null). Revisar vinculos:
select usuario, rol, auth_id, activo
from public.usuarios
where activo = true
order by usuario;
