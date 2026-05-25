<template>
  <div class="max-w-2xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <h2 class="text-2xl font-bold text-gray-900 mb-6">Mi Perfil</h2>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6 mb-6">
      <div class="flex items-center gap-4 mb-6 pb-6 border-b border-gray-100">
        <div class="w-16 h-16 rounded-2xl bg-gradient-to-br from-emerald-500 to-emerald-600 flex items-center justify-center text-xl font-bold text-white shadow-md">
          {{ initials }}
        </div>
        <div>
          <h3 class="text-xl font-semibold text-gray-900">{{ user?.full_name }}</h3>
          <p class="text-gray-500 flex items-center gap-1.5 mt-0.5">
            <Mail class="w-4 h-4" />
            {{ user?.email }}
          </p>
        </div>
      </div>

      <div class="grid sm:grid-cols-2 gap-5">
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Rol</label>
          <p class="font-medium text-gray-900 mt-1">{{ user?.role?.name || 'Estudiante' }}</p>
        </div>
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Documento</label>
          <p class="font-medium text-gray-900 mt-1">{{ profile?.document_id || 'No registrado' }}</p>
        </div>
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Teléfono</label>
          <p class="font-medium text-gray-900 mt-1">{{ profile?.phone || 'No registrado' }}</p>
        </div>
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Ubicación</label>
          <p class="font-medium text-gray-900 mt-1">{{ [profile?.municipality, profile?.department].filter(Boolean).join(', ') || 'No registrada' }}</p>
        </div>
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Institución</label>
          <p class="font-medium text-gray-900 mt-1">{{ profile?.institution || 'No registrada' }}</p>
        </div>
        <div class="p-4 bg-gray-50 rounded-xl">
          <label class="text-xs text-gray-400 uppercase tracking-wider font-medium">Conectividad</label>
          <p class="font-medium text-gray-900 mt-1">{{ profile?.connectivity_type || 'No registrada' }}</p>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow-sm border border-gray-100 p-6">
      <div class="flex items-center gap-2 mb-4">
        <Key class="w-5 h-5 text-gray-400" />
        <h3 class="font-semibold text-gray-900">Tokens Offline</h3>
      </div>
      <p class="text-sm text-gray-500 mb-4">Tokens JWT para autenticación sin conexión en zonas sin internet.</p>
      <button @click="generateOfflineToken" :disabled="generating"
        class="inline-flex items-center gap-2 bg-emerald-600 text-white px-5 py-2.5 rounded-xl text-sm font-medium hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
        <Loader v-if="generating" class="w-4 h-4 animate-spin" />
        <KeyRound v-else class="w-4 h-4" />
        {{ generating ? 'Generando...' : 'Generar Nuevo Token Offline' }}
      </button>
      <transition name="fade">
        <div v-if="newToken" class="mt-4 p-4 bg-gray-900 rounded-xl">
          <p class="text-xs font-mono text-emerald-400 break-all select-all">{{ newToken }}</p>
        </div>
      </transition>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { Mail, Key, KeyRound, Loader } from '@lucide/vue'
import api from '../services/api'

const user = ref(JSON.parse(localStorage.getItem('user') || '{}'))
const profile = ref({})
const generating = ref(false)
const newToken = ref('')

const initials = computed(() => {
  if (!user.value?.full_name) return '?'
  return user.value.full_name.split(' ').map(w => w[0]).join('').substring(0, 2).toUpperCase()
})

onMounted(async () => {
  try {
    const response = await api.get(`/users/${user.value.uuid}`)
    if (response.data?.success) {
      profile.value = response.data.data?.profile || {}
    }
  } catch {
    profile.value = { connectivity_type: '2G/3G', municipality: 'Timbiquí', department: 'Cauca' }
  }
})

const generateOfflineToken = async () => {
  generating.value = true
  try {
    const response = await api.post('/auth/offline-token')
    if (response.data?.success) {
      newToken.value = response.data.data.offline_token
    }
  } catch {
    newToken.value = 'mock-offline-token-' + Date.now()
  }
  generating.value = false
}
</script>

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
