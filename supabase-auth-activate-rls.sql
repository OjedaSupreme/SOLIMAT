-- ============================================================
-- SOLIMAT — Auth JWT ACTIVATE RLS (paso final)
-- ============================================================
--
-- PELIGRO: cierra el acceso anonimo a las tablas.
-- Ejecutar SOLO cuando:
--   1) supabase-auth-jwt.sql ya se ejecuto
--   2) todos los usuarios activos tienen auth_id
--   3) el login con Auth en la app ya funciona
--
-- Si algo falla y la planta queda bloqueada, puedes restaurar
-- acceso temporal con: supabase-fix-rls-public.sql
-- ============================================================

-- ------------------------------------------------------------
-- 1. Quitar policies publicas (anon sin login)
-- ------------------------------------------------------------
drop policy if exists "app_meta_public_access" on app_meta;
drop policy if exists "solicitudes_public_access" on solicitudes;
drop policy if exists "detalles_public_access" on solicitud_detalles;
drop policy if exists "catalogo_public_access" on catalogo_bom;
drop policy if exists "usuarios_public_access" on usuarios;

-- Quitar policies JWT previas (idempotente)
drop policy if exists "app_meta_select_auth" on app_meta;
drop policy if exists "app_meta_write_ops" on app_meta;
drop policy if exists "app_meta_admin" on app_meta;
drop policy if exists "solicitudes_select_auth" on solicitudes;
drop policy if exists "solicitudes_insert_prod" on solicitudes;
drop policy if exists "solicitudes_update_alm" on solicitudes;
drop policy if exists "solicitudes_admin" on solicitudes;
drop policy if exists "solicitudes_write_ops" on solicitudes;
drop policy if exists "solicitudes_update_ops" on solicitudes;
drop policy if exists "solicitudes_delete_admin" on solicitudes;
drop policy if exists "detalles_select_auth" on solicitud_detalles;
drop policy if exists "detalles_insert_prod" on solicitud_detalles;
drop policy if exists "detalles_update_alm" on solicitud_detalles;
drop policy if exists "detalles_admin" on solicitud_detalles;
drop policy if exists "detalles_write_ops" on solicitud_detalles;
drop policy if exists "detalles_update_ops" on solicitud_detalles;
drop policy if exists "detalles_delete_admin" on solicitud_detalles;
drop policy if exists "catalogo_select_auth" on catalogo_bom;
drop policy if exists "catalogo_admin_write" on catalogo_bom;
drop policy if exists "usuarios_select_own" on usuarios;
drop policy if exists "usuarios_admin" on usuarios;

-- Asegurar RLS habilitado
alter table app_meta enable row level security;
alter table solicitudes enable row level security;
alter table solicitud_detalles enable row level security;
alter table catalogo_bom enable row level security;
alter table usuarios enable row level security;

-- ------------------------------------------------------------
-- 2. Policies con JWT (rol en tabla usuarios)
-- ------------------------------------------------------------

-- app_meta: lectura y upsert de folio para roles operativos
create policy "app_meta_select_auth"
  on app_meta for select
  using (is_authenticated());

create policy "app_meta_write_ops"
  on app_meta for all
  using (has_rol(array['produccion', 'almacen', 'admin', 'todos']))
  with check (has_rol(array['produccion', 'almacen', 'admin', 'todos']));

-- solicitudes: leer autenticados; escribir roles operativos
-- (la app usa upsert en sync: requiere INSERT+UPDATE para prod y almacen)
create policy "solicitudes_select_auth"
  on solicitudes for select
  using (is_authenticated());

create policy "solicitudes_write_ops"
  on solicitudes for insert
  with check (has_rol(array['produccion', 'almacen', 'admin', 'todos']));

create policy "solicitudes_update_ops"
  on solicitudes for update
  using (has_rol(array['produccion', 'almacen', 'admin', 'todos']))
  with check (has_rol(array['produccion', 'almacen', 'admin', 'todos']));

create policy "solicitudes_delete_admin"
  on solicitudes for delete
  using (has_rol(array['admin', 'todos']));

-- detalles: mismas reglas que solicitudes
create policy "detalles_select_auth"
  on solicitud_detalles for select
  using (is_authenticated());

create policy "detalles_write_ops"
  on solicitud_detalles for insert
  with check (has_rol(array['produccion', 'almacen', 'admin', 'todos']));

create policy "detalles_update_ops"
  on solicitud_detalles for update
  using (has_rol(array['produccion', 'almacen', 'admin', 'todos']))
  with check (has_rol(array['produccion', 'almacen', 'admin', 'todos']));

create policy "detalles_delete_admin"
  on solicitud_detalles for delete
  using (has_rol(array['admin', 'todos']));

-- catalogo: leer autenticados; escribir admin
create policy "catalogo_select_auth"
  on catalogo_bom for select
  using (is_authenticated());

create policy "catalogo_admin_write"
  on catalogo_bom for all
  using (has_rol(array['admin', 'todos']))
  with check (has_rol(array['admin', 'todos']));

-- usuarios: propio perfil + admin gestiona
create policy "usuarios_select_own"
  on usuarios for select
  using (auth_id = auth.uid());

create policy "usuarios_admin"
  on usuarios for all
  using (has_rol(array['admin', 'todos']))
  with check (has_rol(array['admin', 'todos']));

-- ------------------------------------------------------------
-- 3. Desactivar login RPC legacy (anon ya no autentica por hash)
-- ------------------------------------------------------------
revoke execute on function verify_user_login(text, text) from anon;
revoke execute on function verify_user_login(text, text) from authenticated;
revoke execute on function verify_user_login(text, text) from public;

-- Mantener helpers disponibles
grant execute on function public.current_user_rol() to authenticated;
grant execute on function public.is_authenticated() to authenticated;
grant execute on function public.has_rol(text[]) to authenticated;
grant execute on function public.current_user_profile() to authenticated;
