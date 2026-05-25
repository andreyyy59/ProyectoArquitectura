<template>
  <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-12 animate-fade-in">
    <div class="text-center mb-10">
      <div class="w-20 h-20 bg-gradient-to-br from-yellow-400 to-yellow-500 rounded-2xl flex items-center justify-center mx-auto mb-5 shadow-lg">
        <WifiOff class="w-10 h-10 text-white" />
      </div>
      <h2 class="text-2xl font-bold text-gray-900 mb-2">Modo Sin Conexión</h2>
      <p class="text-gray-500 max-w-md mx-auto">
        Estás navegando sin conexión a internet. Los contenidos previamente descargados
        siguen disponibles para tu aprendizaje.
      </p>
    </div>

    <div class="bg-white rounded-xl p-6 shadow-sm border border-gray-100 mb-6">
      <div class="flex items-center justify-between mb-4">
        <h3 class="font-semibold text-gray-900">Contenidos Disponibles Offline</h3>
        <span class="text-xs text-gray-400">{{ cachedContents.length }} archivos</span>
      </div>

      <div v-if="cachedContents.length === 0" class="text-center py-10">
        <CloudOff class="w-12 h-12 text-gray-300 mx-auto mb-4" />
        <p class="text-gray-500 font-medium">No hay contenidos descargados</p>
        <p class="text-gray-400 text-sm mt-1">Conéctate a internet y descarga contenidos para estudio offline</p>
        <router-link to="/sync"
          class="inline-flex items-center gap-2 mt-4 text-emerald-600 font-medium text-sm hover:text-emerald-700">
          <Download class="w-4 h-4" />
          Ir al Centro de Sincronización
        </router-link>
      </div>

      <div v-else class="space-y-2">
        <div v-for="content in cachedContents" :key="content.uuid || content.id"
          class="flex items-center justify-between p-3 bg-gray-50 rounded-lg hover:bg-gray-100 transition-colors group">
          <div class="flex items-center gap-3">
            <div class="w-10 h-10 rounded-lg bg-white shadow-sm flex items-center justify-center">
              <FileText class="w-5 h-5 text-emerald-600" />
            </div>
            <div>
              <p class="font-medium text-sm text-gray-900">{{ content.title || 'Contenido offline' }}</p>
              <p class="text-xs text-gray-400">{{ content.content_type }}</p>
            </div>
          </div>
          <router-link :to="`/content/${content.uuid}`"
            class="text-emerald-600 text-sm font-medium hover:text-emerald-700 group-hover:gap-2 transition-all inline-flex items-center gap-1">
            Ver
            <ArrowRight class="w-3.5 h-3.5" />
          </router-link>
        </div>
      </div>
    </div>

    <div class="bg-gradient-to-r from-yellow-50 to-amber-50 border border-yellow-200 rounded-xl p-5">
      <div class="flex items-start gap-3">
        <Info class="w-5 h-5 text-yellow-600 shrink-0 mt-0.5" />
        <div>
          <p class="text-sm text-yellow-800 font-medium">Progreso guardado localmente</p>
          <p class="text-sm text-yellow-700/70 mt-1">
            Los datos de tu progreso se guardarán localmente y se sincronizarán
            automáticamente cuando recuperes conexión.
          </p>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, onMounted } from 'vue'
import { WifiOff, CloudOff, Download, FileText, ArrowRight, Info } from '@lucide/vue'
import { offlineManager } from '../services/offline'

const cachedContents = ref([])

onMounted(async () => {
  cachedContents.value = await offlineManager.getCachedContents()
})
</script>
