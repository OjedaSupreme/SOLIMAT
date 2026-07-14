-- ============================================================
-- SOLIMAT — Auth JWT PREPARE (paso 1)
-- Ejecutar en Supabase → SQL Editor
-- ============================================================
--
-- Este script SOLO prepara la BD:
--   - columna auth_id
--   - helpers RLS (current_user_rol, is_authenticated, has_rol)
--   - contrasena nullable (la clave vive en Auth)
--   - policy para leer el propio perfil
--
-- NO elimina las policies publicas. Eso se hace al final con:
--   supabase-auth-activate-rls.sql
--
-- Orden recomendado:
--   1) este archivo
--   2) crear usuarios en Authentication → Users
--   3) vincular con supabase-auth-bootstrap.sql
--   4) probar login en la app
--   5) supabase-auth-activate-rls.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1. Vincular tabla usuarios con auth.users
-- ------------------------------------------------------------
alter table usuarios
  add column if not exists auth_id uuid unique references auth.users (id) on delete set null;

create index if not exists idx_usuarios_auth_id on usuarios (auth_id);

-- Email interno por login: {usuario}@solimat.internal
-- Ejemplo: juan.perez → juan.perez@solimat.internal

-- ------------------------------------------------------------
-- 2. Contrasena nullable (Auth es la fuente de verdad)
-- ------------------------------------------------------------
alter table usuarios alter column contrasena drop not null;

comment on column usuarios.contrasena is
  'Legacy. Tras Auth JWT la clave vive en auth.users; puede ser null.';

-- ------------------------------------------------------------
-- 3. Funciones helper para RLS
-- ------------------------------------------------------------
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
  rec usuarios%rowtype;
begin
  if auth.uid() is null then
    return null;
  end if;

  select * into rec
    from usuarios
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

grant execute on function public.current_user_rol() to anon, authenticated;
grant execute on function public.is_authenticated() to anon, authenticated;
grant execute on function public.has_rol(text[]) to anon, authenticated;
grant execute on function public.current_user_profile() to authenticated;

-- ------------------------------------------------------------
-- 4. Leer el propio perfil (necesario para mapear rol tras login)
--    Compatible con policies publicas mientras no se active RLS final.
-- ------------------------------------------------------------
drop policy if exists "usuarios_select_own" on usuarios;
create policy "usuarios_select_own"
  on usuarios for select
  using (auth_id = auth.uid());

-- Vista de perfiles sin contrasena (uso admin / reportes)
create or replace view usuarios_perfil as
  select id, nombre, usuario, rol, activo, auth_id, created_at, updated_at
  from usuarios;

grant select on usuarios_perfil to authenticated;
