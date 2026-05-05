import router from '@ohos.router'
import { NavigationHistoryService } from '../services/NavigationHistoryService'
import { NavigationHistory } from '../models/BackendModels'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { PendingNavHandover } from '../services/GlobalAnnouncerService'

@Entry
@Component
struct CollaborationResumePage {
  @State private list: NavigationHistory[] = [];
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  @State private isCar: boolean = false;
  // 手机端：跟踪已点过「车机续接」的历史 id，按钮变成「已提交续接申请」并禁用
  @State private submittedIds: number[] = [];
  // 车机端：由 GlobalAnnouncerService 常驻接收后写入 AppStorage。
  // 本页面通过 @StorageLink 读取，即使未进入本页面 handover 也不会丢失。
  @StorageLink('pendingNavHandover') private pending: PendingNavHandover | null = null;

  private readonly historyService: NavigationHistoryService = NavigationHistoryService.getInstance();
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();

  aboutToAppear() {
    this.isCar = this.viewModel.getDeviceId() === 'car-001';
    if (!this.isCar) {
      void this.refresh();
    }
  }

  private async refresh(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      // 拉一页足够多的数据，前端按 endName 去重后取前 10 条
      const resp = await this.historyService.getHistory(1, 50);
      if (resp.code === 200 && resp.data) {
        const raw = resp.data.list || [];
        const seen = new Set<string>();
        const unique: NavigationHistory[] = [];
        for (const item of raw) {
          const key = item.endName || '';
          if (key === '' || seen.has(key)) continue;
          seen.add(key);
          unique.push(item);
          if (unique.length >= 10) break;
        }
        this.list = unique;
      } else if (resp.code === 401) {
        this.errorMessage = '请先登录后再使用导航续接';
      } else {
        this.errorMessage = resp.message || '加载失败';
      }
    } catch (e) {
      this.errorMessage = '加载失败，请稍后重试';
    } finally {
      this.loading = false;
    }
  }

  /**
   * 手机端：把这条历史作为续接申请推到车机
   * - POST /api/v1/sync/navigation/handover → 后端广播 navigation.handover
   * - 车机端收到后会在「导航续接」页弹出「待处理续接申请」卡片
   * - 本端按钮立刻变为「已提交续接申请」并禁用
   */
  private async submitHandover(item: NavigationHistory): Promise<void> {
    if (this.submittedIds.indexOf(item.id) >= 0) return;
    const ok = await this.viewModel.navigationHandover(
      item.endName,
      item.endAddress || '',
      item.endLat,
      item.endLng
    );
    if (ok) {
      this.submittedIds = [...this.submittedIds, item.id];
    } else {
      this.errorMessage = '推送失败，请检查后端连接';
    }
  }

  /**
   * 车机端：用户在「待续接申请」卡片点击「立即续接」
   * - 写 AppStorage destination + navTriggerVersion
   * - router.back 回到栈底原 Index → onPageShow 读 AppStorage → 切 Tab 1 → 自动规划
   */
  private resumeNow(): void {
    if (!this.pending) return;
    const p = this.pending;
    AppStorage.setOrCreate('shouldSwitchToNavigation', true);
    AppStorage.setOrCreate('navigationDestination', {
      name: p.name,
      address: p.address,
      latitude: p.latitude,
      longitude: p.longitude
    });
    AppStorage.setOrCreate('navTriggerVersion', Date.now());
    // 清除待续接状态，@StorageLink 会同步反映
    AppStorage.setOrCreate<PendingNavHandover | null>('pendingNavHandover', null);
    router.back({ url: 'pages/Index' });
  }

  private formatTime(s?: string): string {
    if (!s) return '';
    return s.replace('T', ' ').substring(0, 16);
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
          Text('导航续接')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.isCar ? '车机端：等待手机端续接申请' : '手机端：选择历史推送至车机')
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .layoutWeight(1)
        .margin({ left: 12 })
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
          if (this.isCar) {
            // ========== 车机端：只显示「待处理续接申请」卡片 ==========
            if (this.pending !== null) {
              Column({ space: 10 }) {
                Text('收到来自手机端的续接申请')
                  .fontSize(12)
                  .fontColor('#22C55E')
                Text(this.pending!.name)
                  .fontSize(22)
                  .fontWeight(FontWeight.Bold)
                  .fontColor('#FFFFFF')
                if (this.pending!.address !== '') {
                  Text(this.pending!.address)
                    .fontSize(13)
                    .fontColor('rgba(255,255,255,0.75)')
                    .maxLines(2)
                    .textOverflow({ overflow: TextOverflow.Ellipsis })
                }
                Text(`坐标 ${this.pending!.latitude.toFixed(4)}, ${this.pending!.longitude.toFixed(4)}`)
                  .fontSize(10)
                  .fontColor('rgba(255,255,255,0.45)')

                Button('立即续接')
                  .fontSize(15)
                  .fontWeight(FontWeight.Bold)
                  .backgroundColor('#F59E0B')
                  .fontColor('#FFFFFF')
                  .borderRadius(16)
                  .padding({ left: 24, right: 24, top: 12, bottom: 12 })
                  .width('100%')
                  .onClick(() => this.resumeNow())
              }
              .width('100%')
              .padding(18)
              .backgroundColor('rgba(245,158,11,0.12)')
              .borderRadius(20)
              .alignItems(HorizontalAlign.Start)
            } else {
              Text('暂无续接申请，请在手机端选择导航历史推送。')
                .fontSize(13)
                .fontColor('rgba(255,255,255,0.6)')
                .padding({ top: 24 })
            }
          } else {
            // ========== 手机端：导航历史 + 「车机续接」按钮 ==========
            if (this.loading) {
              Text('正在加载导航历史...')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.6)')
            } else if (this.errorMessage !== '') {
              Text(this.errorMessage)
                .fontSize(12)
                .fontColor('#F87171')
            } else if (this.list.length === 0) {
              Text('暂无导航历史')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.6)')
            } else {
              ForEach(this.list, (item: NavigationHistory) => {
                Row({ space: 12 }) {
                  Column({ space: 6 }) {
                    Text(item.endName)
                      .fontSize(18)
                      .fontWeight(FontWeight.Bold)
                      .fontColor('#FFFFFF')
                    Text(item.endAddress)
                      .fontSize(13)
                      .fontColor('rgba(255,255,255,0.7)')
                      .maxLines(2)
                      .textOverflow({ overflow: TextOverflow.Ellipsis })
                    Text(this.formatTime(item.createdAt))
                      .fontSize(11)
                      .fontColor('rgba(255,255,255,0.45)')
                  }
                  .layoutWeight(1)
                  .alignItems(HorizontalAlign.Start)

                  if (this.submittedIds.indexOf(item.id) >= 0) {
                    Button('已提交续接申请')
                      .fontSize(11)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('rgba(34,197,94,0.18)')
                      .fontColor('#22C55E')
                      .borderRadius(14)
                      .padding({ left: 12, right: 12, top: 10, bottom: 10 })
                      .enabled(false)
                  } else {
                    Button('车机续接')
                      .fontSize(13)
                      .fontWeight(FontWeight.Medium)
                      .backgroundColor('#F59E0B')
                      .fontColor('#FFFFFF')
                      .borderRadius(14)
                      .padding({ left: 16, right: 16, top: 10, bottom: 10 })
                      .onClick(() => { void this.submitHandover(item); })
                  }
                }
                .width('100%')
                .padding(14)
                .backgroundColor('rgba(255,255,255,0.06)')
                .borderRadius(18)
              })
            }
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
