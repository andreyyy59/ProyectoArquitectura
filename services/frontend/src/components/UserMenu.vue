<template>
  <div class="relative" v-if="user">
    <button @click="open = !open"
      class="flex items-center gap-2 text-sm text-white bg-white/10 hover:bg-white/20 rounded-xl px-3 py-1.5 transition-all">
      <span class="w-7 h-7 rounded-lg bg-gradient-to-br from-emerald-400 to-emerald-500 flex items-center justify-center text-xs font-bold shadow-sm">
        {{ initials }}
      </span>
      <span class="hidden md:inline text-white/90">{{ user.full_name }}</span>
      <ChevronDown class="w-3.5 h-3.5 text-white/60" :class="{ 'rotate-180': open }" />
    </button>

    <transition name="dropdown">
      <div v-if="open"
        class="absolute right-0 top-full mt-2 w-56 bg-white rounded-xl shadow-xl shadow-gray-200/50 border border-gray-100 py-1.5 z-50 overflow-hidden"
        @click="open = false">
        <div class="px-4 py-3 border-b border-gray-100">
          <p class="text-sm font-medium text-gray-900 truncate">{{ user.full_name }}</p>
          <p class="text-xs text-gray-400 truncate">{{ user.email }}</p>
        </div>
        <router-link to="/dashboard"
          class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-emerald-50 hover:text-emerald-700 transition-colors">
          <LayoutDashboard class="w-4 h-4" />
          Dashboard
        </router-link>
        <router-link to="/profile"
          class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-emerald-50 hover:text-emerald-700 transition-colors">
          <User class="w-4 h-4" />
          Mi Perfil
        </router-link>
        <router-link to="/sync"
          class="flex items-center gap-3 px-4 py-2.5 text-sm text-gray-700 hover:bg-emerald-50 hover:text-emerald-700 transition-colors">
          <RefreshCw class="w-4 h-4" />
          Sincronización
        </router-link>
        <hr class="my-1 border-gray-100">
        <button @click="logout"
          class="flex items-center gap-3 w-full px-4 py-2.5 text-sm text-red-600 hover:bg-red-50 transition-colors">
          <LogOut class="w-4 h-4" />
          Cerrar Sesión
        </button>
      </div>
    </transition>
  </div>
  <div v-else>
    <router-link to="/login"
      class="inline-flex items-center gap-1.5 text-sm text-white/80 hover:text-white transition-colors">
      <LogIn class="w-4 h-4" />
      Iniciar Sesión
    </router-link>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
import { ChevronDown, LayoutDashboard, User, RefreshCw, LogOut, LogIn } from '@lucide/vue'
import { setToken } from '../services/api'

const router = useRouter()
const open = ref(false)
const user = ref(JSON.parse(localStorage.getItem('user') || 'null'))

const initials = computed(() => {
  if (!user.value?.full_name) return '?'
  return user.value.full_name.split(' ').map(w => w[0]).join('').substring(0, 2).toUpperCase()
})

const logout = () => {
  setToken(null)
  localStorage.removeItem('user')
  user.value = null
  router.push('/login')
}
</script>

<style scoped>
.dropdown-enter-active {
  transition: opacity 0.15s ease, transform 0.15s ease;
}
.dropdown-leave-active {
  transition: opacity 0.1s ease;
}
.dropdown-enter-from {
  opacity: 0;
  transform: translateY(-5px);
}
.dropdown-leave-to {
  opacity: 0;
}
</style>
