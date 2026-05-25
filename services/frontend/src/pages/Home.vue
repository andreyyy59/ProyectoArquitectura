<template>
  <div class="max-w-4xl mx-auto px-4 py-12 text-center">
    <div class="mb-8">
      <div class="text-6xl mb-4">&#x1F393;</div>
      <h2 class="text-4xl font-bold text-emerald-800 mb-4">EduConnect Rural</h2>
      <p class="text-lg text-gray-600 mb-8">
        Plataforma de aprendizaje adaptativo diseñada para zonas con baja conectividad
      </p>
    </div>

    <div class="grid md:grid-cols-3 gap-6 mb-12">
      <div class="bg-white rounded-xl shadow-md p-6">
        <div class="text-3xl mb-3">&#x1F4E1;</div>
        <h3 class="font-semibold text-lg mb-2">Offline-First</h3>
        <p class="text-gray-600 text-sm">Contenidos disponibles sin conexión con sincronización automática al recuperar red</p>
      </div>
      <div class="bg-white rounded-xl shadow-md p-6">
        <div class="text-3xl mb-3">&#x1F9E0;</div>
        <h3 class="font-semibold text-lg mb-2">IA Adaptativa</h3>
        <p class="text-gray-600 text-sm">Rutas de aprendizaje personalizadas generadas por IA local en el Edge Node</p>
      </div>
      <div class="bg-white rounded-xl shadow-md p-6">
        <div class="text-3xl mb-3">&#x26A1;</div>
        <h3 class="font-semibold text-lg mb-2">Sincronización Delta</h3>
        <p class="text-gray-600 text-sm">Protocolo de 5 fases que minimiza el uso de datos en redes 2G/3G</p>
      </div>
    </div>

    <div class="flex gap-4 justify-center">
      <router-link to="/login"
        class="bg-emerald-600 text-white px-8 py-3 rounded-lg font-semibold hover:bg-emerald-700">
        Comenzar
      </router-link>
      <router-link to="/offline"
        class="border-2 border-emerald-600 text-emerald-700 px-8 py-3 rounded-lg font-semibold hover:bg-emerald-50">
        Modo Offline
      </router-link>
    </div>
  </div>
</template>
