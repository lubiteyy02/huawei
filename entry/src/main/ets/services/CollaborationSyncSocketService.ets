import webSocket from '@ohos.net.webSocket'

export type CollaborationSyncEventType = 'contact.updated' | 'message.read' | 'message.created' | 'music.stateChanged' | 'music.handover' | 'continuation.resumed' | 'navigation.handover' | 'overview.refreshed'

export interface CollaborationSyncEvent {
  type: CollaborationSyncEventType;
  sourceDeviceId?: string;
  userId?: string;
  payload: Record<string, string | number | boolean | null>;
  timestamp: string;
}

export type CollaborationSyncEventListener = (event: CollaborationSyncEvent) => void

interface CollaborationSocketClient {
  connect(url: string, callback: (err: object | null, data: boolean) => void): void;
  send(data: string | ArrayBuffer, callback: (err: object | null, data: boolean) => void): void;
  close(callback: (err: object | null, data: boolean) => void): void;
  on(type: string, callback: (data: object, value?: object) => void): void;
  off(type: string, callback: (data: object) => void): void;
}

interface SyncEnvelope {
  type?: string;
  event?: CollaborationSyncEvent;
  targetUserId?: string;
  targetDeviceId?: string;
}

export class CollaborationSyncSocketService {
  private static instance: CollaborationSyncSocketService | null = null
  private readonly listeners: CollaborationSyncEventListener[] = []
  private client: CollaborationSocketClient | null = null
  private userId: string = ''
  private deviceId: string = ''
  private url: string = ''
  private connected: boolean = false
  private reconnectTimer: number = -1
  private manualClose: boolean = false

  static getInstance(): CollaborationSyncSocketService {
    if (!CollaborationSyncSocketService.instance) {
      CollaborationSyncSocketService.instance = new CollaborationSyncSocketService()
    }
    return CollaborationSyncSocketService.instance
  }

  connect(url: string, userId: string, deviceId: string): void {
    this.userId = userId
    this.deviceId = deviceId
    this.url = url
    this.manualClose = false

    if (!this.client) {
      this.client = webSocket.createWebSocket() as CollaborationSocketClient
      const client = this.client
      client.on('open', () => {
        console.info('[SyncSocket] open')
        this.connected = true
        const subscribeMessage = JSON.stringify({
          type: 'subscribe',
          userId: this.userId,
          deviceId: this.deviceId
        })
        client.send(subscribeMessage, () => {
          return
        })
      })
      client.on('message', (_err: object, value?: object) => {
        const raw = typeof value === 'string' ? value as string : ''
        if (!raw) {
          return
        }
        try {
          const envelope = JSON.parse(raw) as SyncEnvelope
          if (envelope.type === 'sync-event' && envelope.event) {
            this.emit(envelope.event)
          }
        } catch {
          return
        }
      })
      client.on('close', (_err: object) => {
        console.warn('[SyncSocket] closed, scheduling reconnect')
        this.connected = false
        this.scheduleReconnect()
      })
      client.on('error', (_err: object) => {
        console.warn('[SyncSocket] error, scheduling reconnect')
        this.connected = false
        this.scheduleReconnect()
      })
    }

    const client = this.client
    client.connect(url, (_err: object | null, _data: boolean) => {
      return
    })
  }

  private scheduleReconnect(): void {
    if (this.manualClose) return
    if (this.reconnectTimer !== -1) return
    this.reconnectTimer = setTimeout((): void => {
      this.reconnectTimer = -1
      if (this.manualClose || this.connected) return
      console.info('[SyncSocket] reconnecting...')
      if (this.client && this.url !== '') {
        this.client.connect(this.url, (_err: object | null, _data: boolean) => {
          return
        })
      }
    }, 3000)
  }

  addListener(listener: CollaborationSyncEventListener): void {
    this.listeners.push(listener)
  }

  removeListener(listener: CollaborationSyncEventListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  emit(event: CollaborationSyncEvent): void {
    this.listeners.forEach((listener) => listener(event))
  }

  close(): void {
    this.manualClose = true
    if (this.reconnectTimer !== -1) {
      clearTimeout(this.reconnectTimer)
      this.reconnectTimer = -1
    }
    if (this.client) {
      this.client.close(() => {
        return
      })
    }
    this.listeners.splice(0, this.listeners.length)
    this.client = null
    this.connected = false
  }
}


