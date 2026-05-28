<template>
  <div class="max-w-4xl mx-auto px-4 sm:px-6 lg:px-8 py-8 animate-fade-in">
    <div class="mb-6">
      <router-link to="/dashboard"
        class="inline-flex items-center gap-1.5 text-sm text-gray-500 hover:text-emerald-600 transition-colors">
        <ArrowLeft class="w-4 h-4" />
        Volver al Dashboard
      </router-link>
    </div>

    <div class="bg-white rounded-2xl shadow-sm border border-gray-100 overflow-hidden">
      <div class="bg-gradient-to-br from-amber-50 to-orange-100/50 p-8 sm:p-12">
        <div v-if="exercises.length === 0 && loadingExercises"
          class="text-center py-12">
          <Loader class="w-10 h-10 text-amber-500 mx-auto mb-3 animate-spin" />
          <p class="text-gray-500 font-medium">Generando ejercicios con IA...</p>
          <p class="text-gray-400 text-sm mt-1">Ollama está preparando tu práctica personalizada</p>
        </div>
        <div v-else-if="exercises.length > 0" class="space-y-6">
          <div class="mb-4">
            <h2 class="text-2xl font-bold text-gray-900">{{ title }}</h2>
            <p class="text-gray-500 text-sm mt-1">Responde los ejercicios generados por IA</p>
          </div>
          <div v-for="(ex, idx) in exercises" :key="idx"
            class="bg-white rounded-xl p-5 shadow-sm border border-gray-200">
            <p class="text-sm text-gray-400 mb-1">Ejercicio {{ idx + 1 }} de {{ exercises.length }}</p>
            <p class="text-gray-900 font-semibold mb-4">{{ ex.question }}</p>
            <div class="space-y-2">
              <button v-for="(opt, oi) in ex.options" :key="oi"
                @click="selectAnswer(idx, oi)"
                class="w-full text-left px-4 py-3 rounded-lg border transition-all text-sm"
                :class="answerClass(idx, oi)">
                <span class="font-medium">{{ ['A', 'B', 'C', 'D'][oi] }}.</span> {{ opt }}
              </button>
            </div>
            <div v-if="answered[idx] !== undefined" class="mt-4 p-4 rounded-xl"
              :class="isCorrect(idx) ? 'bg-green-50 border border-green-200' : 'bg-red-50 border border-red-200'">
              <p class="font-medium text-sm mb-1" :class="isCorrect(idx) ? 'text-green-700' : 'text-red-700'">
                {{ isCorrect(idx) ? '¡Correcto!' : 'Incorrecto' }}
              </p>
              <p class="text-sm text-gray-600">{{ ex.explanation }}</p>
            </div>
          </div>
          <div class="flex items-center justify-between pt-2">
            <p class="text-sm text-gray-500">
              {{ correctCount }} / {{ exercises.length }} correctos
            </p>
            <button @click="regenerateExercises"
              class="inline-flex items-center gap-1.5 text-sm text-emerald-600 hover:text-emerald-700 font-medium">
              <RefreshCw class="w-4 h-4" />
              Generar nuevos ejercicios
            </button>
          </div>
        </div>
        <div v-else
          class="text-center py-12">
          <PenTool class="w-12 h-12 text-amber-400 mx-auto mb-3" />
          <p class="text-gray-500 font-medium">{{ title }}</p>
        </div>
      </div>

      <div class="p-6 sm:p-8">
        <div class="flex flex-wrap items-start justify-between gap-4 mb-6">
          <div class="flex-1 min-w-0">
            <p class="text-gray-500">{{ description }}</p>
          </div>
          <div v-if="offlineAvailable"
            class="inline-flex items-center gap-1.5 bg-yellow-50 border border-yellow-200 text-yellow-700 text-xs px-3 py-1.5 rounded-full font-medium shrink-0">
            <WifiOff class="w-3.5 h-3.5" />
            Disponible sin conexión
          </div>
        </div>

        <div class="flex flex-wrap items-center gap-2 mb-8">
          <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg font-medium">EXERCISE</span>
          <span class="text-xs bg-gray-100 text-gray-600 px-3 py-1.5 rounded-lg font-medium">{{ difficulty }}</span>
          <span class="text-xs text-gray-400 flex items-center gap-1 ml-1">
            <Clock class="w-3.5 h-3.5" />
            30 min
          </span>
        </div>

        <div class="border-t border-gray-100 pt-6">
          <div class="flex items-center justify-between mb-3">
            <h3 class="font-semibold text-gray-900">Tu Progreso</h3>
            <span class="text-sm text-gray-500">{{ localProgress }}%</span>
          </div>
          <div class="w-full bg-gray-100 rounded-full h-3 mb-6 overflow-hidden">
            <div class="bg-gradient-to-r from-emerald-500 to-emerald-400 h-3 rounded-full transition-all duration-500"
              :style="{ width: `${localProgress}%` }"></div>
          </div>

          <div class="flex flex-wrap gap-3">
            <button @click="recordInteraction" :disabled="saving"
              class="inline-flex items-center gap-2 bg-emerald-600 text-white px-6 py-2.5 rounded-xl font-medium hover:bg-emerald-700 disabled:opacity-50 disabled:cursor-not-allowed transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
              <Loader v-if="saving" class="w-4 h-4 animate-spin" />
              <TrendingUp v-else class="w-4 h-4" />
              {{ saving ? 'Guardando...' : 'Marcar Progreso' }}
            </button>
            <button @click="markCompleted"
              class="inline-flex items-center gap-2 bg-blue-600 text-white px-6 py-2.5 rounded-xl font-medium hover:bg-blue-700 transition-all shadow-sm hover:shadow-md active:scale-[0.98]">
              <CheckCircle class="w-4 h-4" />
              Completar
            </button>
          </div>
        </div>
      </div>
    </div>
  </div>
