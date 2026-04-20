import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { avSession } from '@kit.AVSessionKit';
import { common } from '@kit.AbilityKit';

export interface MediaItem {
  id: number;
  title: string;
  artist: string;
  cover: string;
  url: string;
  tag: string;
}

enum MediaTab {
  MUSIC = 0,
  RADIO = 1,
  VIDEO = 2
}

@Component
export struct MediaModule {
  @Prop isPageVisible: boolean = true;

  @State activeTab: MediaTab = MediaTab.MUSIC;
  @State currentItem: MediaItem | null = null;
  @State isPlaying: boolean = false;
  @State isLoading: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State progress: number = 0;
  @State statusText: string = '请选择内容播放';
  @State rotateAngle: number = 0;

  private avPlayer: media.AVPlayer | undefined;
  private session: avSession.AVSession | undefined;
  private rotateTimer: number = -1;
  private progressTimer: number = -1;

  private readonly musicList: MediaItem[] = [
    { id: 1, title: 'Midnight City', artist: 'SoundHelix Demo', cover: 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-1.mp3', tag: '在线音乐' },
    { id: 2, title: 'Ocean Pulse', artist: 'SoundHelix Demo', cover: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-2.mp3', tag: '在线音乐' },
    { id: 3, title: 'Shape of Air', artist: 'SoundHelix Demo', cover: 'https://images.pexels.com/photos/1763075/pexels-photo-1763075.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-3.mp3', tag: '在线音乐' }
  ];

  private readonly radioList: MediaItem[] = [
    { id: 101, title: 'Morning FM', artist: '新闻 / 交通 / 天气', cover: 'https://images.pexels.com/photos/164938/pexels-photo-164938.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-4.mp3', tag: '在线电台' },
    { id: 102, title: 'Travel Radio', artist: '轻音乐 / 伴驾', cover: 'https://images.pexels.com/photos/3394650/pexels-photo-3394650.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-5.mp3', tag: '在线电台' },
    { id: 103, title: 'City FM', artist: '本地资讯 / 路况', cover: 'https://images.pexels.com/photos/111288/pexels-photo-111288.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-6.mp3', tag: '在线电台' }
  ];

  private readonly videoList: MediaItem[] = [
    { id: 201, title: 'Trip Memories', artist: '行车记录片段', cover: 'https://images.pexels.com/photos/276781/pexels-photo-276781.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-7.mp3', tag: '视频模拟' },
    { id: 202, title: 'City View', artist: '风景影像模拟', cover: 'https://images.pexels.com/photos/210182/pexels-photo-210182.jpeg?auto=compress&cs=tinysrgb&w=600', url: 'https://www.soundhelix.com/examples/mp3/SoundHelix-Song-8.mp3', tag: '视频模拟' }
  ];

  private getCurrentList(): MediaItem[] {
    if (this.activeTab === MediaTab.RADIO) return this.radioList;
    if (this.activeTab === MediaTab.VIDEO) return this.videoList;
    return this.musicList;
  }

  aboutToAppear(): void {
    this.currentItem = this.getCurrentList()[0];
    this.initMedia();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private async initMedia(): Promise<void> {
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      this.session = await avSession.createAVSession(context, 'CarMediaSession', 'audio');
      await this.session.activate();
      this.initPlayer();
      this.statusText = '已就绪，选择一首开始播放';
    } catch (err) {
      console.error('[MediaModule] initMedia failed:', JSON.stringify(err));
      this.statusText = '媒体模块初始化失败';
    }
  }

  private initPlayer(): void {
    if (this.avPlayer) {
      return;
    }
    media.createAVPlayer().then((player) => {
      this.avPlayer = player;
      this.avPlayer.audioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };
      this.registerPlayerCallbacks();
      if (this.currentItem) {
        this.avPlayer.url = this.currentItem.url;
      }
    }).catch((err) => {
      console.error('[MediaModule] createAVPlayer failed:', JSON.stringify(err));
      this.statusText = '播放器初始化失败';
    });
  }

  private registerPlayerCallbacks(): void {
    if (!this.avPlayer) return;

    this.avPlayer.on('stateChange', async (state: media.AVPlayerState) => {
      try {
        if (state === 'initialized') {
          await this.avPlayer?.prepare();
        } else if (state === 'prepared') {
          this.totalTime = this.avPlayer?.duration || 0;
          if (this.isPlaying) {
            await this.avPlayer?.play();
          }
        } else if (state === 'playing') {
          this.isPlaying = true;
          this.statusText = '正在播放';
          this.startAnimations();
        } else if (state === 'paused') {
          this.isPlaying = false;
          this.statusText = '已暂停';
          this.stopAnimations();
        } else if (state === 'completed') {
          this.playNext();
        }
      } catch (err) {
        console.error('[MediaModule] stateChange error:', JSON.stringify(err));
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.currentTime = time;
      this.progress = this.totalTime > 0 ? Math.min(100, (time / this.totalTime) * 100) : 0;
    });

    this.avPlayer.on('error', (err) => {
      console.error('[MediaModule] player error:', JSON.stringify(err));
      this.statusText = '播放失败，请重试';
      this.isPlaying = false;
      this.stopAnimations();
    });
  }

  private cleanup(): void {
    this.stopAnimations();
    try {
      this.avPlayer?.release();
    } catch (err) {
      console.error('[MediaModule] release failed:', JSON.stringify(err));
    }
    try {
      this.session?.destroy();
    } catch (err) {
      console.error('[MediaModule] session destroy failed:', JSON.stringify(err));
    }
  }

  private startAnimations(): void {
    this.stopAnimations();
    this.rotateTimer = setInterval(() => {
      this.rotateAngle = (this.rotateAngle + 1.5) % 360;
    }, 30);
    this.progressTimer = setInterval(() => {
      if (this.isPlaying && this.totalTime > 0 && this.currentTime < this.totalTime) {
        this.currentTime += 1000;
        this.progress = Math.min(100, (this.currentTime / this.totalTime) * 100);
      }
    }, 1000);
  }

  private stopAnimations(): void {
    if (this.rotateTimer !== -1) {
      clearInterval(this.rotateTimer);
      this.rotateTimer = -1;
    }
    if (this.progressTimer !== -1) {
      clearInterval(this.progressTimer);
      this.progressTimer = -1;
    }
  }

  private formatTime(ms: number): string {
    if (!ms || ms < 0) return '00:00';
    const totalSeconds = Math.floor(ms / 1000);
    const min = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
    const sec = (totalSeconds % 60).toString().padStart(2, '0');
    return `${min}:${sec}`;
  }

  private async loadItem(item: MediaItem, autoplay: boolean = false): Promise<void> {
    if (!this.avPlayer) {
      this.statusText = '播放器未就绪';
      return;
    }

    try {
      this.isLoading = true;
      this.currentItem = item;
      this.currentTime = 0;
      this.totalTime = 0;
      this.progress = 0;
      this.rotateAngle = 0;
      this.statusText = autoplay ? '正在播放...' : '已加载，点击播放';
      this.isPlaying = autoplay;

      await this.avPlayer.reset();
      this.avPlayer.url = item.url;
    } catch (err) {
      console.error('[MediaModule] loadItem failed:', JSON.stringify(err));
      this.statusText = '加载失败';
      this.isPlaying = false;
    } finally {
      this.isLoading = false;
    }
  }

  private async togglePlay(): Promise<void> {
    if (!this.avPlayer || !this.currentItem) {
      this.statusText = '播放器未就绪';
      return;
    }

    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        if (this.totalTime === 0) {
          this.isPlaying = true;
          await this.avPlayer.play();
        } else {
          await this.avPlayer.play();
        }
      }
    } catch (err) {
      console.error('[MediaModule] togglePlay failed:', JSON.stringify(err));
      this.statusText = '播放失败，请重试';
      this.isPlaying = false;
    }
  }

