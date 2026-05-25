<template>
  <div class="max-w-2xl mx-auto px-4 py-8">
    <h2 class="text-2xl font-bold text-gray-800 mb-6">Mi Perfil</h2>

    <div class="bg-white rounded-xl shadow p-6 mb-6">
      <div class="flex items-center gap-4 mb-6">
        <div class="w-16 h-16 rounded-full bg-emerald-100 flex items-center justify-center text-2xl font-bold text-emerald-700">
          {{ initials }}
        </div>
        <div>
          <h3 class="text-xl font-semibold">{{ user?.full_name }}</h3>
          <p class="text-gray-500">{{ user?.email }}</p>
        </div>
      </div>

      <div class="grid md:grid-cols-2 gap-4 text-sm">
        <div>
          <label class="block text-gray-500">Rol</label>
          <p class="font-medium">{{ user?.role?.name || 'Estudiante' }}</p>
        </div>
        <div>
          <label class="block text-gray-500">Documento</label>
          <p class="font-medium">{{ profile?.document_id || 'No registrado' }}</p>
        </div>
        <div>
          <label class="block text-gray-500">Teléfono</label>
          <p class="font-medium">{{ profile?.phone || 'No registrado' }}</p>
        </div>
        <div>
          <label class="block text-gray-500">Ubicación</label>
          <p class="font-medium">{{ [profile?.municipality, profile?.department].filter(Boolean).join(', ') || 'No registrada' }}</p>
        </div>
        <div>
          <label class="block text-gray-500">Institución</label>
          <p class="font-medium">{{ profile?.institution || 'No registrada' }}</p>
        </div>
        <div>
          <label class="block text-gray-500">Conectividad</label>
          <p class="font-medium">{{ profile?.connectivity_type || 'No registrada' }}</p>
        </div>
      </div>
    </div>

    <div class="bg-white rounded-xl shadow p-6">
      <h3 class="font-semibold text-gray-700 mb-4">Tokens Offline</h3>
      <p class="text-sm text-gray-500 mb-4">Tokens JWT para autenticación sin conexión.</p>
      <button @click="generateOfflineToken" :disabled="generating"
        class="bg-emerald-600 text-white px-4 py-2 rounded-lg text-sm hover:bg-emerald-700 disabled:opacity-50">
        {{ generating ? 'Generando...' : 'Generar Nuevo Token Offline' }}
      </button>
      <p v-if="newToken" class="mt-3 p-3 bg-gray-100 rounded text-xs font-mono break-all">
        {{ newToken }}
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
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
