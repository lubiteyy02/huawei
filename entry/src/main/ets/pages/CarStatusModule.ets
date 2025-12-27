@Component
export struct CarStatusModule {
  @State speed: number = 0;
  @State battery: number = 88;
  private timer: number = -1;

  aboutToAppear() {
    this.timer = setInterval(() => {
      this.speed = this.speed < 120 ? this.speed + 1 : 0;
      this.battery = this.battery > 80 ? this.battery - 0.1 : 88;
    }, 100);
  }

  aboutToDisappear() { clearInterval(this.timer); }

  build() {
    Column() {
      // === 上部：仪表盘 (占据主要空间) ===
      Stack() {
        // 背景光环
        Circle().width(320).height(320)
          .linearGradient({ angle: 180, colors: [['rgba(0, 255, 127, 0.15)', 0.0], ['transparent', 0.8]] })
          .blur(20)

        // 仪表
        Gauge({ value: this.speed, min: 0, max: 240 })
          .startAngle(210).endAngle(150)
          .colors([['#00FFA3', 0.6], ['#00F0FF', 1.0]])
          .strokeWidth(25)
          .width(280).height(280)

        // 数字
        Column() {
          Text(this.speed.toFixed(0)).fontSize(90).fontWeight(FontWeight.Bold).fontColor(Color.White)
          Text("km/h").fontSize(20).fontColor('#64748B').margin({ top: -10 })
        }
      }
      .margin({ top: 40 })
      .layoutWeight(1)

      // === 下部：数据卡片 (避让左下角) ===
      // 使用 Row 居中排列，左右自然留白，不会碰到左下角的菜单按钮
      Row({ space: 16 }) {
        this.InfoCard("剩余电量", `${this.battery.toFixed(0)}%`, '#00FFA3', 88)
        this.InfoCard("续航里程", "420 km", '#00F0FF', 60)
        this.InfoCard("轮胎胎压", "2.4 bar", '#FFD700', 100)
      }
      .width('100%')
      .padding({ left: 20, right: 20 })
      .justifyContent(FlexAlign.Center) // 居中显示
      .margin({ bottom: 40 }) // 底部整体抬高，视觉平衡
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B0F19')
  }

  @Builder InfoCard(title: string, value: string, color: string | Color, progress: number) {
    Column() {
      Text(title).fontSize(14).fontColor('#94A3B8').margin({ bottom: 8 })
      Text(value).fontSize(24).fontWeight(FontWeight.Bold).fontColor(Color.White)
      Progress({ value: progress, total: 100 })
        .color(color)
        .backgroundColor('rgba(255,255,255,0.1)')
        .height(4)
        .margin({ top: 12 })
    }
    .width('30%') // 三个卡片并排
    .padding(20)
    .borderRadius(16)
    .backgroundColor('#161E2E')
  }
}