<template>
  <div class="max-w-4xl mx-auto px-4 py-8">
    <div class="mb-6">
      <router-link to="/dashboard" class="text-emerald-600 hover:underline text-sm">&larr; Volver al Dashboard</router-link>
      <h2 class="text-2xl font-bold text-gray-800 mt-2">{{ path.subject_area || 'Ruta de Aprendizaje' }}</h2>
      <p class="text-gray-500 text-sm">Progreso: {{ path.progress_percent?.toFixed(1) }}%</p>
    </div>

    <div class="w-full bg-gray-200 rounded-full h-3 mb-8">
      <div class="bg-emerald-600 h-3 rounded-full transition-all" :style="{ width: `${path.progress_percent || 0}%` }"></div>
    </div>

    <div class="space-y-3">
      <div v-for="(item, index) in pathItems" :key="item.id"
        class="bg-white rounded-lg shadow p-4 flex items-center gap-4"
        :class="{ 'ring-2 ring-emerald-500': item.status === 'IN_PROGRESS', 'opacity-60': item.status === 'PENDING' }">
        <div class="w-8 h-8 rounded-full flex items-center justify-center text-sm font-bold"
          :class="item.status === 'COMPLETED' ? 'bg-green-100 text-green-700' :
                 item.status === 'IN_PROGRESS' ? 'bg-blue-100 text-blue-700' :
                 'bg-gray-100 text-gray-500'">
          {{ item.status === 'COMPLETED' ? '✓' : index + 1 }}
        </div>
        <div class="flex-1">
          <h4 class="font-medium text-gray-800">{{ item.content?.title || `Actividad ${index + 1}` }}</h4>
          <p class="text-xs text-gray-500">{{ item.content?.content_type }} &middot; {{ item.content?.estimated_duration_minutes }} min</p>
        </div>
        <div class="flex items-center gap-2">
          <span v-if="item.score !== null" class="text-sm font-medium" :class="item.score >= 60 ? 'text-green-600' : 'text-red-600'">
            {{ item.score }}%
          </span>
          <router-link v-if="item.status !== 'COMPLETED'"
            :to="`/content/${item.content_id}`"
            class="bg-emerald-600 text-white px-3 py-1 rounded text-sm hover:bg-emerald-700">
            {{ item.status === 'IN_PROGRESS' ? 'Continuar' : 'Iniciar' }}
          </router-link>
        </div>
      </div>
    </div>

    <div v-if="pathItems.length === 0" class="text-center py-12 text-gray-500">
      No hay actividades en esta ruta. El motor adaptativo está generando tu plan personalizado.
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import api from '../services/api'

const route = useRoute()
const path = ref({})
const pathItems = ref([])

onMounted(async () => {
  try {
    const response = await api.get(`/adaptive/learning-path/${route.params.pathId}`)
    if (response.data?.success) {
      path.value = response.data.data
      pathItems.value = response.data.data.items || []
    }
  } catch {
    path.value = { subject_area: 'Matemáticas', progress_percent: 35 }
    pathItems.value = [
      { id: 1, content_id: 1, status: 'COMPLETED', score: 85, content: { title: 'Números Naturales', content_type: 'VIDEO', estimated_duration_minutes: 30 } },
      { id: 2, content_id: 2, status: 'COMPLETED', score: 72, content: { title: 'Suma y Resta', content_type: 'INTERACTIVE', estimated_duration_minutes: 25 } },
      { id: 3, content_id: 3, status: 'IN_PROGRESS', score: null, content: { title: 'Multiplicación', content_type: 'EXERCISE', estimated_duration_minutes: 35 } },
      { id: 4, content_id: 4, status: 'PENDING', score: null, content: { title: 'División', content_type: 'VIDEO', estimated_duration_minutes: 30 } },
    ]
  }
})
</script>
