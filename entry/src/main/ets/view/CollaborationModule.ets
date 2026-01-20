@Component
export struct CollaborationModule {
  @State messages: string[] = ["导航流转: 目的地已同步", "音乐接续: 正在播放《七里香》"];

  build() {
    Column() {
      // 顶部标题
      Row() {
        Image($r('app.media.app_icon')).width(40).height(40).margin({ right: 15 })
        Text("超级终端互联").fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
      }
      .width('100%')
      .padding({ top: 60, left: 30 })

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
      .layoutWeight(1) // 占满中间
      .margin({ top: 30 })

      // 底部按钮 (居中，并抬高)
      Button("立即同步数据")
        .width('80%').height(56)
        .fontSize(18)
        .backgroundColor('#007DFF')
        .shadow({ radius: 20, color: 'rgba(0, 125, 255, 0.4)' })
        .onClick(() => {
          this.messages.push(`数据同步 ${new Date().toLocaleTimeString()}`);
        })
        // 核心避让：抬高 100vp，左下角安全
        .margin({ bottom: 100 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0F172A')
  }
}