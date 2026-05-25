<template>
  <div class="min-h-[calc(100vh-4rem)] flex items-center justify-center px-4 py-12">
    <div class="w-full max-w-md animate-slide-up">
      <div class="text-center mb-8">
        <div class="w-16 h-16 bg-gradient-to-br from-emerald-500 to-emerald-700 rounded-2xl flex items-center justify-center mx-auto mb-4 shadow-lg">
          <GraduationCap class="w-8 h-8 text-white" />
        </div>
        <h2 class="text-2xl font-bold text-gray-900">Iniciar Sesión</h2>
        <p class="text-gray-500 mt-1">Ingresa con tu cuenta de EduConnect</p>
      </div>

      <div class="bg-white rounded-2xl shadow-lg shadow-gray-200/50 border border-gray-100 p-8">
        <form @submit.prevent="handleLogin" class="space-y-5">
          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Correo Electrónico</label>
            <div class="relative">
              <Mail class="w-5 h-5 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input v-model="email" type="email" required
                class="w-full pl-11 pr-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 bg-gray-50/50 focus:bg-white transition-colors"
                placeholder="estudiante@educonnect.edu">
            </div>
          </div>

          <div>
            <label class="block text-sm font-medium text-gray-700 mb-1.5">Contraseña</label>
            <div class="relative">
              <Lock class="w-5 h-5 text-gray-400 absolute left-3.5 top-1/2 -translate-y-1/2" />
              <input v-model="password" type="password" required
                class="w-full pl-11 pr-4 py-2.5 border border-gray-200 rounded-xl focus:ring-2 focus:ring-emerald-500 focus:border-emerald-500 bg-gray-50/50 focus:bg-white transition-colors"
                placeholder="••••••••">
            </div>
          </div>

          <transition name="fade">
            <div v-if="error" class="flex items-center gap-2 bg-red-50 border border-red-200 text-red-700 text-sm rounded-xl px-4 py-3">
              <AlertCircle class="w-5 h-5 shrink-0" />
              <span>{{ error }}</span>
            </div>
          </transition>

          <button type="submit" :disabled="loading"
            class="w-full inline-flex items-center justify-center gap-2 bg-gradient-to-r from-emerald-600 to-emerald-500 text-white py-2.5 rounded-xl font-semibold hover:from-emerald-700 hover:to-emerald-600 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-md hover:shadow-lg active:scale-[0.98]">
            <Loader v-if="loading" class="w-5 h-5 animate-spin" />
            <LogIn v-else class="w-5 h-5" />
            {{ loading ? 'Ingresando...' : 'Ingresar' }}
          </button>
        </form>

        <div class="relative my-6">
          <div class="absolute inset-0 flex items-center">
            <div class="w-full border-t border-gray-100"></div>
          </div>
          <div class="relative flex justify-center text-xs">
            <span class="bg-white px-3 text-gray-400">Modo offline disponible</span>
          </div>
        </div>

        <p class="text-center text-sm text-gray-500">
          ¿No tienes cuenta?
          <button class="text-emerald-600 hover:text-emerald-700 font-medium hover:underline transition-colors">
            Solicitar acceso
          </button>
        </p>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref } from 'vue'
import { useRouter } from 'vue-router'
import { GraduationCap, Mail, Lock, LogIn, Loader, AlertCircle } from '@lucide/vue'
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

<style scoped>
.fade-enter-active, .fade-leave-active {
  transition: opacity 0.3s ease;
}
.fade-enter-from, .fade-leave-to {
  opacity: 0;
}
</style>
