import router from '@ohos.router'

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
  private readonly tasks: ContinuationTask[] = [
    { id: 1, module: '导航', title: '去公司', detail: '已在手机上规划路线', device: '手机' },
    { id: 2, module: '音乐', title: '七里香', detail: '播放进度 01:08', device: '手机' }
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
        Text('应用续接')
          .fontSize(22)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
      }
      .width('100%')
      .padding(18)

      Scroll() {
        Column({ space: 12 }) {
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
