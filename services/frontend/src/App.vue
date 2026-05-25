<template>
  <div class="min-h-screen flex flex-col">
    <header class="bg-emerald-700 text-white shadow-lg" v-if="!isOfflinePage">
      <div class="max-w-7xl mx-auto px-4 py-3 flex items-center justify-between">
        <div class="flex items-center gap-3">
          <h1 class="text-xl font-bold">EduConnect Rural</h1>
          <span class="text-xs bg-emerald-500 px-2 py-1 rounded-full">Offline-First</span>
        </div>
        <div class="flex items-center gap-4">
          <ConnectivityBadge />
          <SyncStatus />
          <UserMenu />
        </div>
      </div>
    </header>
    <main class="flex-1">
      <router-view />
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import ConnectivityBadge from './components/ConnectivityBadge.vue'
import SyncStatus from './components/SyncStatus.vue'
import UserMenu from './components/UserMenu.vue'

const route = useRoute()
const isOfflinePage = computed(() => route.name === 'offline')
</script>
