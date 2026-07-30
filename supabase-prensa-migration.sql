-- ------------------------------------------------------------
-- SOLIMAT — Migracion: prensa por linea de solicitud
-- Ejecutar en Supabase SQL Editor (proyectos ya existentes).
-- ------------------------------------------------------------

alter table solicitud_detalles
  add column if not exists prensa text not null default '';

create index if not exists idx_detalles_prensa on solicitud_detalles (prensa);
