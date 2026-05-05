import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'
import type { MediaSyncState, MediaCommand, MediaResumeRequest } from '../view/MediaModule'
import type { PendingMusicHandover } from '../services/GlobalAnnouncerService'

/**
 * 协同侧用于回填「待续接申请」卡片标题/艺人的轻量元数据，
 * 与 MediaModule.musicItems / RealAudioPlayerService.TRACK_TABLE / collaboration_music_library 一致。
 */
interface MusicMeta {
  id: number;
  title: string;
  artist: string;
}

const MUSIC_META: MusicMeta[] = [
  { id: 1, title: '发如雪', artist: '周杰伦' },
  { id: 2, title: '听妈妈的话', artist: '周杰伦' },
  { id: 3, title: '以父之名', artist: '周杰伦' }
];

/**
 * 「车机端续接申请」：现由 GlobalAnnouncerService 常驻接收后写入 AppStorage 'pendingMusicHandover'，
 * 本页面通过 @StorageLink 读取。这样即使车机端未进入本页面 handover 也不会丢失。
 */

@Entry
@Component
struct CollaborationMusicPage {
  // ========== 角色 ==========
  @State private isCar: boolean = false;

  // ========== 实时显示 MediaModule 当前播放（手机端 + 车机端均使用） ==========
  // MediaModule 在 stateChange/timeUpdate 时写入 'mediaNowPlaying'，
  // 本页面通过 @StorageProp 自动响应——切到本页时立即看到当前歌、艺人、进度。
  @StorageProp('mediaNowPlaying') @Watch('onMediaNowPlayingChanged') private nowPlaying: MediaSyncState | null = null;

  // 本地推进显示用（每 200ms 在 playing 时把 displayPosition 加 200，
  // AppStorage 来一次新值就纠偏，让进度条/秒数更平滑）
  @State private displayPosition: number = 0;
  private displayTimer: number = -1;

  // ========== 手机端：续接申请已提交标记 ==========
  // 提交后按钮变绿色禁用「已提交续接申请」；
  // 收到车机端开始播放（MediaModule 上报 music.stateChanged 由车机端）回声后复位。
  @State private handoverSubmitted: boolean = false;

  // ========== 车机端：来自手机的待确认续接申请（由 GlobalAnnouncerService 写入） ==========
  @StorageLink('pendingMusicHandover') private pendingHandover: PendingMusicHandover | null = null;

  @State private hint: string = '';

  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();

