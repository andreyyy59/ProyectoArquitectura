<template>
  <div class="max-w-6xl mx-auto px-4 py-8">
    <div class="flex items-center justify-between mb-8">
      <div>
        <h2 class="text-2xl font-bold text-gray-800">Bienvenido, {{ user?.full_name }}</h2>
        <p class="text-gray-500">{{ user?.role?.name }}</p>
      </div>
      <router-link to="/sync"
        class="bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-emerald-700">
        Centro de Sincronización
      </router-link>
    </div>

    <div class="grid md:grid-cols-4 gap-4 mb-8">
      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500 text-sm">Rutas Activas</p>
        <p class="text-2xl font-bold text-emerald-700">{{ stats.activePaths }}</p>
      </div>
      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500 text-sm">Progreso General</p>
        <p class="text-2xl font-bold text-blue-700">{{ stats.overallProgress }}%</p>
      </div>
      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500 text-sm">Contenidos Offline</p>
        <p class="text-2xl font-bold text-yellow-700">{{ stats.offlineContent }}</p>
      </div>
      <div class="bg-white rounded-lg shadow p-4">
        <p class="text-gray-500 text-sm">Pendientes Sync</p>
        <p class="text-2xl font-bold text-red-700">{{ stats.pendingSync }}</p>
      </div>
    </div>

    <div class="mb-8">
      <h3 class="text-lg font-semibold text-gray-800 mb-4">Tus Rutas de Aprendizaje</h3>
      <div v-if="learningPaths.length === 0" class="bg-gray-50 rounded-lg p-8 text-center text-gray-500">
        Aún no tienes rutas de aprendizaje. El motor adaptativo generará una para ti.
      </div>
      <div v-else class="grid md:grid-cols-2 gap-4">
        <div v-for="path in learningPaths" :key="path.uuid"
          class="bg-white rounded-lg shadow p-4 hover:shadow-md transition">
          <div class="flex items-center justify-between mb-2">
            <h4 class="font-semibold text-gray-800">{{ path.subject_area || 'Ruta General' }}</h4>
            <span class="text-xs px-2 py-1 rounded-full" :class="path.status === 'ACTIVE' ? 'bg-green-100 text-green-700' : 'bg-gray-100 text-gray-600'">
              {{ path.status }}
            </span>
          </div>
          <div class="w-full bg-gray-200 rounded-full h-2 mb-2">
            <div class="bg-emerald-600 h-2 rounded-full" :style="{ width: `${path.progress_percent}%` }"></div>
          </div>
          <div class="flex justify-between text-sm text-gray-500">
            <span>{{ path.progress_percent.toFixed(1) }}% completado</span>
            <router-link :to="`/learning/${path.uuid}`" class="text-emerald-600 hover:underline">Continuar</router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import api from '../services/api'
import { syncEngine } from '../services/sync'
import { offlineManager } from '../services/offline'

const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const learningPaths = ref([])
const stats = ref({
  activePaths: 0,
  overallProgress: 0,
  offlineContent: 0,
  pendingSync: 0,
})

onMounted(async () => {
  stats.value.pendingSync = syncEngine.getQueueLength()

  try {
    const response = await api.get('/adaptive/learning-path/list')
    if (response.data?.success) {
      learningPaths.value = response.data.data
    }
  } catch {
    const cached = await offlineManager.getCachedContents()
    stats.value.offlineContent = Array.isArray(cached) ? cached.length : 0
  }
})
</script>
