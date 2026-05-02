import { media } from '@kit.MediaKit';
import { audio } from '@kit.AudioKit';
import { common } from '@kit.AbilityKit';
import { fileIo } from '@kit.CoreFileKit';
import util from '@ohos.util';
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

interface RadioStationEntry {
  id: string;
  name: string;
  url: string;
  language: string;
  tags: string;
  favicon: string;
  country: string;
  codec: string;
  bitrate: number;
  votes: number;
  clickcount: number;
}

interface RadioStationsFile {
  source: string;
  country: string;
  count: number;
  stations: RadioStationEntry[];
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
  @State musicIsPlaying: boolean = false;
  @State radioIsPlaying: boolean = false;
  @State radioReady: boolean = false;
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
  @State tabPressed: TabType | null = null;
  @State searchPressed: boolean = false;
  @State controlPressed: string = '';
  @State tabPressOffset: number = 0;
  @State failedRadioIds: Array<string> = [];
  @State @Watch('onActiveLyricChanged') activeLyricIndex: number = 0;
  // 当前歌曲的歌词整体偏移（毫秒）。正值=歌词比音频晚（往前推），负值=歌词比音频早（往后推）
  @State lyricOffsetMs: number = 0;

  private avPlayer: media.AVPlayer | undefined;
  private pendingAutoplay: boolean = false;
  private rotateTimer: number = -1;
  private cacheService: CacheService = CacheService.getInstance();
  private rawFileDescriptors: Map<string, media.AVFileDescriptor | null> = new Map();
  private lyricScroller: ListScroller = new ListScroller();
  // 运行时从 rawfile/.lrc 加载的歌词缓存（按 item.id），优先级高于硬编码 lyricMap
  private lrcCache: Map<number, LyricLine[]> = new Map();

  private onActiveLyricChanged() {
    try {
      // 让当前播放的歌词行平滑滚动到列表中央
      this.lyricScroller.scrollToIndex(this.activeLyricIndex, true, ScrollAlign.CENTER);
    } catch (err) {
      // 列表尚未渲染或索引越界时忽略
    }
  }

  /**
   * 根据当前播放时间计算 active 行索引
   */
  private computeActiveLyricIndex(time: number): number {
    const lyrics = this.getCurrentLyrics();
    if (lyrics.length === 0) return 0;
    // 应用用户实时校准的偏移：等价于把音频时间整体平移
    const adjusted: number = time - this.lyricOffsetMs;
    let idx = 0;
    for (let i = 0; i < lyrics.length; i++) {
      if (adjusted >= lyrics[i].time) idx = i;
      else break;
    }
    return idx;
  }
  private readonly defaultCover: string = 'https://images.pexels.com/photos/16767318/pexels-photo-16767318.jpeg?auto=compress&cs=tinysrgb&w=600';

