import { CacheService } from './CacheService'
import { CollaborationApiService } from './CollaborationApiService'
import type { CollaborationBackendConfig, MusicStateSnapshot } from './CollaborationApiService'
import type { ContactBulkItem } from './RealContactsService'

export interface CollaborationContact {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

export interface CollaborationMessageThread {
  id: number;
  name: string;
  preview: string;
  time: string;
  unread: number;
}

export interface CollaborationMusicItem {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

export interface CollaborationContinuationTask {
  id: number;
  module: string;
  title: string;
  detail: string;
  device: string;
}

export class BackendFetcher<T> {
  readonly fetch: () => Promise<T | null>;

  constructor(fetch: () => Promise<T | null>) {
    this.fetch = fetch;
  }
}

export interface CollaborationOverview {
  phoneName: string;
  carName: string;
  syncStatus: string;
  lastSyncTime: string;
  unreadMessages: number;
  contactCount: number;
  musicCount: number;
  continuationCount: number;
  logs: string[];
}

export interface ActiveDevice {
  deviceId: string;
  role: string;     // 'phone' | 'car'
  online: boolean;
  lastSeen: string;
}

// 兜底默认值：后端无数据 / 离线时使用，全部为空，避免显示假数据
const defaultOverview: CollaborationOverview = {
  phoneName: '',
  carName: '',
  syncStatus: '连接中',
  lastSyncTime: '',
  unreadMessages: 0,
  contactCount: 0,
  musicCount: 0,
  continuationCount: 0,
  logs: []
}

const defaultContacts: CollaborationContact[] = []
const defaultThreads: CollaborationMessageThread[] = []
const defaultMusic: CollaborationMusicItem[] = []
const defaultContinuation: CollaborationContinuationTask[] = []

export class CollaborationDataService {
  private static instance: CollaborationDataService | null = null
  private readonly apiService: CollaborationApiService = CollaborationApiService.getInstance()
  private readonly cacheService: CacheService = CacheService.getInstance()
  private useBackend: boolean = false

  setBackendMode(enabled: boolean): void {
    this.useBackend = enabled
  }

  configureBackend(config: CollaborationBackendConfig): void {
    this.apiService.configure(config)
  }

  updateContactTag(id: number, tag: string): Promise<boolean> {
    return this.apiService.updateContactTag(id, tag)
  }

  markMessageRead(threadId: number): Promise<boolean> {
    return this.apiService.markMessageRead(threadId)
  }

  resumeContinuation(continuationId: number): Promise<boolean> {
    return this.apiService.resumeContinuation(continuationId)
  }

  static getInstance(): CollaborationDataService {
    if (!CollaborationDataService.instance) {
      CollaborationDataService.instance = new CollaborationDataService()
    }
    return CollaborationDataService.instance
  }

  private async readCached<T>(key: string, fallback: T): Promise<T> {
    try {
      const cached = await this.cacheService.get<T>(key)
      return cached ?? fallback
    } catch {
      return fallback
    }
  }

  private async getFromBackendOrCache<T>(backendFetcher: BackendFetcher<T>, cacheKey: string, fallback: T): Promise<T> {
    if (this.useBackend) {
      const backendData = await backendFetcher.fetch()
      if (backendData !== null) {
        await this.cacheService.set(cacheKey, backendData, 1000 * 60 * 30)
        return backendData
      }
      return this.readCached<T>(cacheKey, fallback)
    }
    return this.readCached<T>(cacheKey, fallback)
  }

  /**
   * 在线设备列表：纯后端数据，不走缓存（实时性强、数据量小）。
   * 后端没响应就返回空数组，调用方按 fallback 渲染「未连接」。
   */
  async getActiveDevices(): Promise<ActiveDevice[]> {
    if (!this.useBackend) return []
    const data = await this.apiService.getActiveDevices()
    return data ?? []
  }

  async getOverview(): Promise<CollaborationOverview> {
    return this.getFromBackendOrCache<CollaborationOverview>(
      new BackendFetcher<CollaborationOverview>(() => this.apiService.getOverview()),
      'collaboration_overview',
      defaultOverview
    )
  }

  async getContacts(): Promise<CollaborationContact[]> {
    return this.getFromBackendOrCache<CollaborationContact[]>(
      new BackendFetcher<CollaborationContact[]>(() => this.apiService.getContacts()),
      'collaboration_contacts',
      defaultContacts
    )
  }

  async getMessageThreads(): Promise<CollaborationMessageThread[]> {
    return this.getFromBackendOrCache<CollaborationMessageThread[]>(
      new BackendFetcher<CollaborationMessageThread[]>(() => this.apiService.getMessageThreads()),
      'collaboration_message_threads',
      defaultThreads
    )
  }

  async getMusicItems(): Promise<CollaborationMusicItem[]> {
    return this.getFromBackendOrCache<CollaborationMusicItem[]>(
      new BackendFetcher<CollaborationMusicItem[]>(() => this.apiService.getMusicItems()),
      'collaboration_music_items',
      defaultMusic
    )
  }

  async getContinuationTasks(): Promise<CollaborationContinuationTask[]> {
    return this.getFromBackendOrCache<CollaborationContinuationTask[]>(
      new BackendFetcher<CollaborationContinuationTask[]>(() => this.apiService.getContinuationTasks()),
      'collaboration_continuation_tasks',
      defaultContinuation
    )
  }

  async syncNow(message: string): Promise<string[]> {
    return [`${message} · ${new Date().toLocaleTimeString()}`]
  }

  async syncMusicState(songId: number, playing: boolean, position: number): Promise<boolean> {
    if (this.useBackend) {
      return this.apiService.syncMusicState(songId, playing, position)
    }
    return true
  }

  async handoverMusic(songId: number, position: number, target: string): Promise<boolean> {
    if (this.useBackend) {
      return this.apiService.handoverMusic(songId, position, target)
    }
    return true
  }

  async bulkUploadContacts(items: ContactBulkItem[]): Promise<boolean> {
    if (this.useBackend) {
      return this.apiService.bulkUploadContacts(items)
    }
    return true
  }

  async createMessage(name: string, preview: string): Promise<boolean> {
    if (this.useBackend) {
      return this.apiService.createMessage(name, preview)
    }
    return true
  }

  async navigationHandover(name: string, address: string, latitude: number, longitude: number): Promise<boolean> {
    if (this.useBackend) {
      return this.apiService.navigationHandover(name, address, latitude, longitude)
    }
    return true
  }

  async getMusicState(): Promise<MusicStateSnapshot | null> {
    if (this.useBackend) {
      return this.apiService.getMusicState()
    }
    return null
  }

  async addLog(message: string, sourceLabel: string): Promise<string[] | null> {
    if (this.useBackend) {
      return this.apiService.addLog(message, sourceLabel)
    }
    return null
  }

  getDeviceId(): string {
    return this.apiService.getDeviceId()
  }
}
