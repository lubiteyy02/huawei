@Component
export struct CollaborationModule {
  @State messages: string[] = ["手机导航: 目的地已同步", "音乐接续: 正在播放《七里香》"];

  build() {
    Column() {
      // 标题头
      Row() {
        Rect().width(16).height(26).borderRadius(3).stroke('#007DFF').strokeWidth(2).fill('transparent')
        Text(" Super Device Link").fontSize(22).fontWeight(FontWeight.Bold).fontColor(Color.White).margin({ left: 10 })
      }.width('100%').padding(30)

      // 消息列表
      List({ space: 15 }) {
        ForEach(this.messages, (msg: string) => {
          ListItem() {
            Row() {
              Circle().width(8).height(8).fill('#00FF00').margin({ right: 15 })
              Text(msg).fontSize(18).fontColor(Color.White)
            }
            .width('100%')
            .padding(24)
            .borderRadius(16)
            .backgroundColor('rgba(255, 255, 255, 0.05)')
            .border({ width: 1, color: 'rgba(255, 255, 255, 0.05)' })
          }
        })
      }
      .width('90%')
      .layoutWeight(1) // 占满中间空间

      // 底部操作区
      Button("从手机同步数据")
        .width('90%').height(56)
        .fontSize(18)
        .backgroundColor('#007DFF')
        .shadow({ radius: 20, color: 'rgba(0, 125, 255, 0.4)' })
        .onClick(() => {
          this.messages.push(`新消息 ${new Date().toLocaleTimeString()}`)
        })
        .margin({ bottom: 40 }) // 适配隐藏式Dock
    }
    .width('100%').height('100%')
    .backgroundColor('#0F172A')
  }
}