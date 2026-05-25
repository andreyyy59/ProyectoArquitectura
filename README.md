# EduConnect Rural

Plataforma de aprendizaje adaptativo diseñada para operar en zonas con baja conectividad mediante un paradigma de **Edge Computing**.

## Arquitectura de Microservicios

| Servicio | Puerto | Base de Datos | Descripción |
|----------|--------|---------------|-------------|
| **MS-01** User Management | 8000 (`api/auth`, `api/users`) | `educonnect_users` | Autenticación SSO JWT, roles, perfiles, tokens offline |
| **MS-02** Edge Node Manager | 8000 (`api/edge-nodes`) | `educonnect_users` | Topología de red, heartbeats, ventanas de sincronización |
| **MS-03** Content Management | 8000 (`api/content`) | `educonnect_content` | Contenidos educativos, versionado, distribución incremental |
| **MS-04** Offline Sync Engine | 8000 (`api/sync`) | `educonnect_sync` | Protocolo de 5 fases, colas Redis, resolución LWW |
| **MS-05** Adaptive Engine | 8000 (`api/adaptive`) | `educonnect_users` | Rutas de aprendizaje personalizadas |
| **MS-06** AI Recommendations | 8000 (`/predict`, `/recommend`) | Redis | TensorFlow Lite, inferencia local offline |
| **MS-07** Learning Analytics | 8000 (`api/analytics`) | `educonnect_analytics` | Eventos xAPI, métricas de progreso |
| **MS-08** Connectivity Monitor | 8001 (`api/connectivity`) | Redis | Heartbeat en tiempo real, circuit breaker |
| **MS-09** Territorial Reports | 8000 (`api/reports`) | `educonnect_reports` | Dashboards geográficos y reportes regionales |
| **MS-10** Notifications | 8000 (`api/notifications`) | Redis + Cache | Notificaciones push, alertas offline |
| **Frontend** PWA | 3000 | IndexedDB | Vue 3 + Inertia, Service Workers, offline-first |

## Protocolo de Sincronización (5 Fases)

1. **DETECTION** → Escaneo de red y medición de latencia/ancho de banda
2. **HANDSHAKE** → Intercambio de manifiestos entre Edge Node y Cloud
3. **DELTA_DOWNLOAD** → Descarga incremental de cambios
4. **DELTA_UPLOAD** → Subida de cambios locales pendientes
5. **CONFLICT_RESOLUTION** → Estrategia Last-Write-Wins (LWW)

## Requisitos

- Docker y Docker Compose
- PHP 8.3+ (desarrollo local)
- Composer 2.x (desarrollo local)
- Node.js 20+ (frontend)

## Inicio Rápido

```bash
# 1. Clonar el repositorio
git clone <repo-url> educonnect-rural
cd educonnect-rural

# 2. Configurar e iniciar
cp .env.example .env
docker compose up -d

# 3. Verificar servicios
docker compose ps
```

O usando el script automatizado:

```bash
./scripts/setup.sh
```

## Stack Tecnológico

- **Backend**: Laravel 11 (PHP 8.3), microservicios con Database per Service
- **Base de Datos**: MySQL 8.0 (5 instancias independientes)
- **Frontend**: Vue.js 3 + Inertia.js, PWA con Service Workers
- **Caché/Mensajería**: Redis 7 (colas, caché, pub/sub)
- **IA Local**: Python (FastAPI) + TensorFlow Lite
- **Infraestructura**: Docker Compose, Nginx API Gateway

## Flujo Offline-First

1. Estudiante descarga contenidos con conexión
2. Service Worker cachea recursos en IndexedDB
3. Estudiante estudia sin conexión (progreso guardado localmente)
4. Al recuperar conexión, Sync Engine inicia protocolo de 5 fases
5. Cambios delta se sincronizan bidireccionalmente
6. Conflictos se resuelven con Last-Write-Wins
