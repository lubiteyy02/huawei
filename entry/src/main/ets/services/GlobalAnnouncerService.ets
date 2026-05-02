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
    let type = ''
    try {
      type = deviceInfo.deviceType ?? ''
    } catch (_) {
      type = ''
    }
    const isCar = type === 'tablet' || type === 'car' || type === '2in1'
    const cfg = new CollaborationBackendConfig()
    cfg.baseUrl = 'http://10.0.2.2:3002'
    cfg.deviceId = isCar ? 'car-001' : 'phone-001'
    cfg.userId = '10001'
    this.viewModel.configureBackend(cfg)
    console.info(`[GlobalAnnouncer] backend configured deviceType=${type} role=${isCar ? 'car' : 'phone'}`)
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

    if (event.type === 'navigation.handover') {
      const name = typeof event.payload.name === 'string' ? event.payload.name : ''
      const address = typeof event.payload.address === 'string' ? event.payload.address : ''
      const latitude = typeof event.payload.latitude === 'number' ? event.payload.latitude : 0
      const longitude = typeof event.payload.longitude === 'number' ? event.payload.longitude : 0
      if (name === '' || latitude === 0 || longitude === 0) return
      console.info(`[GlobalAnnouncer] navigation handover -> ${name} (${latitude},${longitude})`)
      const dest: NavDestination = { name, address, latitude, longitude, category: 'custom' }
      AppStorage.setOrCreate('shouldSwitchToNavigation', true)
      AppStorage.setOrCreate('navigationDestination', dest)
      AppStorage.setOrCreate('navTriggerVersion', Date.now())
      void this.tts.speak(`正在为您启动导航，目的地：${name}`)
      try {
        router.replaceUrl({ url: 'pages/Index' })
      } catch (e) {
        console.error(`[GlobalAnnouncer] router replace failed: ${e}`)
      }
      return
    }
  }
}
