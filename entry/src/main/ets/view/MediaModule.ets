import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { MediaResourceService, MediaResourceItem } from '../services/MediaResourceService';
import { CacheService } from '../services/CacheService';
import { common } from '@kit.AbilityKit';

interface LocalMediaItem {
  id: number;
  title: string;
  artist: string;
  cover: string;
  source: string;
  tag: string;
  mediaType: 'music' | 'radio';
}

@Component
export struct MediaModule {
  @Prop isPageVisible: boolean = true;
  @State activeTab: 'music' | 'radio' = 'music';
  @State currentItem: LocalMediaItem | MediaResourceItem | null = null;
  @State isPlaying: boolean = false;
  @State isLoading: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State progress: number = 0;
  @State statusText: string = '请选择内容播放';
  @State rotateAngle: number = 0;
  @State searchKeyword: string = '';
  @State showSearchPanel: boolean = false;
  @State searchResults: MediaResourceItem[] = [];
  @State localEmptyMessage: string = '';

  private avPlayer: media.AVPlayer | undefined;
  private rotateTimer: number = -1;
  private progressTimer: number = -1;
  private resourceService: MediaResourceService = MediaResourceService.getInstance();
  private cacheService: CacheService = CacheService.getInstance();

  private readonly musicItems: LocalMediaItem[] = [
    { id: 1, title: '本地音乐一', artist: 'Rawfile 资源', cover: 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600', source: 'rawfile:sample_music_1.mp3', tag: '离线音乐', mediaType: 'music' },
    { id: 2, title: '本地音乐二', artist: 'Rawfile 资源', cover: 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', source: 'rawfile:sample_music_2.mp3', tag: '离线音乐', mediaType: 'music' }
  ];

  private readonly radioItems: LocalMediaItem[] = [
    { id: 101, title: '晨间电台', artist: '本地电台占位', cover: 'https://images.pexels.com/photos/164938/pexels-photo-164938.jpeg?auto=compress&cs=tinysrgb&w=600', source: 'rawfile:radio_1.mp3', tag: '离线电台', mediaType: 'radio' }
  ];

  aboutToAppear(): void {
    this.currentItem = this.getCurrentList()[0] || null;
    this.initPlayer();
    void this.checkLocalCacheAndLoad();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private getCurrentList(): Array<LocalMediaItem | MediaResourceItem> {
    return this.activeTab === 'music' ? this.musicItems : this.radioItems;
  }

  private async checkLocalCacheAndLoad(): Promise<void> {
    const cacheKey = this.activeTab === 'music' ? 'local_music_cache' : 'local_radio_cache';
    const cached = await this.cacheService.get<Array<LocalMediaItem | MediaResourceItem>>(cacheKey);
    if (!cached || cached.length === 0) {
      this.localEmptyMessage = '没有音乐缓存';
      this.statusText = '没有音乐缓存';
      this.currentItem = null;
      this.searchResults = [];
      return;
    }

    this.localEmptyMessage = '';
    this.currentItem = cached[0] || null;
    this.statusText = '已加载缓存内容';
    if (this.currentItem) {
      await this.loadItem(this.currentItem, false);
    }
  }

  private initPlayer(): void {
    if (this.avPlayer) {
      return;
    }
    media.createAVPlayer().then((player: media.AVPlayer) => {
      this.avPlayer = player;
      this.avPlayer.audioRendererInfo = {
        usage: audio.StreamUsage.STREAM_USAGE_MUSIC,
        rendererFlags: 0
      };
      this.registerPlayerCallbacks();
    }).catch(() => {
      this.statusText = '播放器初始化失败';
    });
  }

  private registerPlayerCallbacks(): void {
    if (!this.avPlayer) {
      return;
    }

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
          void this.playNext();
        }
      } catch (err) {
        console.error('[MediaModule] stateChange error:', JSON.stringify(err));
      }
    });

    this.avPlayer.on('timeUpdate', (time: number) => {
      this.currentTime = time;
      this.progress = this.totalTime > 0 ? Math.min(100, (time / this.totalTime) * 100) : 0;
    });

