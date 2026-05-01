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

export class CollaborationSyncConfig {
  baseUrl: string = '';
  deviceId: string = '';
  userId: string = '';

  constructor(baseUrl: string, deviceId: string, userId: string) {
    this.baseUrl = baseUrl;
    this.deviceId = deviceId;
    this.userId = userId;
  }
}

export class CollaborationBackendConfig {
  baseUrl: string | null = null;
  deviceId: string | null = null;
  userId: string | null = null;
}

class HttpRequestOptions {
  method: http.RequestMethod = http.RequestMethod.GET;
  header: Record<string, string> = {};
  extraData: string = '';
  connectTimeout: number = 5000;
  readTimeout: number = 5000;
}

class AddLogRequest {
  message: string = '';
  sourceLabel: string = '';
}

class ContactTagRequest {
  id: number = 0;
  tag: string = '';
}

class MessageReadRequest {
  threadId: number = 0;
}

class ContinuationResumeRequest {
  continuationId: number = 0;
}

class ContactTagResponse {
  version: number = 0;
}

class MessageReadResponse {
  version: number = 0;
}

class ContinuationResumeResponse {
  version: number = 0;
}

class MusicStateRequest {
  userId: string = '';
  deviceId: string = '';
  songId: number = 0;
  playing: boolean = false;
  position: number = 0;
  updatedAt: string = '';
}

class VersionResponse {
  version: number = 0;
}

class CollaborationLogResponse {
  version: number = 0;
  logs: string[] = [];
}

export class MusicStateSnapshot {
  songId: number = 0;
  playing: boolean = false;
  position: number = 0;
  updatedAt: string = '';
  title: string = '';
  artist: string = '';
  sourceDevice: string = '';
}

class MusicStateResponse {
  version: number = 0;
  musicState: MusicStateSnapshot = new MusicStateSnapshot();
}

const defaultConfig = new CollaborationSyncConfig(
  'http://192.168.26.191:3002',
  'car-001',
  '10001'
)

export class CollaborationApiService {
  private static instance: CollaborationApiService | null = null
  private config: CollaborationSyncConfig = defaultConfig

  static getInstance(): CollaborationApiService {
    if (!CollaborationApiService.instance) {
      CollaborationApiService.instance = new CollaborationApiService()
    }
    return CollaborationApiService.instance
  }

  configure(config: CollaborationBackendConfig): void {
    if (config.baseUrl !== null) {
      this.config.baseUrl = config.baseUrl
    }
    if (config.deviceId !== null) {
      this.config.deviceId = config.deviceId
    }
    if (config.userId !== null) {
      this.config.userId = config.userId
    }
  }

  private buildUrl(path: string): string {
    return `${this.config.baseUrl}${path}`
  }

  private async requestJson<T>(path: string, method: http.RequestMethod, body?: string): Promise<T | null> {
    const client = http.createHttp()
    try {
      const options = new HttpRequestOptions()
      options.method = method
      options.header = {
        'Content-Type': 'application/json',
        'X-Device-Id': this.config.deviceId,
        'X-User-Id': this.config.userId
      }
      options.extraData = body ?? ''

      const response = await client.request(this.buildUrl(path), options)
      if (typeof response.responseCode === 'number' && response.responseCode >= 400) {
        return null
      }

      const result = response.result
      if (typeof result === 'string') {
        try {
          return JSON.parse(result) as T
        } catch {
          return null
        }
      }
      return (result ?? null) as T | null
    } catch {
      return null
    } finally {
      client.destroy()
    }
  }

  async getOverview(): Promise<CollaborationOverview | null> {
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationOverview>>('/api/v1/sync/overview', http.RequestMethod.GET)
    return res && res.code === 0 ? res.data : null
  }

  async getContacts(): Promise<CollaborationContact[] | null> {
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationContact[]>>('/api/v1/sync/contacts', http.RequestMethod.GET)
    return res && res.code === 0 ? res.data : null
  }

  async updateContactTag(id: number, tag: string): Promise<boolean> {
    const request = new ContactTagRequest()
    request.id = id
    request.tag = tag
    const body = JSON.stringify(request)
    const res = await this.requestJson<CollaborationSyncPayload<ContactTagResponse>>('/api/v1/sync/contacts/tag', http.RequestMethod.POST, body)
    return !!(res && res.code === 0)
  }

  async getMessageThreads(): Promise<CollaborationMessageThread[] | null> {
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationMessageThread[]>>('/api/v1/sync/messages', http.RequestMethod.GET)
    return res && res.code === 0 ? res.data : null
  }

  async markMessageRead(threadId: number): Promise<boolean> {
    const request = new MessageReadRequest()
    request.threadId = threadId
    const body = JSON.stringify(request)
    const res = await this.requestJson<CollaborationSyncPayload<MessageReadResponse>>('/api/v1/sync/messages/read', http.RequestMethod.POST, body)
    return !!(res && res.code === 0)
  }

  async getMusicItems(): Promise<CollaborationMusicItem[] | null> {
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationMusicItem[]>>('/api/v1/sync/music/library', http.RequestMethod.GET)
    return res && res.code === 0 ? res.data : null
  }

  async getContinuationTasks(): Promise<CollaborationContinuationTask[] | null> {
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationContinuationTask[]>>('/api/v1/sync/continuation/list', http.RequestMethod.GET)
    return res && res.code === 0 ? res.data : null
  }

  async resumeContinuation(continuationId: number): Promise<boolean> {
    const request = new ContinuationResumeRequest()
    request.continuationId = continuationId
    const body = JSON.stringify(request)
    const res = await this.requestJson<CollaborationSyncPayload<ContinuationResumeResponse>>('/api/v1/sync/continuation/resume', http.RequestMethod.POST, body)
    return !!(res && res.code === 0)
  }

  async addLog(message: string, sourceLabel: string): Promise<string[] | null> {
    const body = new AddLogRequest()
    body.message = message
    body.sourceLabel = sourceLabel
    const res = await this.requestJson<CollaborationSyncPayload<CollaborationLogResponse>>('/api/v1/sync/log', http.RequestMethod.POST, JSON.stringify(body))
    return res && res.code === 0 ? res.data.logs : null
  }

  getDeviceId(): string {
    return this.config.deviceId
  }

  async getMusicState(): Promise<MusicStateSnapshot | null> {
    const res = await this.requestJson<CollaborationSyncPayload<MusicStateSnapshot>>('/api/v1/sync/music/state', http.RequestMethod.GET)
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
    const res = await this.requestJson<CollaborationSyncPayload<MusicStateResponse>>('/api/v1/sync/music/state', http.RequestMethod.POST, JSON.stringify(body))
    return !!(res && res.code === 0)
  }
}


