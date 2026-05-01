import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'

interface ContinuationTask {
  id: number;
  module: string;
  title: string;
  detail: string;
  device: string;
}

@Entry
@Component
struct CollaborationResumePage {
  @State private tasks: ContinuationTask[] = [];
  @State private initialLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private lastSyncHint: string = '等待同步事件';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'continuation.resumed') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      const continuationId = typeof event.payload.continuationId === 'number' ? event.payload.continuationId : -1;
      if (continuationId >= 0) {
        this.tasks = this.tasks.filter((item) => item.id !== continuationId);
      }
      return;
    }
    if (event.type === 'overview.refreshed') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      return;
    }
  };

  aboutToAppear() {
    this.initialLoading = true;
    void this.refreshContinuation();
    this.viewModel.onSyncEvent(this.syncListener);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  private async refreshContinuation(): Promise<void> {
    this.errorMessage = '';
    try {
      this.tasks = await this.viewModel.loadContinuation() as ContinuationTask[];
    } catch (error) {
      this.errorMessage = '续接任务加载失败，请稍后重试';
    } finally {
      this.initialLoading = false;
    }
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
          Text('应用续接')
            .fontSize(22)
            .fontWeight(FontWeight.Bold)
            .fontColor('#FFFFFF')
          Text(this.lastSyncHint)
            .fontSize(10)
            .fontColor('rgba(255,255,255,0.55)')
        }
        .layoutWeight(1)
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
          if (this.initialLoading) {
            Text('正在加载续接任务...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#F87171')
          } else if (this.tasks.length === 0) {
            Text('暂无可续接任务')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else {
            Text('已连接真实接口，续接状态会实时刷新')
              .fontSize(10)
              .fontColor('#22C55E')
            ForEach(this.tasks, (task: ContinuationTask) => {
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
                  .onClick(async () => {
                    const updated = await this.viewModel.resumeContinuation(task.id);
                    if (updated) {
                      await this.refreshContinuation();
                    }
                  })
              }
              .width('100%')
              .padding(14)
              .backgroundColor('rgba(255,255,255,0.06)')
              .borderRadius(18)
            })
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
