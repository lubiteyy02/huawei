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

const defaultOverview: CollaborationOverview = {
  phoneName: 'Harmony Phone',
  carName: 'Harmony Car',
  syncStatus: '已连接',
  lastSyncTime: '刚刚',
  unreadMessages: 3,
  contactCount: 128,
  musicCount: 56,
  continuationCount: 2,
  logs: [
    '联系人：已同步 128 条',
    '短信：已同步最近 20 条会话',
    '音乐：已续接播放《七里香》',
    '应用续接：导航任务已同步到车机'
  ]
}

const defaultContacts: CollaborationContact[] = [
  { id: 1, name: '李明', phone: '138-0000-0001', tag: '常用' },
  { id: 2, name: '王婷', phone: '138-0000-0002', tag: '最近' },
  { id: 3, name: '张伟', phone: '138-0000-0003', tag: '收藏' }
]

const defaultThreads: CollaborationMessageThread[] = [
  { id: 1, name: '妈妈', preview: '路上注意安全，到家告诉我', time: '09:12', unread: 1 },
  { id: 2, name: '同事-小周', preview: '会议资料已经发到群里了', time: '08:40', unread: 0 },
  { id: 3, name: '物业', preview: '明天早上停水，请提前储水', time: '昨天', unread: 2 }
]

const defaultMusic: CollaborationMusicItem[] = [
  { id: 1, title: '七里香', artist: '周杰伦', progress: 64, device: '手机正在播放' },
  { id: 2, title: '稻香', artist: '周杰伦', progress: 22, device: '车机可续接' },
  { id: 3, title: '晴天', artist: '周杰伦', progress: 89, device: '最近播放' }
]

const defaultContinuation: CollaborationContinuationTask[] = [
  { id: 1, module: '导航', title: '去公司', detail: '已在手机上规划路线', device: '手机' },
  { id: 2, module: '音乐', title: '七里香', detail: '播放进度 01:08', device: '手机' }
]

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
