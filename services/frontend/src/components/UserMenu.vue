<template>
  <div class="relative" v-if="user">
    <button @click="open = !open" class="flex items-center gap-2 text-white text-sm">
      <span class="w-7 h-7 rounded-full bg-emerald-500 flex items-center justify-center text-xs font-bold">
        {{ initials }}
      </span>
      <span class="hidden md:inline">{{ user.full_name }}</span>
    </button>
    <div v-if="open" class="absolute right-0 top-full mt-2 w-48 bg-white rounded-lg shadow-xl py-2 z-50"
      @click="open = false">
      <router-link to="/dashboard" class="block px-4 py-2 text-gray-700 hover:bg-gray-100">Dashboard</router-link>
      <router-link to="/profile" class="block px-4 py-2 text-gray-700 hover:bg-gray-100">Mi Perfil</router-link>
      <router-link to="/sync" class="block px-4 py-2 text-gray-700 hover:bg-gray-100">Sincronización</router-link>
      <hr class="my-1">
      <button @click="logout" class="w-full text-left px-4 py-2 text-red-600 hover:bg-gray-100">Cerrar Sesión</button>
    </div>
  </div>
  <div v-else>
    <router-link to="/login" class="text-white text-sm hover:underline">Iniciar Sesión</router-link>
  </div>
</template>

<script setup>
import { ref, computed } from 'vue'
import { useRouter } from 'vue-router'
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
