import api from './api'
import { openDB, get, set, del, keys } from 'idb-keyval'

const SYNC_INTERVAL = 30000
let syncTimer = null

export class SyncEngine {
  constructor() {
    this.isSyncing = false
    this.queue = []
    this.lastSyncAt = null
  }

  async init() {
    await this.loadQueue()
    this.startAutoSync()

    window.addEventListener('online', () => this.triggerSync())
  }

  async enqueue(entityType, entityId, operation, payload) {
    const event = {
      id: crypto.randomUUID(),
      entity_type: entityType,
      entity_id: entityId,
      operation,
      payload,
      client_timestamp: new Date().toISOString(),
      createdAt: Date.now(),
    }

    this.queue.push(event)
    await this.saveQueue()
    await set(`pending:${event.id}`, event)

    return event
  }

  async triggerSync() {
    if (this.isSyncing || this.queue.length === 0) return

    this.isSyncing = true

    try {
      const batch = this.queue.splice(0, 50)
      const response = await api.post('/sync/events', {
        edge_node_id: this.getNodeId(),
        events: batch,
      })

      if (response.data?.success) {
        for (const event of batch) {
          await del(`pending:${event.id}`)
        }
        this.lastSyncAt = new Date().toISOString()
        await set('lastSyncAt', this.lastSyncAt)
      } else {
        this.queue.unshift(...batch)
      }
    } catch (error) {
      this.queue.unshift(...this.queue.splice(0, 50))
      console.warn('Sync failed, events re-queued:', error.message)
    } finally {
      this.isSyncing = false
      await this.saveQueue()
    }
  }

  startAutoSync() {
    syncTimer = setInterval(() => {
      if (navigator.onLine) {
        this.triggerSync()
      }
    }, SYNC_INTERVAL)
  }

  stopAutoSync() {
    if (syncTimer) clearInterval(syncTimer)
  }

  async loadQueue() {
    const saved = await get('syncQueue')
    if (saved) this.queue = saved
  }

  async saveQueue() {
    await set('syncQueue', this.queue.slice(0, 500))
  }

  getNodeId() {
    return parseInt(localStorage.getItem('edge_node_id') || '1')
  }

  getQueueLength() {
    return this.queue.length
  }

  getLastSyncAt() {
    return this.lastSyncAt
  }
}

export const syncEngine = new SyncEngine()
