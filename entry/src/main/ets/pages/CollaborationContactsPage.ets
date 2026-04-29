import router from '@ohos.router'

interface ContactItem {
  id: number;
  name: string;
  phone: string;
  tag: string;
}

@Entry
@Component
struct CollaborationContactsPage {
  private readonly contacts: ContactItem[] = [
    { id: 1, name: '李明', phone: '138-0000-0001', tag: '常用' },
    { id: 2, name: '王婷', phone: '138-0000-0002', tag: '最近' },
    { id: 3, name: '张伟', phone: '138-0000-0003', tag: '收藏' },
    { id: 4, name: '陈晨', phone: '138-0000-0004', tag: '工作' }
  ];

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
          ForEach(this.contacts, (item: ContactItem) => {
            Row() {
              Column({ space: 4 }) {
                Text(item.name).fontSize(16).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                Text(item.phone).fontSize(11).fontColor('rgba(255,255,255,0.6)')
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
          })
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
