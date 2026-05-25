<template>
  <button @click="manualSync"
    class="inline-flex items-center gap-1.5 px-3 py-1.5 rounded-lg text-xs font-medium transition-all active:scale-[0.97]"
    :class="buttonClass" :disabled="syncing">
    <RefreshCw v-if="syncing" class="w-3.5 h-3.5 animate-spin" />
    <Cloud v-else-if="pendingCount === 0" class="w-3.5 h-3.5" />
    <CloudOff v-else class="w-3.5 h-3.5" />
    <span class="hidden sm:inline">{{ text }}</span>
  </button>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { RefreshCw, Cloud, CloudOff } from '@lucide/vue'
import { syncEngine } from '../services/sync'

const syncing = ref(false)
const pendingCount = ref(0)
const lastSync = ref(null)

const text = computed(() => {
  if (syncing.value) return 'Sincronizando...'
  if (pendingCount.value > 0) return `${pendingCount.value} pendientes`
  if (lastSync.value) return 'Sincronizado'
  return 'Sin sync'
})

const buttonClass = computed(() => {
  if (syncing.value) return 'bg-blue-500 text-white hover:bg-blue-600'
  if (pendingCount.value > 0) return 'bg-yellow-500 text-white hover:bg-yellow-600'
  return 'bg-emerald-600/10 text-emerald-700 hover:bg-emerald-600/20 border border-emerald-200'
})

const updateStatus = () => {
  pendingCount.value = syncEngine.getQueueLength()
  lastSync.value = syncEngine.getLastSyncAt()
}

const manualSync = async () => {
  syncing.value = true
  await syncEngine.triggerSync()
  syncing.value = false
  updateStatus()
}

onMounted(() => {
  updateStatus()
  setInterval(updateStatus, 5000)
})
</script>
