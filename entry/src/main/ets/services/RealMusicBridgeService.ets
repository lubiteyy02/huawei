import { CollaborationViewModel } from './CollaborationViewModel'
import { RealMusicSessionService, RealMusicSessionSnapshot } from './RealMusicSessionService'

export class RealMusicBridgeService {
  private static instance: RealMusicBridgeService | null = null
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance()
  private readonly musicSession: RealMusicSessionService = RealMusicSessionService.getInstance()
  private syncEnabled: boolean = false

  static getInstance(): RealMusicBridgeService {
    if (!RealMusicBridgeService.instance) {
      RealMusicBridgeService.instance = new RealMusicBridgeService()
    }
    return RealMusicBridgeService.instance
  }

  enable(): void {
    this.syncEnabled = true
  }

  disable(): void {
    this.syncEnabled = false
  }

  updateFromSession(snapshot: RealMusicSessionSnapshot): void {
    if (!this.syncEnabled) {
      return
    }
    void this.viewModel.syncMusic(snapshot.songId, snapshot.playing, snapshot.position)
    void this.viewModel.pushSharedLog(`音乐状态变化：${snapshot.title}`, snapshot.sourceDevice)
  }

  getSessionService(): RealMusicSessionService {
    return this.musicSession
  }
}