</template>

<script setup>
import { ref, computed, onMounted } from 'vue'
import { useRoute } from 'vue-router'
import { ArrowLeft, WifiOff, Clock, TrendingUp, CheckCircle, Loader, PenTool, RefreshCw } from '@lucide/vue'
import api from '../services/api'
import { syncEngine } from '../services/sync'
import { offlineManager } from '../services/offline'

const route = useRoute()
const localProgress = ref(0)
const saving = ref(false)
const offlineAvailable = ref(true)

const title = ref(route.query.title || 'Ejercicio')
const subject = ref(route.query.subject || 'Matemáticas')
const difficulty = ref('BEGINNER')
const description = ref('Ejercicios generados por IA adaptativa')

const exercises = ref([])
const selected = ref({})
const answered = ref({})
const loadingExercises = ref(false)

const correctCount = computed(() => {
  let count = 0
  for (const idx in answered.value) {
    const ex = exercises.value[parseInt(idx)]
    if (ex && answered.value[idx] === ex.correct_answer) count++
  }
  return count
})

function answerClass(idx, oi) {
  const ans = answered.value[idx]
  if (ans === undefined) {
    return selected.value[idx] === oi
      ? 'border-emerald-500 bg-emerald-50 text-emerald-700'
      : 'border-gray-200 hover:border-gray-300 text-gray-700'
  }
  const ex = exercises.value[idx]
  if (oi === ex.correct_answer) return 'border-green-500 bg-green-50 text-green-700'
  if (oi === ans && ans !== ex.correct_answer) return 'border-red-500 bg-red-50 text-red-700'
  return 'border-gray-100 text-gray-400 opacity-60'
}

function isCorrect(idx) {
  return answered.value[idx] === exercises.value[idx]?.correct_answer
}

function selectAnswer(idx, oi) {
  if (answered.value[idx] !== undefined) return
  selected.value[idx] = oi
  answered.value[idx] = oi
}

