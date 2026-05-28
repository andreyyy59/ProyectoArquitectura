# EduConnect Rural — Documentación de Arquitectura

## Visión General

Plataforma de aprendizaje adaptativo **offline-first** diseñada para zonas rurales con baja conectividad.  
Arquitectura de **10 microservicios** (9 Laravel 11 + 1 Python FastAPI) + frontend **Vue 3 PWA**, orquestados con Docker Compose (20 contenedores).

---

## Diagrama de Arquitectura

```
Navegador (Vue 3 PWA)              :3000
       │
       ▼
┌──────────────────────────────────────────────────────────┐
│                  NGINX API Gateway (:80)                   │
│                                                            │
│  /api/auth/*              → ms-01-user:8000               │
│  /api/users/*             → ms-01-user:8000               │
│  /api/edge-nodes/*        → ms-02-edge-node:8000          │
│  /api/content/*           → ms-03-content:8000            │
│  /api/sync/*              → ms-04-sync:8000   (120s)     │
│  /api/adaptive/*          → ms-05-adaptive:8000           │
│  /predict, /recommend     → ms-06-ai:8000                 │
│  /api/analytics/*         → ms-07-analytics:8000          │
│  /api/connectivity/*      → ms-08-connectivity:8001       │
│  /api/reports/*           → ms-09-reports:8000            │
│  /api/notifications/*     → ms-10-notifications:8000      │
│  /ws/*                    → ms-08 (WebSocket upgrade)     │
│  /                        → frontend:80                   │
└──────────────────────────────────────────────────────────┘
       │
       ├── MySQL 8.0 (5 instancias)
       │   ├── 3307: educonnect_users   ← ms-01, ms-02, ms-05, ms-10
       │   ├── 3308: educonnect_content ← ms-03
       │   ├── 3309: educonnect_sync    ← ms-04
       │   ├── 3310: educonnect_analytics ← ms-07
       │   └── 3311: educonnect_reports ← ms-09
       │
       ├── Redis 7 (6379)
       │   └── Caché, colas, pub/sub, sesiones compartidas
       │
       ├── MinIO (9000 S3 API, 9001 Console)
       │   └── Almacenamiento de objetos multimedia (videos, PDFs, imágenes)
       │
       └── MailHog (1025 SMTP, 8025 Web UI)
           └── Captura de correos electrónicos en desarrollo
```

---

## Microservicios

| Servicio | Framework | Base de Datos | Puerto Interno | Rol |
|---|---|---|---|---|
| **ms-01-user** | Laravel 11 | educonnect_users | 8000 | Auth (JWT), usuarios, roles, perfiles, sesiones, tokens offline |
| **ms-02-edge-node** | Laravel 11 | educonnect_users | 8000 | Gestión de nodos periféricos, heartbeats, ventanas de sincronización |
| **ms-03-content** | Laravel 11 | educonnect_content | 8000 | CRUD de contenidos, categorías, distribución a edge nodes, fulltext search |
| **ms-04-sync** | Laravel 11 | educonnect_sync | 8000 | Protocolo de sincronización delta de 5 fases, colas de eventos, resolución de conflictos |
| **ms-05-adaptive** | Laravel 11 | educonnect_users | 8000 | Motor adaptativo: rutas de aprendizaje, progreso, competencias |
| **ms-06-ai** | FastAPI (Python) | Redis | 8000 | IA predictiva: recomendaciones de contenido, predicción de desempeño |
| **ms-07-analytics** | Laravel 11 | educonnect_analytics | 8000 | Analíticas de uso, métricas de aprendizaje, dashboards |
| **ms-08-connectivity** | Laravel 11 | Redis | 8001 | Monitoreo de conectividad, WebSockets, estado de red en tiempo real |
| **ms-09-reports** | Laravel 11 | educonnect_reports | 8000 | Reportes exportables (PDF/CSV), estadísticas institucionales |
| **ms-10-notifications** | Laravel 11 | educonnect_users | 8000 | Notificaciones por email, alertas del sistema |

### Infraestructura

| Componente | Imagen | Puerto | Propósito |
|---|---|---|---|
| **api-gateway** | nginx:alpine | 80 → 80 | Proxy inverso, routing de peticiones a microservicios |
| **frontend** | nginx:alpine (multi-stage) | 3000 → 80 | SPA Vue 3 compilada servida por nginx |
| **redis** | redis:7-alpine | 6379 | Caché, colas, pub/sub entre servicios |
| **minio** | minio/minio | 9000, 9001 | Almacenamiento S3-compatible para archivos multimedia |
| **mailhog** | mailhog/mailhog | 1025, 8025 | Servidor SMTP falso para desarrollo |

