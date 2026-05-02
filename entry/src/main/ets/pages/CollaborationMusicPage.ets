import router from '@ohos.router'
import type common from '@ohos.app.ability.common'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'
import { MusicStateSnapshot } from '../services/CollaborationApiService'
import { RealMusicSessionService } from '../services/RealMusicSessionService'
import { RealMusicBridgeService } from '../services/RealMusicBridgeService'
import { RealAudioPlayerService, AudioPlayerSnapshot } from '../services/RealAudioPlayerService'

interface MusicItem {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

@Entry
@Component
struct CollaborationMusicPage {
  @State private musicItems: MusicItem[] = [];
  @State private nowPlaying: MusicStateSnapshot | null = null;
  @State private resumeHint: string = '';
  @State private lastSyncHint: string = '等待同步事件';
  @State private initialLoading: boolean = false;
  @State private isCar: boolean = false;
  @State private currentSongId: number = 0;
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly musicSessionService: RealMusicSessionService = RealMusicSessionService.getInstance();
  private readonly musicBridge: RealMusicBridgeService = RealMusicBridgeService.getInstance();
  private readonly audioPlayer: RealAudioPlayerService = RealAudioPlayerService.getInstance();
  private lastReportedMs: number = -1;
  private lastReportedTime: number = 0;
  private lastReportedPlaying: boolean = false;
  private lastReportedSongId: number = 0;
  private remoteEventTimestamp: number = 0;
  private tickerId: number = -1;
  private readonly audioListener: (snap: AudioPlayerSnapshot) => void = (snap: AudioPlayerSnapshot): void => {
    this.currentSongId = snap.songId;
    this.nowPlaying = {
      songId: snap.songId,
      playing: snap.playing,
      position: snap.position,
      updatedAt: new Date().toISOString(),
      title: snap.title,
      artist: snap.artist,
      sourceDevice: this.viewModel.getDeviceId()
    };
    this.reportToBackend(snap);
  };
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'music.stateChanged') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      const songId = typeof event.payload.songId === 'number' ? event.payload.songId : -1;
      const playing = event.payload.playing === 1 || event.payload.playing === true;
      const position = typeof event.payload.position === 'number' ? event.payload.position : 0;
      const fromSelf = event.sourceDeviceId === this.viewModel.getDeviceId();
      if (songId >= 0 && !fromSelf) {
        this.remoteEventTimestamp = Date.now();
        this.nowPlaying = {
          songId,
          playing,
          position,
          updatedAt: event.timestamp,
          title: this.nowPlaying && this.nowPlaying.songId === songId ? this.nowPlaying.title : '',
          artist: this.nowPlaying && this.nowPlaying.songId === songId ? this.nowPlaying.artist : '',
          sourceDevice: event.sourceDeviceId ?? ''
        };
      }
      return;
    }
    if (event.type === 'music.handover') {
      this.lastSyncHint = `续接事件 · ${event.timestamp}`;
      const songId = typeof event.payload.songId === 'number' ? event.payload.songId : -1;
      const position = typeof event.payload.position === 'number' ? event.payload.position : 0;
      const target = typeof event.payload.target === 'string' ? event.payload.target : '';
      const myId = this.viewModel.getDeviceId();
      if (songId < 0) return;
      if (target === myId) {
        void this.audioPlayer.playById(songId, position, true);
        this.resumeHint = `已接收续接，开始播放`;
      } else {
        void this.audioPlayer.pause();
        this.resumeHint = `已让出播放权给 ${target}`;
      }
      return;
    }
    if (event.type === 'overview.refreshed') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      return;
    }
  };

  aboutToAppear() {
    this.initialLoading = true;
    const deviceId = this.viewModel.getDeviceId();
    this.isCar = deviceId === 'car-001';
    const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
    this.audioPlayer.setContext(ctx);
    this.audioPlayer.addListener(this.audioListener);
    void this.initializeRealMusicSession();
    void this.refreshMusic();
    void this.refreshNowPlaying();
    this.viewModel.onSyncEvent(this.syncListener);
    this.tickerId = setInterval((): void => { this.tickRemotePosition(); }, 250);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
    this.audioPlayer.removeListener(this.audioListener);
    void this.audioPlayer.release();
    if (this.tickerId !== -1) {
      clearInterval(this.tickerId);
      this.tickerId = -1;
    }
    void this.musicSessionService.destroy();
  }

  private tickRemotePosition(): void {
    if (!this.nowPlaying) return;
    if (!this.nowPlaying.playing) return;
    const mine = this.nowPlaying.sourceDevice === this.viewModel.getDeviceId();
    if (mine) return;
    if (this.remoteEventTimestamp === 0) return;
    const elapsed = Date.now() - this.remoteEventTimestamp;
    this.nowPlaying = {
      songId: this.nowPlaying.songId,
      playing: this.nowPlaying.playing,
      position: this.nowPlaying.position + elapsed,
      updatedAt: this.nowPlaying.updatedAt,
      title: this.nowPlaying.title,
      artist: this.nowPlaying.artist,
      sourceDevice: this.nowPlaying.sourceDevice
    };
    this.remoteEventTimestamp = Date.now();
  }

  private reportToBackend(snap: AudioPlayerSnapshot): void {
    if (this.isCar) return;
    if (snap.songId <= 0) return;
    const now = Date.now();
    const timeDiff = now - this.lastReportedTime;
    const stateChanged = snap.playing !== this.lastReportedPlaying
      || snap.songId !== this.lastReportedSongId;
    if (!stateChanged && timeDiff < 3000) return;
    this.lastReportedMs = snap.position;
    this.lastReportedTime = now;
    this.lastReportedPlaying = snap.playing;
    this.lastReportedSongId = snap.songId;
    void this.viewModel.syncMusic(snap.songId, snap.playing, snap.position);
  }

  private async onPhonePlay(songId: number): Promise<void> {
    await this.audioPlayer.playById(songId, 0, true);
    void this.viewModel.pushSharedLog(`手机开始播放：${songId}`, this.viewModel.getDeviceId());
  }

  private async onPhonePause(): Promise<void> {
    await this.audioPlayer.pause();
  }

  private async onPhoneResume(): Promise<void> {
    await this.audioPlayer.resume();
  }

  private async initializeRealMusicSession(): Promise<void> {
    try {
      this.musicBridge.disable()
      const uiAbilityContext = this.getUIContext().getHostContext() as common.UIAbilityContext
      await this.musicSessionService.initialize(uiAbilityContext)
    } catch {
      this.lastSyncHint = '真实音乐会话初始化失败'
    }
  }

  private async refreshMusic(): Promise<void> {
    this.musicItems = await this.viewModel.loadMusic() as MusicItem[];
    this.initialLoading = false;
  }

  private async refreshNowPlaying(): Promise<void> {
    const state = await this.viewModel.loadMusicState();
    this.nowPlaying = state;
    this.initialLoading = false;
  }

  private formatPosition(ms: number): string {
    const total = Math.max(0, Math.floor(ms / 1000));
    const m = Math.floor(total / 60).toString().padStart(2, '0');
    const s = (total % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  private computeHandoverTarget(): string {
    const source = this.nowPlaying ? this.nowPlaying.sourceDevice : '';
    const myId = this.viewModel.getDeviceId();
    if (source === 'phone-001') return 'car-001';
    if (source === 'car-001') return 'phone-001';
    return myId === 'phone-001' ? 'car-001' : 'phone-001';
  }

  private handoverTargetLabel(): string {
    return this.computeHandoverTarget() === 'car-001' ? '续接到车机' : '拉回手机播放';
  }

  private async triggerHandover(): Promise<void> {
    if (!this.nowPlaying || this.nowPlaying.songId <= 0) {
      this.resumeHint = '暂无正在播放的曲目';
      return;
    }
    const songId = this.nowPlaying.songId;
    const position = this.nowPlaying.position;
    const target = this.computeHandoverTarget();
    const ok = await this.viewModel.handoverMusic(songId, position, target);
    const label = target === 'car-001' ? '车机' : '手机';
    this.resumeHint = ok ? `已通知${label}接手播放 @ ${this.formatPosition(position)}` : '续接失败，请稍后重试';
  }

  build() {
    Column() {
      Row() {
        Button('返回')
          .fontSize(12)
          .backgroundColor('rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(12)
          .onClick(() => router.back())
        Column({ space: 4 }) {
          Text('音乐同步')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.lastSyncHint)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
          if (this.initialLoading) {
            Text('正在加载音乐...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else if (this.nowPlaying !== null && this.nowPlaying!.songId > 0) {
            Text('已连接真实接口，手机与车机将实时同步播放状态')
              .fontSize(10)
              .fontColor('#22C55E')
            Column({ space: 8 }) {
              Row() {
                Text('当前手机播放').fontSize(11).fontColor('rgba(255,255,255,0.55)')
                Blank()
                Text(this.nowPlaying!.playing ? '播放中' : '已暂停')
                  .fontSize(10)
                  .fontColor(this.nowPlaying!.playing ? '#22C55E' : 'rgba(255,255,255,0.6)')
              }
              .width('100%')
              Text(this.nowPlaying!.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(`${this.nowPlaying!.artist} · ${this.formatPosition(this.nowPlaying!.position)}`)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.7)')
              Row() {
                if (!this.isCar) {
                  Button(this.nowPlaying && this.nowPlaying.playing ? '暂停' : '播放')
                    .fontSize(12)
                    .backgroundColor('#2563EB')
                    .fontColor('#FFFFFF')
                    .borderRadius(14)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .onClick(() => {
                      if (this.nowPlaying && this.nowPlaying.playing) {
                        void this.onPhonePause();
                      } else {
                        void this.onPhoneResume();
                      }
                    })
                }
                Button(this.handoverTargetLabel())
                  .fontSize(12)
                  .backgroundColor('#8B5CF6')
                  .fontColor('#FFFFFF')
                  .borderRadius(14)
                  .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                  .onClick(() => { void this.triggerHandover(); })
                Blank()
                if (this.resumeHint !== '') {
                  Text(this.resumeHint).fontSize(10).fontColor('#A78BFA').maxLines(2)
                }
              }
              .width('100%')
            }
            .width('100%')
            .padding(16)
            .backgroundColor('rgba(139,92,246,0.14)')
            .borderRadius(18)
            .border({ width: 1, color: 'rgba(139,92,246,0.28)' })
          }
          ForEach(this.musicItems, (music: MusicItem) => {
            Column({ space: 6 }) {
              Row() {
                Column({ space: 4 }) {
                  Text(music.title).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text(music.artist).fontSize(11).fontColor('rgba(255,255,255,0.6)')
                }
                .layoutWeight(1)
                if (!this.isCar) {
                  Button(this.currentSongId === music.id && this.nowPlaying && this.nowPlaying.playing ? '播放中' : '播放')
                    .fontSize(11)
                    .backgroundColor(this.currentSongId === music.id ? '#22C55E' : '#2563EB')
                    .fontColor('#FFFFFF')
                    .borderRadius(12)
                    .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                    .onClick(() => { void this.onPhonePlay(music.id); })
                } else {
                  Text(music.device).fontSize(10).fontColor('#A78BFA')
                }
              }
              Progress({ value: music.progress, total: 100, style: ProgressStyle.Linear })
                .color('#8B5CF6')
                .backgroundColor('rgba(255,255,255,0.08)')
            }
            .width('100%')
            .padding(14)
            .backgroundColor('rgba(255,255,255,0.06)')
            .borderRadius(18)
          })
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 18 })
      }
      .layoutWeight(1)
      .scrollBar(BarState.Off)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}