const FALLBACK_BY_SUBJECT = {
  'Matemáticas': [
    { question: '¿Cuánto es 25 + 37?', options: ['52', '62', '72', '42'], correct_answer: 1, explanation: '25 + 37 = 62' },
    { question: '¿Cuánto es 8 × 7?', options: ['48', '56', '64', '54'], correct_answer: 1, explanation: '8 × 7 = 56' },
    { question: '¿Cuánto es 12 × 5?', options: ['50', '60', '55', '65'], correct_answer: 1, explanation: '12 × 5 = 60' },
    { question: '¿Cuánto es 9 × 9?', options: ['72', '81', '90', '79'], correct_answer: 1, explanation: '9 × 9 = 81' },
    { question: '¿Cuánto es 36 ÷ 6?', options: ['4', '6', '7', '5'], correct_answer: 1, explanation: '36 ÷ 6 = 6' },
  ],
  'Ciencias': [
    { question: '¿Los seres vivos que nacen, crecen, se reproducen y mueren se llaman?', options: ['Seres inertes', 'Seres vivos', 'Plantas', 'Animales'], correct_answer: 1, explanation: 'Los seres vivos cumplen esas funciones vitales.' },
    { question: '¿Cuál es el órgano más grande del cuerpo humano?', options: ['El hígado', 'La piel', 'El cerebro', 'El corazón'], correct_answer: 1, explanation: 'La piel es el órgano más grande.' },
    { question: '¿Qué necesitan las plantas para realizar la fotosíntesis?', options: ['Agua y sales', 'Luz solar', 'Suelo fértil', 'Insectos'], correct_answer: 1, explanation: 'La luz solar es esencial para la fotosíntesis.' },
    { question: '¿Cuántos huesos tiene un adulto?', options: ['106', '206', '306', '156'], correct_answer: 1, explanation: 'El cuerpo adulto tiene 206 huesos.' },
    { question: '¿Qué planeta es conocido como el planeta rojo?', options: ['Venus', 'Marte', 'Júpiter', 'Saturno'], correct_answer: 1, explanation: 'Marte es conocido como el planeta rojo por su color.' },
  ],
  'Lenguaje': [
    { question: '¿Cuál es el sinónimo de "alegría"?', options: ['Tristeza', 'Felicidad', 'Enojo', 'Miedo'], correct_answer: 1, explanation: 'Alegría y felicidad son sinónimos.' },
    { question: 'El antónimo de "grande" es:', options: ['Enorme', 'Pequeño', 'Gigante', 'Alto'], correct_answer: 1, explanation: 'Pequeño es lo opuesto a grande.' },
    { question: '¿Qué es un sustantivo?', options: ['Una acción', 'Una persona, animal o cosa', 'Una cualidad', 'Un lugar'], correct_answer: 1, explanation: 'El sustantivo nombra personas, animales o cosas.' },
    { question: '¿Cuántas letras tiene el abecedario español?', options: ['26', '27', '28', '25'], correct_answer: 1, explanation: 'El abecedario español tiene 27 letras.' },
    { question: '¿Qué signo se usa al inicio de una pregunta?', options: ['¡', '¿', '"', '('], correct_answer: 1, explanation: 'En español las preguntas comienzan con ¿.' },
  ],
  'Historia': [
    { question: '¿Qué celebramos el 20 de julio en Colombia?', options: ['La independencia', 'El carnaval', 'La batalla', 'El descubrimiento'], correct_answer: 0, explanation: 'El 20 de julio de 1810 se conmemora el Grito de Independencia.' },
    { question: '¿Quién fue Simón Bolívar?', options: ['Un escritor', 'Un libertador', 'Un rey', 'Un científico'], correct_answer: 1, explanation: 'Simón Bolívar fue el Libertador de varias naciones.' },
    { question: '¿Cuál es la bandera de Colombia?', options: ['Verde, blanca, roja', 'Amarillo, azul, rojo', 'Rojo, blanco, azul', 'Azul, amarillo, verde'], correct_answer: 1, explanation: 'La bandera colombiana tiene los colores amarillo, azul y rojo.' },
    { question: '¿Quién descubrió América?', options: ['Simón Bolívar', 'Cristóbal Colón', 'Francisco Pizarro', 'Hernán Cortés'], correct_answer: 1, explanation: 'Cristóbal Colón descubrió América en 1492.' },
    { question: '¿Cuál es la capital de Colombia?', options: ['Medellín', 'Bogotá', 'Cali', 'Barranquilla'], correct_answer: 1, explanation: 'Bogotá es la capital de Colombia.' },
  ],
}

async function loadExercises() {
  const topic = title.value || 'Ejercicio'
  loadingExercises.value = true
  exercises.value = []

  try {
    const resp = await api.post('/ai/generate-exercises', {
      topic,
      subject: subject.value,
      count: 5,
      difficulty: difficulty.value,
      language: 'es',
    })
    if (resp.data?.exercises && resp.data.exercises.length > 0) {
      exercises.value = resp.data.exercises
    }
  } catch {
    // fallback offline
  }

  if (exercises.value.length === 0) {
    const fallback = FALLBACK_BY_SUBJECT[subject.value] || FALLBACK_BY_SUBJECT['Matemáticas']
    exercises.value = fallback.slice(0, 5)
  }

  loadingExercises.value = false
}

async function regenerateExercises() {
  selected.value = {}
  answered.value = {}
  await loadExercises()
}

onMounted(async () => {
  loadExercises()

  const userId = JSON.parse(localStorage.getItem('user') || '{}')?.id
  if (userId && route.params.uuid) {
    const savedProgress = await offlineManager.getProgress(userId, route.params.uuid).catch(() => null)
    if (savedProgress) {
      localProgress.value = savedProgress.progress_percent || 0
    }
  }
})

const recordInteraction = async () => {
  saving.value = true
  localProgress.value = Math.min(100, localProgress.value + 10)
  const user = JSON.parse(localStorage.getItem('user') || '{}')

  const progress = {
    progress_percent: localProgress.value,
    last_position: `${localProgress.value}%`,
    status: localProgress.value >= 100 ? 'COMPLETED' : 'IN_PROGRESS',
    is_offline: !navigator.onLine,
  }

  await offlineManager.saveProgress(user.id, route.params.uuid, progress)

  if (navigator.onLine) {
    try {
      await api.post('/adaptive/progress', {
        user_id: user.id,
        content_id: route.params.uuid,
        ...progress,
      })
    } catch {
      await syncEngine.enqueue('progress', `${user.id}:${route.params.uuid}`, 'UPDATE', progress)
    }
  } else {
    await syncEngine.enqueue('progress', `${user.id}:${route.params.uuid}`, 'UPDATE', progress)
  }

  saving.value = false
}

const markCompleted = () => {
  localProgress.value = 100
  recordInteraction()
}
</script>
