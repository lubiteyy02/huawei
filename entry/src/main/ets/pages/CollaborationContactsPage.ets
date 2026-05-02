import router from '@ohos.router'
import type common from '@ohos.app.ability.common'
import { CollaborationViewModel } from '../services/CollaborationViewModel'
import type { CollaborationSyncEvent } from '../services/CollaborationSyncSocketService'
import { RealContactsService, LocalContact, ContactBulkItem } from '../services/RealContactsService'

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
  @State private initialLoading: boolean = false;
  @State private errorMessage: string = '';
  @State private lastSyncHint: string = '等待同步事件';
  @State private isCar: boolean = false;
  @State private syncing: boolean = false;
  @State private syncHint: string = '';
  private readonly viewModel: CollaborationViewModel = CollaborationViewModel.getInstance();
  private readonly contactsService: RealContactsService = RealContactsService.getInstance();
  private readonly syncListener: (event: CollaborationSyncEvent) => void = (event: CollaborationSyncEvent): void => {
    if (event.type === 'contact.updated') {
      this.lastSyncHint = `${event.type} · ${event.timestamp}`;
      const bulk = event.payload.bulk === 1 || event.payload.bulk === true;
      if (bulk) {
        void this.refreshContacts();
        return;
      }
      const tag = typeof event.payload.tag === 'string' ? event.payload.tag : '';
      const id = typeof event.payload.id === 'number' ? event.payload.id : -1;
      if (id >= 0) {
        this.contacts = this.contacts.map((item) => item.id === id ? { id: item.id, name: item.name, phone: item.phone, tag: tag !== '' ? tag : item.tag } : item);
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
    void this.refreshContacts();
    this.viewModel.onSyncEvent(this.syncListener);
  }

  private async syncLocalContacts(): Promise<void> {
    if (this.syncing) return;
    this.syncing = true;
    this.syncHint = '请在系统选择器中选择要同步的联系人...';
    try {
      const ctx = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const local: LocalContact[] = await this.contactsService.readLocalContacts(ctx);
      if (local.length === 0) {
        this.syncHint = '未选择联系人（用户取消或本机无联系人）';
        return;
      }
      this.syncHint = `已选择 ${local.length} 条，上传中...`;
      const payload: ContactBulkItem[] = local.map((c: LocalContact): ContactBulkItem => {
        const item: ContactBulkItem = { name: c.name, phone: c.phone, tag: c.tag };
        return item;
      });
      const ok = await this.viewModel.uploadContacts(payload);
      if (ok) {
        this.syncHint = `已同步 ${local.length} 条到车机`;
        await this.refreshContacts();
      } else {
        this.syncHint = '同步失败，请检查后端连接';
      }
    } catch (e) {
      this.syncHint = '同步异常';
    } finally {
      this.syncing = false;
    }
  }

  aboutToDisappear() {
    this.viewModel.offSyncEvent(this.syncListener);
  }

  private async refreshContacts(): Promise<void> {
    this.errorMessage = '';
    try {
      this.contacts = await this.viewModel.loadContacts() as ContactItem[];
    } catch (error) {
      this.errorMessage = '联系人加载失败，请稍后重试';
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
          Text('联系人同步')
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
            Text('正在加载联系人...')
              .fontSize(12)
              .fontColor('rgba(255,255,255,0.6)')
          } else if (this.errorMessage !== '') {
            Text(this.errorMessage)
              .fontSize(12)
              .fontColor('#F87171')
          } else {
            Row() {
              Text(this.isCar ? '车机端：展示手机同步过来的联系人' : '手机端：可一键把本机联系人同步到车机')
                .fontSize(10)
                .fontColor('#22C55E')
                .layoutWeight(1)
              if (!this.isCar) {
                Button(this.syncing ? '同步中...' : '同步手机联系人')
                  .fontSize(11)
                  .backgroundColor('#8B5CF6')
                  .fontColor('#FFFFFF')
                  .borderRadius(12)
                  .padding({ left: 12, right: 12, top: 6, bottom: 6 })
                  .enabled(!this.syncing)
                  .onClick(() => { void this.syncLocalContacts(); })
              }
            }
            .width('100%')
            if (this.syncHint !== '') {
              Text(this.syncHint)
                .fontSize(10)
                .fontColor('#A78BFA')
            }
            if (this.contacts.length === 0) {
              Text(this.isCar ? '等待手机端同步...' : '点击右上方按钮同步本机联系人')
                .fontSize(12)
                .fontColor('rgba(255,255,255,0.6)')
                .padding({ top: 24 })
            }
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
