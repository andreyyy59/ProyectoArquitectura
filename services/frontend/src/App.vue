<template>
  <div class="min-h-screen flex flex-col bg-gradient-to-br from-gray-50 via-white to-emerald-50">
    <header class="bg-white/80 backdrop-blur-md shadow-sm border-b border-emerald-100 sticky top-0 z-50" v-if="!isOfflinePage">
      <div class="max-w-7xl mx-auto px-4 sm:px-6 lg:px-8">
        <div class="flex items-center justify-between h-16">
          <router-link to="/" class="flex items-center gap-3 group">
            <GraduationCap class="w-7 h-7 text-emerald-600 group-hover:text-emerald-700 transition-colors" />
            <span class="text-lg font-bold text-emerald-800">EduConnect Rural</span>
            <span class="hidden sm:inline text-xs bg-emerald-100 text-emerald-700 px-2 py-0.5 rounded-full font-medium">Offline-First</span>
          </router-link>
          <div class="flex items-center gap-3 sm:gap-4">
            <ConnectivityBadge />
            <SyncStatus />
            <UserMenu />
          </div>
        </div>
      </div>
    </header>
    <main class="flex-1">
      <router-view v-slot="{ Component }">
        <transition name="page" mode="out-in">
          <component :is="Component" />
        </transition>
      </router-view>
    </main>
  </div>
</template>

<script setup>
import { computed } from 'vue'
import { useRoute } from 'vue-router'
import { GraduationCap } from '@lucide/vue'
import ConnectivityBadge from './components/ConnectivityBadge.vue'
import SyncStatus from './components/SyncStatus.vue'
import UserMenu from './components/UserMenu.vue'

const route = useRoute()
const isOfflinePage = computed(() => route.name === 'offline')
</script>

<style>
.page-enter-active {
  transition: opacity 0.25s ease, transform 0.25s ease;
}
.page-leave-active {
  transition: opacity 0.15s ease;
}
.page-enter-from {
  opacity: 0;
  transform: translateY(8px);
}
.page-leave-to {
  opacity: 0;
}
</style>
