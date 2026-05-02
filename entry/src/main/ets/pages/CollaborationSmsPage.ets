import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'
import { RealTtsService } from '../services/RealTtsService'

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
  @State private initialLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private lastSyncHint: string = '等待同步事件';
  @State private isCar: boolean = false;
  @State private composeName: string = '姈姈';
  @State private composePreview: string = '路上注意安全';
  @State private composing: boolean = false;
  @State private composeHint: string = '';
  @State private ttsHint: string = '';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly tts: RealTtsService = RealTtsService.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'message.read') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      const threadId = typeof event.payload.threadId === 'number' ? event.payload.threadId : -1;
      if (threadId >= 0) {
        this.threads = this.threads.map((item) => item.id === threadId ? { id: item.id, name: item.name, preview: item.preview, time: item.time, unread: 0 } : item);
      }
      return;
    }
    if (event.type === 'message.created') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      const fromSelf = event.sourceDeviceId === this.viewModel.getDeviceId();
      const name = typeof event.payload.name === 'string' ? event.payload.name : '';
      const preview = typeof event.payload.preview === 'string' ? event.payload.preview : '';
      void this.refreshMessages();
      if (this.isCar && !fromSelf && name !== '' && preview !== '') {
        this.ttsHint = `车机正在朗读：${name} · ${preview}`;
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
    this.isCar = this.viewModel.getDeviceId() === 'car-001';
    void this.refreshMessages();
    this.viewModel.onSyncEvent(this.syncListener);
    if (this.isCar) {
      void this.tts.ensureEngine();
    }
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
    void this.tts.stop();
  }

  private async sendCompose(): Promise<void> {
    if (this.composing) return;
    const name = this.composeName.trim();
    const preview = this.composePreview.trim();
    if (name === '' || preview === '') {
      this.composeHint = '请填写发送人和内容';
      return;
    }
    this.composing = true;
    this.composeHint = '发送中...';
    const ok = await this.viewModel.createMessage(name, preview);
    this.composing = false;
    if (ok) {
      this.composeHint = `已发送到车机：${name}`;
      await this.refreshMessages();
    } else {
      this.composeHint = '发送失败，请检查后端';
    }
  }

  private async refreshMessages(): Promise<void> {
    this.errorMessage = '';
    try {
      this.threads = await this.viewModel.loadMessages() as MessageThread[];
    } catch (error) {
      this.errorMessage = '短信加载失败，请稍后重试';
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
          Text('短信同步')
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
            if (!this.isCar) {
              Column({ space: 8 }) {
                Text('手机端：模拟一条来信，推送到车机、车机会语音朗读')
                  .fontSize(10)
                  .fontColor('#22C55E')
                TextInput({ placeholder: '发送人（如：姈姈）', text: this.composeName })
                  .fontSize(13)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .fontColor('#FFFFFF')
                  .placeholderColor('rgba(255,255,255,0.4)')
                  .borderRadius(10)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .onChange((v: string) => { this.composeName = v; })
                TextInput({ placeholder: '短信内容', text: this.composePreview })
                  .fontSize(13)
                  .backgroundColor('rgba(255,255,255,0.06)')
                  .fontColor('#FFFFFF')
                  .placeholderColor('rgba(255,255,255,0.4)')
                  .borderRadius(10)
                  .padding({ left: 12, right: 12, top: 8, bottom: 8 })
                  .onChange((v: string) => { this.composePreview = v; })
                Row() {
                  Button(this.composing ? '发送中...' : '推送到车机')
                    .fontSize(12)
                    .backgroundColor('#8B5CF6')
                    .fontColor('#FFFFFF')
                    .borderRadius(12)
                    .padding({ left: 14, right: 14, top: 8, bottom: 8 })
                    .enabled(!this.composing)
                    .onClick(() => { void this.sendCompose(); })
                  Blank()
                  if (this.composeHint !== '') {
                    Text(this.composeHint).fontSize(10).fontColor('#A78BFA')
                  }
                }
                .width('100%')
              }
              .width('100%')
              .padding(14)
              .backgroundColor('rgba(139,92,246,0.10)')
              .borderRadius(16)
            } else {
              Column({ space: 6 }) {
                Text('车机端：新短信到达时会自动语音朗读')
                  .fontSize(10)
                  .fontColor('#22C55E')
                if (this.ttsHint !== '') {
                  Text(this.ttsHint).fontSize(10).fontColor('#A78BFA').maxLines(2)
                }
              }
              .width('100%')
              .padding(14)
              .backgroundColor('rgba(139,92,246,0.10)')
              .borderRadius(16)
            }
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
