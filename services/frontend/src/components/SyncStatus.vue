<template>
  <button @click="manualSync" class="flex items-center gap-1 px-2 py-1 rounded text-xs"
    :class="buttonClass" :disabled="syncing">
    <span class="inline-block" :class="{ 'animate-spin': syncing }">
      &#x21bb;
    </span>
    <span class="hidden sm:inline">{{ text }}</span>
  </button>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
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
  if (syncing.value) return 'bg-blue-500 text-white'
  if (pendingCount.value > 0) return 'bg-yellow-500 text-white'
  return 'bg-emerald-600 text-white'
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
