const CACHE_VERSION = 'v1'
const STATIC_CACHE = `educonnect-static-${CACHE_VERSION}`
const DYNAMIC_CACHE = `educonnect-dynamic-${CACHE_VERSION}`
const API_CACHE = `educonnect-api-${CACHE_VERSION}`

const STATIC_ASSETS = [
  '/',
  '/index.html',
  '/offline',
  '/manifest.json',
]

self.addEventListener('install', event => {
  event.waitUntil(
    caches.open(STATIC_CACHE).then(cache => {
      return cache.addAll(STATIC_ASSETS)
    })
  )
  self.skipWaiting()
})

self.addEventListener('activate', event => {
  event.waitUntil(
    caches.keys().then(keys => {
      return Promise.all(
        keys
          .filter(key => key !== STATIC_CACHE && key !== DYNAMIC_CACHE && key !== API_CACHE)
          .map(key => caches.delete(key))
      )
    })
  )
  self.clients.claim()
})

self.addEventListener('fetch', event => {
  const { request } = event
  const url = new URL(request.url)

  if (url.origin !== self.location.origin && !url.href.includes('/api/')) {
    return
  }

  if (request.method !== 'GET') {
    if (navigator.onLine === false) {
      event.respondWith(
        new Response(JSON.stringify({ error: 'offline', message: 'Sin conexión' }), {
          status: 503,
          headers: { 'Content-Type': 'application/json' },
        })
      )
    }
    return
  }

  if (url.pathname.startsWith('/api/')) {
    event.respondWith(networkFirstWithCache(request))
  } else if (STATIC_ASSETS.includes(url.pathname)) {
    event.respondWith(cacheFirst(request))
  } else {
    event.respondWith(networkFirstWithCache(request))
  }
})

async function cacheFirst(request) {
  const cached = await caches.match(request)
  if (cached) return cached

  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(STATIC_CACHE)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    return caches.match('/offline')
  }
}

async function networkFirstWithCache(request) {
  try {
    const response = await fetch(request)
    if (response.ok) {
      const cache = await caches.open(DYNAMIC_CACHE)
      cache.put(request, response.clone())
    }
    return response
  } catch {
    const cached = await caches.match(request)
    if (cached) {
      return new Response(cached.body, {
        ...cached,
        headers: new Headers({
          ...Object.fromEntries(cached.headers.entries()),
          'X-Offline-Cache': 'hit',
        }),
      })
    }
    return new Response(
      JSON.stringify({ error: 'offline', message: 'Contenido no disponible sin conexión' }),
      { status: 503, headers: { 'Content-Type': 'application/json' } }
    )
  }
}

self.addEventListener('message', event => {
  if (event.data?.type === 'SKIP_WAITING') {
    self.skipWaiting()
  }

  if (event.data?.type === 'CACHE_CONTENT') {
    const { url, data } = event.data
    caches.open(API_CACHE).then(cache => {
      cache.put(url, new Response(JSON.stringify(data)))
    })
  }
})
