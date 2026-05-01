import router from '@ohos.router'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'

interface ContactItem {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

@Entry
@Component
struct CollaborationContactsPage {
  @State private contacts: ContactItem[] = [];
  @State private loading: boolean = false;
  @State private errorMessage: string = '';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'contact.updated' || event.type === 'overview.refreshed') {
      void this.refreshContacts();
    }
  };

  aboutToAppear() {
    void this.refreshContacts();
    this.viewModel.onSyncEvent(this.syncListener);
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  private async refreshContacts(): Promise<void> {
    this.loading = true;
    this.errorMessage = '';
    try {
      this.contacts = await this.viewModel.loadContacts() as ContactItem[];
    } catch (error) {
      this.errorMessage = '联系人加载失败，请稍后重试';
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
        Text('联系人同步')
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
            Text('正在加载联系人...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#F87171')
          } else if (this.contacts.length === 0) {
            Text('暂无联系人数据')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else {
            ForEach(this.contacts, (item: ContactItem) => {
              Row() {
                Column({ space: 4 }) {
                  Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text(item.phone).fontSize(11).fontColor('rgba(255,255,255,0.6)')
                }
                .layoutWeight(1)
                Button(item.tag)
                  .fontSize(10)
                  .fontColor('#A78BFA')
                  .backgroundColor('rgba(168,85,247,0.12)')
                  .borderRadius(999)
                  .onClick(async () => {
                    const nextTag = item.tag === '收藏' ? '常用' : '收藏';
                    const updated = await this.viewModel.updateContactTag(item.id, nextTag);
                    if (updated) {
                      await this.refreshContacts();
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