  /**
   * WebSocket 同步事件监听
   * - music.handover 由 GlobalAnnouncerService 常驻处理，本页面不再重复订阅
   * - music.stateChanged：手机端收到「车机已经开始播放」回声 → 复位 handoverSubmitted
   */
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'music.stateChanged') {
      // 手机端：检测到车机已开始播放 → 复位「已提交续接申请」
      if (this.isCar) return;
      if (!this.handoverSubmitted) return;
      const playing = event.payload.playing === 1 || event.payload.playing === true;
      if (playing && event.sourceDeviceId === 'car-001') {
        this.handoverSubmitted = false;
        this.hint = '车机已接受续接，正在播放';
      }
      return;
    }
  };

  aboutToAppear() {
    this.isCar = this.viewModel.getDeviceId() === 'car-001';
    this.viewModel.onSyncEvent(this.syncListener);
    // 初始化 displayPosition
    if (this.nowPlaying) {
      this.displayPosition = this.nowPlaying.position;
    }
    // 启动 200ms 显示推进定时器，让进度条/秒数视觉上平滑变化
    this.displayTimer = setInterval((): void => { this.tickDisplay(); }, 200);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
    if (this.displayTimer !== -1) {
      clearInterval(this.displayTimer);
      this.displayTimer = -1;
    }
  }

  /**
   * AppStorage 来新值时纠偏 displayPosition；
   * 同时如果歌曲变了，也重置 displayPosition。
   */
  private onMediaNowPlayingChanged(): void {
    if (!this.nowPlaying) {
      this.displayPosition = 0;
      return;
    }
    this.displayPosition = this.nowPlaying.position;
  }

  /**
   * 200ms 心跳：playing=true 时本地把 displayPosition 加 200，
   * 让进度条/秒数视觉变化更连续；下一个 AppStorage 写入到来时会自动纠偏。
   */
  private tickDisplay(): void {
    if (!this.nowPlaying) return;
    if (!this.nowPlaying.playing) return;
    const next = this.displayPosition + 200;
    if (this.nowPlaying.duration > 0 && next > this.nowPlaying.duration) {
      this.displayPosition = this.nowPlaying.duration;
    } else {
      this.displayPosition = next;
    }
  }

  /**
   * 手机端：把当前 MediaModule 正在播放的曲目作为续接申请推送到车机
   * 1. POST /api/v1/sync/music/handover → 后端广播 music.handover
   * 2. 写 AppStorage 'mediaCommand'={type:'pause'} + 自增 'mediaCommandVersion' → MediaModule 立即暂停
   * 3. handoverSubmitted=true，按钮变绿色禁用
   */
  private async submitHandover(): Promise<void> {
    if (!this.nowPlaying || this.nowPlaying.songId <= 0) {
      this.hint = '请先在娱乐模块选择一首歌播放';
      return;
    }
    if (this.handoverSubmitted) return;
    const snap = this.nowPlaying;
    const ok = await this.viewModel.handoverMusic(snap.songId, snap.position, 'car-001');
    if (!ok) {
      this.hint = '推送失败，请检查后端连接';
      return;
    }
    // 让 MediaModule 立即暂停，让出播放权
    AppStorage.setOrCreate<MediaCommand>('mediaCommand', { type: 'pause' });
    const v = (AppStorage.get<number>('mediaCommandVersion') ?? 0) + 1;
    AppStorage.setOrCreate<number>('mediaCommandVersion', v);
    this.handoverSubmitted = true;
    this.hint = `已提交续接申请 @ ${this.formatPosition(snap.position)}，等待车机确认`;
  }

  /**
   * 车机端：用户点击「立即续接」
   * 1. 写 AppStorage 'mediaResumeRequest'={songId, position} + 自增 'mediaTriggerVersion'
   * 2. router.back 回 Index → Index 自动切到娱乐 Tab(2) → MediaModule 加载并 seek 播放
   * 3. 同时主动调 viewModel.syncMusic 上报状态，让手机端的 handoverSubmitted 复位
   */
  private async acceptHandover(): Promise<void> {
    if (!this.pendingHandover) return;
    const p = this.pendingHandover;
    // 清除 AppStorage：@StorageLink 会同步反映到 this.pendingHandover
    AppStorage.setOrCreate<PendingMusicHandover | null>('pendingMusicHandover', null);
    AppStorage.setOrCreate<MediaResumeRequest>('mediaResumeRequest', {
      songId: p.songId,
      position: p.position
    });
    const v = (AppStorage.get<number>('mediaTriggerVersion') ?? 0) + 1;
    AppStorage.setOrCreate<number>('mediaTriggerVersion', v);
    // 通知后端：车机已开始播放（手机端会基于此回声复位「已提交续接申请」）
    void this.viewModel.syncMusic(p.songId, true, p.position);
    router.back({ url: 'pages/Index' });
  }

  private formatPosition(ms: number): string {
    const total = Math.max(0, Math.floor(ms / 1000));
    const m = Math.floor(total / 60).toString().padStart(2, '0');
    const s = (total % 60).toString().padStart(2, '0');
    return `${m}:${s}`;
  }

  private computeProgress(): number {
    if (!this.nowPlaying || this.nowPlaying.duration <= 0) return 0;
    const ratio = this.displayPosition / this.nowPlaying.duration;
    return Math.max(0, Math.min(100, ratio * 100));
  }

  build() {
    Column() {
      // ========== 顶部 ==========
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
          Text(this.isCar ? '车机端：等待手机端续接申请' : '手机端：自动同步娱乐模块当前播放')
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(18)

      // ========== 内容 ==========
      Scroll() {
        Column({ space: 14 }) {
          // ----- 车机端：待续接申请卡片 -----
          if (this.isCar && this.pendingHandover !== null) {
            Column({ space: 10 }) {
              Text('收到来自手机端的音乐续接申请')
                .fontSize(12)
                .fontColor('#22C55E')
              Text(this.pendingHandover!.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              if (this.pendingHandover!.artist !== '') {
                Text(this.pendingHandover!.artist)
                  .fontSize(13)
                  .fontColor('rgba(255,255,255,0.75)')
              }
              Text(`从 ${this.formatPosition(this.pendingHandover!.position)} 继续播放`)
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.55)')
              Button('立即续接')
                .fontSize(15)
                .fontWeight(FontWeight.Bold)
                .backgroundColor('#F59E0B')
                .fontColor('#FFFFFF')
                .borderRadius(16)
                .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                .width('100%')
                .onClick(() => { void this.acceptHandover(); })
            }
            .width('100%')
            .padding(18)
            .backgroundColor('rgba(245,158,11,0.12)')
            .borderRadius(20)
            .alignItems(HorizontalAlign.Start)
          }

          // ----- 当前正在播放卡片（手机端核心区域，车机端无 MediaModule 数据则不显示） -----
          if (this.nowPlaying !== null && this.nowPlaying!.songId > 0) {
            Column({ space: 12 }) {
              Row() {
                Text(this.isCar ? '车机本机播放' : '手机本机播放').fontSize(11).fontColor('rgba(255,255,255,0.55)')
                Blank()
                Text(this.nowPlaying!.playing ? '播放中' : '已暂停')
                  .fontSize(10)
                  .fontColor(this.nowPlaying!.playing ? '#22C55E' : 'rgba(255,255,255,0.6)')
              }
              .width('100%')

              Text(this.nowPlaying!.title)
                .fontSize(22)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Text(this.nowPlaying!.artist)
                .fontSize(13)
                .fontColor('rgba(255,255,255,0.7)')

              // 实时进度条 + 秒数
              Progress({ value: this.computeProgress(), total: 100, style: ProgressStyle.Linear })
                .color('#8B5CF6')
                .backgroundColor('rgba(255,255,255,0.08)')
                .width('100%')
              Row() {
                Text(this.formatPosition(this.displayPosition))
                  .fontSize(11)
                  .fontColor('#A78BFA')
                Blank()
                Text(this.formatPosition(this.nowPlaying!.duration))
                  .fontSize(11)
                  .fontColor('rgba(255,255,255,0.55)')
              }
              .width('100%')

              // 操作按钮
              if (!this.isCar) {
                Row({ space: 12 }) {
                  if (this.handoverSubmitted) {
                    Button('已提交续接申请')
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('rgba(34,197,94,0.18)')
                      .fontColor('#22C55E')
                      .borderRadius(14)
                      .padding({ left: 14, right: 14, top: 10, bottom: 10 })
                      .enabled(false)
                  } else {
                    Button('车机端续接')
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('#F59E0B')
                      .fontColor('#FFFFFF')
                      .borderRadius(14)
                      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                      .onClick(() => { void this.submitHandover(); })
                  }
                  Blank()
                }
                .width('100%')
              }
            }
            .width('100%')
            .padding(18)
            .backgroundColor('rgba(139,92,246,0.14)')
            .borderRadius(20)
            .border({ width: 1, color: 'rgba(139,92,246,0.28)' })
            .alignItems(HorizontalAlign.Start)
          } else if (!(this.isCar && this.pendingHandover !== null)) {
            // 没有正在播放的歌：手机端引导用户去娱乐模块；车机端等待申请
            // 车机端若已有待续接卡片则不再显示「暂无续接申请」空态
            Column({ space: 8 }) {
              Text(this.isCar ? '暂无续接申请' : '当前没有正在播放的曲目')
                .fontSize(14)
                .fontColor('rgba(255,255,255,0.7)')
              Text(this.isCar ? '请等待手机端从娱乐模块发起续接申请' : '请先到「娱乐」模块选择一首歌开始播放，然后回到本页')
                .fontSize(11)
                .fontColor('rgba(255,255,255,0.5)')
            }
            .width('100%')
            .padding(20)
            .backgroundColor('rgba(255,255,255,0.04)')
            .borderRadius(16)
            .alignItems(HorizontalAlign.Start)
          }

          // 全局提示
          if (this.hint !== '') {
            Text(this.hint)
              .fontSize(11)
              .fontColor('#A78BFA')
              .padding({ left: 4, right: 4 })
          }
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