---

## Frontend (Vue 3 PWA)

### Stack

- **Vue 3** (Composition API + `<script setup>`) como framework
- **Vue Router** con `createWebHistory()` y lazy loading de rutas
- **Vite 5** como bundler con HMR en desarrollo
- **Tailwind CSS 3** con tema extendido (colores `edu-*`, animaciones personalizadas)
- **@lucide/vue** para iconografía SVG
- **vite-plugin-pwa** con Workbox para Service Worker
- **idb-keyval** para almacenamiento IndexedDB (offline)
- Docker multi-stage: Node 20 build → nginx:alpine sirve `dist/`

### Rutas

| Ruta | Nombre | Requiere Auth | Offline | Componente |
|---|---|---|---|---|
| `/` | home | ✗ | ✗ | Home.vue |
| `/login` | login | ✗ | ✗ | Login.vue |
| `/dashboard` | dashboard | ✓ | ✗ | Dashboard.vue |
| `/learning/:pathId` | learning-path | ✓ | ✓ | LearningPath.vue |
| `/content/:uuid` | content | ✓ | ✓ | ContentPlayer.vue |
| `/sync` | sync | ✓ | ✗ | SyncCenter.vue |
| `/offline` | offline | ✗ | ✗ | OfflineMode.vue |
| `/profile` | profile | ✓ | ✗ | Profile.vue |

### Servicios JavaScript

#### api.js — Cliente HTTP Axios

- Base URL: `VITE_API_GATEWAY/api`
- **Request interceptor**: inyecta token JWT `Authorization: Bearer` en cada petición
- **Response interceptor**: cachea respuestas GET exitosas en IndexedDB (`idb-keyval`)
- **Offline fallback**: si una petición GET falla por falta de red, retorna datos cacheados
- Funciones exportadas: `setToken(token)`, `restoreToken()`, `clearCache()`

#### sync.js — SyncEngine

- Mantiene una **cola persistente** de eventos de sincronización en IndexedDB
- `enqueue(entityType, entityId, operation, payload)` → agrega un cambio a la cola
- `triggerSync()` → envía batch de hasta **50 eventos** a `POST /api/sync/events` y limpia los sincronizados
- Sincronización automática cada **30 segundos** cuando hay conexión
- Se activa automáticamente al dispararse el evento `online` del navegador
- Cola limitada a **500 items** máximo

#### offline.js — OfflineManager

- `cacheContent(uuid, data)` / `getCachedContent(uuid)` → contenido offline en IndexedDB
- `saveProgress(userId, contentId, progress)` / `getProgress()` → progreso local persistente
- `queueXapiEvent(event)` / `getPendingXapiEvents()` → cola de eventos xAPI para sync posterior
- `cacheAuthToken(token, user)` / `getCachedAuth()` → autenticación persistente para login offline

#### sw-register.js — Service Worker

- `registerServiceWorker()` → registra `/sw.js` con manejo de actualizaciones
- `checkOnlineStatus()` → verifica conectividad real contra `/api/health`
- `listenConnectivity(callback)` → listener de eventos `online`/`offline`

### Componentes Compartidos

| Componente | Propósito |
|---|---|
| **ConnectivityBadge** | Indicador online/offline con ping animado. 3 estados: Online (verde), Red limitada (amarillo), Sin conexión (rojo). Health check cada 15s. |
| **SyncStatus** | Botón que muestra contador de eventos pendientes. Permite trigger manual de sincronización. 3 estados: sincronizado, N pendientes, sincronizando. |
| **UserMenu** | Dropdown de usuario con avatar iniciales, nombre, enlaces a Dashboard/Perfil/Sync y botón de Cerrar Sesión. Diseño glassmorphism con animación de apertura. |

### Diseño UI/UX

- **Paleta**: emerald como color primario (`edu-50` a `edu-900`)
- **Tipografía**: sistema nativa (Inter/sans-serif vía Tailwind)
- **Iconos**: Lucide SVG en toda la interfaz (reemplazo completo de emojis)
- **Animaciones**:
  - `fade-in` (0.6s) para entrada de páginas
  - `slide-up` (0.5s) para hero sections
  - `scale-in` (0.3s) para modales/dropdowns
  - `pulse-soft` (2s) para indicadores de estado
  - `gradient` (8s) para fondos animados
  - Transición `page` con Vue `<transition>` entre rutas
- **Responsive**: mobile-first con puntos de corte `sm`, `md`, `lg`
- **Estados visuales** para cada componente: loading (spinner), empty (icono + mensaje), error (alerta roja), hover (escala + sombra), active (escala 0.98)

