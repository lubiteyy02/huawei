import router from '@ohos.router'

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
  private readonly threads: MessageThread[] = [
    { id: 1, name: '妈妈', preview: '路上注意安全，到家告诉我', time: '09:12', unread: 1 },
    { id: 2, name: '同事-小周', preview: '会议资料已经发到群里了', time: '08:40', unread: 0 },
    { id: 3, name: '物业', preview: '明天早上停水，请提前储水', time: '昨天', unread: 2 }
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
