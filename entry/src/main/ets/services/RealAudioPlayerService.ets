import { media } from '@kit.MediaKit'
import { common } from '@kit.AbilityKit'
import { BusinessError } from '@kit.BasicServicesKit'
import { audio } from '@kit.AudioKit'

export class AudioPlayerSnapshot {
  songId: number = 0
  title: string = ''
  artist: string = ''
  playing: boolean = false
  position: number = 0
  duration: number = 0
}

export type AudioPlayerListener = (snapshot: AudioPlayerSnapshot) => void

interface TrackMeta {
  id: number
  title: string
  artist: string
  rawfile: string
}

const TRACK_TABLE: TrackMeta[] = [
  { id: 1, title: '夜曲', artist: '周杰伦', rawfile: 'sample_music_1.mp3' },
  { id: 2, title: '稻香', artist: '周杰伦', rawfile: 'sample_music_2.mp3' },
  { id: 3, title: '晴天', artist: '周杰伦', rawfile: 'sample_music_3.mp3' }
]

export class RealAudioPlayerService {
  private static instance: RealAudioPlayerService | null = null
  private context: common.UIAbilityContext | null = null
  private player: media.AVPlayer | null = null
  private currentTrack: TrackMeta | null = null
  private snapshot: AudioPlayerSnapshot = new AudioPlayerSnapshot()
  private listeners: AudioPlayerListener[] = []
  private pendingSeekMs: number = -1
  private pendingAutoPlay: boolean = false
  private preparing: boolean = false

  static getInstance(): RealAudioPlayerService {
    if (!RealAudioPlayerService.instance) {
      RealAudioPlayerService.instance = new RealAudioPlayerService()
    }
    return RealAudioPlayerService.instance
  }

  getTracks(): TrackMeta[] {
    return TRACK_TABLE
  }

  setContext(ctx: common.UIAbilityContext): void {
    this.context = ctx
  }

  addListener(listener: AudioPlayerListener): void {
    this.listeners.push(listener)
  }

  removeListener(listener: AudioPlayerListener): void {
    const idx = this.listeners.indexOf(listener)
    if (idx >= 0) {
      this.listeners.splice(idx, 1)
    }
  }

  getSnapshot(): AudioPlayerSnapshot {
    return this.snapshot
  }

  async playById(songId: number, positionMs: number = 0, autoPlay: boolean = true): Promise<void> {
    const track = TRACK_TABLE.find((t) => t.id === songId) ?? TRACK_TABLE[0]
    if (!this.context) {
      console.error('[RealAudioPlayer] context not set')
      return
    }
    if (this.currentTrack && this.currentTrack.id === track.id && this.player) {
      if (positionMs > 0) {
        this.player.seek(positionMs)
      }
      if (autoPlay) {
        try { await this.player.play() } catch (e) { console.error('[RealAudioPlayer] play error', e) }
      }
      return
    }
    await this.release()
    this.currentTrack = track
    this.pendingSeekMs = positionMs
    this.pendingAutoPlay = autoPlay
    this.preparing = true
    try {
      console.info(`[RealAudioPlayer] play start songId=${track.id} file=${track.rawfile} pos=${positionMs} auto=${autoPlay}`)
      this.player = await media.createAVPlayer()
      this.attachListeners(this.player)
      const rawFd = await this.context.resourceManager.getRawFd(track.rawfile)
      console.info(`[RealAudioPlayer] rawFd fd=${rawFd.fd} offset=${rawFd.offset} length=${rawFd.length}`)
      this.player.fdSrc = {
        fd: rawFd.fd,
        offset: rawFd.offset,
        length: rawFd.length
      }
    } catch (e) {
      const err = e as BusinessError
      console.error(`[RealAudioPlayer] init error code=${err.code} msg=${err.message}`)
      this.preparing = false
    }
  }

  async pause(): Promise<void> {
    if (!this.player) return
    try { await this.player.pause() } catch (e) { console.error('[RealAudioPlayer] pause error', e) }
  }

  async resume(): Promise<void> {
    if (!this.player) return
    try { await this.player.play() } catch (e) { console.error('[RealAudioPlayer] resume error', e) }
  }

  async seek(positionMs: number): Promise<void> {
    if (!this.player) return
    this.player.seek(positionMs)
  }

  async release(): Promise<void> {
    if (this.player) {
      try { await this.player.release() } catch (e) { console.error('[RealAudioPlayer] release error', e) }
      this.player = null
    }
    this.currentTrack = null
    this.preparing = false
    this.pendingSeekMs = -1
    this.pendingAutoPlay = false
  }

  async syncRemote(songId: number, playing: boolean, positionMs: number): Promise<void> {
    await this.playById(songId, positionMs, playing)
    if (!playing && this.player) {
      try { await this.player.pause() } catch (_) { }
    }
  }

  private attachListeners(player: media.AVPlayer): void {
    player.on('stateChange', (state: string, _reason: number) => {
      console.info(`[RealAudioPlayer] stateChange -> ${state}`)
      if (state === 'initialized') {
        try {
          player.audioRendererInfo = {
            usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
            rendererFlags: 0
          }
          console.info('[RealAudioPlayer] audioRendererInfo set before prepare')
        } catch (e) {
          console.warn('[RealAudioPlayer] set audioRendererInfo fail', (e as BusinessError).message)
        }
        player.prepare().catch((e: BusinessError) => console.error('[RealAudioPlayer] prepare', e.message))
      } else if (state === 'prepared') {
        this.preparing = false
        this.snapshot.duration = player.duration
        if (this.currentTrack) {
          this.snapshot.songId = this.currentTrack.id
          this.snapshot.title = this.currentTrack.title
          this.snapshot.artist = this.currentTrack.artist
        }
        if (this.pendingSeekMs > 0) {
          player.seek(this.pendingSeekMs)
          this.pendingSeekMs = -1
        }
        if (this.pendingAutoPlay) {
          player.play().catch((e: BusinessError) => console.error('[RealAudioPlayer] play', e.message))
          this.pendingAutoPlay = false
        } else {
          this.emit()
        }
      } else if (state === 'playing') {
        this.snapshot.playing = true
        this.emit()
      } else if (state === 'paused') {
        this.snapshot.playing = false
        this.emit()
      } else if (state === 'completed') {
        this.snapshot.playing = false
        this.snapshot.position = this.snapshot.duration
        this.emit()
      } else if (state === 'error') {
        this.preparing = false
        this.snapshot.playing = false
        this.emit()
      }
    })
    player.on('timeUpdate', (time: number) => {
      this.snapshot.position = time
      this.emit()
    })
    player.on('error', (err: BusinessError) => {
      console.error('[RealAudioPlayer] error', err.code, err.message)
    })
  }

  private emit(): void {
    const snap = this.snapshot
    this.listeners.forEach((l) => l(snap))
  }
}