---

## Motor de Sincronización (Sync Protocol — 5 Fases)

Definido en `shared/protocols/SyncProtocol.php` e implementado en **ms-04-sync**:

```
Fase 1:  detectConnectivityWindow()  — Evalúa calidad de red (2G/3G/4G/satélite)
Fase 2:  handshake()                 — Intercambio de manifiestos y checkpoint IDs
Fase 3:  downloadDelta()             — Descarga diferencial de contenidos nuevos/modificados
Fase 4:  uploadChanges()             — Sube cambios locales (progreso, xAPI, respuestas)
Fase 5:  resolveConflicts()          — Resolución de conflictos (Last-Write-Wins o merge)
```

### Sincronización Delta

- Solo se transfieren los cambios desde el último checkpoint
- Cada contenido tiene un `version` (incrementa con cada modificación)
- Los payloads incluyen `payload_hash` (SHA-256) para verificar integridad
- Los eventos tienen `client_timestamp` para resolución de conflictos temporal

---

## Circuit Breaker

Implementación en `shared/protocols/CircuitBreaker.php` con 3 estados:

```
         ┌─────────┐     5 fallos       ┌──────┐
         │ CLOSED  │ ──────────────────► │ OPEN │
         │ (normal) │                    │      │
         └────┬─────┘                    └──┬───┘
              ▲                             │
              │   3 éxitos        30s       │
              │   consecutivos    timeout   │
              │                             ▼
              │                    ┌──────────┐
              └────────────────────│ HALF_OPEN │
                                   │ (prueba)  │
                                   └──────────┘
```

- **CLOSED**: funcionamiento normal. 5 fallos consecutivos → OPEN
- **OPEN**: rechaza todas las llamadas inmediatamente durante 30 segundos
- **HALF_OPEN**: permite 1 llamada de prueba. Si éxito → CLOSED. Si falla → OPEN otra vez

---

## Base de Datos

### educonnect_users (MySQL :3307) — 4 servicios comparten

```
roles
├── id, name (student|teacher|admin|edge_admin), slug, description

users
├── id, uuid, full_name, email, password (bcrypt), role_id (FK)
├── document_id, phone, avatar_url, locale, is_active
├── last_login_at, last_sync_at, deleted_at (soft delete)
└── índices: role_id, is_active, last_sync_at

user_profiles
├── user_id (FK), birth_date, gender
├── municipality, department, institution, grade_level
├── connectivity_type (2G/3G/4G/SATELLITE/FIBER/NONE), device_type

user_sessions        → JWT + refresh_token + device_info + expires_at
offline_tokens       → Tokens offline con hash, expiry, revoked

edge_nodes           → Nodos con ubicación, tipo, recursos, status, heartbeat
node_heartbeats      → Series temporales de salud del nodo
node_sync_windows    → Ventanas de conectividad programadas

learning_paths       → Rutas por usuario con status y progress_percent
learning_path_items  → Items de ruta con status, score, time_spent, attempts
student_progress     → Progreso por usuario+contenido (con client_timestamp para offline)

competencies         → Catálogo de competencias por área
user_competencies    → Nivel de dominio por usuario (0.00-100.00)
```

### educonnect_content (MySQL :3308) — 1 servicio

```
content_categories   → Categorías jerárquicas (parent_id)
contents             → UUID, título, descripción, tipo (VIDEO/PDF/EXERCISE/etc)
                     → dificultad, duración, file_url, file_hash (SHA-256)
                     → storage_path (MinIO), version, is_offline_available
                     → índice FULLTEXT en título+descripción
content_dependencies → Relaciones prerequisito/recomendado/secuela
content_distributions → Estado de distribución a edge nodes (PENDING→COMPLETED)
```

### educonnect_sync (MySQL :3309) — 1 servicio

```
sync_batches      → Sesiones de sync con fase, status, items, bytes
sync_events       → Eventos de cambio con entity_type, operation, payload (JSON)
                  → payload_hash, client_timestamp, conflict_resolution
sync_conflicts    → Conflictos con payloads cliente vs servidor
sync_checkpoints  → Checkpoints por edge_node + entity para reanudar sync
```

### educonnect_analytics (MySQL :3310) — 1 servicio  
### educonnect_reports (MySQL :3311) — 1 servicio

---

## Shared Contracts & Protocols

Archivos PHP en `shared/` que definen contratos e implementaciones usados entre microservicios:

