import { createApp } from 'vue'
import { createPinia } from 'pinia'
import { router } from './router'
import App from './App.vue'
import { restoreToken } from './services/api'
import './style.css'

restoreToken()

const app = createApp(App)
app.use(createPinia())
app.use(router)
app.mount('#app')
