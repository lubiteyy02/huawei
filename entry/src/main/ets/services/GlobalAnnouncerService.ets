import { CollaborationViewModel } from './CollaborationViewModel'
import { CollaborationBackendConfig } from './CollaborationApiService'
import type { CollaborationSyncEvent, CollaborationSyncEventListener } from './CollaborationSyncSocketService'
import { RealTtsService } from './RealTtsService'
import deviceInfo from '@ohos.deviceInfo'
import router from '@ohos.router'

interface NavDestination {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  category: string;
}

/**
 * 车机端常驻持有的「待续接音乐申请」结构。
 * 写入 AppStorage 'pendingMusicHandover'，由 CollaborationMusicPage 通过 @StorageLink 读取。
 * 这样即便用户尚未进入音乐同步页面，handover 事件也不会丢失。
 */
export interface PendingMusicHandover {
  songId: number;
  position: number;
  title: string;
  artist: string;
  receivedAt: string;
}

/**
 * 车机端常驻持有的「待续接导航申请」结构。
 * 写入 AppStorage 'pendingNavHandover'，由 CollaborationResumePage 通过 @StorageLink 读取。
 */
export interface PendingNavHandover {
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  receivedAt: string;
}

const MUSIC_HANDOVER_META: PendingMusicHandover[] = [
  { songId: 1, position: 0, title: '发如雪', artist: '周杰伦', receivedAt: '' },
  { songId: 2, position: 0, title: '听妈妈的话', artist: '周杰伦', receivedAt: '' },
  { songId: 3, position: 0, title: '以父之名', artist: '周杰伦', receivedAt: '' }
];

export class GlobalAnnouncerService {
  private static instance: GlobalAnnouncerService | null = null
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance()
  private readonly tts: RealTtsService = RealTtsService.getInstance()
  private listener: CollaborationSyncEventListener | null = null
  private initialized: boolean = false
  private lastSpokenId: number = -1

  static getInstance(): GlobalAnnouncerService {
    if (!GlobalAnnouncerService.instance) {
      GlobalAnnouncerService.instance = new GlobalAnnouncerService()
    }
    return GlobalAnnouncerService.instance
  }

  init(): void {
    if (this.initialized) return
    this.initialized = true
    this.bootstrapBackend()
    this.listener = (event: CollaborationSyncEvent): void => { this.handle(event) }
    this.viewModel.onSyncEvent(this.listener)
    console.info('[GlobalAnnouncer] initialized')
  }

  private bootstrapBackend(): void {
    // 优先读 AppStorage 'collab.role'（CollaborationModule 切换按钮写入的），
    // 否则按 deviceInfo.deviceType 自动判定。两台手机模拟器演示时可手动切换。
    const forced = AppStorage.get<string>('collab.role') ?? ''
    let isCar: boolean
    let type = ''
    if (forced === 'car') {
      isCar = true
    } else if (forced === 'phone') {
      isCar = false
    } else {
      try {
        type = deviceInfo.deviceType ?? ''
      } catch (_) {
        type = ''
      }
      isCar = type === 'tablet' || type === 'car' || type === '2in1'
    }
    const cfg = new CollaborationBackendConfig()
    cfg.baseUrl = 'http://10.0.2.2:3002'
    cfg.deviceId = isCar ? 'car-001' : 'phone-001'
    cfg.userId = '10001'
    this.viewModel.configureBackend(cfg)
    console.info(`[GlobalAnnouncer] backend configured forced=${forced} deviceType=${type} role=${isCar ? 'car' : 'phone'}`)
  }

  private handle(event: CollaborationSyncEvent): void {
    const myId = this.viewModel.getDeviceId()
    if (myId !== 'car-001') return
    if (event.sourceDeviceId === myId) return

    if (event.type === 'message.created') {
      const threadId = typeof event.payload.threadId === 'number' ? event.payload.threadId : -1
      if (threadId === this.lastSpokenId) return
      this.lastSpokenId = threadId
      const name = typeof event.payload.name === 'string' ? event.payload.name : ''
      const preview = typeof event.payload.preview === 'string' ? event.payload.preview : ''
      if (name === '' || preview === '') return
      console.info(`[GlobalAnnouncer] speaking message from ${name}`)
      void this.tts.speak(`收到一条来自${name}的短信。内容是：${preview}`)
      return
    }

    if (event.type === 'music.handover') {
      // 车机端常驻接收：把 handover 申请写入 AppStorage，
      // CollaborationMusicPage 用 @StorageLink 读取，避免必须先进入页面才能收到。
      const songId = typeof event.payload.songId === 'number' ? event.payload.songId : -1
      const position = typeof event.payload.position === 'number' ? event.payload.position : 0
      const target = typeof event.payload.target === 'string' ? event.payload.target : ''
      if (songId < 0 || target !== myId) return
      const meta = MUSIC_HANDOVER_META.find((m) => m.songId === songId)
      const pending: PendingMusicHandover = {
        songId,
        position,
        title: meta ? meta.title : `曲目 #${songId}`,
        artist: meta ? meta.artist : '',
        receivedAt: event.timestamp
      }
      AppStorage.setOrCreate<PendingMusicHandover>('pendingMusicHandover', pending)
      console.info(`[GlobalAnnouncer] music handover stored: ${pending.title} @ ${position}ms`)
      void this.tts.speak(`收到来自手机端的音乐续接申请，${pending.title}。请到协同模块的音乐同步页确认。`)
      return
    }

    if (event.type === 'navigation.handover') {
      // 车机端常驻接收：写 AppStorage 'pendingNavHandover'，
      // CollaborationResumePage 通过 @StorageLink 自动反映，避免必须先进页才能收到。
      const name = typeof event.payload.name === 'string' ? event.payload.name : ''
      const address = typeof event.payload.address === 'string' ? event.payload.address : ''
      const latitude = typeof event.payload.latitude === 'number' ? event.payload.latitude : 0
      const longitude = typeof event.payload.longitude === 'number' ? event.payload.longitude : 0
      if (name === '' || latitude === 0 || longitude === 0) return
      const pending: PendingNavHandover = { name, address, latitude, longitude, receivedAt: event.timestamp }
      AppStorage.setOrCreate<PendingNavHandover>('pendingNavHandover', pending)
      console.info(`[GlobalAnnouncer] navigation handover stored -> ${name}`)
      void this.tts.speak(`收到来自手机端的导航续接申请，目的地：${name}。请在导航续接页确认。`)
      return
    }
  }
}
