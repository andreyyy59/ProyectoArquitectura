<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div class="bg-white rounded-xl shadow-lg overflow-hidden">
      <div class="bg-gray-900 aspect-video flex items-center justify-center text-white" v-if="content?.content_type === 'VIDEO'">
        <div class="text-center">
          <div class="text-6xl mb-4">&#x25B6;</div>
          <p class="text-gray-400">Reproductor de Video Offline</p>
        </div>
      </div>

      <div v-else class="p-8">
        <div class="text-center text-gray-400 mb-4">
          <div class="text-6xl mb-2">{{ contentTypeIcon }}</div>
          <p>{{ contentTypeLabel }}</p>
        </div>
      </div>

      <div class="p-6">
        <h2 class="text-2xl font-bold text-gray-800 mb-2">{{ content?.title || 'Cargando...' }}</h2>
        <p class="text-gray-600 mb-4">{{ content?.description }}</p>

        <div v-if="offlineAvailable" class="mb-4">
          <span class="bg-yellow-100 text-yellow-800 text-xs px-2 py-1 rounded-full">
            Disponible sin conexi&oacute;n
          </span>
        </div>

        <div class="flex items-center gap-4 mb-6">
          <span class="text-xs bg-gray-100 px-2 py-1 rounded">{{ content?.content_type }}</span>
          <span class="text-xs bg-gray-100 px-2 py-1 rounded">{{ content?.difficulty_level }}</span>
          <span class="text-xs text-gray-500">{{ content?.estimated_duration_minutes }} min</span>
        </div>

        <div class="border-t pt-4">
          <h3 class="font-semibold text-gray-700 mb-3">Tu Progreso</h3>
          <div class="w-full bg-gray-200 rounded-full h-3 mb-2">
            <div class="bg-emerald-600 h-3 rounded-full" :style="{ width: `${localProgress}%` }"></div>
          </div>
          <p class="text-sm text-gray-500">{{ localProgress }}% completado</p>

          <div class="mt-4 flex gap-3">
            <button @click="recordInteraction" :disabled="saving"
              class="bg-emerald-600 text-white px-6 py-2 rounded-lg hover:bg-emerald-700 disabled:opacity-50">
              {{ saving ? 'Guardando...' : 'Marcar Progreso' }}
            </button>
            <button @click="markCompleted"
              class="bg-blue-600 text-white px-6 py-2 rounded-lg hover:bg-blue-700">
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
  const icons = { PDF: '📄', EXERCISE: '✏️', QUIZ: '📝', INTERACTIVE: '🔄', DOCUMENT: '📃' }
  return icons[content.value?.content_type] || '📁'
})

const contentTypeLabel = computed(() => {
  const labels = { PDF: 'Documento PDF', EXERCISE: 'Ejercicio Interactivo', QUIZ: 'Evaluación', INTERACTIVE: 'Actividad Interactiva', DOCUMENT: 'Documento' }
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
