<template>
  <div class="flex items-center gap-2 text-sm">
    <span class="w-2 h-2 rounded-full" :class="statusClass"></span>
    <span class="hidden sm:inline">{{ statusText }}</span>
  </div>
</template>

<script setup>
import { ref, computed, onMounted, onUnmounted } from 'vue'

const isOnline = ref(navigator.onLine)
const isApiReachable = ref(false)

const statusClass = computed(() => ({
  'bg-green-400': isOnline.value && isApiReachable.value,
  'bg-yellow-400': isOnline.value && !isApiReachable.value,
  'bg-red-400': !isOnline.value,
}))

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
