import { common } from '@kit.AbilityKit'
import { avSession } from '@kit.AVSessionKit'

export class RealMusicSessionSnapshot {
  songId: number = 0
  title: string = ''
  artist: string = ''
  playing: boolean = false
  position: number = 0
  sourceDevice: string = 'phone'
}

export type RealMusicSessionListener = (snapshot: RealMusicSessionSnapshot) => void

export class SessionUpdate {
  songId: number = -1
  title: string = ''
  artist: string = ''
  playing: boolean = false
  position: number = -1
  sourceDevice: string = ''
}

interface PlaybackPositionValue {
  elapsedTime: number;
}

interface PlaybackStateValue {
  state: number;
  position: PlaybackPositionValue;
}

interface ConnectionStateValue {
  state: number;
}

interface MetadataValue {
  title: string;
  artist: string;
}

export class RealMusicSessionService {
  private static instance: RealMusicSessionService | null = null
  private session: avSession.AVSession | null = null
  private listeners: RealMusicSessionListener[] = []
  private currentSnapshot: RealMusicSessionSnapshot = new RealMusicSessionSnapshot()
  private initialized: boolean = false

  static getInstance(): RealMusicSessionService {
    if (!RealMusicSessionService.instance) {
      RealMusicSessionService.instance = new RealMusicSessionService()
    }
    return RealMusicSessionService.instance
  }

  async initialize(context: common.Context): Promise<void> {
    if (this.initialized) {
      return
    }
    this.session = await avSession.createAVSession(context, 'MusicSession', 'audio')
    await this.session.activate()
    this.initialized = true
  }

  setSnapshot(partial: SessionUpdate): void {
    if (partial.songId >= 0) {
      this.currentSnapshot.songId = partial.songId
    }
    if (partial.title !== '') {
      this.currentSnapshot.title = partial.title
    }
    if (partial.artist !== '') {
      this.currentSnapshot.artist = partial.artist
    }
    this.currentSnapshot.playing = partial.playing
    if (partial.position >= 0) {
      this.currentSnapshot.position = partial.position
    }
    if (partial.sourceDevice !== '') {
      this.currentSnapshot.sourceDevice = partial.sourceDevice
    }
    this.emit()
  }

  updatePlaybackState(state: PlaybackStateValue): void {
    this.currentSnapshot.playing = state.state === 0
    this.currentSnapshot.position = state.position.elapsedTime
    this.emit()
  }

  updateConnectionState(state: ConnectionStateValue): void {
    this.currentSnapshot.sourceDevice = state.state === 0 ? 'phone' : 'unknown'
    this.emit()
  }

  getSnapshot(): RealMusicSessionSnapshot {
    return this.currentSnapshot
  }

  addListener(listener: RealMusicSessionListener): void {
    this.listeners.push(listener)
  }

  removeListener(listener: RealMusicSessionListener): void {
    const index = this.listeners.indexOf(listener)
    if (index >= 0) {
      this.listeners.splice(index, 1)
    }
  }

  private emit(): void {
    this.listeners.forEach((listener) => listener(this.currentSnapshot))
  }

  simulatePhonePlaybackChange(partial: SessionUpdate): void {
    this.setSnapshot(partial)
  }

  async syncToSession(): Promise<void> {
    if (!this.session) {
      return
    }
    const playbackState: avSession.AVPlaybackState = {
      state: this.currentSnapshot.playing ? avSession.PlaybackState.PLAYBACK_STATE_PLAY : avSession.PlaybackState.PLAYBACK_STATE_PAUSE,
      position: {
        elapsedTime: this.currentSnapshot.position,
        updateTime: Date.now()
      }
    }
    const metadata: avSession.AVMetadata = {
      assetId: this.currentSnapshot.songId.toString(),
      title: this.currentSnapshot.title,
      artist: this.currentSnapshot.artist
    }
    await this.session.setAVPlaybackState(playbackState)
    await this.session.setAVMetadata(metadata)
  }

  async destroy(): Promise<void> {
    if (this.session) {
      await this.session.deactivate()
      await this.session.destroy()
      this.session = null
      this.initialized = false
    }
  }
}
