import router from '@ohos.router'
import { CollaborationDataService, type CollaborationContact, type CollaborationMessageThread, type CollaborationMusicItem, type CollaborationContinuationTask } from '../services/CollaborationDataService'

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

interface ContactItem {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

interface MessageThread {
  id: number;
  name: string;
  preview: string;
  time: string;
  unread: number;
}

interface MusicItem {
  id: number;
  title: string;
  artist: string;
  progress: number;
  device: string;
}

interface ContinuationTask {
  id: number;
  module: string;
  title: string;
  detail: string;
  device: string;
}

enum CollaborationSection {
  HOME = 'home',
  CONTACTS = 'contacts',
  SMS = 'sms',
  MUSIC = 'music',
  RESUME = 'resume'
}

@Component
export struct CollaborationModule {
  @State activeSection: CollaborationSection = CollaborationSection.HOME;
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
  @State contactItems: CollaborationContact[] = [];
  @State messageThreads: CollaborationMessageThread[] = [];
  @State musicItems: CollaborationMusicItem[] = [];
  @State continuationTasks: CollaborationContinuationTask[] = [];

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
    this.logs = [`${message} · ${this.formatTimeText()}`, ...this.logs].slice(0, 6);
    this.lastSyncTime = '刚刚';
    this.syncStatus = '同步中';
    setTimeout(() => {
      this.syncStatus = '已连接';
      this.lastSyncTime = '刚刚';
    }, 600);
  }

  private switchSection(section: CollaborationSection): void {
    this.activeSection = section;
    if (section === CollaborationSection.CONTACTS) {
      this.pushLog('联系人已打开');
      void this.refreshContacts();
    } else if (section === CollaborationSection.SMS) {
      this.pushLog('短信已打开');
      void this.refreshMessages();
    } else if (section === CollaborationSection.MUSIC) {
      this.pushLog('音乐已打开');
      void this.refreshMusic();
    } else if (section === CollaborationSection.RESUME) {
      this.pushLog('续接已打开');
      void this.refreshContinuation();
    } else {
      this.pushLog('协同首页');
      void this.refreshOverview();
    }
  }

  private initSyncConfig(): void {
    const service = CollaborationDataService.getInstance();
    service.configureBackend({
      baseUrl: 'http://192.168.26.191:3002',
      deviceId: 'car-001',
      userId: '10001'
    });
    service.setBackendMode(true);
  }

  private async refreshOverview(): Promise<void> {
    const overview = await CollaborationDataService.getInstance().getOverview();
    this.phoneName = overview.phoneName;
    this.carName = overview.carName;
    this.syncStatus = overview.syncStatus;
    this.lastSyncTime = overview.lastSyncTime;
    this.unreadMessages = overview.unreadMessages;
    this.contactCount = overview.contactCount;
    this.musicCount = overview.musicCount;
    this.continuationCount = overview.continuationCount;
    this.logs = overview.logs;
  }

  private async refreshContacts(): Promise<void> {
    this.contactItems = await CollaborationDataService.getInstance().getContacts();
  }

  private async refreshMessages(): Promise<void> {
    this.messageThreads = await CollaborationDataService.getInstance().getMessageThreads();
  }

  private async refreshMusic(): Promise<void> {
    this.musicItems = await CollaborationDataService.getInstance().getMusicItems();
  }

  private async refreshContinuation(): Promise<void> {
    this.continuationTasks = await CollaborationDataService.getInstance().getContinuationTasks();
  }

  @Builder
  private buildSectionHeader(title: string, subtitle: string) {
    Column({ space: 4 }) {
      Text(title)
        .fontSize(18)
        .fontWeight(FontWeight.Bold)
        .fontColor('#FFFFFF')
      Text(subtitle)
        .fontSize(11)
        .fontColor('rgba(255,255,255,0.58)')
    }
    .width('100%')
  }

  @Builder
  private buildStatusChip(text: string, bg: string, border: string) {
    Text(text)
      .fontSize(10)
      .fontColor('#FFFFFF')
      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
      .backgroundColor(bg)
      .borderRadius(999)
      .border({ width: 1, color: border })
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
          Text(`最后同步 ${this.lastSyncTime}`)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .padding({ left: 14, right: 14, top: 10, bottom: 10 })
        .backgroundColor('rgba(139,92,246,0.15)')
        .borderRadius(16)
        .border({ width: 1, color: 'rgba(139,92,246,0.22)' })
      }
      .width('100%')
      .padding({ top: 18, left: 18, right: 18 })

