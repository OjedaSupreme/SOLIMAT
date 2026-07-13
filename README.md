# SOLIMAT

**Solicitud de Material** — aplicación web para gestionar pedidos de material entre **Producción**, **Almacén** y **Administración**.

Diseñada para el flujo operativo de una empresa automotriz: crear solicitudes, verificar con código PIN, surtir y dar seguimiento al tiempo de atención.

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
- **Backend / BD:** [Supabase](https://supabase.com) (PostgreSQL + Auth JWT)
- **Deploy:** compatible con Vercel u otro hosting estático

---

## Estructura del proyecto

```text
DANA_project/
├── index.html                         # App principal (SOLIMAT)
├── config.example.js                  # Plantilla de credenciales
├── config.js                          # Credenciales reales (no se sube a git)
├── demo.html                          # Demo / referencia
├── supabase-setup.sql                 # Esquema base de tablas
├── supabase-token-migration.sql       # Códigos PIN de verificación
├── supabase-progress-migration.sql    # Progreso de órdenes
├── supabase-security.sql              # Login RPC legacy + hash (histórico)
├── supabase-auth-jwt.sql              # Auth: auth_id + helpers (PREPARE)
├── supabase-auth-bootstrap.sql        # Vincular Auth ↔ usuarios
├── supabase-auth-activate-rls.sql     # Cerrar RLS anónimo (FINAL)
└── supabase-fix-rls-public.sql        # Rollback temporal de RLS público
```

---

## Puesta en marcha

### 1. Clonar el repositorio

```bash
git clone https://github.com/TU-USUARIO/DANA_project.git
cd DANA_project
```

### 2. Configurar Supabase (esquema base)

1. Crea un proyecto en [Supabase](https://supabase.com).
2. Abre **SQL Editor** y ejecuta, en este orden:
   - `supabase-setup.sql`
   - `supabase-token-migration.sql`
   - `supabase-progress-migration.sql`
   - `supabase-security.sql` (opcional / legacy)
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

### 4. Migración Auth JWT + RLS (obligatorio para producción)

**No ejecutes el cierre de RLS hasta probar el login.** Orden exacto:

#### Paso A — Preparar BD

Ejecuta `supabase-auth-jwt.sql` (columna `auth_id`, helpers, `contrasena` nullable).

#### Paso B — Configurar Authentication

En el Dashboard de Supabase:

1. **Authentication → Providers:** Email habilitado.
2. **Authentication → Settings:** desactiva **Confirm email** (app interna), o confirma manualmente cada usuario.
3. **Authentication → Users → Add user** para cada persona:
   - **Email:** `{usuario}@solimat.internal`  
     Ejemplo: login `juan.perez` → `juan.perez@solimat.internal`
   - **Password:** la que usará en la app
   - Auto Confirm: sí

#### Paso C — Vincular perfiles

1. En la tabla `usuarios` debe existir el perfil (nombre, usuario, rol).
2. Copia el UUID de **Authentication → Users**.
3. Usa los ejemplos de `supabase-auth-bootstrap.sql` para asignar `auth_id`.

Verificación:

```sql
select usuario, rol, auth_id is not null as vinculado
from usuarios
where activo = true
order by usuario;
```

Todos los activos deben tener `vinculado = true`.

#### Paso D — Probar la app (aún con RLS público)

```bash
npx serve .
```

1. Abre la app e inicia sesión con el **usuario** (sin escribir el email completo) y la contraseña de Auth.
2. Confirma que Producción / Almacén / Admin abren según el rol.
3. Confirma que puedes crear o surtir una solicitud de prueba.

#### Paso E — Activar RLS (cierra acceso anónimo)

Solo cuando el paso D funcione:

1. Ejecuta `supabase-auth-activate-rls.sql`.
2. Prueba de nuevo el login y las operaciones.
3. Comprueba que **sin sesión** ya no se pueden leer tablas (PostgREST debe denegar).

Si la planta queda bloqueada, puedes restaurar acceso temporal con `supabase-fix-rls-public.sql` y revisar vínculos `auth_id`.

### 5. Abrir / desplegar

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

Hay **una sesión Auth (JWT) por navegador**. Los módulos se desbloquean según el rol del perfil vinculado.

Los perfiles se administran desde el módulo **Administrador**. La **contraseña** se crea o cambia en **Supabase → Authentication → Users**. Tras crear un perfil en la app, vincula `auth_id` (ver bootstrap).

---

## Scripts SQL

| Archivo | Propósito |
|---------|-----------|
| `supabase-setup.sql` | Tablas: solicitudes, detalles, catálogo, usuarios, meta |
| `supabase-token-migration.sql` | Token / hash de verificación por folio |
| `supabase-progress-migration.sql` | Columnas `progreso`, `progreso_por`, `progreso_en` |
| `supabase-security.sql` | Login RPC legacy (histórico) |
| `supabase-auth-jwt.sql` | **PREPARE:** `auth_id`, helpers RLS, perfil propio |
| `supabase-auth-bootstrap.sql` | Ejemplos para vincular Auth ↔ `usuarios` |
| `supabase-auth-activate-rls.sql` | **FINAL:** policies JWT y revoca RPC anónimo |
| `supabase-fix-rls-public.sql` | Rollback temporal a policies públicas |

---

## Seguridad

- Login con **Supabase Auth** (JWT). La app ya no autentica con el RPC público `verify_user_login`.
- Tras `supabase-auth-activate-rls.sql`, las tablas solo son accesibles con sesión y rol correcto.
- Email interno de login: `{usuario}@solimat.internal`.
- No subas `config.js` ni archivos `.env` al repositorio.
- No uses la **service role key** en el frontend.

---

## Notas

- La app es **client-side**: el navegador habla directo con Supabase (con JWT tras login).
- Los datos viven en el servidor; no se usa almacenamiento local como fuente de verdad.
- El archivo `DANA Solicitud de material (4).html` es una versión legacy / referencia y no es la app activa.

---

## Licencia / uso

Proyecto interno Dana — uso operativo para solicitud y surtido de material (**SOLIMAT**).
