<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <div class="mb-8">
      <h2 class="text-2xl font-bold text-gray-900">Centro de Sincronización</h2>
      <p class="text-gray-500 text-sm mt-1">Gestiona la sincronización de datos entre el dispositivo y el servidor</p>
    </div>

    <div class="grid md:grid-cols-2 gap-6 mb-8">
      <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <div class="flex items-center gap-2 mb-5">
          <Signal class="w-5 h-5 text-emerald-600" />
          <h3 class="font-semibold text-gray-900">Estado de Conexión</h3>
        </div>
        <div class="space-y-4">
          <div class="flex items-center justify-between py-2 border-b border-gray-50">
            <span class="text-sm text-gray-500">Red</span>
            <span class="inline-flex items-center gap-1.5 text-sm font-medium"
              :class="isOnline ? 'text-green-600' : 'text-red-600'">
              <span class="w-2 h-2 rounded-full" :class="isOnline ? 'bg-green-500' : 'bg-red-500'"></span>
              {{ isOnline ? 'Conectado' : 'Desconectado' }}
            </span>
          </div>
          <div class="flex items-center justify-between py-2 border-b border-gray-50">
            <span class="text-sm text-gray-500">API</span>
            <span class="inline-flex items-center gap-1.5 text-sm font-medium"
              :class="apiReachable ? 'text-green-600' : 'text-yellow-600'">
              <span class="w-2 h-2 rounded-full" :class="apiReachable ? 'bg-green-500' : 'bg-yellow-500'"></span>
              {{ apiReachable ? 'Disponible' : 'No disponible' }}
            </span>
          </div>
          <div class="flex items-center justify-between py-2 border-b border-gray-50">
            <span class="text-sm text-gray-500">Eventos Pendientes</span>
            <span class="text-sm font-semibold text-gray-900">{{ pendingEvents }}</span>
          </div>
          <div class="flex items-center justify-between py-2">
            <span class="text-sm text-gray-500">Última Sync</span>
            <span class="text-sm text-gray-600">{{ lastSync || 'Nunca' }}</span>
          </div>
        </div>
      </div>

      <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
        <div class="flex items-center gap-2 mb-5">
          <Settings class="w-5 h-5 text-emerald-600" />
          <h3 class="font-semibold text-gray-900">Acciones</h3>
        </div>
        <div class="space-y-3">
          <button @click="forceSync" :disabled="syncing || !isOnline"
            class="w-full inline-flex items-center justify-center gap-2 bg-gradient-to-r from-emerald-600 to-emerald-500 text-white py-2.5 rounded-xl font-medium hover:from-emerald-700 hover:to-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
            <Loader v-if="syncing" class="w-4 h-4 animate-spin" />
            <RefreshCw v-else class="w-4 h-4" />
            {{ syncing ? 'Sincronizando...' : 'Forzar Sincronización' }}
          </button>
          <button @click="downloadContent"
            class="w-full inline-flex items-center justify-center gap-2 bg-blue-600 text-white py-2.5 rounded-xl font-medium hover:bg-blue-700 transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
            <Download class="w-4 h-4" />
            Descargar Contenidos Offline
          </button>
          <button @click="clearOfflineData"
            class="w-full inline-flex items-center justify-center gap-2 border-2 border-red-200 text-red-600 py-2.5 rounded-xl font-medium hover:bg-red-50 transition-all active:scale-[0.98]">
            <Trash2 class="w-4 h-4" />
            Limpiar Datos Offline
          </button>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100">
      <div class="flex items-center justify-between mb-5">
        <div class="flex items-center gap-2">
          <History class="w-5 h-5 text-gray-400" />
          <h3 class="font-semibold text-gray-900">Últimos Eventos</h3>
        </div>
        <span class="text-xs text-gray-400">{{ events.length }} eventos</span>
      </div>

      <div v-if="events.length === 0" class="text-center py-10">
        <Inbox class="w-10 h-10 text-gray-300 mx-auto mb-3" />
        <p class="text-gray-500 text-sm">No hay eventos de sincronización recientes</p>
      </div>

      <div v-else class="space-y-2">
        <div v-for="event in events" :key="event.id"
          class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors">
          <div class="flex items-center gap-3">
            <div class="w-8 h-8 rounded-lg bg-white flex items-center justify-center shadow-sm">
              <component :is="event.is_synced ? CheckCircle : Clock" class="w-4 h-4"
                :class="event.is_synced ? 'text-green-500' : 'text-yellow-500'" />
            </div>
            <div>
              <p class="text-sm font-medium text-gray-900">{{ event.entity_type }}</p>
              <p class="text-xs text-gray-400">{{ event.operation }}</p>
            </div>
          </div>
          <span class="text-xs font-medium px-2.5 py-1 rounded-full"
            :class="event.is_synced ? 'bg-green-100 text-green-700' : 'bg-yellow-100 text-yellow-700'">
            {{ event.is_synced ? 'Sincronizado' : 'Pendiente' }}
          </span>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { Signal, Settings, RefreshCw, Download, Trash2, History, Inbox, CheckCircle, Clock, Loader } from '@lucide/vue'
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
