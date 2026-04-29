import http from '@ohos.net.http'
import type {
  CollaborationContact,
  CollaborationMessageThread,
  CollaborationMusicItem,
  CollaborationContinuationTask,
  CollaborationOverview
} from './CollaborationDataService'

export interface CollaborationSyncPayload<T> {
  code: number;
  message: string;
  data: T;
}

export interface CollaborationSyncConfig {
  baseUrl: string;
  deviceId: string;
  userId: string;
}

interface MusicStateRequest {
  userId: string;
  deviceId: string;
  songId: number;
  playing: boolean;
  position: number;
  updatedAt: string;
}

interface VersionResponse {
  version: number;
}

const defaultConfig: CollaborationSyncConfig = {
  baseUrl: 'http://192.168.26.191:3002',
  deviceId: 'car-001',
  userId: '10001'
}

export class CollaborationApiService {
  private static instance: CollaborationApiService | null = null
  private config: CollaborationSyncConfig = defaultConfig

  static getInstance(): CollaborationApiService {
    if (!CollaborationApiService.instance) {
      CollaborationApiService.instance = new CollaborationApiService()
    }
    return CollaborationApiService.instance
  }

  configure(config: Partial<CollaborationSyncConfig>): void {
    this.config = {
      baseUrl: config.baseUrl ?? this.config.baseUrl,
      deviceId: config.deviceId ?? this.config.deviceId,
      userId: config.userId ?? this.config.userId
    }
  }

  private buildUrl(path: string): string {
    return `${this.config.baseUrl}${path}`
  }

  private async getJson<T>(path: string): Promise<T | null> {
    const client = http.createHttp()
    try {
      const response = await client.request(this.buildUrl(path), {
        method: http.RequestMethod.GET,
        header: {
          'Content-Type': 'application/json',
          'X-Device-Id': this.config.deviceId,
          'X-User-Id': this.config.userId
        }
      })
      const result = response.result
      if (typeof result === 'string') {
        return JSON.parse(result) as T
      }
      return result as T
    } catch {
      return null
    } finally {
      client.destroy()
    }
  }

  private async postJson<T>(path: string, body: string): Promise<T | null> {
    const client = http.createHttp()
    try {
      const response = await client.request(this.buildUrl(path), {
        method: http.RequestMethod.POST,
        header: {
          'Content-Type': 'application/json',
          'X-Device-Id': this.config.deviceId,
          'X-User-Id': this.config.userId
        },
        extraData: body
      })
      const result = response.result
      if (typeof result === 'string') {
        return JSON.parse(result) as T
      }
      return result as T
    } catch {
      return null
    } finally {
      client.destroy()
    }
  }

  async getOverview(): Promise<CollaborationOverview | null> {
    const res = await this.getJson<CollaborationSyncPayload<CollaborationOverview>>('/api/sync/overview')
    return res && res.code === 0 ? res.data : null
  }

  async getContacts(): Promise<CollaborationContact[] | null> {
    const res = await this.getJson<CollaborationSyncPayload<CollaborationContact[]>>('/api/sync/contacts')
    return res && res.code === 0 ? res.data : null
  }

  async getMessageThreads(): Promise<CollaborationMessageThread[] | null> {
    const res = await this.getJson<CollaborationSyncPayload<CollaborationMessageThread[]>>('/api/sync/messages')
    return res && res.code === 0 ? res.data : null
  }

  async getMusicItems(): Promise<CollaborationMusicItem[] | null> {
    const res = await this.getJson<CollaborationSyncPayload<CollaborationMusicItem[]>>('/api/sync/music/library')
    return res && res.code === 0 ? res.data : null
  }

  async getContinuationTasks(): Promise<CollaborationContinuationTask[] | null> {
    const res = await this.getJson<CollaborationSyncPayload<CollaborationContinuationTask[]>>('/api/sync/continuation/list')
    return res && res.code === 0 ? res.data : null
  }

  async syncMusicState(songId: number, playing: boolean, position: number): Promise<boolean> {
    const body: MusicStateRequest = {
      userId: this.config.userId,
      deviceId: this.config.deviceId,
      songId,
      playing,
      position,
      updatedAt: new Date().toISOString()
    }
    const res = await this.postJson<CollaborationSyncPayload<VersionResponse>>('/api/sync/music/state', JSON.stringify(body))
    return !!(res && res.code === 0)
  }
}