  private readonly musicItems: LocalMediaItem[] = [
    new LocalMediaItem(1, '发如雪', '本地缓存', 'https://images.pexels.com/photos/1389429/pexels-photo-1389429.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_1.mp3', '离线音乐', 'music'),
    new LocalMediaItem(2, '听妈妈的话', '本地缓存', 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_2.mp3', '离线音乐', 'music'),
    new LocalMediaItem(3, '以父之名', '本地缓存', 'https://images.pexels.com/photos/167092/pexels-photo-167092.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:sample_music_3.mp3', '离线音乐', 'music')
  ];

  private radioItems: LocalMediaItem[] = [
    new LocalMediaItem(101, '晨间电台', '本地缓存', 'https://images.pexels.com/photos/164938/pexels-photo-164938.jpeg?auto=compress&cs=tinysrgb&w=600', 'rawfile:radio_1.mp3', '离线电台', 'radio')
  ];
  // v2: 修复 UTF-8 解码后需要让旧版乱码缓存失效
  private radioStationCacheKey: string = 'radio_stations_clean_cache_v2';

  // 真实歌词（周杰伦），时间戳对齐前奏/间奏。点击任意行可跳转到对应进度。
  private readonly lyricMap: Map<number, LyricLine[]> = new Map<number, LyricLine[]>([
    // 1 - 发如雪（专辑《十一月的萧邦》2005，4:59）
    [1, [
      new LyricLine(0, '《发如雪》  词：方文山  曲：周杰伦'),
      new LyricLine(23000, '狼牙月 伊人憔悴'),
      new LyricLine(29000, '我举杯 饮尽了风雪'),
      new LyricLine(34000, '是谁打翻前世柜 惹尘埃是非'),
      new LyricLine(43000, '缘字诀 几番轮回'),
      new LyricLine(49000, '你锁眉 哭红颜唤不回'),
      new LyricLine(54000, '纵然青史已经成灰 我爱不灭'),
      new LyricLine(64000, '繁华如三千东流水'),
      new LyricLine(69000, '我只取一瓢爱了解'),
      new LyricLine(75000, '只恋你化身的蝶'),
      new LyricLine(82000, '你发如雪 凄美了离别'),
      new LyricLine(87000, '我焚香感动了谁'),
      new LyricLine(93000, '邀明月 让回忆皎洁'),
      new LyricLine(99000, '爱在月光下完美'),
      new LyricLine(106000, '你发如雪 纷飞了眼泪'),
      new LyricLine(112000, '我等待苍老了谁'),
      new LyricLine(118000, '红尘醉 微醺的岁月'),
      new LyricLine(124000, '我用无悔 刻永世爱你的碑'),
      new LyricLine(134000, '铜镜映无邪 扎马尾'),
      new LyricLine(140000, '你若撒野 今生我把酒奉陪'),
      new LyricLine(165000, '邀明月 让回忆皎洁'),
      new LyricLine(170000, '爱在月光下完美'),
      new LyricLine(177000, '你发如雪 纷飞了眼泪'),
      new LyricLine(183000, '我等待苍老了谁'),
      new LyricLine(189000, '红尘醉 微醺的岁月'),
      new LyricLine(196000, '我用无悔 刻永世爱你的碑'),
      new LyricLine(206000, '铜镜映无邪 扎马尾'),
      new LyricLine(212000, '你若撒野 今生我把酒奉陪')
    ]],
    // 2 - 听妈妈的话（专辑《依然范特西》2006，4:23）
    [2, [
      new LyricLine(0, '《听妈妈的话》  词曲：周杰伦'),
      new LyricLine(24000, '小朋友 你是否有很多问号'),
      new LyricLine(30000, '为什么 别人在那看漫画'),
      new LyricLine(35000, '我却在学画画 对着钢琴说话'),
      new LyricLine(41000, '别人在玩游戏 我却靠在墙壁背我的ABC'),
      new LyricLine(48000, '我说我要一台大大的飞机'),
      new LyricLine(54000, '但却得到一台旧旧录音机'),
      new LyricLine(60000, '为什么要听妈妈的话'),
      new LyricLine(66000, '长大后你就会开始懂了这段话'),
      new LyricLine(73000, '长大后我开始明白'),
      new LyricLine(77000, '为什么我跑得比别人快'),
      new LyricLine(81000, '飞得比别人高'),
      new LyricLine(86000, '将来大家看的都是我画的漫画'),
      new LyricLine(94000, '听妈妈的话 别让她受伤'),
      new LyricLine(101000, '想快快长大 才能保护她'),
      new LyricLine(108000, '美丽的白发 幸福中发芽'),
      new LyricLine(115000, '天使的魔法 温暖中慈祥'),
      new LyricLine(135000, '在你的未来 音乐是你的王牌'),
      new LyricLine(141000, '拿王牌谈个恋爱'),
      new LyricLine(146000, '唉 我不想把你教坏'),
      new LyricLine(152000, '还是听妈妈的话吧'),
      new LyricLine(157000, '晚点再恋爱吧'),
      new LyricLine(162000, '我知道你未来的路'),
      new LyricLine(168000, '但妈比我更清楚')
    ]],
    // 3 - 以父之名（专辑《叶惠美》2003，5:42，前奏含意大利语 ~30s）
    [3, [
      new LyricLine(0, '《以父之名》  词：黄俊郎  曲：周杰伦'),
      new LyricLine(33000, '微凉的晨露 沾湿黑礼服'),
      new LyricLine(38000, '石板路有雾 父在低诉'),
      new LyricLine(44000, '无奈的觉悟 只能更残酷'),
      new LyricLine(50000, '一切都为了 通往圣堂的路'),
      new LyricLine(56000, '吹不散的雾 隐没了意图'),
      new LyricLine(62000, '谁地下沉睡 满是裂痕的大理石'),
      new LyricLine(69000, '一颗心着魔 是谁谋杀了我'),
      new LyricLine(76000, '沉默的对我 那爱已耗尽了空壳'),
      new LyricLine(83000, '以父之名判决 那感觉没有适合字汇'),
      new LyricLine(91000, '就像边笑边掉泪 凝视著完全的黑'),
      new LyricLine(99000, '阻挡悲剧蔓延的悲剧会让我沉醉'),
      new LyricLine(107000, '低头亲吻我的左手 换取被宽恕的承诺'),
      new LyricLine(115000, '老旧管风琴在角落 一直一直一直伴奏'),
      new LyricLine(123000, '黑色帘幕被风吹动 阳光无言的穿透'),
      new LyricLine(131000, '洒向那群被我驯服后的兽'),
      new LyricLine(140000, '沉默的喊叫 沉默的喊叫'),
      new LyricLine(146000, '孤单 的人 那么 多 快乐 的 没几个'),
      new LyricLine(155000, '不少人 为了那 而走 偏激')
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

  private radioStationsToMediaItems(stations: RadioStationEntry[]): LocalMediaItem[] {
    const filteredStations = stations.filter((station) => {
      const stationId = station.id || station.name;
      return !this.failedRadioIds.includes(stationId);
    });

    return filteredStations.slice(0, 200).map((station, index) => {
      // 仅信任 https 图片链接，避免明文 http 被系统拦截/超时
      const fav: string = (station.favicon || '').trim();
      const isUsable: boolean = fav.startsWith('https://') && /\.(png|jpg|jpeg|webp|ico|svg)/i.test(fav);
      const cover: string = isUsable ? fav : this.defaultCover;
      const tag = station.tags && station.tags.trim() !== '' ? station.tags.split(',')[0] : '网络电台';
      return new LocalMediaItem(
        1000 + index,
        station.name,
        station.language || '未知',
        cover,
        station.url,
        tag,
        'radio'
      );
    });
  }

  private async loadRadioStations(): Promise<void> {
    try {
      const cached = await this.cacheService.get<Array<RadioStationEntry>>(this.radioStationCacheKey);
      if (cached && cached.length > 0) {
        this.radioItems = this.radioStationsToMediaItems(cached);
        return;
      }

      const context = getContext() as common.Context;
      const rawName: string = 'radio_stations_clean.json';
      const rawBytes: Uint8Array = await context.resourceManager.getRawFileContent(rawName) as Uint8Array;
      // 必须用 UTF-8 解码，否则中文名/标签会出现乱码（每个汉字 3 字节被当成 3 个 Latin-1 字符）
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const content: string = decoder.decodeWithStream(rawBytes, { stream: false });
      const parsed = JSON.parse(content) as RadioStationsFile;
      const stations: RadioStationEntry[] = parsed.stations || [];
      await this.cacheService.set(this.radioStationCacheKey, stations, 1000 * 60 * 60 * 12);
      this.radioItems = this.radioStationsToMediaItems(stations);
    } catch (err) {
      console.error('[MediaModule] loadRadioStations failed:', JSON.stringify(err));
      this.statusText = '电台数据加载失败';
    }
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
          if (this.currentItem && (this.currentItem.mediaType as string) === 'radio') {
            this.radioIsPlaying = true;
            this.statusText = `电台：${this.currentItem.title}（播放中）`;
          } else {
            this.statusText = '正在播放';
          }
          this.startAnimations();
        } else if (state === 'paused') {
          this.isPlaying = false;
          this.radioIsPlaying = false;
          this.statusText = '已暂停';
          this.stopAnimations();
        } else if (state === 'completed') {
          if (!this.currentItem || (this.currentItem.mediaType as string) !== 'radio') {
            void this.playNext();
          }
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
      // 计算当前应高亮的歌词行；变化时 @Watch 触发滚动
      const idx = this.computeActiveLyricIndex(time);
      if (idx !== this.activeLyricIndex) {
        this.activeLyricIndex = idx;
      }
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
    // 优先使用 rawfile/.lrc 加载的精准歌词；缺失则回退到硬编码 lyricMap
    const fromLrc = this.lrcCache.get(this.currentItem.id);
    if (fromLrc && fromLrc.length > 0) {
      return fromLrc;
    }
    return this.lyricMap.get(this.currentItem.id) || [];
  }

  /**
   * 解析标准 LRC 文本，支持：
   *   - [mm:ss.xx] / [mm:ss:xx] / [mm:ss] 时间戳
   *   - 同一行多个时间戳（重复副歌）
   *   - [ti:][ar:][al:][by:][offset:] 等元信息行（自动忽略）
   *   - offset 头（毫秒级整体偏移）
   */
  private parseLrc(content: string): LyricLine[] {
    const lines: LyricLine[] = [];
    let offset: number = 0;
    const offsetMatch = content.match(/\[offset:\s*(-?\d+)\s*\]/i);
    if (offsetMatch) {
      offset = parseInt(offsetMatch[1], 10) || 0;
    }
    const timeRe = /\[(\d{1,3}):(\d{1,2})(?:[.:](\d{1,3}))?\]/g;
    const rawLines = content.split(/\r?\n/);
    for (let r = 0; r < rawLines.length; r++) {
      const raw = rawLines[r];
      if (!raw) continue;
      const stamps: number[] = [];
      let m: RegExpExecArray | null;
      let lastEnd: number = 0;
      timeRe.lastIndex = 0;
      while ((m = timeRe.exec(raw)) !== null) {
        const min = parseInt(m[1], 10);
        const sec = parseInt(m[2], 10);
        const fracStr = m[3] || '0';
        // 把 'xx' / 'x' 标准化到毫秒
        const frac = parseInt((fracStr + '000').substring(0, 3), 10);
        stamps.push(min * 60000 + sec * 1000 + frac + offset);
        lastEnd = m.index + m[0].length;
      }
      if (stamps.length === 0) continue;
      const text = raw.substring(lastEnd).trim();
      if (text.length === 0) continue;
      for (let i = 0; i < stamps.length; i++) {
        lines.push(new LyricLine(stamps[i], text));
      }
    }
    lines.sort((a, b) => a.time - b.time);
    return lines;
  }

  /**
   * 根据 item.source（如 rawfile:sample_music_1.mp3）推导出同名 .lrc 文件，
   * 从 rawfile 中读出并解析；找不到或解析失败则静默回退到硬编码歌词。
   */
  private async loadLyricsForItem(item: LocalMediaItem): Promise<void> {
    if (!item || item.mediaType !== 'music') return;
    if (this.lrcCache.has(item.id)) return;
    if (!item.source.startsWith('rawfile:')) return;
    const mp3Name: string = item.source.substring('rawfile:'.length);
    const lrcName: string = mp3Name.replace(/\.[^.]+$/, '') + '.lrc';
    try {
      const ctx = getContext() as common.Context;
      const bytes: Uint8Array = await ctx.resourceManager.getRawFileContent(lrcName) as Uint8Array;
      const decoder: util.TextDecoder = util.TextDecoder.create('utf-8', { ignoreBOM: true });
      const text: string = decoder.decodeWithStream(bytes, { stream: false });
      const parsed: LyricLine[] = this.parseLrc(text);
      if (parsed.length > 0) {
        this.lrcCache.set(item.id, parsed);
      }
    } catch (err) {
      // .lrc 文件不存在则使用 lyricMap 兜底，不打印为 error
      console.info(`[MediaModule] no lrc for ${lrcName}, fallback to built-in lyrics`);
    }
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

  private async loadItem(item: LocalMediaItem, autoplay: boolean = false): Promise<boolean> {
    if (!this.avPlayer) {
      this.statusText = '播放器未就绪';
      return false;
    }

    try {
      this.isLoading = true;
      this.defaultCoverVisible = false;
      this.currentItem = item;
      this.currentTime = 0;
      this.totalTime = 0;
      this.progress = 0;
      this.rotateAngle = 0;
      this.isPlaying = false;
      this.pendingAutoplay = autoplay;
      this.radioReady = false;
      this.statusText = item.mediaType === 'radio' ? `电台：${item.title}（准备中）` : `本地缓存：${item.title}`;
      this.emptyHint = '';
      this.activeLyricIndex = 0;
      this.lyricOffsetMs = 0;
      // 切换歌曲时尝试加载同名 .lrc，失败则回退硬编码
      void this.loadLyricsForItem(item);

      if (!this.avPlayer) {
        this.statusText = '播放器未就绪';
        return false;
      }
      await this.avPlayer.reset();
      if (item.mediaType === 'radio') {
        this.avPlayer.url = item.source;
        this.radioReady = true;
        await this.avPlayer.prepare();
        if (autoplay) {
          await this.avPlayer.play();
          this.isPlaying = true;
          this.radioIsPlaying = true;
          this.statusText = `电台：${item.title}（播放中）`;
          this.pendingAutoplay = false;
          return true;
        }
        return true;
      } else {
        const rawFile = await this.getRawFileDescriptor(item.source);
        if (!rawFile) {
          this.statusText = '找不到本地音频资源';
          return false;
        }
        this.avPlayer.fdSrc = rawFile;
        await this.avPlayer.prepare();
        if (autoplay) {
          await this.avPlayer.play();
          this.isPlaying = true;
        }
        return true;
      }
    } catch (err) {
      console.error('[MediaModule] loadItem failed:', JSON.stringify(err));
      this.statusText = '加载失败';
      this.isPlaying = false;
      this.radioIsPlaying = false;
      if ((item.mediaType as string) === 'radio') {
        const failedId = item.source;
        if (!this.failedRadioIds.includes(failedId)) {
          this.failedRadioIds = [...this.failedRadioIds, failedId];
        }
        return false;
      }
      return false;
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
    if ((localItem.mediaType as string) === 'radio') {
      this.statusText = `电台：${localItem.title}（播放中）`;
    } else {
      this.statusText = `本地缓存：${localItem.title}`;
    }

    try {
      if (this.isPlaying) {
        await this.avPlayer.pause();
      } else {
        this.pendingAutoplay = false;
        await this.avPlayer.play();
        if ((localItem.mediaType as string) === 'radio') {
          this.statusText = `电台：${localItem.title}（播放中）`;
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
      if (tab === TabType.RADIO && this.radioItems.length <= 1) {
        void this.loadRadioStations();
      }
      return;
    }

    this.stopAnimations();
    this.isPlaying = false;
    this.musicIsPlaying = false;
    this.radioIsPlaying = false;
    this.radioReady = false;
    this.pendingAutoplay = false;
    this.currentItem = null;
    this.defaultCoverVisible = true;
    this.currentTime = 0;
    this.totalTime = 0;
    this.progress = 0;
    this.rotateAngle = 0;
    if (this.avPlayer) {
      try {
        await this.avPlayer.pause();
        await this.avPlayer.reset();
      } catch (err) {
        console.error('[MediaModule] switchTab reset failed:', JSON.stringify(err));
      }
    }

    this.activeTab = tab;
    this.updateAccent();
    this.statusText = tab === TabType.MUSIC ? '当前为音乐模式' : '当前为电台模式';
    this.searchResults = [];
    this.searchKeyword = '';
    this.isSearchPanelVisible = false;
    this.emptyHint = '';

    if (tab === TabType.RADIO && this.radioItems.length <= 1) {
      void this.loadRadioStations();
    } else {
      void this.loadLocalCache();
    }
  }

  private async searchOnlineResources(): Promise<void> {
    const keyword = this.searchKeyword.trim();
    if (keyword === '') {
      this.searchResults = [];
      this.statusText = '请输入搜索关键词';
      return;
    }

    this.searchResults = this.getCurrentList().filter((item) =>
      item.title.includes(keyword) || item.artist.includes(keyword) || item.tag.includes(keyword)
    );
    this.statusText = this.searchResults.length > 0 ? `找到 ${this.searchResults.length} 条结果` : '未找到匹配内容';

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
  private PillButton(title: string, selected: boolean, onClickAction: () => void, type: TabType) {
    Stack({ alignContent: Alignment.Center }) {
      Text(title)
        .width('100%')
        .height('100%')
        .fontSize(12)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .letterSpacing(1)
        .textAlign(TextAlign.Center)
    }
    .width(78)
    .height(34)
    .padding(0)
    .translate({ x: 0, y: this.tabPressed === type ? 10 : 0 })
    .backgroundColor('rgba(255,255,255,0.08)')
    .border({ width: 1.1, color: 'rgba(255,255,255,0.22)' })
    .borderRadius(12)
    .shadow({ radius: 6, color: selected ? 'rgba(96,165,250,0.12)' : 'rgba(0,0,0,0.06)', offsetY: 2 })
    .animation({ duration: 120 })
    .onTouch((event) => {
      if (event.type === TouchType.Down) {
        this.tabPressed = type;
      } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
        this.tabPressed = null;
      }
    })
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
        .alt(this.defaultCover)
        .onError(() => {
          // 远端图片加载失败时回落到默认封面
          item.cover = this.defaultCover;
          this.viewToken++;
        })

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
    .backgroundColor('rgba(255,255,255,0.16)')
    .border({ width: 1, color: 'rgba(255,255,255,0.34)' })
    .borderRadius(16)
    .animation({ duration: 120 })
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

          Stack({ alignContent: Alignment.Center }) {
            Text('搜索')
              .width('100%')
              .height('100%')
              .fontSize(12)
              .fontWeight(FontWeight.Bold)
              .fontColor('#FFFFFF')
              .letterSpacing(1)
              .textAlign(TextAlign.Center)
          }
          .width(78)
          .height(34)
          .padding(0)
          .backgroundColor('rgba(72, 126, 255, 0.22)')
          .border({ width: 1.1, color: 'rgba(191,219,254,0.70)' })
          .borderRadius(12)
          .shadow({ radius: 8, color: 'rgba(96,165,250,0.10)', offsetY: 2 })
          .translate({ x: 0, y: this.controlPressed === 'search' ? 10 : 0 })
          .animation({ duration: 120 })
          .margin({ top: 24, bottom: 2 })
          .onTouch((event) => {
            if (event.type === TouchType.Down) {
              this.controlPressed = 'search';
            } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
              this.controlPressed = '';
            }
          })
          .onClick(() => {
            this.openSearchPanel();
          })
        }
        .width('100%')
        .justifyContent(FlexAlign.SpaceBetween)
        .padding({ left: 18, right: 18, top: 10, bottom: 8 })

        Row({ space: 10 }) {
          this.PillButton('音乐', this.activeTab === TabType.MUSIC, () => { void this.switchTab(TabType.MUSIC); }, TabType.MUSIC)
          this.PillButton('电台', this.activeTab === TabType.RADIO, () => { void this.switchTab(TabType.RADIO); }, TabType.RADIO)
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
                  .backgroundColor('rgba(11, 18, 32, 0.72)')
                  .fontColor('#FFFFFF')
                  .placeholderColor('rgba(255,255,255,0.45)')
                  .borderRadius(21)
                  .padding({ left: 12, right: 12 })
                  .onChange((value: string) => {
                    this.onSearchKeywordChange(value);
                  })

                Stack({ alignContent: Alignment.Center }) {
                  Text('查找')
                    .width('100%')
                    .height('100%')
                    .fontSize(12)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .letterSpacing(1)
                    .textAlign(TextAlign.Center)
                }
                .width(78)
                .height(42)
                .margin({ left: 8 })
                .backgroundColor('rgba(72, 126, 255, 0.22)')
                .border({ width: 1.1, color: 'rgba(191,219,254,0.70)' })
                .borderRadius(12)
                .shadow({ radius: 8, color: 'rgba(96,165,250,0.10)', offsetY: 2 })
                .translate({ x: 0, y: this.controlPressed === 'find' ? 10 : 0 })
                .animation({ duration: 120 })
                .onTouch((event) => {
                  if (event.type === TouchType.Down) {
                    this.controlPressed = 'find';
                  } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                    this.controlPressed = '';
                  }
                })
                .onClick(() => {
                  void this.searchOnlineResources();
                })
              }
              .width('100%')
            }
            .width('92%')
            .padding(14)
            .backgroundColor('rgba(9, 15, 28, 0.88)')
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(255,255,255,0.34)' })
            .shadow({ radius: 14, color: 'rgba(0,0,0,0.22)', offsetY: 8 })
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
                  .alt(this.defaultCover)
                  .onError(() => {
                    if (this.currentItem) {
                      this.currentItem.cover = this.defaultCover;
                      this.viewToken++;
                    }
                  })
              }
            }
            .width('44%')
            .height(160)

            Column() {
              if (!this.defaultCoverVisible && this.currentItem) {
                Row() {
                  Text('歌词')
                    .fontSize(15)
                    .fontWeight(FontWeight.Bold)
                    .fontColor('#FFFFFF')
                    .layoutWeight(1)

                  // 实时校准：把歌词整体往前/往后推 0.5 秒，直到与音频同步
                  Text('-0.5s')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('rgba(255,255,255,0.14)')
                    .borderRadius(8)
                    .onClick(() => {
                      this.lyricOffsetMs -= 500;
                      // 立即重新计算当前行
                      this.activeLyricIndex = this.computeActiveLyricIndex(this.currentTime);
                    })

                  Text(`${this.lyricOffsetMs >= 0 ? '+' : ''}${(this.lyricOffsetMs / 1000).toFixed(1)}s`)
                    .fontSize(10)
                    .fontColor('rgba(255,255,255,0.7)')
                    .margin({ left: 6, right: 6 })

                  Text('+0.5s')
                    .fontSize(11)
                    .fontColor('#FFFFFF')
                    .padding({ left: 8, right: 8, top: 4, bottom: 4 })
                    .backgroundColor('rgba(255,255,255,0.14)')
                    .borderRadius(8)
                    .onClick(() => {
                      this.lyricOffsetMs += 500;
                      this.activeLyricIndex = this.computeActiveLyricIndex(this.currentTime);
                    })
                }
                .width('100%')
                .margin({ bottom: 10 })

                if (this.getCurrentLyrics().length === 0) {
                  Text('暂无歌词')
                    .fontSize(13)
                    .fontColor('rgba(255,255,255,0.42)')
                    .layoutWeight(1)
                    .width('100%')
                    .textAlign(TextAlign.Center)
                }
                List({ scroller: this.lyricScroller, space: 8 }) {
                  ForEach(this.getCurrentLyrics(), (line: LyricLine, idx: number) => {
                    ListItem() {
                      Text(line.text)
                        .fontSize(idx === this.activeLyricIndex ? 18 : 13)
                        .fontWeight(idx === this.activeLyricIndex ? FontWeight.Bold : FontWeight.Normal)
                        .fontColor(idx === this.activeLyricIndex ? '#FFFFFF' : 'rgba(255,255,255,0.42)')
                        .backgroundColor(idx === this.activeLyricIndex ? 'rgba(56,189,248,0.22)' : 'transparent')
                        .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                        .borderRadius(10)
                        .width('100%')
                        .animation({ duration: 200 })
                        .onClick(() => {
                          void this.seekToLyric(line.time);
                        })
                    }
                  }, (line: LyricLine, idx: number) => `${idx}-${line.time}`)
                }
                .layoutWeight(1)
                .width('100%')
                .scrollBar(BarState.Off)
                .edgeEffect(EdgeEffect.Spring)
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
          .backgroundColor('rgba(255,255,255,0.14)')
          .borderRadius(20)
          .border({ width: 1, color: 'rgba(255,255,255,0.34)' })
          .margin({ left: 18, right: 18, top: 2 })
          .opacity(this.contentOpacity)
          .translate({ x: 0, y: this.contentOffset })

          Row() {
            Row({ space: 10 }) {
              Stack({ alignContent: Alignment.Center }) {
                Text('⏮')
                  .width('100%')
                  .height('100%')
                  .fontSize(18)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
              }
              .width(46)
              .height(46)
              .backgroundColor('rgba(255,255,255,0.16)')
              .border({ width: 1.2, color: 'rgba(255,255,255,0.34)' })
              .borderRadius(14)
              .scale({ x: this.controlPressed === 'prev' ? 0.96 : 1, y: this.controlPressed === 'prev' ? 0.96 : 1 })
              .onTouch((event) => {
                if (event.type === TouchType.Down) {
                  this.controlPressed = 'prev';
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.controlPressed = '';
                }
              })
              .onClick(() => { void this.playPrev(); })

              Stack({ alignContent: Alignment.Center }) {
                Text(this.isPlaying ? '⏸' : '▶')
                  .width('100%')
                  .height('100%')
                  .fontSize(18)
                  .fontColor('#FFFFFF')
                  .fontWeight(FontWeight.Bold)
                  .textAlign(TextAlign.Center)
              }
              .width(62)
              .height(62)
              .backgroundColor('rgba(56,189,248,0.28)')
              .border({ width: 1.2, color: 'rgba(96,165,250,0.95)' })
              .borderRadius(18)
              .scale({ x: this.controlPressed === 'play' ? 0.96 : 1, y: this.controlPressed === 'play' ? 0.96 : 1 })
              .onTouch((event) => {
                if (event.type === TouchType.Down) {
                  this.controlPressed = 'play';
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.controlPressed = '';
                }
              })
              .onClick(() => { void this.togglePlay(); })

              Stack({ alignContent: Alignment.Center }) {
                Text('⏭')
                  .width('100%')
                  .height('100%')
                  .fontSize(18)
                  .fontColor('#FFFFFF')
                  .textAlign(TextAlign.Center)
              }
              .width(46)
              .height(46)
              .backgroundColor('rgba(255,255,255,0.16)')
              .border({ width: 1.2, color: 'rgba(255,255,255,0.34)' })
              .borderRadius(14)
              .scale({ x: this.controlPressed === 'next' ? 0.96 : 1, y: this.controlPressed === 'next' ? 0.96 : 1 })
              .onTouch((event) => {
                if (event.type === TouchType.Down) {
                  this.controlPressed = 'next';
                } else if (event.type === TouchType.Up || event.type === TouchType.Cancel) {
                  this.controlPressed = '';
                }
              })
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
          .backgroundColor('rgba(255,255,255,0.08)')
          .backgroundBlurStyle(BlurStyle.Thin)
          .border({ width: 1, color: 'rgba(255,255,255,0.16)' })
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
