<template>
  <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <div class="flex flex-col sm:flex-row sm:items-center justify-between gap-4 mb-8">
      <div>
        <h2 class="text-2xl sm:text-3xl font-bold text-gray-900">Bienvenido, {{ user?.full_name }}</h2>
        <p class="text-gray-500 mt-1">{{ user?.role?.name }}</p>
      </div>
      <router-link to="/sync"
        class="inline-flex items-center gap-2 bg-emerald-600 text-white px-5 py-2.5 rounded-xl text-sm font-medium hover:bg-emerald-700 transition-all shadow-md hover:shadow-lg active:scale-[0.98]">
        <RefreshCw class="w-4 h-4" />
        Centro de Sincronización
      </router-link>
    </div>

    <div class="grid sm:grid-cols-2 lg:grid-cols-4 gap-4 mb-8">
      <div v-for="(card, i) in statCards" :key="i"
        class="bg-white rounded-xl p-5 shadow-sm border border-gray-100 hover:shadow-md transition-all hover:-translate-y-0.5"
        :style="{ animationDelay: `${i * 0.05}s` }">
        <div class="flex items-center justify-between mb-3">
          <p class="text-sm text-gray-500">{{ card.label }}</p>
          <div class="w-9 h-9 rounded-lg flex items-center justify-center" :class="card.bgClass">
            <component :is="card.icon" class="w-5 h-5" :class="card.iconClass" />
          </div>
        </div>
        <p class="text-2xl font-bold" :class="card.textClass">{{ card.value }}</p>
      </div>
    </div>

    <div class="mb-8">
      <div class="flex items-center justify-between mb-5">
        <h3 class="text-lg font-semibold text-gray-900">Tus Rutas de Aprendizaje</h3>
        <span class="text-xs text-gray-400">{{ learningPaths.length }} rutas</span>
      </div>

      <div v-if="learningPaths.length === 0"
        class="bg-white rounded-2xl p-12 text-center border border-dashed border-gray-200">
        <BookOpen class="w-12 h-12 text-gray-300 mx-auto mb-4" />
        <p class="text-gray-500 font-medium">Aún no tienes rutas de aprendizaje</p>
        <p class="text-gray-400 text-sm mt-1">El motor adaptativo generará una para ti</p>
        <button @click="generatePath"
          :disabled="generating"
          class="mt-6 inline-flex items-center gap-2 bg-emerald-600 text-white px-6 py-2.5 rounded-xl text-sm font-medium hover:bg-emerald-700 transition-all shadow-md hover:shadow-lg active:scale-[0.98] disabled:opacity-50 disabled:cursor-not-allowed">
          <Brain v-if="!generating" class="w-4 h-4" />
          <Loader v-else class="w-4 h-4 animate-spin" />
          {{ generating ? 'Generando...' : 'Generar Ruta de Aprendizaje' }}
        </button>
      </div>

      <div v-else class="grid md:grid-cols-2 gap-4">
        <div v-for="path in learningPaths" :key="path.uuid"
          class="group bg-white rounded-xl p-5 shadow-sm border border-gray-100 hover:shadow-lg hover:border-emerald-200 transition-all">
          <div class="flex items-start justify-between mb-3">
            <div>
              <h4 class="font-semibold text-gray-900">{{ path.subject_area || 'Ruta General' }}</h4>
              <p class="text-xs text-gray-400 mt-0.5">{{ Number(path.progress_percent).toFixed(1) }}% completado</p>
            </div>
            <span class="text-xs px-2.5 py-1 rounded-full font-medium"
              :class="path.status === 'ACTIVE'
                ? 'bg-emerald-100 text-emerald-700'
                : 'bg-gray-100 text-gray-600'">
              {{ path.status === 'ACTIVE' ? 'Activa' : 'Inactiva' }}
            </span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-2 mb-3">
            <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-2 rounded-full transition-all duration-500"
              :style="{ width: `${path.progress_percent}%` }"></div>
          </div>
          <div class="flex justify-end">
            <router-link :to="`/learning/${path.uuid}`"
              class="inline-flex items-center gap-1 text-sm text-emerald-600 font-medium hover:text-emerald-700 group-hover:gap-2 transition-all">
              Continuar
              <ArrowRight class="w-4 h-4" />
            </router-link>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRouter } from 'vue-router'
import { RefreshCw, BookOpen, ArrowRight, Route, BarChart3, CloudOff, Clock, Brain, Loader } from '@lucide/vue'
import api from '../services/api'
import { syncEngine } from '../services/sync'
import { offlineManager } from '../services/offline'

const router = useRouter()
const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const learningPaths = ref([])
const generating = ref(false)
const stats = ref({
  activePaths: 0,
  overallProgress: 0,
  offlineContent: 0,
  pendingSync: 0,
})

const statCards = [
  { label: 'Rutas Activas', icon: Route, value: '0', bgClass: 'bg-emerald-100', iconClass: 'text-emerald-600', textClass: 'text-emerald-700' },
  { label: 'Progreso General', icon: BarChart3, value: '0%', bgClass: 'bg-blue-100', iconClass: 'text-blue-600', textClass: 'text-blue-700' },
  { label: 'Contenidos Offline', icon: CloudOff, value: '0', bgClass: 'bg-yellow-100', iconClass: 'text-yellow-600', textClass: 'text-yellow-700' },
  { label: 'Pendientes Sync', icon: Clock, value: '0', bgClass: 'bg-red-100', iconClass: 'text-red-600', textClass: 'text-red-700' },
]

async function loadPaths() {
  if (!user.value?.id) return
  try {
    const response = await api.get(`/adaptive/learning-path/list/${user.value.id}`)
    if (response.data?.success) {
      learningPaths.value = response.data.data || []
    }
  } catch {
    const cached = await offlineManager.getCachedContents()
    stats.value.offlineContent = Array.isArray(cached) ? cached.length : 0
  }
}

async function generatePath() {
  const existing = learningPaths.value.find(
    p => p.subject_area === 'Matemáticas' && p.status === 'ACTIVE'
  )
  if (existing) {
    router.push(`/learning/${existing.uuid}`)
    return
  }
  generating.value = true
  try {
    const response = await api.post('/adaptive/learning-path/generate', {
      user_id: user.value.id,
      subject_area: 'Matemáticas',
    })
    if (response.data?.success) {
      await loadPaths()
    }
  } catch (e) {
    console.error('Error generando ruta:', e)
  } finally {
    generating.value = false
  }
}

onMounted(async () => {
  stats.value.pendingSync = syncEngine.getQueueLength()
  await loadPaths()

  statCards[0].value = String(stats.value.activePaths)
  statCards[1].value = `${stats.value.overallProgress}%`
  statCards[2].value = String(stats.value.offlineContent)
  statCards[3].value = String(stats.value.pendingSync)
})
</script>
