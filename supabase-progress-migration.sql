-- SOLIMAT — Progreso de atencion por folio (almacenista)
-- Ejecutar en Supabase → SQL Editor

alter table solicitudes
  add column if not exists progreso text not null default 'pendiente',
  add column if not exists progreso_por text not null default '',
  add column if not exists progreso_en text not null default '';

alter table solicitudes drop constraint if exists solicitudes_progreso_check;
alter table solicitudes add constraint solicitudes_progreso_check
  check (progreso in ('pendiente', 'siendo_atendida', 'entregado'));
