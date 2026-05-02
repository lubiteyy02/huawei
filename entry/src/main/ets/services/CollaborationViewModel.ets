import { CollaborationDataService, type CollaborationContact, type CollaborationMessageThread, type CollaborationMusicItem, type CollaborationContinuationTask } from './CollaborationDataService'
import type { CollaborationBackendConfig, MusicStateSnapshot } from './CollaborationApiService'
import type { ContactBulkItem } from './RealContactsService'
import { CollaborationSyncSocketService, type CollaborationSyncEvent, type CollaborationSyncEventListener } from './CollaborationSyncSocketService'
import { RealMusicBridgeService } from './RealMusicBridgeService'

export class CollaborationViewModel {
  private static instance: CollaborationViewModel | null = null
  private readonly service: CollaborationDataService = CollaborationDataService.getInstance()
  private readonly socketService: CollaborationSyncSocketService = CollaborationSyncSocketService.getInstance()
  private readonly socketListener: CollaborationSyncEventListener = (event: CollaborationSyncEvent): void => {
    this.handleSyncEvent(event)
  }
  private musicBridge: RealMusicBridgeService | null = null

  static getInstance(): CollaborationViewModel {
    if (!CollaborationViewModel.instance) {
      CollaborationViewModel.instance = new CollaborationViewModel()
    }
    return CollaborationViewModel.instance
  }

  configureBackend(config: CollaborationBackendConfig): void {
    this.service.configureBackend(config)
    this.service.setBackendMode(true)
    if (config.baseUrl && config.deviceId && config.userId) {
      this.socketService.connect(config.baseUrl.replace('http', 'ws') + '/api/v1/sync/ws', config.userId, config.deviceId)
      this.socketService.addListener(this.socketListener)
    }
  }

  private handleSyncEvent(event: CollaborationSyncEvent): void {
    void event
  }

  async loadContacts(): Promise<CollaborationContact[]> {
    return this.service.getContacts()
  }

  async loadMessages(): Promise<CollaborationMessageThread[]> {
    return this.service.getMessageThreads()
  }

  async loadMusic(): Promise<CollaborationMusicItem[]> {
    return this.service.getMusicItems()
  }

  async loadContinuation(): Promise<CollaborationContinuationTask[]> {
    return this.service.getContinuationTasks()
  }

  async loadOverview(): Promise<import('./CollaborationDataService').CollaborationOverview> {
    return this.service.getOverview()
  }

  async syncMusic(songId: number, playing: boolean, position: number): Promise<boolean> {
    return this.service.syncMusicState(songId, playing, position)
  }

  async handoverMusic(songId: number, position: number, target: string): Promise<boolean> {
    return this.service.handoverMusic(songId, position, target)
  }

  async uploadContacts(items: ContactBulkItem[]): Promise<boolean> {
    return this.service.bulkUploadContacts(items)
  }

  async createMessage(name: string, preview: string): Promise<boolean> {
    return this.service.createMessage(name, preview)
  }

  async navigationHandover(name: string, address: string, latitude: number, longitude: number): Promise<boolean> {
    return this.service.navigationHandover(name, address, latitude, longitude)
  }

  async loadMusicState(): Promise<MusicStateSnapshot | null> {
    return this.service.getMusicState()
  }

  async pushSharedLog(message: string, sourceLabel: string): Promise<string[] | null> {
    return this.service.addLog(message, sourceLabel)
  }

  getDeviceId(): string {
    return this.service.getDeviceId()
  }

  async updateContactTag(id: number, tag: string): Promise<boolean> {
    return this.service.updateContactTag(id, tag)
  }

  async markMessageRead(threadId: number): Promise<boolean> {
    return this.service.markMessageRead(threadId)
  }

  async resumeContinuation(continuationId: number): Promise<boolean> {
    return this.service.resumeContinuation(continuationId)
  }

  onSyncEvent(listener: (event: CollaborationSyncEvent) => void): void {
    this.socketService.addListener(listener)
  }

  offSyncEvent(listener: (event: CollaborationSyncEvent) => void): void {
    this.socketService.removeListener(listener)
  }
}
