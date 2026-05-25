<template>
  <div class="inline-flex items-center gap-1.5 px-2.5 py-1 rounded-lg text-xs font-medium transition-colors duration-300"
    :class="badgeClass">
    <span class="relative flex w-2 h-2">
      <span class="animate-ping absolute inline-flex h-full w-full rounded-full opacity-75" :class="pingClass"></span>
      <span class="relative inline-flex rounded-full w-2 h-2" :class="dotClass"></span>
    </span>
    <span class="hidden sm:inline">{{ statusText }}</span>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const isOnline = ref(navigator.onLine)
const isApiReachable = ref(false)

const badgeClass = computed(() => {
  if (!isOnline.value) return 'bg-red-50 text-red-700 border border-red-200'
  if (!isApiReachable.value) return 'bg-yellow-50 text-yellow-700 border border-yellow-200'
  return 'bg-emerald-50 text-emerald-700 border border-emerald-200'
})

const dotClass = computed(() => {
  if (!isOnline.value) return 'bg-red-500'
  if (!isApiReachable.value) return 'bg-yellow-500'
  return 'bg-emerald-500'
})

const pingClass = computed(() => {
  if (!isOnline.value) return 'bg-red-400'
  if (!isApiReachable.value) return 'bg-yellow-400'
  return 'bg-emerald-400'
})

const statusText = computed(() => {
  if (!isOnline.value) return 'Sin conexión'
  if (!isApiReachable.value) return 'Red limitada'
  return 'En línea'
})

const checkApi = async () => {
  try {
    const res = await fetch('/api/health', { cache: 'no-store' })
    isApiReachable.value = res.ok
  } catch {
    isApiReachable.value = false
  }
}

let interval

onMounted(() => {
  window.addEventListener('online', () => { isOnline.value = true; checkApi() })
  window.addEventListener('offline', () => { isOnline.value = false })
  checkApi()
  interval = setInterval(checkApi, 15000)
})

onUnmounted(() => clearInterval(interval))
</script>
