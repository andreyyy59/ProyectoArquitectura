<template>
  <div class="min-h-[80vh] flex items-center justify-center px-4">
    <div class="bg-white rounded-xl shadow-lg p-8 w-full max-w-md">
      <div class="text-center mb-6">
        <div class="text-4xl mb-2">&#x1F393;</div>
        <h2 class="text-2xl font-bold text-emerald-800">Iniciar Sesión</h2>
        <p class="text-gray-500 text-sm mt-1">Ingresa con tu cuenta de EduConnect</p>
      </div>

      <form @submit.prevent="handleLogin" class="space-y-4">
        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Correo Electrónico</label>
          <input v-model="email" type="email" required
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            placeholder="estudiante@educonnect.edu">
        </div>

        <div>
          <label class="block text-sm font-medium text-gray-700 mb-1">Contraseña</label>
          <input v-model="password" type="password" required
            class="w-full px-4 py-2 border rounded-lg focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500"
            placeholder="••••••••">
        </div>

        <p v-if="error" class="text-red-600 text-sm text-center">{{ error }}</p>

        <button type="submit" :disabled="loading"
          class="w-full bg-emerald-600 text-white py-2 rounded-lg font-semibold hover:bg-emerald-700 disabled:opacity-50">
          {{ loading ? 'Ingresando...' : 'Ingresar' }}
        </button>
      </form>

      <p class="text-center text-sm text-gray-500 mt-6">
        ¿No tienes cuenta?
        <button class="text-emerald-600 hover:underline font-medium">
          Solicitar acceso
        </button>
      </p>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import api, { setToken } from '../services/api'
import { offlineManager } from '../services/offline'

const router = useRouter()
const email = ref('')
const password = ref('')
const loading = ref(false)
const error = ref('')

const handleLogin = async () => {
  loading.value = true
  error.value = ''

  try {
    const response = await api.post('/auth/login', {
      email: email.value,
      password: password.value,
    })

    if (response.data?.success) {
      const { token, user } = response.data.data
      setToken(token)
      localStorage.setItem('user', JSON.stringify(user))
      await offlineManager.cacheAuthToken(token, user)
      router.push('/dashboard')
    }
  } catch (e) {
    if (!navigator.onLine) {
      const cached = await offlineManager.getCachedAuth()
      if (cached && cached.user?.email === email.value) {
        setToken(cached.token)
        localStorage.setItem('user', JSON.stringify(cached.user))
        router.push('/dashboard')
        return
      }
    }
    error.value = 'Credenciales inválidas o sin conexión'
  } finally {
    loading.value = false
  }
}
</script>
