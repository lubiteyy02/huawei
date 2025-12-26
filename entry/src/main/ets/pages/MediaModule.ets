import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { avSession } from '@kit.AVSessionKit';
import { common } from '@kit.AbilityKit';

export interface Song {
  id: number;
  title: string;
  artist: string;
  cover: string;
  url: string;
  quality: string;
}

class Particle {
  x: number = 0;
  y: number = 0;
  radius: number = 0;
  speed: number = 0;
  opacity: number = 0;

  constructor(width: number, height: number) { this.reset(width, height); }

  reset(width: number, height: number): void {
    this.x = Math.random() * width;
    this.y = height + Math.random() * 50;
    this.radius = Math.random() * 2 + 1;
    this.speed = Math.random() * 1 + 0.5;
    this.opacity = Math.random() * 0.5 + 0.2;
  }

  update(width: number, height: number): void {
    this.y -= this.speed;
    if (this.y < 0) this.reset(width, height);
  }
}

@Component
export struct MediaModule {
  @State currentSong: Song | null = null;
  @State isPlaying: boolean = false;
  @State isLoading: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State rotateAngle: number = 0;
  @State showPlaylist: boolean = false;
  @State spectrumHeight: number = 10;
  @Prop isPageVisible: boolean = true;

  private avPlayer: media.AVPlayer | undefined = undefined;
  private session: avSession.AVSession | undefined = undefined;
  private timer: number = -1;
  private renderTimer: number = -1;
  private particleSettings: RenderingContextSettings = new RenderingContextSettings(true);
  private particleContext: CanvasRenderingContext2D = new CanvasRenderingContext2D(this.particleSettings);
  private particles: Particle[] = [];
  private canvasWidth: number = 0;
  private canvasHeight: number = 0;

  private songList: Song[] = [
    {
      id: 1,
      title: 'Midnight City',
      artist: 'M83 Style',
      cover: 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3',
      quality: 'SQ'
    },
    {
      id: 2,
      title: 'Ocean Eyes',
      artist: 'Billie Eilish',
      cover: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3',
      quality: 'HR'
    },
    {
      id: 3,
      title: 'Shape of You',
      artist: 'Ed Sheeran',
      cover: 'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?auto=compress&cs=tinysrgb&w=600',
      url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3',
      quality: 'HQ'
    }
  ];

  aboutToAppear(): void {
    this.init().catch((err: Error) => {
      console.error("Init failed:", err);
    });
  }

  async init(): Promise<void> {
    try {
      this.currentSong = this.songList[0];
      await this.initSession();
      await this.initPlayer();
      this.startSpectrumAnim();
    } catch (e) {
      console.error("MediaModule internal init error:", e);
    }
  }

  aboutToDisappear(): void {
    this.releasePlayer();
    if (this.session) {
      this.session.destroy();
    }
    this.stopAnimations();
  }

  onPageShow(): void {
    this.startParticleLoop();
  }

  onPageHide(): void {
    clearInterval(this.renderTimer);
  }

