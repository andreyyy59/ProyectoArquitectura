<template>
  <div class="min-h-[calc(100vh-4rem)]">
    <section class="relative overflow-hidden">
      <div class="absolute inset-0 bg-gradient-to-br from-emerald-600 via-emerald-700 to-emerald-900"></div>
      <div class="absolute inset-0 bg-[url('data:image/svg+xml;base64,PHN2ZyB3aWR0aD0iNjAiIGhlaWdodD0iNjAiIHZpZXdCb3g9IjAgMCA2MCA2MCIgeG1sbnM9Imh0dHA6Ly93d3cudzMub3JnLzIwMDAvc3ZnIj48ZyBmaWxsPSJub25lIiBmaWxsLXJ1bGU9ImV2ZW5vZGQiPjxnIGZpbGw9IiNmZmYiIGZpbGwtb3BhY2l0eT0iMC4wNSI+PGNpcmNsZSBjeD0iMzAiIGN5PSIzMCIgcj0iMiIvPjwvZz48L2c+PC9zdmc+')] opacity-30"></div>
      <div class="absolute top-0 -left-40 w-96 h-96 bg-emerald-400 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse-soft"></div>
      <div class="absolute top-0 -right-40 w-96 h-96 bg-emerald-300 rounded-full mix-blend-multiply filter blur-3xl opacity-20 animate-pulse-soft" style="animation-delay: 1s"></div>

      <div class="relative max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20 sm:py-28 lg:py-36">
        <div class="text-center max-w-3xl mx-auto">
          <div class="inline-flex items-center gap-2 bg-white/10 backdrop-blur-sm text-emerald-100 px-4 py-1.5 rounded-full text-sm mb-6 animate-fade-in">
            <WifiOff class="w-4 h-4" />
            <span>Plataforma educativa Offline-First</span>
          </div>
          <h1 class="text-4xl sm:text-5xl lg:text-6xl font-bold text-white leading-tight mb-6 animate-slide-up">
            Educación sin límites
            <span class="text-transparent bg-clip-text bg-gradient-to-r from-emerald-200 to-emerald-100">, incluso sin conexión</span>
          </h1>
          <p class="text-lg sm:text-xl text-emerald-100/80 mb-10 max-w-2xl mx-auto animate-slide-up" style="animation-delay: 0.1s">
            Plataforma de aprendizaje adaptativo diseñada para zonas rurales con baja conectividad.
            IA local, sincronización inteligente y contenido siempre disponible.
          </p>
          <div class="flex flex-col sm:flex-row gap-4 justify-center animate-slide-up" style="animation-delay: 0.2s">
            <router-link to="/login"
              class="inline-flex items-center justify-center gap-2 bg-white text-emerald-700 px-8 py-3.5 rounded-xl font-semibold hover:bg-emerald-50 transition-all shadow-lg hover:shadow-xl active:scale-[0.98]">
              <LogIn class="w-5 h-5" />
              Comenzar ahora
            </router-link>
            <router-link to="/offline"
              class="inline-flex items-center justify-center gap-2 border-2 border-white/30 text-white px-8 py-3.5 rounded-xl font-semibold hover:bg-white/10 transition-all active:scale-[0.98]">
              <WifiOff class="w-5 h-5" />
              Explorar sin conexión
            </router-link>
          </div>
        </div>
      </div>
    </section>

    <section class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-20">
      <div class="text-center mb-14">
        <h2 class="text-3xl font-bold text-gray-900 mb-3">Diseñado para la ruralidad</h2>
        <p class="text-gray-500 max-w-xl mx-auto">Tecnología adaptativa que funciona donde más se necesita</p>
      </div>
      <div class="grid md:grid-cols-3 gap-6 lg:gap-8">
        <div v-for="(feature, i) in features" :key="i"
          class="group bg-white rounded-2xl p-8 shadow-sm hover:shadow-xl transition-all duration-300 border border-gray-100 hover:border-emerald-200 hover:-translate-y-1"
          :style="{ animationDelay: `${i * 0.1}s` }">
          <div class="w-14 h-14 rounded-2xl bg-gradient-to-br from-emerald-50 to-emerald-100 flex items-center justify-center mb-5 group-hover:scale-110 transition-transform duration-300">
            <component :is="feature.icon" class="w-7 h-7 text-emerald-600" />
          </div>
          <h3 class="text-xl font-semibold text-gray-900 mb-3">{{ feature.title }}</h3>
          <p class="text-gray-500 leading-relaxed">{{ feature.description }}</p>
        </div>
      </div>
    </section>

    <section class="bg-white border-t border-gray-100">
      <div class="max-w-6xl mx-auto px-4 sm:px-6 lg:px-8 py-16">
        <div class="grid md:grid-cols-4 gap-8">
          <div v-for="(stat, i) in stats" :key="i" class="text-center">
            <p class="text-3xl font-bold text-emerald-600 mb-1">{{ stat.value }}</p>
            <p class="text-sm text-gray-500">{{ stat.label }}</p>
          </div>
        </div>
      </div>
    </section>
  </div>
</template>

<script setup>
import { LogIn, WifiOff, CloudOff, Brain, Database, MapPin, Users, BookOpen, Signal } from '@lucide/vue'

const features = [
  {
    icon: CloudOff,
    title: 'Offline-First',
    description: 'Contenidos disponibles sin conexión con sincronización automática al recuperar red. Estudia desde cualquier lugar.',
  },
  {
    icon: Brain,
    title: 'IA Adaptativa',
    description: 'Rutas de aprendizaje personalizadas generadas por IA local en el Edge Node, adaptadas al ritmo de cada estudiante.',
  },
  {
    icon: Database,
    title: 'Sincronización Delta',
    description: 'Protocolo de 5 fases que minimiza el uso de datos en redes 2G/3G. Solo sincroniza lo necesario.',
  },
]

const stats = [
  { value: '10+', label: 'Microservicios' },
  { value: '5', label: 'Fases de Sync' },
  { value: '100%', label: 'Offline Capable' },
  { value: '2G/3G', label: 'Redes Soportadas' },
]
</script>
