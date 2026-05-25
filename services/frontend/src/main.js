import { createApp, h } from 'vue'
import { createInertiaApp } from '@inertiajs/vue3'
import { createPinia } from 'pinia'
import { router } from './router'
import App from './App.vue'

createInertiaApp({
  resolve: name => {
    const pages = import.meta.glob('./pages/**/*.vue', { eager: true })
    return pages[`./pages/${name}.vue`]
  },
  setup({ el, App: InertiaApp, props, plugin }) {
    const app = createApp({ render: () => h(InertiaApp, props) })
    app.use(plugin)
    app.use(createPinia())
    app.use(router)
    app.mount(el)
  },
  title: title => title ? `${title} - EduConnect Rural` : 'EduConnect Rural',
})
