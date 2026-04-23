import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { CacheService } from '../services/CacheService';

class LocalMediaItem {
  id: number;
  title: string;
  artist: string;
  cover: string;
  source: string;
  tag: string;
  mediaType: 'music' | 'radio';

  constructor(id: number, title: string, artist: string, cover: string, source: string, tag: string, mediaType: 'music' | 'radio') {
    this.id = id;
    this.title = title;
    this.artist = artist;
    this.cover = cover;
    this.source = source;
    this.tag = tag;
    this.mediaType = mediaType;
  }
}

class LyricLine {
  time: number;
  text: string;

  constructor(time: number, text: string) {
    this.time = time;
    this.text = text;
  }
}

class LyricRenderLine {
  time: number;
  text: string;
  isActive: boolean;

  constructor(time: number, text: string, isActive: boolean) {
    this.time = time;
    this.text = text;
    this.isActive = isActive;
  }
}

enum TabType {
  MUSIC = 0,
  RADIO = 1
}

@Component
export struct MediaModule {
  @Prop isPageVisible: boolean = true;

  @State activeTab: TabType = TabType.MUSIC;
  @State currentItem: LocalMediaItem | null = null;
  @State defaultCoverVisible: boolean = true;
  @State isPlaying: boolean = false;
  @State isLoading: boolean = false;
  @State currentTime: number = 0;
  @State totalTime: number = 0;
  @State progress: number = 0;
  @State statusText: string = '请选择内容播放';
  @State rotateAngle: number = 0;
  @State showSearchPanel: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: Array<LocalMediaItem> = [];
  @State isSearchPanelVisible: boolean = false;
  @State emptyHint: string = '';
  @State viewToken: number = 0;
  @State contentOpacity: number = 1;
  @State contentOffset: number = 0;
  @State activeAccent: string = '#38BDF8';
  @State activeFill: string = 'rgba(56,189,248,0.18)';
  @State activeTabBorder: string = '#38BDF8';
  @State activeGlow: string = 'rgba(56,189,248,0.22)';
  @State isSeeking: boolean = false;

  private avPlayer: media.AVPlayer | undefined;
  private pendingAutoplay: boolean = false;
  private rotateTimer: number = -1;
  private cacheService: CacheService = CacheService.getInstance();
  private rawFileDescriptors: Map<string, media.AVFileDescriptor | null> = new Map();
  private lyricScroller: Scroller = new Scroller();
  private readonly defaultCover: string = 'https://images.pexels.com/photos/16767318/pexels-photo-16767318.jpeg?auto=compress&cs=tinysrgb&w=600';

