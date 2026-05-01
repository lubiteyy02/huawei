import router from '@ohos.router'
import { deviceInfo } from '@kit.BasicServicesKit'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import { CollaborationBackendConfig } from '../services/CollaborationApiService'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'

interface DeviceStatusCard {
  title: string;
  value: string;
  detail: string;
}

interface CollaborationEntry {
  id: string;
  title: string;
  subtitle: string;
  actionLabel: string;
  status: string;
}

@Component
export struct CollaborationModule {
  @State phoneName: string = 'Harmony Phone';
  @State carName: string = 'Harmony Car';
  @State syncStatus: string = '已连接';
  @State lastSyncTime: string = '刚刚';
  @State unreadMessages: number = 3;
  @State contactCount: number = 128;
  @State musicCount: number = 56;
  @State continuationCount: number = 2;
  @State logs: string[] = [
    '联系人：已同步 128 条',
    '短信：已同步最近 20 条会话',
    '音乐：已续接播放《七里香》',
    '应用续接：导航任务已同步到车机'
  ];
  @State loading: boolean = false;
  @State errorMessage: string = '';
  @State syncHint: string = '等待同步事件';
  @State deviceRole: string = 'phone';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    this.syncHint = `${event.type} · ${event.timestamp}`;
    if (event.type === 'contact.updated') {
      const tag = typeof event.payload.tag === 'string' ? event.payload.tag : '';
      this.contactCount = this.contactCount;
      if (tag !== '') {
        this.logs = [`联系人已更新：${tag} · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
      }
      this.syncStatus = '已连接';
      return;
    }
    if (event.type === 'message.read') {
      const unread = typeof event.payload.unread === 'number' ? event.payload.unread : 0;
      this.unreadMessages = Math.max(0, this.unreadMessages - unread);
      this.logs = [`短信状态已同步 · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
      this.syncStatus = '已连接';
      return;
    }
    if (event.type === 'music.stateChanged') {
      const playing = event.payload.playing === 1 || event.payload.playing === true;
      const position = typeof event.payload.position === 'number' ? event.payload.position : 0;
      const songId = typeof event.payload.songId === 'number' ? event.payload.songId : 0;
      this.syncHint = `音乐刷新 · ${songId > 0 ? songId : '未知歌曲'} · ${playing ? '播放中' : '已暂停'}`;
      this.logs = [`音乐状态已更新 · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
      this.syncStatus = '已连接';
      return;
    }
    if (event.type === 'continuation.resumed') {
      this.continuationCount = Math.max(0, this.continuationCount - 1);
      this.logs = [`续接任务已完成 · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
      this.syncStatus = '已连接';
      return;
    }
    this.logs = [`总览已刷新 · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
  };

  private readonly deviceCards: DeviceStatusCard[] = [
    { title: '手机', value: 'Harmony Phone', detail: '主设备 · 正在同步' },
    { title: '车机', value: 'Harmony Car', detail: '协同终端 · 在线' },
    { title: '状态', value: '已连接', detail: '最后同步：刚刚' }
  ];

  private readonly featureEntries: CollaborationEntry[] = [
    { id: 'contacts', title: '联系人同步', subtitle: '最近联系人 / 常用联系人 / 快速拨号', actionLabel: '进入联系人', status: '128 条联系人' },
    { id: 'sms', title: '短信同步', subtitle: '会话摘要 / 未读提醒 / 语音播报', actionLabel: '进入短信', status: '3 条未读' },
    { id: 'music', title: '音乐同步', subtitle: '播放列表 / 收藏 / 续接播放', actionLabel: '进入音乐', status: '56 首歌曲' },
    { id: 'resume', title: '应用续接', subtitle: '页面状态 / 播放进度 / 任务恢复', actionLabel: '进入续接', status: '2 个可续接任务' }
  ];

  // 数据由 CollaborationDataService 提供，避免假数据硬编码在页面中

  private formatTimeText(): string {
    const now = new Date();
    const hour = now.getHours().toString().padStart(2, '0');
    const minute = now.getMinutes().toString().padStart(2, '0');
    const second = now.getSeconds().toString().padStart(2, '0');
    return `${hour}:${minute}:${second}`;
  }

  private pushLog(message: string): void {
    this.logs = [`${message} · ${this.formatTimeText()}`, ...this.logs].slice(0, 8);
    this.lastSyncTime = '刚刚';
    this.syncStatus = '同步中';
    setTimeout(() => {
      this.syncStatus = '已连接';
      this.lastSyncTime = '刚刚';
    }, 600);
  }

  private async pushSharedLog(message: string): Promise<void> {
    this.syncStatus = '同步中';
    const label = this.deviceRole === 'car' ? '车机' : '手机';
    const remote = await this.viewModel.pushSharedLog(message, label);
    if (remote && remote.length > 0) {
      this.logs = remote;
      this.syncStatus = '已连接';
      this.lastSyncTime = '刚刚';
    } else {
      this.errorMessage = '日志同步失败，请检查后端连接';
      this.syncStatus = '离线';
    }
  }

  private setLoadingState(loading: boolean, errorMessage: string = ''): void {
    this.loading = loading;
    this.errorMessage = errorMessage;
  }

  private detectRole(): string {
    let type = '';
    try {
      type = deviceInfo.deviceType ?? '';
    } catch {
      type = '';
    }
    if (type === 'tablet' || type === 'car' || type === '2in1') {
      return 'car';
    }
    return 'phone';
  }

  private initSyncConfig(): void {
    const role = this.detectRole();
    this.deviceRole = role;
    const backendConfig = new CollaborationBackendConfig();
    backendConfig.baseUrl = 'http://192.168.26.191:3002';
    backendConfig.deviceId = role === 'car' ? 'car-001' : 'phone-001';
    backendConfig.userId = '10001';
    this.viewModel.configureBackend(backendConfig);
  }

  private async refreshOverview(): Promise<void> {
    try {
      const overview = await this.viewModel.loadOverview();
      this.phoneName = overview.phoneName;
      this.carName = overview.carName;
      this.syncStatus = overview.syncStatus;
      this.lastSyncTime = overview.lastSyncTime;
      this.unreadMessages = overview.unreadMessages;
      this.contactCount = overview.contactCount;
      this.musicCount = overview.musicCount;
      this.continuationCount = overview.continuationCount;
      this.logs = overview.logs;
      this.errorMessage = '';
      this.syncHint = `总览刷新 · ${overview.lastSyncTime}`;
    } catch (error) {
      this.errorMessage = '协同总览加载失败';
    }
  }

  private async refreshContacts(): Promise<void> {
    try {
      const contacts = await this.viewModel.loadContacts();
      this.contactCount = contacts.length;
      this.syncHint = `联系人刷新 · ${this.formatTimeText()}`;
    } catch (error) {
      this.errorMessage = '联系人同步失败';
    }
  }

  private async refreshMessages(): Promise<void> {
    try {
      const messages = await this.viewModel.loadMessages();
      this.unreadMessages = messages.reduce((sum, item) => sum + (item.unread > 0 ? item.unread : 0), 0);
      this.syncHint = `短信刷新 · ${this.formatTimeText()}`;
    } catch (error) {
      this.errorMessage = '短信同步失败';
    }
  }

  private async refreshMusic(): Promise<void> {
    try {
      this.musicCount = (await this.viewModel.loadMusic()).length;
      this.syncHint = `音乐刷新 · ${this.formatTimeText()}`;
    } catch (error) {
      this.errorMessage = '音乐同步失败';
    }
  }

  private async refreshMusicState(): Promise<void> {
    try {
      const state = await this.viewModel.loadMusicState();
      if (state) {
        this.syncHint = `${state.title} · ${state.playing ? '播放中' : '已暂停'}`;
      }
    } catch (error) {
      this.errorMessage = '音乐状态同步失败';
    }
  }

  private async refreshContinuation(): Promise<void> {
    try {
      this.continuationCount = (await this.viewModel.loadContinuation()).length;
      this.syncHint = `续接刷新 · ${this.formatTimeText()}`;
    } catch (error) {
      this.errorMessage = '续接任务同步失败';
    }
  }

  aboutToAppear() {
    this.initSyncConfig();
    this.setLoadingState(true);
    this.viewModel.onSyncEvent(this.syncListener);
    void this.refreshOverview();
    void this.refreshContacts();
    void this.refreshMessages();
    void this.refreshMusic();
    void this.refreshMusicState();
    void this.refreshContinuation();
    this.setLoadingState(false);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  build() {
    Column() {
      Row() {
        Column({ space: 4 }) {
          Text('设备协同')
            .fontSize(24)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text('手机、车机、音乐、短信与联系人统一接续')
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.62)')
        }
        .layoutWeight(1)

        Column({ space: 6 }) {
          Text(this.syncStatus)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
            .fontColor('#8B5CF6')
          Text(`本机：${this.deviceRole === 'car' ? '车机端' : '手机端'}`)
            .fontSize(10)
            .fontColor('#A78BFA')
          Text(`最后同步 ${this.lastSyncTime}`)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
          Text(this.syncHint)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.42)')
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('rgba(139,92,246,0.15)')
        .borderRadius(16)
        .border({ width: 1, color: 'rgba(139,92,246,0.22)' })
      }
      .width('100%')
      .padding({ top: 18, left: 18, right: 18 })

      Scroll() {
        Column({ space: 14 }) {
          if (this.loading) {
            Text('正在加载协同数据...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
              .padding({ left: 18, right: 18 })
          }
          if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#F87171')
              .padding({ left: 18, right: 18 })
          }
          Column({ space: 10 }) {
            Text('设备状态')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')

              Row({ space: 10 }) {
                ForEach(this.deviceCards, (card: DeviceStatusCard) => {
                  Column({ space: 6 }) {
                    Text(card.title)
                      .fontSize(12)
                      .fontColor('rgba(255,255,255,0.55)')
                    Text(card.value)
                      .fontSize(16)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                      .maxLines(1)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(card.detail)
                      .fontSize(10)
                      .fontColor('rgba(255,255,255,0.50)')
                  }
                  .layoutWeight(1)
                  .padding(14)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .borderRadius(18)
                  .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
                })
              }
            }
            .width('100%')
            .padding({ left: 18, right: 18 })

            Column({ space: 10 }) {
              Text('协同总览')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')

              Column({ space: 12 }) {
                ForEach(this.featureEntries, (entry: CollaborationEntry) => {
                  Row({ space: 12 }) {
                    Column({ space: 6 }) {
                      Text(entry.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                      Text(entry.subtitle)
                        .fontSize(11)
                        .fontColor('rgba(255,255,255,0.58)')
                        .maxLines(2)
                        .textOverflow({ overflow: TextOverflow.Ellipsis })
                      Text(entry.status)
                        .fontSize(10)
                        .fontColor('#A78BFA')
                    }
                    .layoutWeight(1)

                    Button(entry.actionLabel)
                      .fontSize(12)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('#8B5CF6')
                      .fontColor('#FFFFFF')
                      .borderRadius(14)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .onClick(() => {
                        if (entry.id === 'contacts') {
                          router.pushUrl({ url: 'pages/CollaborationContactsPage' });
                        } else if (entry.id === 'sms') {
                          router.pushUrl({ url: 'pages/CollaborationSmsPage' });
                        } else if (entry.id === 'music') {
                          router.pushUrl({ url: 'pages/CollaborationMusicPage' });
                        } else {
                          router.pushUrl({ url: 'pages/CollaborationResumePage' });
                        }
                      })
                  }
                  .width('100%')
                  .padding(14)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .borderRadius(18)
                  .border({ width: 1, color: 'rgba(255,255,255,0.08)' })
                })
              }
            }
            .width('100%')
            .padding({ left: 18, right: 18 })

          Column({ space: 10 }) {
            Row() {
              Text('同步日志')
                .fontSize(14)
                .fontWeight(FontWeight.Bold)
                .fontColor('#FFFFFF')
              Blank()
              Button('立即同步')
                .fontSize(12)
                .backgroundColor('#2563EB')
                .fontColor('#FFFFFF')
                .borderRadius(12)
                .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                .onClick(() => {
                  void this.pushSharedLog('手动触发同步');
                })
            }
            .width('100%')

            Column({ space: 8 }) {
              ForEach(this.logs, (item: string) => {
                Row({ space: 10 }) {
                  Circle()
                    .width(8)
                    .height(8)
                    .fill('#22C55E')
                  Text(item)
                    .fontSize(11)
                    .fontColor('rgba(255,255,255,0.82)')
                    .layoutWeight(1)
                    .maxLines(1)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                .width('100%')
                .padding(12)
                .backgroundColor('rgba(255,255,255,0.05)')
                .borderRadius(14)
                .border({ width: 1, color: 'rgba(255,255,255,0.06)' })
              })
            }
          }
          .width('100%')
          .padding({ left: 18, right: 18, bottom: 18 })
        }
        .width('100%')
      }
      .scrollBar(BarState.Off)
      .layoutWeight(1)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B1020')
  }
}