  async initSession(): Promise<void> {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.session = await avSession.createAVSession(context, 'CarInfotainmentSession', 'audio');
      this.session.on('play', () => { this.togglePlay(); });
      this.session.on('pause', () => { this.togglePlay(); });
      this.session.on('playNext', () => { this.playNext(); });
      this.session.on('playPrevious', () => { this.playPrev(); });
      await this.session.activate();
    } catch (e) {
      console.error(`Failed to init session: ${e.message}`);
    }
  }

  async updateSessionMetadata(song: Song): Promise<void> {
    if (!this.session) return;
    let metadata: avSession.AVMetadata = {
      assetId: song.id.toString(),
      title: song.title,
      artist: song.artist,
      mediaImage: song.cover,
      duration: this.totalTime
    };
    try { await this.session.setAVMetadata(metadata); } catch(e) {}
  }

  async updateSessionPlaybackState(state: avSession.PlaybackState, time: number): Promise<void> {
    if (!this.session) return;
    let playbackState: avSession.AVPlaybackState = {
      state: state,
      position: { elapsedTime: time, updateTime: new Date().getTime() },
      speed: 1.0,
      bufferedTime: this.totalTime,
      loopMode: avSession.LoopMode.LOOP_MODE_LIST,
      isFavorite: false
    };
    try { await this.session.setAVPlaybackState(playbackState); } catch(e) {}
  }

  async initPlayer(): Promise<void> {
    try {
      this.avPlayer = await media.createAVPlayer();
      let audioRendererInfo: audio.AudioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      }
      this.avPlayer.audioRendererInfo = audioRendererInfo;
      this.setAVPlayerCallback();
      if (this.currentSong) this.avPlayer.url = this.currentSong.url;
    } catch (e) {
      console.error("Player init error", e);
    }
  }

  releasePlayer(): void {
    try { if (this.avPlayer) this.avPlayer.release(); } catch(e) {}
    this.stopAnimations();
  }

  stopAnimations(): void {
    clearInterval(this.timer);
    clearInterval(this.renderTimer);
  }

  setAVPlayerCallback(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
      switch (state) {
        case 'initialized':
          this.isLoading = true;
          try { await this.avPlayer!.prepare(); } catch(e) { console.error("Prepare failed", e); }
          break;
        case 'prepared':
          this.totalTime = this.avPlayer!.duration;
          this.isLoading = false;
          if(this.currentSong) this.updateSessionMetadata(this.currentSong);
          if (this.isPlaying) {
            try { this.avPlayer!.play(); } catch(e) {}
          }
          break;
        case 'playing':
          this.isPlaying = true;
          this.startRotateAnim();
          this.updateSessionPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY, this.currentTime);
          break;
        case 'paused':
          this.isPlaying = false;
          this.stopRotateAnim();
          this.updateSessionPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE, this.currentTime);
          break;
        case 'completed':
          this.isPlaying = false;
          this.stopRotateAnim();
          this.playNext();
          break;
        case 'error':
          this.isPlaying = false;
          this.stopRotateAnim();
          break;
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => { this.currentTime = time; });

    this.avPlayer.on('audioInterrupt', (info: audio.InterruptEvent) => {
      if (info.forceType === audio.InterruptForceType.INTERRUPT_FORCE) {
        if (info.hintType === audio.InterruptHint.INTERRUPT_HINT_PAUSE) {
          try { this.avPlayer?.pause(); } catch(e) {}
        } else if (info.hintType === audio.InterruptHint.INTERRUPT_HINT_DUCK) {
          try { this.avPlayer?.setVolume(0.2); } catch(e) {}
        }
      } else if (info.forceType === audio.InterruptForceType.INTERRUPT_SHARE) {
        try { this.avPlayer?.setVolume(1.0); } catch(e) {}
        if (this.isPlaying) try { this.avPlayer?.play(); } catch(e) {}
      }
    });
    this.avPlayer.on('error', () => { this.isLoading = false; });
  }

  async playSong(song: Song): Promise<void> {
    if (!this.avPlayer) return;
    if (this.currentSong?.id === song.id) { this.togglePlay(); return; }

    this.isLoading = true;
    this.currentSong = song;
    this.isPlaying = true;
    this.rotateAngle = 0;

    try {
      await this.avPlayer.reset();
      this.avPlayer.url = song.url;
    } catch(e) {
      console.error("Switch song failed", e);
    }
  }

  async togglePlay(): Promise<void> {
    if (!this.avPlayer) return;
    try {
      if (this.isPlaying) await this.avPlayer.pause();
      else await this.avPlayer.play();
    } catch (e) {
      console.error("Toggle play failed", e);
    }
  }

  playNext(): void {
    if (!this.currentSong) return;
    let index = this.songList.findIndex(item => item.id === this.currentSong?.id);
    let nextIndex = (index + 1) % this.songList.length;
    this.playSong(this.songList[nextIndex]);
  }

  playPrev(): void {
    if (!this.currentSong) return;
    let index = this.songList.findIndex(item => item.id === this.currentSong?.id);
    let prevIndex = index === 0 ? this.songList.length - 1 : index - 1;
    this.playSong(this.songList[prevIndex]);
  }

  startRotateAnim(): void {
    clearInterval(this.timer);
    this.timer = setInterval(() => { this.rotateAngle = (this.rotateAngle + 0.4) % 360; }, 16);
  }

  stopRotateAnim(): void { clearInterval(this.timer); }

  startSpectrumAnim(): void { setInterval(() => { this.spectrumHeight = Math.random() * 15 + 5; }, 100); }

  initParticles(width: number, height: number): void {
    this.canvasWidth = width;
    this.canvasHeight = height;
    this.particles = [];
    for (let i = 0; i < 40; i++) this.particles.push(new Particle(width, height));
    this.startParticleLoop();
  }

  startParticleLoop(): void {
    clearInterval(this.renderTimer);
    this.renderTimer = setInterval(() => {
      if (!this.particleContext) return;
      this.particleContext.clearRect(0, 0, this.canvasWidth, this.canvasHeight);
      this.particles.forEach(p => {
        p.update(this.canvasWidth, this.canvasHeight);
        this.particleContext.beginPath();
        this.particleContext.arc(p.x, p.y, p.radius, 0, Math.PI * 2);
        this.particleContext.fillStyle = `rgba(0, 229, 255, ${p.opacity})`;
        this.particleContext.fill();
      });
    }, 30);
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      if (this.currentSong) {
        Stack() {
          Image(this.currentSong.cover).width('120%').height('120%').blur(100).opacity(0.5).objectFit(ImageFit.Cover)
          Rect().width('100%').height('100%')
            .linearGradient({ angle: 180, colors: [['rgba(0,0,0,0.2)', 0.0], ['#000000', 1.0]] })
          Canvas(this.particleContext).width('100%').height('100%')
            .onReady(() => this.initParticles(300, 300))
            .onAreaChange((o, n) => this.initParticles(n.width as number, n.height as number))
            .opacity(0.6)
            .hitTestBehavior(HitTestMode.Transparent)
        }
        .width('100%').height('100%')
      } else {
        Rect().width('100%').height('100%').fill('#0F172A')
      }

      Column() {
        Blank().height(20)
        Stack() {
          Circle({ width: 300, height: 300 })
            .radialGradient({ center: ['50%', '50%'], radius: 150, colors: [['rgba(255,255,255,0.1)', 0.0], ['transparent', 1.0]] })
            .blur(40)
          Stack() {
            Circle({ width: 260, height: 260 }).fill('#181818').shadow({ radius: 40, color: 'rgba(0,0,0,0.6)', offsetY: 20 })
            Image(this.currentSong?.cover).width(160).height(160).borderRadius(80)
              .rotate({ angle: this.rotateAngle })
          }
        }
        .layoutWeight(1)

        Column() {
          Text(this.currentSong?.title).fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White)
            .textShadow({ radius: 20, color: 'rgba(255,255,255,0.3)' }).maxLines(1)
          Text(this.currentSong?.artist).fontSize(16).fontColor('rgba(255,255,255,0.6)').margin({ top: 8 })
          Text(this.currentSong?.quality).fontSize(10).fontColor('#00E5FF').border({width:1, color:'#00E5FF', radius: 4}).padding({left:4, right:4}).margin({top: 6})
        }.margin({ bottom: 20 })

        Blank().height(140)
      }
      .width('100%').height('100%')
      .offset({ x: this.showPlaylist ? 100 : 0 })
      .animation({ duration: 300, curve: Curve.EaseOut })
      .scale(this.showPlaylist ? { x: 0.9, y: 0.9 } : { x: 1, y: 1 })
      .opacity(this.showPlaylist ? 0.6 : 1)
      .hitTestBehavior(HitTestMode.Transparent)

      Column() {
        Row() {
          Text(this.formatTime(this.currentTime)).fontColor('#AAA').fontSize(11)
          Slider({ value: this.currentTime, min: 0, max: this.totalTime })
            .layoutWeight(1).trackColor('rgba(255,255,255,0.2)').selectedColor('#00E5FF').blockColor('#00E5FF')
            .margin({ left: 10, right: 10 })
            .onChange((val, mode) => { if(mode === SliderChangeMode.End) try { this.avPlayer?.seek(val) } catch(e){} })
          Text(this.formatTime(this.totalTime)).fontColor('#AAA').fontSize(11)
        }.width('90%').margin({ bottom: 10 })

        Row({ space: 50 }) {
          this.ControlBtn("⏮", 28, () => this.playPrev())
          Stack() {
            if (this.isLoading) {
              LoadingProgress().width(50).height(50).color('#00E5FF')
            } else {
              Button() {
                Text(this.isPlaying ? "⏸" : "▶").fontSize(32).fontColor(Color.White)
              }
              .width(72).height(72).borderRadius(36)
              .linearGradient({ angle: 135, colors: [['#00E5FF', 0], ['#007AFF', 1]] })
              .shadow({ radius: 20, color: 'rgba(0,122,255,0.5)' })
              .onClick(() => this.togglePlay())
            }
          }
          this.ControlBtn("⏭", 28, () => this.playNext())
        }
      }
      .width('95%').padding(20)
      .backgroundColor('rgba(20, 20, 20, 0.7)')
      .backdropBlur(50).borderRadius(30)
      .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
      .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)' })
      .margin({ bottom: 120 })

      Button() {
        Row() {
          Text("🎵").fontSize(18)
          Text(this.showPlaylist ? " 收起" : " 歌单").fontSize(14).fontColor(Color.White)
        }
      }
      .position({ x: 20, y: 20 })
      .backgroundColor('rgba(255,255,255,0.1)').backdropBlur(20).height(36).borderRadius(18)
      .onClick(() => { this.showPlaylist = !this.showPlaylist; }).zIndex(100)

      if (this.showPlaylist) {
        Column() {
          Text("PLAYLIST").fontSize(14).fontWeight(FontWeight.Bold).fontColor('rgba(255,255,255,0.5)').margin({ bottom: 20, left: 10 })
          List({ space: 10 }) {
            ForEach(this.songList, (song: Song, index: number) => {
              ListItem() { this.SongItem(song, index) }
            })
          }
          .layoutWeight(1).scrollBar(BarState.Off)
        }
        .width('50%').height('100%').backgroundColor('rgba(10, 10, 10, 0.95)')
        .padding({ top: 80, bottom: 20, left: 20, right: 20 })
        .position({ x: 0, y: 0 })
        .transition({ type: TransitionType.Insert, translate: { x: -300 } })
        .transition({ type: TransitionType.Delete, translate: { x: -300 } })
        .zIndex(99)
        .border({ width: { right: 1 }, color: 'rgba(255,255,255,0.1)' })
      }
    }
    .width('100%').height('100%')
  }

  @Builder SongItem(song: Song, index: number): void {
    Row() {
      Image(song.cover).width(40).height(40).borderRadius(6).margin({ right: 12 }).backgroundColor('#333')
      Column() {
        Text(song.title)
          .fontColor(this.currentSong?.id === song.id ? '#00E5FF' : '#FFF')
          .fontSize(15).fontWeight(this.currentSong?.id === song.id ? FontWeight.Bold : FontWeight.Normal)
          .maxLines(1).textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(song.artist).fontColor('rgba(255,255,255,0.5)').fontSize(12).margin({ top: 4 })
      }.alignItems(HorizontalAlign.Start).layoutWeight(1)

      if (this.currentSong?.id === song.id) {
        Row({ space: 2 }) {
          Rect().width(3).height(12).fill('#00E5FF')
          Rect().width(3).height(20).fill('#00E5FF')
        }
      }
    }
    .width('100%').padding(12).borderRadius(12)
    .backgroundColor(this.currentSong?.id === song.id ? 'rgba(255,255,255,0.1)' : 'transparent')
    .onClick(() => { this.playSong(song); })
  }

  @Builder ControlBtn(text: string, size: number, action: () => void): void {
    Button() {
      Text(text).fontSize(size).fontColor('rgba(255,255,255,0.9)')
    }
    .width(60).height(60).borderRadius(30)
    .backgroundColor('rgba(255,255,255,0.05)')
    .onClick(action)
  }

  formatTime(ms: number): string {
    if (!ms || ms < 0) return '00:00';
    let s = Math.floor(ms / 1000);
    return `${Math.floor(s / 60).toString().padStart(2, '0')}:${(s % 60).toString().padStart(2, '0')}`;
  }
}