| Archivo | Tipo | Descripción |
|---|---|---|
| `contracts/AdaptiveEngineContract.php` | Interface | `generateLearningPath()`, `evaluateProgress()`, `predictNextActivity()`, `processXapiEvent()` |
| `contracts/CircuitBreakerContract.php` | Interface | `isAvailable()`, `recordSuccess/Failure()`, `getState()`, `attemptReset()` |
| `contracts/SyncProtocolContract.php` | Interface | Las 5 fases del protocolo de sincronización |
| `protocols/CircuitBreaker.php` | Implementation | Threshold 5, timeout 30s, half-open con 3 éxitos para cerrar |
| `protocols/SyncProtocol.php` | Implementation | Manifiesto, delta, LWW conflict resolution |
| `protocols/XapiStatement.php` | Implementation | Builder para statements xAPI (Tin Can API) estándar |

---

## Flujo de Datos (Offline-First)

```
1. Usuario inicia sesión (online o con credenciales cacheadas)
       │
2. Navega por rutas de aprendizaje
       │
       ├── ¿Hay conexión?
       │     ├── Sí → API normal con cache en IndexedDB
       │     └── No → Datos servidos desde IndexedDB
       │
3. Interactúa con contenido (marca progreso)
       │
       ├── Si online → POST a /api/adaptive/progress
       │   └── Si falla → encola en SyncEngine
       │
       └── Si offline → guarda en IndexedDB + encola en SyncEngine
       │
4. Cuando recupera conexión:
       │
       ├── SyncEngine.triggerSync() envía batch POST /api/sync/events
       ├── ms-04-sync procesa fase 4 (upload) y fase 5 (conflictos)
       └── Eventos sincronizados se eliminan de la cola local
```

---

## Variables de Entorno Clave

```
# Base de datos
DB_ROOT_PASSWORD=rootsecret
DB_USERNAME=educonnect
DB_PASSWORD=secret

# JWT
JWT_SECRET=change-me-in-production

# Redis
REDIS_HOST=redis
REDIS_PORT=6379

# MinIO (S3)
MINIO_ROOT_USER=minioadmin
MINIO_ROOT_PASSWORD=minioadmin
S3_ENDPOINT=http://minio:9000
S3_BUCKET=educonnect-content

# Correo
MAIL_HOST=mailhog
MAIL_PORT=1025
MAIL_FROM=noreply@educonnectrural.edu

# IA
AI_MODEL_PATH=/models
AI_SERVICE_URL=http://ms-06-ai:8000

# Sincronización
SYNC_BATCH_SIZE=50
SYNC_HEARTBEAT_INTERVAL=30
CIRCUIT_BREAKER_THRESHOLD=5
CIRCUIT_BREAKER_TIMEOUT=30000
```

---

## Comandos Útiles

```bash
# Iniciar todo el entorno
docker compose up -d

# Reconstruir un servicio específico
docker compose build frontend
docker compose up -d frontend

# Ver logs de un servicio
docker compose logs -f frontend
docker compose logs -f api-gateway
docker compose logs -f ms-04-sync

# Ver todos los contenedores en ejecución
docker compose ps

# Acceder al SQL de una base de datos
docker exec -it educonnect-mysql-user mysql -uroot -prootsecret educonnect_users

# Reset completo (destructivo)
./scripts/reset.sh

# Setup inicial
./scripts/setup.sh
```

---

## Puertos Expuestos al Host

| Puerto | Servicio | Propósito |
|---|---|---|
| **80** | api-gateway | API Gateway (proxy a todos los microservicios) |
| **3000** | frontend | Frontend Vue 3 PWA |
| **6379** | redis | Redis directo (solo diagnóstico) |
| **8000** | ms-06-ai | API de IA predictiva (solo diagnóstico) |
| **8025** | mailhog | Web UI de correos capturados |
| **9000** | minio | S3 API |
| **9001** | minio | Console web MinIO |
| **3307-3311** | mysql-* | Bases de datos MySQL directas (solo diagnóstico) |

---

## Migraciones

Las migraciones están en `database/migrations/` como archivos SQL que se ejecutan automáticamente al iniciar los contenedores MySQL mediante `docker-entrypoint-initdb.d/`:

```
database/migrations/
├── 001_users.sql           → educonnect_users (roles, usuarios, perfiles, sesiones, tokens)
├── 002_edge_nodes.sql      → educonnect_users (edge_nodes, heartbeats, sync_windows)
├── 003_contents.sql        → educonnect_content (categorías, contenidos, dependencias, distribuciones)
├── 004_learning_paths.sql  → educonnect_users (learning_paths, items, progreso, competencias)
└── 005_sync_log.sql        → educonnect_sync (batches, eventos, conflictos, checkpoints)
```