    this.avPlayer.on('error', () => {
      this.statusText = '播放失败，请检查资源';
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
  }

  private startAnimations(): void {
    this.stopAnimations();
    this.rotateTimer = setInterval(() => {
      this.rotateAngle = (this.rotateAngle + 1.2) % 360;
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
    if (!ms || ms < 0) {
      return '00:00';
    }
    const totalSeconds = Math.floor(ms / 1000);
    const min = Math.floor(totalSeconds / 60).toString().padStart(2, '0');
    const sec = (totalSeconds % 60).toString().padStart(2, '0');
    return `${min}:${sec}`;
  }

  private async loadItem(item: LocalMediaItem | MediaResourceItem, autoplay: boolean = false): Promise<void> {
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
      this.isPlaying = autoplay;

      if (item.sourceType === 'online') {
        await this.avPlayer.reset();
        this.avPlayer.url = item.source;
        this.statusText = autoplay ? '正在播放在线资源...' : '在线资源已加载';
        if (autoplay) {
          await this.avPlayer.play();
        }
        return;
      }

      this.statusText = '请先确认 rawfile 中存在对应离线资源';
      this.localEmptyMessage = '没有音乐缓存';
      this.isPlaying = false;
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

    if (this.currentItem.sourceType === 'local') {
      this.statusText = '没有音乐缓存';
      return;
    }

    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        await this.avPlayer.play();
      }
    } catch (err) {
      console.error('[MediaModule] togglePlay failed:', JSON.stringify(err));
      this.statusText = '播放失败，请重试';
      this.isPlaying = false;
    }
  }

  private async playNext(): Promise<void> {
    const list = this.getCurrentList();
    if (list.length === 0) {
      return;
    }
    const index = list.findIndex((i) => i.id === this.currentItem?.id);
    const next = list[(index + 1) % list.length];
    await this.loadItem(next, true);
  }

  private async playPrev(): Promise<void> {
    const list = this.getCurrentList();
    if (list.length === 0) {
      return;
    }
    const index = list.findIndex((i) => i.id === this.currentItem?.id);
    const prevIndex = index <= 0 ? list.length - 1 : index - 1;
    await this.loadItem(list[prevIndex], true);
  }

  private switchTab(tab: 'music' | 'radio'): void {
    if (this.activeTab === tab) {
      return;
    }
    this.activeTab = tab;
    this.currentItem = this.getCurrentList()[0] || null;
    this.statusText = '正在检查缓存...';
    void this.checkLocalCacheAndLoad();
  }

  private async searchOnlineResources(): Promise<void> {
    const keyword = this.searchKeyword.trim();
    if (keyword === '') {
      this.statusText = '请输入搜索关键词';
      return;
    }

    this.isLoading = true;
    const response = await this.resourceService.getResources(this.activeTab, keyword);
    if (response.code === 200 && response.data) {
      this.searchResults = response.data;
      this.showSearchPanel = true;
      this.statusText = `找到 ${response.data.length} 条在线资源`;
    } else {
      this.searchResults = [];
      this.statusText = response.message || '未找到资源';
    }
    this.isLoading = false;
  }

  @Builder
  private PillButton(title: string, selected: boolean, onClickAction: () => void) {
    Button(title)
      .height(34)
      .padding({ left: 14, right: 14 })
      .backgroundColor(selected ? '#00E5FF' : 'rgba(255,255,255,0.08)')
      .fontColor(selected ? '#08111F' : '#FFFFFF')
      .fontWeight(FontWeight.Medium)
      .borderRadius(17)
      .onClick(onClickAction)
  }

  @Builder
  private MediaCard(item: LocalMediaItem | MediaResourceItem) {
    Row() {
      Image(item.cover)
        .width(62)
        .height(62)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)

      Column() {
        Text(item.tag)
          .fontSize(10)
          .fontColor('#00E5FF')
        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        Text(item.artist)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.65)')
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.06)')
    .borderRadius(18)
    .onClick(() => {
      void this.loadItem(item, false);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#020617')

      Column() {
        Row() {
          Column({ space: 1 }) {
            Text('多媒体娱乐')
              .fontSize(22)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('先查缓存，再搜在线资源')
              .fontSize(10)
              .fontColor('rgba(255,255,255,0.55)')
          }
          .alignItems(HorizontalAlign.Start)

          Button('搜索')
            .height(34)
            .fontSize(12)
            .backgroundColor('#00E5FF')
            .fontColor('#08111F')
            .borderRadius(17)
            .onClick(() => {
              this.showSearchPanel = !this.showSearchPanel;
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 18, right: 18, top: 10, bottom: 6 })

        Row({ space: 10 }) {
          this.PillButton('音乐', this.activeTab === 'music', () => this.switchTab('music'))
          this.PillButton('电台', this.activeTab === 'radio', () => this.switchTab('radio'))
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 8 })

        if (this.showSearchPanel) {
          Row() {
            TextInput({ placeholder: '搜索在线资源，如：天气 / 交通 / 轻音乐' })
              .layoutWeight(1)
              .height(40)
              .onChange((value: string) => {
                this.searchKeyword = value;
              })
            Button('查找')
              .height(40)
              .margin({ left: 8 })
              .backgroundColor('#00E5FF')
              .fontColor('#08111F')
              .borderRadius(20)
              .onClick(() => {
                void this.searchOnlineResources();
              })
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 8 })
        }

        Row() {
          Stack({ alignContent: Alignment.Center }) {
            if (this.currentItem) {
              Image(this.currentItem.cover)
                .width(120)
                .height(120)
                .borderRadius(18)
                .rotate({ angle: this.rotateAngle })
                .objectFit(ImageFit.Cover)
            }
          }
          .width(132)
          .height(132)

          Column() {
            if (this.currentItem) {
              Text(this.currentItem.title)
                .fontSize(18)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
                .maxLines(1)
                .textOverflow({ overflow: TextOverflow.Ellipsis })
              Text(this.currentItem.artist)
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.65)')
                .margin({ top: 4 })
            } else {
              Text(this.localEmptyMessage || '没有音乐缓存')
                .fontSize(16)
                .fontColor('#FFFFFF')
            }
          }
          .layoutWeight(1)
          .alignItems(HorizontalAlign.Start)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding(14)
        .margin({ left: 18, right: 18, top: 2 })
        .backgroundColor('rgba(255,255,255,0.06)')
        .borderRadius(20)
        .border({ width: 1, color: 'rgba(255,255,255,0.08)' })

        Row() {
          Row({ space: 10 }) {
            Button('⏮')
              .width(46)
              .height(46)
              .borderRadius(23)
              .backgroundColor('rgba(255,255,255,0.08)')
              .fontColor('#FFFFFF')
              .onClick(() => { void this.playPrev(); })
            Button(this.isPlaying ? '⏸' : '▶')
              .width(62)
              .height(62)
              .borderRadius(31)
              .backgroundColor('#00E5FF')
              .fontColor('#08111F')
              .fontWeight(FontWeight.Bold)
              .onClick(() => { void this.togglePlay(); })
            Button('⏭')
              .width(46)
              .height(46)
              .borderRadius(23)
              .backgroundColor('rgba(255,255,255,0.08)')
              .fontColor('#FFFFFF')
              .onClick(() => { void this.playNext(); })
          }

          Column() {
            Row() {
              Text(this.formatTime(this.currentTime))
                .fontSize(10)
                .fontColor('rgba(255,255,255,0.55)')
              Slider({ value: this.progress, min: 0, max: 100 })
                .layoutWeight(1)
                .margin({ left: 8, right: 8 })
                .trackColor('rgba(255,255,255,0.10)')
                .selectedColor('#00E5FF')
              Text(this.formatTime(this.totalTime))
                .fontSize(10)
                .fontColor('rgba(255,255,255,0.55)')
            }
            .width('100%')

            Text(this.statusText)
              .fontSize(10)
              .fontColor('rgba(255,255,255,0.55)')
              .margin({ top: 4 })
          }
          .layoutWeight(1)
          .margin({ left: 12 })
        }
        .width('100%')
        .padding({ left: 18, right: 18, top: 10, bottom: 10 })
        .margin({ left: 18, right: 18, top: 10 })
        .backgroundColor('rgba(255,255,255,0.05)')
        .borderRadius(20)

        Column() {
          Text(this.activeTab === 'music' ? '本地音乐缓存 / 在线资源' : '本地电台缓存 / 在线资源')
            .fontSize(14)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
            .margin({ bottom: 8 })

          if (this.searchResults.length > 0) {
            Text('在线搜索结果')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.55)')
              .margin({ bottom: 6 })

            List({ space: 8 }) {
              ForEach(this.searchResults, (item: MediaResourceItem) => {
                ListItem() {
                  this.MediaCard(item)
                }
              })
            }
            .width('100%')
            .height('45%')
          }

          List({ space: 8 }) {
            ForEach(this.getCurrentList(), (item: LocalMediaItem | MediaResourceItem) => {
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
        .padding({ left: 18, right: 18, top: 10, bottom: 12 })
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
