<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <h2 class="text-2xl font-bold text-gray-800 mb-6">Centro de Sincronización</h2>

    <div class="grid md:grid-cols-2 gap-6 mb-8">
      <div class="bg-white rounded-xl shadow p-6">
        <h3 class="font-semibold text-gray-700 mb-4">Estado de Conexión</h3>
        <div class="space-y-3">
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Red</span>
            <span :class="isOnline ? 'text-green-600' : 'text-red-600'">
              {{ isOnline ? 'Conectado' : 'Desconectado' }}
            </span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">API Reachable</span>
            <span :class="apiReachable ? 'text-green-600' : 'text-yellow-600'">
              {{ apiReachable ? 'Disponible' : 'No disponible' }}
            </span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Eventos Pendientes</span>
            <span class="font-medium">{{ pendingEvents }}</span>
          </div>
          <div class="flex justify-between text-sm">
            <span class="text-gray-500">Última Sync</span>
            <span class="text-gray-600">{{ lastSync || 'Nunca' }}</span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl shadow p-6">
        <h3 class="font-semibold text-gray-700 mb-4">Acciones</h3>
        <div class="space-y-3">
          <button @click="forceSync" :disabled="syncing || !isOnline"
            class="w-full bg-emerald-600 text-white py-2 rounded-lg hover:bg-emerald-700 disabled:opacity-50">
            {{ syncing ? 'Sincronizando...' : 'Forzar Sincronización' }}
          </button>
          <button @click="clearOfflineData"
            class="w-full border-2 border-red-300 text-red-600 py-2 rounded-lg hover:bg-red-50">
            Limpiar Datos Offline
          </button>
          <button @click="downloadContent"
            class="w-full bg-blue-600 text-white py-2 rounded-lg hover:bg-blue-700">
            Descargar Contenidos Offline
          </button>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow p-6">
      <h3 class="font-semibold text-gray-700 mb-4">Últimos Eventos de Sincronización</h3>
      <div v-if="events.length === 0" class="text-center py-8 text-gray-500">
        No hay eventos de sincronización recientes.
      </div>
      <div v-else class="space-y-2">
        <div v-for="event in events" :key="event.id"
          class="flex items-center justify-between text-sm p-2 bg-gray-50 rounded">
          <div>
            <span class="font-medium">{{ event.entity_type }}</span>
            <span class="text-gray-500 ml-2">{{ event.operation }}</span>
          </div>
          <span :class="event.is_synced ? 'text-green-600' : 'text-yellow-600'">
            {{ event.is_synced ? 'Sincronizado' : 'Pendiente' }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api, { clearCache } from '../services/api'
import { syncEngine } from '../services/sync'
import { offlineManager } from '../services/offline'

const isOnline = ref(navigator.onLine)
const apiReachable = ref(false)
const pendingEvents = ref(0)
const lastSync = ref(null)
const syncing = ref(false)
const events = ref([])

const checkStatus = async () => {
  isOnline.value = navigator.onLine
  pendingEvents.value = syncEngine.getQueueLength()
  lastSync.value = syncEngine.getLastSyncAt()

  try {
    const res = await fetch('/api/health', { cache: 'no-store' })
    apiReachable.value = res.ok
  } catch {
    apiReachable.value = false
  }
}

onMounted(async () => {
  checkStatus()
  setInterval(checkStatus, 5000)

  try {
    const response = await api.get('/sync/events')
    if (response.data?.success) {
      events.value = response.data.data?.events || response.data.data || []
    }
  } catch {
    events.value = []
  }
})

const forceSync = async () => {
  syncing.value = true
  await syncEngine.triggerSync()
  syncing.value = false
  checkStatus()
}

const clearOfflineData = async () => {
  if (confirm('¿Estás seguro de limpiar todos los datos offline?')) {
    await clearCache()
    events.value = []
    checkStatus()
  }
}

const downloadContent = async () => {
  if ('caches' in window) {
    const cache = await caches.open('educonnect-content-v1')
    const urls = ['/api/content?offline=true&limit=50']
    await cache.addAll(urls)
    alert('Contenidos descargados para uso offline')
  }
}
</script>
