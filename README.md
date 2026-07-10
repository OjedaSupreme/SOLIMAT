# SOLIMAT

**Solicitud de Material** — aplicación web para gestionar pedidos de material entre **Producción**, **Almacén** y **Administración**.

Diseñada para el flujo operativo de Dana: crear solicitudes, verificar con código PIN, surtir y dar seguimiento al tiempo de atención.

---

## Características

| Módulo | Qué hace |
|--------|----------|
| **Producción** | Crea solicitudes por área y material, genera códigos PIN de 4 dígitos y consulta historial propio |
| **Almacén** | Toma órdenes, verifica el PIN, surte cantidades y actualiza estatus |
| **Administración** | Catálogo BOM, usuarios, respaldos e importación/exportación |

### Flujo de una orden

```text
Producción crea solicitud
        ↓
  Código PIN (4 dígitos)
        ↓
Almacén toma la orden  →  verifica PIN  →  surte material
        ↓
   Entregado + tiempos
```

### Progreso de almacén

1. **Pendiente** — orden nueva, sin atender  
2. **Siendo atendida** — un almacenista tomó la orden  
3. **Entregado** — material surtido / cerrado  

Se registran fechas de **creación**, **aceptación** y **surtido**, más el **tiempo en minutos** desde la creación hasta el surtido.

---

## Stack

- **Frontend:** HTML / CSS / JavaScript (app de una sola página)
- **Backend / BD:** [Supabase](https://supabase.com) (PostgreSQL)
- **Deploy:** compatible con Vercel u otro hosting estático

---

## Estructura del proyecto

```text
DANA_project/
├── index.html                      # App principal (SOLIMAT)
├── config.example.js               # Plantilla de credenciales
├── config.js                       # Credenciales reales (no se sube a git)
├── demo.html                       # Demo / referencia
├── supabase-setup.sql              # Esquema base de tablas
├── supabase-token-migration.sql    # Códigos PIN de verificación
├── supabase-progress-migration.sql # Progreso de órdenes
├── supabase-security.sql           # Seguridad / RLS
├── supabase-auth-jwt.sql           # Auth JWT (si aplica)
└── supabase-fix-rls-public.sql   # Ajuste de políticas RLS
```

---

## Puesta en marcha

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU-USUARIO/DANA_project.git
cd DANA_project
```

### 2. Configurar Supabase

1. Crea un proyecto en [Supabase](https://supabase.com).
2. Abre **SQL Editor** y ejecuta, en este orden:
   - `supabase-setup.sql`
   - `supabase-token-migration.sql`
   - `supabase-progress-migration.sql`
   - `supabase-security.sql` (y los scripts de RLS/auth según tu entorno)
3. Copia las credenciales desde **Project Settings → API**.

### 3. Credenciales locales

```bash
cp config.example.js config.js
```

Edita `config.js`:

```js
window.SUPABASE_URL = "https://TU-PROYECTO.supabase.co";
window.SUPABASE_ANON_KEY = "tu-anon-key-aqui";
```

> `config.js` está en `.gitignore` para no exponer claves en el repositorio.

### 4. Abrir la app

Sirve la carpeta con cualquier servidor estático, por ejemplo:

```bash
npx serve .
```

O despliega en Vercel / Netlify y asegúrate de que `config.js` exista en el entorno de producción (variable de build o archivo privado).

---

## Roles de usuario

| Rol | Acceso |
|-----|--------|
| `produccion` | Crear solicitudes y ver códigos / historial propio |
| `almacen` | Tomar órdenes, verificar PIN y surtir |
| `admin` | Catálogo, usuarios y respaldos |
| `todos` | Acceso a todos los módulos |

Los usuarios se administran desde el módulo **Administrador**.

---

## Scripts SQL

| Archivo | Propósito |
|---------|-----------|
| `supabase-setup.sql` | Tablas: solicitudes, detalles, catálogo, usuarios, meta |
| `supabase-token-migration.sql` | Token / hash de verificación por folio |
| `supabase-progress-migration.sql` | Columnas `progreso`, `progreso_por`, `progreso_en` |
| `supabase-security.sql` | Políticas de seguridad |
| `supabase-auth-jwt.sql` | Soporte JWT |
| `supabase-fix-rls-public.sql` | Corrección / ajuste de RLS público |

---

## Seguridad

- Las contraseñas y tokens se manejan con hash (SHA-256) en el cliente / flujo de la app.
- No subas `config.js` ni archivos `.env` al repositorio.
- Revisa las políticas RLS de Supabase antes de exponer la app en producción.

---

## Notas

- La app es **client-side**: el navegador habla directo con Supabase.
- Los datos viven en el servidor; no se usa almacenamiento local como fuente de verdad.
- El archivo `DANA Solicitud de material (4).html` es una versión legacy / referencia y no es la app activa.

---

## Licencia / uso

Proyecto interno Dana — uso operativo para solicitud y surtido de material (**SOLIMAT**).
