import axios from 'axios'
import { get, set, del } from 'idb-keyval'

const API_GATEWAY = import.meta.env.VITE_API_GATEWAY || ''

const api = axios.create({
  baseURL: `${API_GATEWAY}/api`,
  timeout: 15000,
  headers: { 'Content-Type': 'application/json' },
})

let authToken = null
let isOnline = navigator.onLine

api.interceptors.request.use(async config => {
  if (authToken) {
    config.headers.Authorization = `Bearer ${authToken}`
  }

  if (!navigator.onLine && config.method === 'get') {
    const cached = await get(config.url)
    if (cached) {
      config.adapter = () => Promise.resolve({
        data: cached,
        status: 200,
        statusText: 'OK (offline)',
        headers: {},
        config,
      })
    }
  }

  return config
})

api.interceptors.response.use(
  async response => {
    if (response.config.method === 'get' && response.status === 200) {
      await set(response.config.url, response.data)
    }
    return response
  },
  async error => {
    if (!navigator.onLine && error.config?.method === 'get') {
      const cached = await get(error.config.url)
      if (cached) {
        return { data: cached, status: 200, statusText: 'OK (offline cache)' }
      }
    }
    return Promise.reject(error)
  }
)

export function setToken(token) {
  authToken = token
  if (token) {
    localStorage.setItem('auth_token', token)
  } else {
    localStorage.removeItem('auth_token')
  }
}

export function restoreToken() {
  authToken = localStorage.getItem('auth_token')
  return authToken
}

export function clearCache() {
  return new Promise((resolve, reject) => {
    if ('caches' in window) {
      caches.keys().then(names => {
        Promise.all(names.map(n => caches.delete(n))).then(resolve)
      })
    } else {
      resolve()
    }
  })
}

export default api
