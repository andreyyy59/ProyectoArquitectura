<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <div class="mb-6">
      <router-link to="/dashboard"
        class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-emerald-600 transition-colors">
        <ArrowLeft class="w-4 h-4" />
        Volver
      </router-link>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div v-if="content?.content_type === 'VIDEO'"
        class="bg-gradient-to-br from-gray-900 via-gray-800 to-gray-900 aspect-video flex items-center justify-center relative group">
        <div class="absolute inset-0 bg-[radial-gradient(circle_at_center,_rgba(16,185,129,0.1)_0%,_transparent_70%)]"></div>
        <div class="text-center relative">
          <div class="w-20 h-20 rounded-full bg-white/10 backdrop-blur-sm flex items-center justify-center mx-auto mb-4 group-hover:bg-white/20 transition-all cursor-pointer group-hover:scale-105">
            <Play class="w-10 h-10 text-white ml-1" />
          </div>
          <p class="text-gray-400 text-sm">Reproductor de Video Offline</p>
          <p class="text-gray-600 text-xs mt-1">Contenido disponible sin conexión</p>
        </div>
      </div>

      <div v-else class="bg-gradient-to-br from-emerald-50 to-emerald-100/50 p-12 sm:p-16">
        <div class="text-center">
          <div class="w-16 h-16 rounded-2xl bg-white shadow-sm flex items-center justify-center mx-auto mb-4">
            <component :is="contentTypeIcon" class="w-8 h-8 text-emerald-600" />
          </div>
          <p class="text-gray-500 font-medium">{{ contentTypeLabel }}</p>
        </div>
      </div>

      <div class="p-6 sm:p-8">
        <div class="flex flex-wrap items-start justify-between gap-4 mb-6">
          <div class="flex-1 min-w-0">
            <h2 class="text-2xl font-bold text-gray-900 mb-2">{{ content?.title || 'Cargando...' }}</h2>
            <p class="text-gray-500">{{ content?.description }}</p>
          </div>
          <div v-if="offlineAvailable"
            class="inline-flex items-center gap-1.5 bg-yellow-50 border border-yellow-200 text-yellow-700 text-xs px-3 py-1.5 rounded-full font-medium shrink-0">
            <WifiOff class="w-3.5 h-3.5" />
            Disponible sin conexión
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2 mb-8">
          <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg font-medium">{{ content?.content_type }}</span>
          <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg font-medium">{{ content?.difficulty_level }}</span>
          <span class="text-xs text-gray-400 flex items-center gap-1 ml-1">
            <Clock class="w-3.5 h-3.5" />
            {{ content?.estimated_duration_minutes }} min
          </span>
        </div>

        <div class="border-t border-gray-100 pt-6">
          <div class="flex items-center justify-between mb-3">
            <h3 class="font-semibold text-gray-900">Tu Progreso</h3>
            <span class="text-sm text-gray-500">{{ localProgress }}%</span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-3 mb-6 overflow-hidden">
            <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-3 rounded-full transition-all duration-500"
              :style="{ width: `${localProgress}%` }"></div>
          </div>

          <div class="flex flex-wrap gap-3">
            <button @click="recordInteraction" :disabled="saving"
              class="inline-flex items-center gap-2 bg-emerald-600 text-white px-6 py-2.5 rounded-xl font-medium hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
              <Loader v-if="saving" class="w-4 h-4 animate-spin" />
              <TrendingUp v-else class="w-4 h-4" />
              {{ saving ? 'Guardando...' : 'Marcar Progreso' }}
            </button>
            <button @click="markCompleted"
              class="inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-xl font-medium hover:bg-blue-700 transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
              <CheckCircle class="w-4 h-4" />
              Completar
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute, useRouter } from 'vue-router'
import { ArrowLeft, Play, WifiOff, Clock, TrendingUp, CheckCircle, Loader, FileText, PenTool, ClipboardList, RefreshCw, File } from '@lucide/vue'
import api from '../services/api'
import { syncEngine } from '../services/sync'
import { offlineManager } from '../services/offline'

const route = useRoute()
const router = useRouter()
const content = ref(null)
const localProgress = ref(0)
const saving = ref(false)
const offlineAvailable = ref(false)

const contentTypeIcon = computed(() => {
  const icons = {
    PDF: FileText,
    EXERCISE: PenTool,
    QUIZ: ClipboardList,
    INTERACTIVE: RefreshCw,
    DOCUMENT: File,
  }
  return icons[content.value?.content_type] || File
})

const contentTypeLabel = computed(() => {
  const labels = {
    PDF: 'Documento PDF',
    EXERCISE: 'Ejercicio Interactivo',
    QUIZ: 'Evaluación',
    INTERACTIVE: 'Actividad Interactiva',
    DOCUMENT: 'Documento',
  }
  return labels[content.value?.content_type] || 'Contenido'
})

onMounted(async () => {
  try {
    const response = await api.get(`/content/${route.params.uuid}`)
    if (response.data?.success) {
      content.value = response.data.data
      offlineAvailable.value = content.value.is_offline_available
    }
  } catch {
    const cached = await offlineManager.getCachedContent(route.params.uuid)
    if (cached) {
      content.value = cached.data
      offlineAvailable.value = true
    }
  }

  const savedProgress = await offlineManager.getProgress(
    JSON.parse(localStorage.getItem('user') || '{}')?.id,
    content.value?.id
  )
  if (savedProgress) {
    localProgress.value = savedProgress.progress_percent || 0
  }
})

const recordInteraction = async () => {
  saving.value = true
  localProgress.value = Math.min(100, localProgress.value + 10)
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  const progress = {
    progress_percent: localProgress.value,
    last_position: `${localProgress.value}%`,
    status: localProgress.value >= 100 ? 'COMPLETED' : 'IN_PROGRESS',
    is_offline: !navigator.onLine,
  }

  await offlineManager.saveProgress(user.id, content.value?.id, progress)

  if (navigator.onLine) {
    try {
      await api.post('/adaptive/progress', {
        user_id: user.id,
        content_id: content.value?.id,
        ...progress,
      })
    } catch {
      await syncEngine.enqueue('progress', `${user.id}:${content.value?.id}`, 'UPDATE', progress)
    }
  } else {
    await syncEngine.enqueue('progress', `${user.id}:${content.value?.id}`, 'UPDATE', progress)
  }

  saving.value = false
}

const markCompleted = () => {
  localProgress.value = 100
  recordInteraction()
}
</script>
