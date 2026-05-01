import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'

interface MessageThread {
  id: number;
  name: string;
  preview: string;
  time: string;
  unread: number;
}

@Entry
@Component
struct CollaborationSmsPage {
  @State private threads: MessageThread[] = [];
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'message.read' || event.type === 'overview.refreshed') {
      void this.refreshMessages();
    }
  };

  aboutToAppear() {
    void this.refreshMessages();
    this.viewModel.onSyncEvent(this.syncListener);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  private async refreshMessages(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.threads = await this.viewModel.loadMessages() as MessageThread[];
    } catch (error) {
      this.errorMessage = '短信加载失败，请稍后重试';
    } finally {
      this.loading = false;
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
        Text('短信同步')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
          if (this.loading) {
            Text('正在加载短信...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#F87171')
          } else if (this.threads.length === 0) {
            Text('暂无短信会话')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else {
            ForEach(this.threads, (thread: MessageThread) => {
              Column({ space: 6 }) {
                Row() {
                  Text(thread.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Blank()
                  Text(thread.time).fontSize(10).fontColor('rgba(255,255,255,0.5)')
                }
                Text(thread.preview)
                  .fontSize(11)
                  .fontColor('rgba(255,255,255,0.68)')
                  .maxLines(2)
                  .textOverflow({ overflow: TextOverflow.Ellipsis })
                Row() {
                  if (thread.unread > 0) {
                    Text(`未读 ${thread.unread}`)
                      .fontSize(10)
                      .fontColor('#22C55E')
                  }
                  Blank()
                  Button(thread.unread > 0 ? '标记已读' : '已读')
                    .fontSize(10)
                    .backgroundColor('rgba(34,197,94,0.12)')
                    .fontColor('#FFFFFF')
                    .borderRadius(12)
                    .onClick(async () => {
                      const updated = await this.viewModel.markMessageRead(thread.id);
                      if (updated) {
                        await this.refreshMessages();
                      }
                    })
                }
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