  private async playNext(): Promise<void> {
    const list = this.getCurrentList();
    const index = list.findIndex((i) => i.id === this.currentItem?.id);
    const next = list[(index + 1) % list.length];
    await this.loadItem(next, true);
  }

  private async playPrev(): Promise<void> {
    const list = this.getCurrentList();
    const index = list.findIndex((i) => i.id === this.currentItem?.id);
    const prevIndex = index <= 0 ? list.length - 1 : index - 1;
    await this.loadItem(list[prevIndex], true);
  }

  private switchTab(tab: MediaTab): void {
    this.activeTab = tab;
    const first = this.getCurrentList()[0];
    if (first) {
      void this.loadItem(first, false);
    }
  }

  @Builder
  private TabButton(title: string, tab: MediaTab) {
    Button(title)
      .height(40)
      .padding({ left: 18, right: 18 })
      .backgroundColor(this.activeTab === tab ? '#00E5FF' : 'rgba(255,255,255,0.08)')
      .fontColor(this.activeTab === tab ? '#08111F' : '#FFFFFF')
      .fontWeight(FontWeight.Medium)
      .borderRadius(20)
      .onClick(() => this.switchTab(tab))
  }

  @Builder
  private MediaCard(item: MediaItem) {
    Row() {
      Image(item.cover)
        .width(74)
        .height(74)
        .borderRadius(18)
        .objectFit(ImageFit.Cover)

      Column() {
        Text(item.tag)
          .fontSize(10)
          .fontColor('#00E5FF')
          .padding({ left: 8, right: 8, top: 4, bottom: 4 })
          .backgroundColor('rgba(0,229,255,0.12)')
          .borderRadius(10)

        Text(item.title)
          .fontSize(16)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 8 })

        Text(item.artist)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.65)')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 14 })
    }
    .width('100%')
    .padding(14)
    .backgroundColor('rgba(255,255,255,0.06)')
    .borderRadius(22)
    .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
    .onClick(() => {
      void this.loadItem(item, false);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column() {
        LinearGradient({
          angle: 135,
          colors: [['#09111F', 0], ['#102A43', 0.45], ['#020617', 1]]
        })
        .width('100%')
        .height('100%')
      }

      Column() {
        // 顶部标题
        Row() {
          Column({ space: 4 }) {
            Text('多媒体娱乐')
              .fontSize(26)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('在线音乐 · 电台收听 · 视频模拟播放')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          }
          .alignItems(HorizontalAlign.Start)

          Text(this.statusText)
            .fontSize(12)
            .fontColor('#00E5FF')
            .padding({ left: 12, right: 12, top: 8, bottom: 8 })
            .backgroundColor('rgba(0,229,255,0.12)')
            .borderRadius(999)
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 20, right: 20, top: 20, bottom: 12 })

        // 切换标签
        Row({ space: 12 }) {
          this.TabButton('音乐', MediaTab.MUSIC)
          this.TabButton('电台', MediaTab.RADIO)
          this.TabButton('视频', MediaTab.VIDEO)
        }
        .width('100%')
        .padding({ left: 20, right: 20, bottom: 12 })

        // 当前封面区
        Stack({ alignContent: Alignment.Center }) {
          if (this.currentItem) {
            Image(this.currentItem.cover)
              .width(240)
              .height(240)
              .borderRadius(120)
              .rotate({ angle: this.rotateAngle })
              .objectFit(ImageFit.Cover)
              .shadow({ radius: 30, color: 'rgba(0,0,0,0.45)', offsetY: 10 })

            Circle({ width: 82, height: 82 })
              .fill('rgba(8,17,31,0.92)')
              .border({ width: 8, color: 'rgba(255,255,255,0.05)' })
          }
        }
        .width('100%')
        .height(290)
        .margin({ top: 10 })

        if (this.currentItem) {
          Column({ space: 8 }) {
            Text(this.currentItem.title)
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .maxLines(1)
              .textOverflow({ overflow: TextOverflow.Ellipsis })
            Text(this.currentItem.artist)
              .fontSize(14)
              .fontColor('rgba(255,255,255,0.65)')
          }
          .width('100%')
          .alignItems(HorizontalAlign.Center)
          .margin({ top: 4 })
        }

        // 进度与控制区
        Column() {
          Row() {
            Text(this.formatTime(this.currentTime))
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.65)')
            Slider({ value: this.progress, min: 0, max: 100 })
              .layoutWeight(1)
              .margin({ left: 12, right: 12 })
              .trackColor('rgba(255,255,255,0.10)')
              .selectedColor('#00E5FF')
            Text(this.formatTime(this.totalTime))
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.65)')
          }
          .width('100%')
          .margin({ bottom: 18 })

          Row({ space: 22 }) {
            Button('⏮')
              .width(58)
              .height(58)
              .borderRadius(29)
              .fontSize(24)
              .backgroundColor('rgba(255,255,255,0.08)')
              .fontColor('#FFFFFF')
              .onClick(() => { void this.playPrev(); })

            Button(this.isPlaying ? '⏸' : '▶')
              .width(82)
              .height(82)
              .borderRadius(41)
              .fontSize(32)
              .backgroundColor('#00E5FF')
              .fontColor('#08111F')
              .fontWeight(FontWeight.Bold)
              .shadow({ radius: 18, color: 'rgba(0,229,255,0.35)', offsetY: 8 })
              .onClick(() => { void this.togglePlay(); })

            Button('⏭')
              .width(58)
              .height(58)
              .borderRadius(29)
              .fontSize(24)
              .backgroundColor('rgba(255,255,255,0.08)')
              .fontColor('#FFFFFF')
              .onClick(() => { void this.playNext(); })
          }
          .width('100%')
          .justifyContent(FlexAlign.Center)
        }
        .width('100%')
        .padding(20)
        .margin({ top: 14 })
        .backgroundColor('rgba(255,255,255,0.05)')
        .backdropBlur(28)
        .borderRadius(28)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

        // 列表
        Column() {
          Row() {
            Text(this.activeTab === MediaTab.MUSIC ? '在线音乐' : this.activeTab === MediaTab.RADIO ? '在线电台' : '视频模拟')
              .fontSize(16)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('点击任意条目切换')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.55)')
          }
          .width('100%')
          .justifyContent(FlexAlign.SpaceBetween)
          .margin({ bottom: 12 })

          List({ space: 12 }) {
            ForEach(this.getCurrentList(), (item: MediaItem) => {
              ListItem() {
                this.MediaCard(item)
              }
            })
          }
          .width('100%')
          .layoutWeight(1)
        }
        .width('100%')
        .layoutWeight(1)
        .padding({ left: 20, right: 20, top: 18, bottom: 20 })
      }
      .width('100%')
      .height('100%')
    }
    .width('100%')
    .height('100%')
    .onAppear(() => {
      if (this.currentItem) {
        void this.loadItem(this.currentItem, false);
      }
    })
  }
}
