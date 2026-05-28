<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <div class="mb-8">
      <router-link to="/dashboard"
        class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-emerald-600 transition-colors mb-4">
        <ArrowLeft class="w-4 h-4" />
        Volver al Dashboard
      </router-link>
      <div class="flex flex-col sm:flex-row sm:items-center sm:justify-between gap-2">
        <div>
          <h2 class="text-2xl font-bold text-gray-900">{{ path.subject_area || 'Ruta de Aprendizaje' }}</h2>
          <p class="text-gray-500 text-sm mt-1">Progreso general: {{ Number(path.progress_percent).toFixed(1) }}%</p>
        </div>
        <span class="text-xs px-3 py-1 rounded-full font-medium w-fit"
          :class="Number(path.progress_percent) >= 100 ? 'bg-emerald-100 text-emerald-700' : 'bg-blue-100 text-blue-700'">
          {{ Number(path.progress_percent) >= 100 ? 'Completada' : 'En progreso' }}
        </span>
      </div>
    </div>

    <div class="w-full bg-gray-100 rounded-full h-3 mb-10 overflow-hidden">
      <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-3 rounded-full transition-all duration-700 ease-out"
        :style="{ width: `${path.progress_percent || 0}%` }"></div>
    </div>

    <div class="relative">
      <div class="absolute left-5 top-0 bottom-0 w-0.5 bg-gray-200 hidden sm:block"></div>

      <div v-if="pathItems.length === 0" class="text-center py-16">
        <BookOpen class="w-14 h-14 text-gray-300 mx-auto mb-4" />
        <p class="text-gray-500 font-medium">No hay actividades en esta ruta</p>
        <p class="text-gray-400 text-sm mt-1">El motor adaptativo está generando tu plan personalizado</p>
      </div>

      <div v-else class="space-y-4">
        <div v-for="(item, index) in pathItems" :key="item.id"
          class="relative flex items-start gap-4 sm:gap-6 group">
          <div class="hidden sm:flex relative z-10">
            <div class="w-10 h-10 rounded-xl flex items-center justify-center text-sm font-bold shadow-sm transition-all duration-200"
              :class="stepClass(item.status)">
              <Check v-if="item.status === 'COMPLETED'" class="w-5 h-5" />
              <span v-else-if="item.status === 'IN_PROGRESS'">{{ index + 1 }}</span>
              <span v-else class="text-gray-400">{{ index + 1 }}</span>
            </div>
          </div>

          <div class="flex-1 bg-white rounded-xl p-5 shadow-sm border transition-all duration-200"
            :class="borderClass(item.status)">
            <div class="flex items-start justify-between gap-3">
              <div class="flex-1">
                <h4 class="font-semibold text-gray-900">{{ item.content?.title || `Actividad ${index + 1}` }}</h4>
                <div class="flex items-center gap-3 mt-1.5">
                  <span class="text-xs text-gray-400">{{ item.content?.content_type }}</span>
                  <span class="text-gray-300">·</span>
                  <span class="text-xs text-gray-400">{{ item.content?.estimated_duration_minutes }} min</span>
                </div>
              </div>
              <div class="flex items-center gap-3 shrink-0">
                <span v-if="item.score !== null"
                  class="text-sm font-semibold px-2.5 py-0.5 rounded-full"
                  :class="item.score >= 60 ? 'bg-green-100 text-green-700' : 'bg-red-100 text-red-700'">
                  {{ item.score }}%
                </span>
                <router-link v-if="item.status !== 'COMPLETED'"
                  :to="`/content/${item.content_id}?title=${encodeURIComponent(item.content?.title || 'Ejercicio')}&subject=${encodeURIComponent(path.subject_area || 'Matemáticas')}`"
                  class="inline-flex items-center gap-1.5 bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm font-medium hover:bg-emerald-700 transition-all active:scale-[0.97] shadow-sm">
                  {{ item.status === 'IN_PROGRESS' ? 'Continuar' : 'Iniciar' }}
                  <ArrowRight class="w-4 h-4" />
                </router-link>
                <div v-else class="flex items-center gap-1.5 text-emerald-600 text-sm font-medium">
                  <CheckCircle class="w-5 h-5" />
                  <span class="hidden sm:inline">Completado</span>
                </div>
              </div>
            </div>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ArrowLeft, ArrowRight, BookOpen, Check, CheckCircle } from '@lucide/vue'
import api from '../services/api'

const route = useRoute()
const path = ref({})
const pathItems = ref([])

const stepClass = (status) => {
  if (status === 'COMPLETED') return 'bg-green-100 text-green-700 ring-2 ring-green-200'
  if (status === 'IN_PROGRESS') return 'bg-blue-100 text-blue-700 ring-2 ring-blue-200 animate-pulse-soft'
  return 'bg-gray-100 text-gray-400'
}

const borderClass = (status) => {
  if (status === 'IN_PROGRESS') return 'border-blue-200 ring-1 ring-blue-100'
  if (status === 'COMPLETED') return 'border-green-100'
  return 'border-gray-100 opacity-70 hover:opacity-100'
}

const SUBJECT_TOPICS = {
  'Matemáticas': [
    'Números Naturales', 'Suma y Resta', 'Multiplicación',
    'División', 'Fracciones', 'Geometría Básica',
    'Estadística', 'Probabilidad',
  ],
  'Ciencias': [
    'Seres Vivos', 'Cuerpo Humano', 'Ecosistemas',
    'Materia y Energía', 'El Sistema Solar',
  ],
  'Lenguaje': [
    'Vocabulario', 'Lectura', 'Gramática',
    'Ortografía', 'Comprensión Lectora',
  ],
  'Historia': [
    'Historia Local', 'Cultura y Sociedad', 'Símbolos Patrios',
    'Personajes Históricos', 'Fechas Cívicas',
  ],
}

function enrichItem(item, subject) {
  if (!item.content) {
    const idx = item.content_id - 1
    const topics = SUBJECT_TOPICS[subject] || SUBJECT_TOPICS['Matemáticas']
    item.content = {
      title: topics[idx] || `Ejercicio ${item.sort_order + 1}`,
      content_type: 'EXERCISE',
      estimated_duration_minutes: 30,
      difficulty_level: idx >= 4 ? 'INTERMEDIATE' : 'BEGINNER',
    }
  }
  return item
}

onMounted(async () => {
  try {
    const response = await api.get(`/adaptive/learning-path/${route.params.pathId}`)
    if (response.data?.success) {
      path.value = response.data.data
      pathItems.value = (response.data.data.items || []).map(i => enrichItem(i, path.value.subject_area))
    }
  } catch {
    path.value = { subject_area: 'Matemáticas', progress_percent: 35 }
    const subject = path.value.subject_area
    const topics = SUBJECT_TOPICS[subject] || SUBJECT_TOPICS['Matemáticas']
    pathItems.value = Array.from({ length: topics.length }, (_, i) => enrichItem({
      id: i + 1, content_id: i + 1, sort_order: i,
      status: i < 2 ? 'COMPLETED' : i === 2 ? 'IN_PROGRESS' : 'PENDING',
      score: i < 2 ? [85, 72][i] : null,
      content: null,
    }, subject))
  }
})
</script>
