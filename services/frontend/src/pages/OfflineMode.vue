<template>
  <div class="max-w-lg mx-auto px-4 py-16 text-center">
    <div class="text-8xl mb-6">&#x1F4F6;</div>
    <h2 class="text-2xl font-bold text-gray-800 mb-4">Modo Sin Conexión</h2>
    <p class="text-gray-600 mb-8">
      Estás navegando sin conexión a internet. Los contenidos previamente descargados
      siguen disponibles para tu aprendizaje.
    </p>

    <div class="bg-white rounded-xl shadow p-6 mb-6">
      <h3 class="font-semibold text-gray-700 mb-3">Contenidos Disponibles Offline</h3>
      <div v-if="cachedContents.length === 0" class="text-gray-400 py-4">
        No hay contenidos descargados. Conéctate a internet y descarga contenidos para estudio offline.
      </div>
      <div v-else class="space-y-2">
        <div v-for="content in cachedContents" :key="content.uuid || content.id"
          class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100">
          <div class="text-left">
            <p class="font-medium text-sm">{{ content.title || 'Contenido offline' }}</p>
            <p class="text-xs text-gray-500">{{ content.content_type }}</p>
          </div>
          <router-link :to="`/content/${content.uuid}`"
            class="text-emerald-600 text-sm hover:underline">
            Ver
          </router-link>
        </div>
      </div>
    </div>

    <div class="bg-yellow-50 rounded-xl p-4 text-sm text-yellow-800">
      <p>Los datos de tu progreso se guardarán localmente y se sincronizarán
      automáticamente cuando recuperes conexión.</p>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { offlineManager } from '../services/offline'

const cachedContents = ref([])

onMounted(async () => {
  cachedContents.value = await offlineManager.getCachedContents()
})
</script>