      Row({ space: 8 }) {
        Button('首页')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor(this.activeSection === CollaborationSection.HOME ? '#8B5CF6' : 'rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => this.switchSection(CollaborationSection.HOME))
        Button('联系人')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor(this.activeSection === CollaborationSection.CONTACTS ? '#8B5CF6' : 'rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => this.switchSection(CollaborationSection.CONTACTS))
        Button('短信')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor(this.activeSection === CollaborationSection.SMS ? '#8B5CF6' : 'rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => this.switchSection(CollaborationSection.SMS))
        Button('音乐')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor(this.activeSection === CollaborationSection.MUSIC ? '#8B5CF6' : 'rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => this.switchSection(CollaborationSection.MUSIC))
        Button('续接')
          .layoutWeight(1)
          .fontSize(12)
          .backgroundColor(this.activeSection === CollaborationSection.RESUME ? '#8B5CF6' : 'rgba(255,255,255,0.08)')
          .fontColor('#FFFFFF')
          .borderRadius(14)
          .onClick(() => this.switchSection(CollaborationSection.RESUME))
      }
      .padding({ left: 18, right: 18, top: 12 })

      Scroll() {
        Column({ space: 14 }) {
          if (this.activeSection === CollaborationSection.HOME) {
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
          }

          if (this.activeSection === CollaborationSection.CONTACTS) {
            Column({ space: 10 }) {
              this.buildSectionHeader('联系人同步', '手机联系人实时同步到车机，可快速拨号')
              Row({ space: 8 }) {
                this.buildStatusChip('常用', 'rgba(56,189,248,0.16)', 'rgba(56,189,248,0.24)')
                this.buildStatusChip('最近', 'rgba(168,85,247,0.16)', 'rgba(168,85,247,0.24)')
                this.buildStatusChip('收藏', 'rgba(34,197,94,0.16)', 'rgba(34,197,94,0.24)')
              }

              Column({ space: 8 }) {
                ForEach(this.contactItems, (item: ContactItem) => {
                  Row() {
                    Column({ space: 4 }) {
                      Text(item.name)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                      Text(item.phone)
                        .fontSize(11)
                        .fontColor('rgba(255,255,255,0.60)')
                    }
                    .layoutWeight(1)
                    Text(item.tag)
                      .fontSize(10)
                      .fontColor('#A78BFA')
                      .padding({ left: 10, right: 10, top: 6, bottom: 6 })
                      .backgroundColor('rgba(168,85,247,0.12)')
                      .borderRadius(999)
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
          }

          if (this.activeSection === CollaborationSection.SMS) {
            Column({ space: 10 }) {
              this.buildSectionHeader('短信同步', '会话摘要、未读提醒与语音播报')
              Row({ space: 8 }) {
                this.buildStatusChip(`${this.unreadMessages} 条未读`, 'rgba(34,197,94,0.16)', 'rgba(34,197,94,0.24)')
                this.buildStatusChip('语音播报', 'rgba(59,130,246,0.16)', 'rgba(59,130,246,0.24)')
              }

              Column({ space: 8 }) {
                ForEach(this.messageThreads, (thread: MessageThread) => {
                  Column({ space: 6 }) {
                    Row() {
                      Text(thread.name)
                        .fontSize(15)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                      Blank()
                      Text(thread.time)
                        .fontSize(10)
                        .fontColor('rgba(255,255,255,0.50)')
                    }
                    Text(thread.preview)
                      .fontSize(11)
                      .fontColor('rgba(255,255,255,0.68)')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    if (thread.unread > 0) {
                      Text(`未读 ${thread.unread}`)
                        .fontSize(10)
                        .fontColor('#22C55E')
                    }
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
          }

          if (this.activeSection === CollaborationSection.MUSIC) {
            Column({ space: 10 }) {
              this.buildSectionHeader('音乐同步', '列表、收藏和播放进度可从手机续接到车机')
              Row({ space: 8 }) {
                this.buildStatusChip(`播放列表 ${this.musicCount}`, 'rgba(168,85,247,0.16)', 'rgba(168,85,247,0.24)')
                this.buildStatusChip('正在续接', 'rgba(56,189,248,0.16)', 'rgba(56,189,248,0.24)')
              }

              Column({ space: 8 }) {
                ForEach(this.musicItems, (music: MusicItem) => {
                  Column({ space: 6 }) {
                    Row() {
                      Column({ space: 4 }) {
                        Text(music.title)
                          .fontSize(16)
                          .fontWeight(FontWeight.Bold)
                          .fontColor('#FFFFFF')
                        Text(music.artist)
                          .fontSize(11)
                          .fontColor('rgba(255,255,255,0.60)')
                      }
                      .layoutWeight(1)
                      Text(music.device)
                        .fontSize(10)
                        .fontColor('#A78BFA')
                    }
                    Progress({ value: music.progress, total: 100, style: ProgressStyle.Linear })
                      .color('#8B5CF6')
                      .backgroundColor('rgba(255,255,255,0.08)')
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
          }

          if (this.activeSection === CollaborationSection.RESUME) {
            Column({ space: 10 }) {
              this.buildSectionHeader('应用续接', '记录页面状态、播放进度与跨设备恢复点')
              Row({ space: 8 }) {
                this.buildStatusChip(`可续接 ${this.continuationCount}`, 'rgba(251,191,36,0.16)', 'rgba(251,191,36,0.24)')
                this.buildStatusChip('手机 → 车机', 'rgba(99,102,241,0.16)', 'rgba(99,102,241,0.24)')
              }

              Column({ space: 8 }) {
                ForEach(this.continuationTasks, (task: ContinuationTask) => {
                  Row({ space: 12 }) {
                    Column({ space: 4 }) {
                      Text(task.module)
                        .fontSize(12)
                        .fontColor('rgba(255,255,255,0.55)')
                      Text(task.title)
                        .fontSize(16)
                        .fontWeight(FontWeight.Bold)
                        .fontColor('#FFFFFF')
                      Text(task.detail)
                        .fontSize(11)
                        .fontColor('rgba(255,255,255,0.60)')
                    }
                    .layoutWeight(1)
                    Button('续接')
                      .fontSize(12)
                      .backgroundColor('#F59E0B')
                      .fontColor('#FFFFFF')
                      .borderRadius(14)
                      .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                      .onClick(() => this.pushLog(`续接：${task.title}`))
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
          }

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
                  this.pushLog('手动触发同步');
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