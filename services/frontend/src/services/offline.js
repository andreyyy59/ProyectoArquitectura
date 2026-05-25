import { openDB, get, set, del, keys } from 'idb-keyval'

export const DB_KEYS = {
  CONTENTS: 'cached_contents',
  PROGRESS: 'offline_progress',
  XAPI_EVENTS: 'xapi_pending',
  AUTH: 'offline_auth',
  LEARNING_PATHS: 'cached_paths',
}

export class OfflineManager {
  async cacheContent(uuid, data) {
    const key = `${DB_KEYS.CONTENTS}:${uuid}`
    await set(key, { data, cachedAt: Date.now() })
  }

  async getCachedContent(uuid) {
    const key = `${DB_KEYS.CONTENTS}:${uuid}`
    return get(key)
  }

  async getCachedContents() {
    const allKeys = await keys()
    const contentKeys = allKeys.filter(k => k.startsWith(DB_KEYS.CONTENTS))
    const contents = []
    for (const k of contentKeys) {
      const val = await get(k)
      if (val) contents.push(val.data)
    }
    return contents
  }

  async saveProgress(userId, contentId, progress) {
    const key = `${DB_KEYS.PROGRESS}:${userId}:${contentId}`
    await set(key, { ...progress, lastUpdated: Date.now() })
  }

  async getProgress(userId, contentId) {
    const key = `${DB_KEYS.PROGRESS}:${userId}:${contentId}`
    return get(key)
  }

  async getAllOfflineProgress() {
    const allKeys = await keys()
    const progressKeys = allKeys.filter(k => k.startsWith(DB_KEYS.PROGRESS))
    const progress = []
    for (const k of progressKeys) {
      const val = await get(k)
      if (val) progress.push({ key: k, ...val })
    }
    return progress
  }

  async queueXapiEvent(event) {
    const id = `xapi:${Date.now()}:${Math.random().toString(36).substr(2, 9)}`
    await set(id, { event, queuedAt: Date.now() })
  }

  async getPendingXapiEvents() {
    const allKeys = await keys()
    const xapiKeys = allKeys.filter(k => k.startsWith('xapi:'))
    const events = []
    for (const k of xapiKeys) {
      const val = await get(k)
      if (val) events.push(val.event)
      await del(k)
    }
    return events
  }

  async cacheAuthToken(token, user) {
    await set(DB_KEYS.AUTH, { token, user, cachedAt: Date.now() })
  }

  async getCachedAuth() {
    return get(DB_KEYS.AUTH)
  }
}

export const offlineManager = new OfflineManager()
