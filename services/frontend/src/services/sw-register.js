export function registerServiceWorker() {
  if ('serviceWorker' in navigator) {
    navigator.serviceWorker
      .register('/sw.js')
      .then(registration => {
        console.log('SW registered:', registration.scope)

        registration.addEventListener('updatefound', () => {
          const newWorker = registration.installing
          newWorker.addEventListener('statechange', () => {
            if (newWorker.state === 'installed' && navigator.serviceWorker.controller) {
              showUpdateNotification(registration)
            }
          })
        })
      })
      .catch(error => {
        console.error('SW registration failed:', error)
      })

    navigator.serviceWorker.addEventListener('message', event => {
      if (event.data?.type === 'CACHE_UPDATED') {
        console.log('Cache actualizado:', event.data.url)
      }
    })
  }
}

function showUpdateNotification(registration) {
  if (confirm('Nueva versión disponible. ¿Actualizar?')) {
    registration.waiting?.postMessage({ type: 'SKIP_WAITING' })
    window.location.reload()
  }
}

export async function checkOnlineStatus() {
  if (!navigator.onLine) return false

  try {
    const response = await fetch('/api/health', {
      method: 'GET',
      cache: 'no-store',
    })
    return response.ok
  } catch {
    return false
  }
}

export function listenConnectivity(callback) {
  window.addEventListener('online', () => callback(true))
  window.addEventListener('offline', () => callback(false))
}
