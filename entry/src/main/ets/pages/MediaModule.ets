import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { avSession } from '@kit.AVSessionKit';
import { common } from '@kit.AbilityKit';

export interface Song { id: number; title: string; artist: string; cover: string; url: string; quality: string; }

@Component
export struct MediaModule {
  @State currentSong: Song | null = null;
  @State isPlaying: boolean = false;
  @State isLoading: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State rotateAngle: number = 0;
  @Prop isPageVisible: boolean = true;

  private avPlayer: media.AVPlayer | undefined = undefined;
  private session: avSession.AVSession | undefined = undefined;
  private timer: number = -1;

  private songList: Song[] = [
    { id: 1, title: 'Midnight City', artist: 'M83 Style', cover: 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', quality: 'SQ' },
    { id: 2, title: 'Ocean Eyes', artist: 'Billie Eilish', cover: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', quality: 'HR' },
    { id: 3, title: 'Shape of You', artist: 'Ed Sheeran', cover: 'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', quality: 'HQ' }
  ];

  aboutToAppear(): void { this.safeInit(); }
  async safeInit(): Promise<void> { try { this.currentSong = this.songList[0]; await this.initSession(); await this.initPlayer(); this.startSpectrumAnim(); } catch (e) {} }
  aboutToDisappear(): void { this.releasePlayer(); if(this.session) this.session.destroy(); clearInterval(this.timer); }

  async initSession(): Promise<void> { try { let context = this.getUIContext().getHostContext() as common.UIAbilityContext; this.session = await avSession.createAVSession(context, 'CarInfotainmentSession', 'audio'); await this.session.activate(); } catch(e){} }
  async updateSessionMetadata(song: Song): Promise<void> { if(!this.session) return; try{ await this.session.setAVMetadata({assetId: song.id.toString(), title: song.title, artist: song.artist, mediaImage: song.cover, duration: this.totalTime}); }catch(e){} }
  async updateSessionPlaybackState(state: avSession.PlaybackState, time: number): Promise<void> { if(!this.session) return; try{ await this.session.setAVPlaybackState({state: state, position:{elapsedTime:time, updateTime:new Date().getTime()}, speed:1.0, bufferedTime:this.totalTime, loopMode: avSession.LoopMode.LOOP_MODE_LIST, isFavorite:false}); }catch(e){} }

  async initPlayer(): Promise<void> { try { this.avPlayer = await media.createAVPlayer(); this.avPlayer.audioRendererInfo = {usage: audio.StreamUsage.STREAM_USAGE_MUSIC, rendererFlags: 0}; this.setAVPlayerCallback(); if(this.currentSong) this.avPlayer.url = this.currentSong.url; } catch(e){} }
  releasePlayer(): void { try { if(this.avPlayer) this.avPlayer.release(); } catch(e){} }

  setAVPlayerCallback(): void {
    if(!this.avPlayer) return;
    this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
      switch(state) {
        case 'initialized': try{ await this.avPlayer!.prepare(); }catch(e){} break;
        case 'prepared': this.totalTime = this.avPlayer!.duration; if(this.currentSong) this.updateSessionMetadata(this.currentSong); if(this.isPlaying) try{this.avPlayer!.play();}catch(e){} break;
        case 'playing': this.isPlaying = true; this.startRotateAnim(); this.updateSessionPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PLAY, this.currentTime); break;
        case 'paused': this.isPlaying = false; this.stopRotateAnim(); this.updateSessionPlaybackState(avSession.PlaybackState.PLAYBACK_STATE_PAUSE, this.currentTime); break;
        case 'completed': this.playNext(); break;
      }
    });
    this.avPlayer.on('timeUpdate', (time) => this.currentTime = time);
  }

  async playSong(song: Song): Promise<void> { if(!this.avPlayer) return; if(this.currentSong?.id === song.id) { this.togglePlay(); return; } this.currentSong = song; this.isPlaying = true; this.rotateAngle = 0; try{ await this.avPlayer.reset(); this.avPlayer.url = song.url; }catch(e){} }
  async togglePlay(): Promise<void> { if(!this.avPlayer) return; try{ if(this.isPlaying) await this.avPlayer.pause(); else await this.avPlayer.play(); }catch(e){} }
  playNext(): void { if(!this.currentSong) return; let idx = this.songList.findIndex(i=>i.id===this.currentSong?.id); this.playSong(this.songList[(idx+1)%this.songList.length]); }
  playPrev(): void { if(!this.currentSong) return; let idx = this.songList.findIndex(i=>i.id===this.currentSong?.id); this.playSong(this.songList[idx===0?this.songList.length-1:idx-1]); }
  startRotateAnim(): void { clearInterval(this.timer); this.timer = setInterval(() => { this.rotateAngle = (this.rotateAngle+0.2)%360; }, 16); }
  stopRotateAnim(): void { clearInterval(this.timer); }
  startSpectrumAnim(): void {}
  formatTime(ms: number): string { if(!ms||ms<0) return '00:00'; let s=Math.floor(ms/1000); return `${Math.floor(s/60).toString().padStart(2,'0')}:${(s%60).toString().padStart(2,'0')}`; }

  build() {
    Stack({ alignContent: Alignment.Bottom }) { // 内容底部对齐

      // 1. 背景层
      if (this.currentSong) {
        Image(this.currentSong.cover).width('120%').height('120%').blur(100).opacity(0.4).objectFit(ImageFit.Cover)
        Rect().width('100%').height('100%').fill(Color.Black).opacity(0.5)
      } else {
        Rect().width('100%').height('100%').fill('#0F172A')
      }

      // 2. 唱片区 (居中)
      Column() {
        Stack() {
          Circle({ width: 280, height: 280 }).fill('#101010').shadow({ radius: 30, color: 'rgba(0,0,0,0.6)' })
          Image(this.currentSong?.cover).width(180).height(180).borderRadius(90).rotate({ angle: this.rotateAngle })
        }
        Text(this.currentSong?.title).fontSize(32).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ top: 30 })
        Text(this.currentSong?.artist).fontSize(16).fontColor('rgba(255,255,255,0.6)').margin({ top: 8 })
      }
      .width('100%')
      .height('100%')
      .justifyContent(FlexAlign.Center)
      .padding({ bottom: 150 }) // 给底部控制台腾出空间

      // 3. 底部悬浮控制岛 (避让左下角)
      Column() {
        // 进度
        Row() {
          Text(this.formatTime(this.currentTime)).fontSize(12).fontColor('#AAA')
          Slider({ value: this.currentTime, min: 0, max: this.totalTime })
            .layoutWeight(1).trackColor('rgba(255,255,255,0.1)').selectedColor('#00E5FF').margin({ left: 10, right: 10 })
            .onChange((v, m) => { if(m===SliderChangeMode.End) try{this.avPlayer?.seek(v)}catch(e){} })
          Text(this.formatTime(this.totalTime)).fontSize(12).fontColor('#AAA')
        }.width('90%').margin({ bottom: 20 })

        // 按钮
        Row({ space: 50 }) {
          this.Btn("⏮", 28, () => this.playPrev())
          Button() { Text(this.isPlaying ? "⏸" : "▶").fontSize(32).fontColor(Color.White) }
          .width(72).height(72).borderRadius(36).backgroundColor('#00E5FF').shadow({ radius: 20, color: 'rgba(0,229,255,0.4)' })
          .onClick(() => this.togglePlay())
          this.Btn("⏭", 28, () => this.playNext())
        }
      }
      .width('85%')
      .padding(24)
      .backgroundColor('rgba(255,255,255,0.05)')
      .backdropBlur(30)
      .borderRadius(30)
      .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
      // 核心避让：距离底部 100vp，使控制台浮起来，左下角按钮不被遮挡
      .margin({ bottom: 100 })
    }
    .width('100%').height('100%')
  }

  @Builder Btn(txt: string, size: number, cb: ()=>void) {
    Button(txt).type(ButtonType.Circle).width(60).height(60).fontSize(size).backgroundColor('rgba(255,255,255,0.05)').onClick(cb)
  }
}