  private readonly musicItems: LocalMediaItem[] = [
    new LocalMediaItem(1, '发如雪', '本地缓存', 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_1.mp3', '离线音乐', 'music'),
    new LocalMediaItem(2, '听妈妈的话', '本地缓存', 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_2.mp3', '离线音乐', 'music'),
    new LocalMediaItem(3, '以父之名', '本地缓存', 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_3.mp3', '离线音乐', 'music')
  ];

  private readonly radioItems: LocalMediaItem[] = [
    new LocalMediaItem(101, '晨间电台', '本地缓存', 'https://images.pexels.com/photos/164938/pexels-photo-164938.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:radio_1.mp3', '离线电台', 'radio')
  ];

  private readonly lyricMap: Map<number, LyricLine[]> = new Map<number, LyricLine[]>([
    [1, [
      new LyricLine(0, '冰雪覆盖了青瓦'),
      new LyricLine(12000, '我在等一场大雨落下'),
      new LyricLine(23000, '灯火映着你脸颊'),
      new LyricLine(34000, '把思念慢慢融化'),
      new LyricLine(45000, '一夜风雪吹不散牵挂')
    ]],
    [2, [
      new LyricLine(0, '窗外的天空还没亮'),
      new LyricLine(11000, '妈妈的声音已经在回响'),
      new LyricLine(22000, '那些简单的话'),
      new LyricLine(32000, '陪我一路长大'),
      new LyricLine(44000, '像一束光照进心房')
    ]],
    [3, [
      new LyricLine(0, '我听见钟声在回荡'),
      new LyricLine(13000, '黑夜里名字被轻轻念唱'),
      new LyricLine(26000, '沿着命运的走廊'),
      new LyricLine(38000, '把沉默都收藏'),
      new LyricLine(50000, '只剩心跳还在发烫')
    ]]
  ]);

  private async getRawFileDescriptor(fileName: string): Promise<media.AVFileDescriptor | null> {
    if (this.rawFileDescriptors.has(fileName)) {
      return this.rawFileDescriptors.get(fileName) || null;
    }

    try {
      const context = getContext() as common.Context;
      const resourceManager = context.resourceManager;
      const rawName = fileName.replace('rawfile:', '');
      const descriptor = await resourceManager.getRawFd(rawName);
      this.rawFileDescriptors.set(fileName, descriptor);
      return descriptor;
    } catch (err) {
      console.error('[MediaModule] getRawFileDescriptor failed:', JSON.stringify(err));
      this.rawFileDescriptors.set(fileName, null);
      return null;
    }
  }

  aboutToAppear(): void {
    this.initPlayer();
    this.defaultCoverVisible = !this.currentItem && !this.isPlaying;
    void this.loadLocalCache();
  }

  aboutToDisappear(): void {
    this.cleanup();
  }

  private getCurrentList(): LocalMediaItem[] {
    return this.activeTab === TabType.MUSIC ? this.musicItems : this.radioItems;
  }

  private async loadLocalCache(): Promise<void> {
    const key = this.activeTab === TabType.MUSIC ? 'local_music_cache' : 'local_radio_cache';
    const cached = await this.cacheService.get<Array<LocalMediaItem>>(key);
    this.updateAccent();

    if (cached && cached.length > 0) {
      this.emptyHint = '';
      if (!this.currentItem && !this.isPlaying) {
        this.defaultCoverVisible = true;
      }
      this.statusText = '已加载本地缓存';
      this.searchResults = [];
      this.viewToken++;
      return;
    }

    this.emptyHint = '没有音乐缓存';
    this.statusText = '没有音乐缓存';
    if (!this.currentItem && !this.isPlaying) {
      this.defaultCoverVisible = true;
    }
    this.searchResults = [];
    this.viewToken++;
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
          if (this.pendingAutoplay) {
            this.pendingAutoplay = false;
            this.isPlaying = true;
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
      if (this.isSeeking) {
        return;
      }
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
  }

  private stopAnimations(): void {
    if (this.rotateTimer !== -1) {
      clearInterval(this.rotateTimer);
      this.rotateTimer = -1;
    }
  }

  private getCurrentLyrics(): LyricLine[] {
    if (this.defaultCoverVisible || !this.currentItem || this.currentItem.mediaType !== 'music') {
      return [];
    }
    return this.lyricMap.get(this.currentItem.id) || [];
  }

  private getRenderedLyrics(): LyricRenderLine[] {
    const lyrics = this.getCurrentLyrics();
    if (lyrics.length === 0) {
      return [new LyricRenderLine(0, '暂无歌词', true)];
    }

    let activeIndex = 0;
    for (let index = 0; index < lyrics.length; index++) {
      if (this.currentTime >= lyrics[index].time) {
        activeIndex = index;
      } else {
        break;
      }
    }

    return lyrics.map((line, index) => new LyricRenderLine(line.time, line.text, index === activeIndex));
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

  private async loadItem(item: LocalMediaItem, autoplay: boolean = false): Promise<void> {
    if (!this.avPlayer) {
      this.statusText = '播放器未就绪';
      return;
    }

    try {
      this.isLoading = true;
      this.defaultCoverVisible = false;
      this.currentItem = item;
      this.currentTime = 0;
      this.totalTime = 0;
      this.progress = 0;
      this.rotateAngle = 0;
      this.isPlaying = autoplay;
      this.pendingAutoplay = autoplay;

      const localItem = item;
      this.defaultCoverVisible = false;
      this.currentItem = localItem;
      this.statusText = `本地缓存：${localItem.title}`;
      this.emptyHint = '';
      this.isPlaying = autoplay;
      if (!this.avPlayer) {
        this.statusText = '播放器未就绪';
        return;
      }
      const rawFile = await this.getRawFileDescriptor(localItem.source);
      if (!rawFile) {
        this.statusText = '找不到本地音频资源';
        return;
      }
      await this.avPlayer.reset();
      this.avPlayer.fdSrc = rawFile;
      await this.avPlayer.prepare();
      this.pendingAutoplay = autoplay;
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

    const localItem = this.currentItem as LocalMediaItem;
    this.statusText = `本地缓存：${localItem.title}`;

    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        this.pendingAutoplay = false;
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

  private updateAccent(): void {
    if (this.activeTab === TabType.MUSIC) {
      this.activeAccent = '#38BDF8';
      this.activeFill = 'rgba(56,189,248,0.22)';
      this.activeTabBorder = '#38BDF8';
      this.activeGlow = 'rgba(56,189,248,0.26)';
    } else {
      this.activeAccent = '#818CF8';
      this.activeFill = 'rgba(129,140,248,0.22)';
      this.activeTabBorder = '#818CF8';
      this.activeGlow = 'rgba(129,140,248,0.26)';
    }
  }

  private async switchTab(tab: TabType): Promise<void> {
    if (this.activeTab === tab) {
      if (tab === TabType.MUSIC) {
        this.searchResults = [];
        this.searchKeyword = '';
        this.isSearchPanelVisible = false;
      }
      void this.loadLocalCache();
      return;
    }

    this.contentOpacity = 0;
    this.contentOffset = 14;
    setTimeout(() => {
      this.activeTab = tab;
      this.updateAccent();
      this.statusText = tab === TabType.MUSIC ? '当前为音乐模式' : '当前为电台模式';
      this.searchResults = [];
      this.searchKeyword = '';
      this.isSearchPanelVisible = false;
      this.emptyHint = '';
      void this.loadLocalCache();
      setTimeout(() => {
        this.contentOpacity = 1;
        this.contentOffset = 0;
      }, 80);
    }, 120);
  }

  private async searchOnlineResources(): Promise<void> {
    const keyword = this.searchKeyword.trim();
    if (keyword === '') {
      this.searchResults = [];
      this.statusText = '请输入搜索关键词';
      return;
    }

    this.searchResults = this.getCurrentList().filter((item) =>
      item.title.includes(keyword) || item.artist.includes(keyword)
    );
    this.statusText = this.searchResults.length > 0 ? `找到 ${this.searchResults.length} 条本地结果` : '未找到匹配歌曲';

    this.isSearchPanelVisible = false;
  }

  private openSearchPanel(): void {
    this.isSearchPanelVisible = true;
  }

  private closeSearchPanel(): void {
    this.isSearchPanelVisible = false;
    this.searchKeyword = '';
    this.searchResults = [];
    this.loadLocalCache();
  }

  private onSearchKeywordChange(value: string): void {
    this.searchKeyword = value;
  }

  private async seekToLyric(time: number): Promise<void> {
    if (!this.avPlayer || this.totalTime <= 0) {
      return;
    }
    const target = Math.max(0, Math.min(time, this.totalTime));
    const progressValue = Math.min(100, Math.max(0, (target / this.totalTime) * 100));
    this.isSeeking = true;
    this.currentTime = target;
    this.progress = progressValue;
    try {
      await this.avPlayer.seek(target);
    } catch (err) {
      console.error('[MediaModule] seekToLyric failed:', JSON.stringify(err));
    } finally {
      this.isSeeking = false;
    }
  }

  @Builder
  private PillButton(title: string, selected: boolean, onClickAction: () => void) {
    Button(title)
      .height(36)
      .padding({ left: 16, right: 16 })
      .backgroundColor(selected ? this.activeFill : 'rgba(255,255,255,0.08)')
      .fontColor(selected ? '#08111F' : '#FFFFFF')
      .fontWeight(FontWeight.Medium)
      .border({ width: selected ? 1.2 : 0.6, color: selected ? this.activeTabBorder : 'rgba(255,255,255,0.12)' })
      .borderRadius(18)
      .shadow(selected ? { radius: 14, color: this.activeGlow, offsetY: 4 } : undefined)
      .onClick(onClickAction)
  }

  @Builder
  private MediaCard(item: LocalMediaItem) {
    Row() {
      Image(item.cover)
        .width(72)
        .height(72)
        .borderRadius(16)
        .objectFit(ImageFit.Cover)

      Column() {
        Text(item.tag)
          .fontSize(10)
          .fontColor(this.activeAccent)
          .padding({ left: 8, right: 8, top: 3, bottom: 3 })
          .backgroundColor(this.activeFill)
          .borderRadius(8)

        Text(item.title)
          .fontSize(15)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 6 })

        Text(item.artist)
          .fontSize(11)
          .fontColor('rgba(255,255,255,0.65)')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      .margin({ left: 12 })
    }
    .width('100%')
    .padding(12)
    .backgroundColor('rgba(255,255,255,0.05)')
    .borderRadius(16)
    .onClick(() => {
      void this.loadItem(item, true);
    })
  }

  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      Column()
        .width('100%')
        .height('100%')
        .backgroundColor('#0B1220')

      Column() {
        Row() {
          Column({ space: 2 }) {
            Text('多媒体娱乐')
              .fontSize(21)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
            Text('音乐主功能 · 电台独立 · 在线搜索')
              .fontSize(10)
              .fontColor('rgba(255,255,255,0.55)')
          }
          .alignItems(HorizontalAlign.Start)

          Button('搜索')
            .height(34)
            .fontSize(12)
            .backgroundColor('#38BDF8')
            .fontColor('#08111F')
            .borderRadius(17)
            .margin({ top: 24, bottom: 2 })
            .onClick(() => {
              this.openSearchPanel();
            })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 18, right: 18, top: 10, bottom: 8 })

        Row({ space: 10 }) {
          this.PillButton('音乐', this.activeTab === TabType.MUSIC, () => { void this.switchTab(TabType.MUSIC); })
          this.PillButton('电台', this.activeTab === TabType.RADIO, () => { void this.switchTab(TabType.RADIO); })
        }
        .width('100%')
        .padding({ left: 18, right: 18, bottom: 8 })

        Text(this.emptyHint)
          .fontSize(12)
          .fontColor(this.activeAccent)
          .padding({ left: 18, right: 18, bottom: 6 })

        if (this.isSearchPanelVisible) {
          Stack() {
            Rect()
              .width('100%')
              .height('100%')
              .fill('rgba(3, 7, 18, 0.30)')
              .onClick(() => {
                this.closeSearchPanel();
              })

            Column() {
              Text('在线资源搜索')
                .fontSize(14)
                .fontColor('#FFFFFF')
                .fontWeight(FontWeight.Bold)
                .margin({ bottom: 10 })

              Row() {
                TextInput({ placeholder: '搜索歌曲名或歌手名' })
                  .layoutWeight(1)
                  .height(42)
                  .backgroundColor('rgba(11, 18, 32, 0.96)')
                  .fontColor('#FFFFFF')
                  .placeholderColor('rgba(255,255,255,0.45)')
                  .borderRadius(21)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.onSearchKeywordChange(value);
                  })

                Button('查找')
                  .height(42)
                  .margin({ left: 8 })
                  .backgroundColor('#38BDF8')
                  .fontColor('#08111F')
                  .borderRadius(21)
                  .onClick(() => {
                    void this.searchOnlineResources();
                  })
              }
              .width('100%')
            }
            .width('92%')
            .padding(14)
            .backgroundColor('rgba(9, 15, 28, 0.98)')
            .borderRadius(20)
            .shadow({ radius: 16, color: 'rgba(0,0,0,0.35)', offsetY: 8 })
          }
          .width('100%')
          .height('100%')
          .padding({ top: 138, left: 0, right: 0, bottom: 0 })
          .position({ x: 0, y: 0 })
          .zIndex(9999)
        }

        Column() {
          Row() {
            Stack({ alignContent: Alignment.Center }) {
              if (this.defaultCoverVisible || !this.currentItem) {
                Stack({ alignContent: Alignment.Center }) {
                  Circle()
                    .width(132)
                    .height(132)
                    .fill('rgba(255,255,255,0.04)')

                  Circle()
                    .width(118)
                    .height(118)
                    .fill('rgba(255,255,255,0.08)')

                  Circle()
                    .width(86)
                    .height(86)
                    .fill('rgba(56,189,248,0.22)')

                  Image('https://images.pexels.com/photos/16767318/pexels-photo-16767318.jpeg?auto=compress&cs=tinysrgb&w=600')
                    .width(78)
                    .height(78)
                    .borderRadius(39)
                    .rotate({ angle: this.rotateAngle })
                    .objectFit(ImageFit.Cover)
                }
                .width(132)
                .height(132)
              } else {
                Image(this.currentItem.cover)
                  .width(132)
                  .height(132)
                  .borderRadius(20)
                  .rotate({ angle: this.rotateAngle })
                  .objectFit(ImageFit.Cover)
              }
            }
            .width('44%')
            .height(160)

            Column() {
              if (!this.defaultCoverVisible && this.currentItem) {
                Text('歌词')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                  .margin({ bottom: 10 })

                Scroll(this.lyricScroller) {
                  Column({ space: 10 }) {
                    ForEach(this.getRenderedLyrics(), (line: LyricRenderLine) => {
                      Text(line.text)
                        .fontSize(line.isActive ? 18 : 13)
                        .fontWeight(line.isActive ? FontWeight.Bold : FontWeight.Normal)
                        .fontColor(line.isActive ? '#FFFFFF' : 'rgba(255,255,255,0.42)')
                        .backgroundColor(line.isActive ? 'rgba(56,189,248,0.22)' : 'transparent')
                        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                        .borderRadius(10)
                        .width('100%')
                        .onClick(() => {
                          void this.seekToLyric(line.time);
                        })
                    }, (line: LyricRenderLine) => `${line.time}-${line.text}`)
                  }
                  .width('100%')
                  .padding({ right: 10 })
                }
                .layoutWeight(1)
                .scrollBar(BarState.Off)
              } else {
                Text('')
                  .fontSize(13)
              }
            }
            .layoutWeight(1)
            .height(160)
            .alignItems(HorizontalAlign.Start)
            .margin({ left: 16 })
          }
          .width('100%')
          .padding(16)
          .backgroundColor('rgba(255,255,255,0.06)')
          .borderRadius(20)
          .border({ width: 1, color: 'rgba(255,255,255,0.10)' })
          .margin({ left: 18, right: 18, top: 2 })
          .opacity(this.contentOpacity)
          .translate({ x: 0, y: this.contentOffset })

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
                .backgroundColor('#38BDF8')
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
            .alignItems(VerticalAlign.Center)

            Column() {
              Row() {
                Text(this.formatTime(this.currentTime))
                  .fontSize(10)
                  .fontColor('rgba(255,255,255,0.55)')
                Slider({ value: this.progress, min: 0, max: 100 })
                  .layoutWeight(1)
                  .margin({ left: 8, right: 8 })
                  .trackColor('rgba(255,255,255,0.10)')
                  .selectedColor('#38BDF8')
                  .onChange(async (value: number) => {
                    const clamped = Math.max(0, Math.min(100, value));
                    const target = this.totalTime > 0 ? Math.floor((clamped / 100) * this.totalTime) : 0;
                    this.isSeeking = true;
                    this.progress = clamped;
                    this.currentTime = target;
                    try {
                      await this.avPlayer?.seek(target);
                    } catch (err) {
                      console.error('[MediaModule] seek failed:', JSON.stringify(err));
                    } finally {
                      this.isSeeking = false;
                    }
                  })
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
          .backgroundColor('rgba(255,255,255,0.04)')
          .borderRadius(18)
          .opacity(this.contentOpacity)
          .translate({ x: 0, y: this.contentOffset })

          Column() {
            Text(this.activeTab === TabType.MUSIC ? '音乐列表' : '电台列表')
              .fontSize(14)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .margin({ bottom: 8 })

            List({ space: 8 }) {
              ForEach(this.searchKeyword.trim() === ''
                ? this.getCurrentList()
                : this.getCurrentList().filter((item) =>
                    item.title.includes(this.searchKeyword.trim()) || item.artist.includes(this.searchKeyword.trim())
                  ), (item: LocalMediaItem) => {
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
          .opacity(this.contentOpacity)
          .translate({ x: 0, y: this.contentOffset })
        }
        .width('100%')
        .layoutWeight(1)
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
