interface MileageBar {
  day: string;
  value: number;
}

@Component
export struct CarStatusModule {
  // === 核心仿真数据 ===
  @State speed: number = 0;
  @State battery: number = 88;
  @State range: number = 420;
  @State chargingPower: number = 25;
  @State tirePressure: number = 2.4;
  @State cabinTemp: number = 23;
  @State outsideTemp: number = 18;
  @State motorTemp: number = 42;
  @State safetyScore: number = 96;
  @State batteryHealth: number = 98;
  @State odometer: number = 12105;
  @State ecoScore: number = 87;
  // 7 日行驶里程柱状图数据
  @State weekMileage: MileageBar[] = [
    { day: '一', value: 42 },
    { day: '二', value: 58 },
    { day: '三', value: 95 },
    { day: '四', value: 36 },
    { day: '五', value: 77 },
    { day: '六', value: 120 },
    { day: '日', value: 64 }
  ];
  @State tickBeat: number = 0;

  private timer: number = -1;
  private slowTimer: number = -1;

  aboutToAppear() {
    // 高频更新：速度/心跳（保留原有速度模拟）
    this.timer = setInterval(() => {
      this.speed = this.speed < 120 ? this.speed + 1 : 0;
      this.battery = this.battery > 80 ? this.battery - 0.05 : 88;
      this.tickBeat = (this.tickBeat + 1) % 1000;
    }, 100);

    // 低频更新：续航/温度/胎压等，避免高频重绘
    this.slowTimer = setInterval(() => {
      this.range = Math.max(180, Math.min(520, this.range + (Math.random() * 6 - 3)));
      this.chargingPower = Math.max(0, Math.min(250, 20 + Math.random() * 10));
      this.tirePressure = parseFloat((2.3 + Math.random() * 0.2).toFixed(2));
      this.cabinTemp = parseFloat((22 + Math.random() * 2).toFixed(1));
      this.outsideTemp = parseFloat((16 + Math.random() * 4).toFixed(1));
      this.motorTemp = parseFloat((40 + Math.random() * 8).toFixed(1));
      this.ecoScore = Math.max(70, Math.min(99, Math.round(85 + Math.random() * 10)));
      this.odometer = this.odometer + Math.round(Math.random() * 2);
      // 每 10 秒抖动一次柱状图，显现动态
      const shift: MileageBar = this.weekMileage[0];
      const rest: MileageBar[] = this.weekMileage.slice(1);
      const next: MileageBar = { day: shift.day, value: Math.max(20, Math.min(140, Math.round(40 + Math.random() * 100))) };
      this.weekMileage = rest.concat([next]);
    }, 2000);
  }

  aboutToDisappear() {
    if (this.timer !== -1) clearInterval(this.timer);
    if (this.slowTimer !== -1) clearInterval(this.slowTimer);
  }

  build() {
    Column() {
      // ===== 顶部标题栏 =====
      Row() {
        Row({ space: 10 }) {
          Circle().width(10).height(10).fill('#00FFA3')
            .shadow({ radius: 10, color: '#00FFA3', offsetX: 0, offsetY: 0 })
          Text('智行座舱').fontSize(18).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
          Text('Tesla Model 3').fontSize(12).fontColor('#64748B').margin({ left: 6 })
        }
        .layoutWeight(1)

        Row({ space: 16 }) {
          this.HeaderPill('车况', '优秀', '#00FFA3')
          this.HeaderPill('连接', '在线', '#00F0FF')
          this.HeaderPill('OTA', '最新', '#A78BFA')
        }
      }
      .width('100%')
      .padding({ left: 28, right: 28, top: 18, bottom: 8 })

      // ===== 主体左右两列 =====
      Row({ space: 14 }) {
        // ---- 左列：单张大卡（速度表 + 温度条） ----
        Column() {
          // 卡片标题
          Row() {
            Text('驾驶状态').fontSize(13).fontColor('#94A3B8').layoutWeight(1)
            Text('D · ECO').fontSize(11).fontColor('#00FFA3')
              .padding({ left: 8, right: 8, top: 3, bottom: 3 })
              .backgroundColor('rgba(0,255,163,0.12)')
              .borderRadius(8)
          }.width('100%')

          // 速度仪表（柔和融入：去掉 blur Circle，改用径向叠层 + shadow）
          Stack({ alignContent: Alignment.Center }) {
            // 外层柔光：半透明环底，与卡片背景同色系
            Circle().width(248).height(248)
              .fill('rgba(0, 240, 255, 0.06)')
            // 内层中心暗圆：让数字更聚焦，避免空洞感
            Circle().width(190).height(190)
              .fill('#0F1726')

            Gauge({ value: this.speed, min: 0, max: 240 })
              .startAngle(210).endAngle(150)
              .colors([['#00FFA3', 0.6], ['#00F0FF', 1.0]])
              .strokeWidth(18)
              .description(null)
              .width(238).height(238)

            Column() {
              Text(this.speed.toFixed(0))
                .fontSize(64).fontWeight(FontWeight.Bold).fontColor(Color.White)
              Text('km/h').fontSize(13).fontColor('#64748B').margin({ top: -2 })
              Text(`ECO ${this.ecoScore}`).fontSize(10).fontColor('#94A3B8').margin({ top: 4 })
            }
          }
          .layoutWeight(1)
          .width('100%')

          // 下部 3 张小卡（嵌在同一张大卡内）
          Row({ space: 10 }) {
            this.MiniMetric('舱内', `${this.cabinTemp.toFixed(1)}°`, '🌡️', '#00F0FF')
            this.MiniMetric('车外', `${this.outsideTemp.toFixed(1)}°`, '☀️', '#FDBA74')
            this.MiniMetric('电机', `${this.motorTemp.toFixed(0)}°`, '⚡', '#A78BFA')
          }
          .width('100%')
          .margin({ top: 12 })
        }
        .layoutWeight(1)
        .height('100%')
        .padding(16)
        .borderRadius(20)
        .backgroundColor('#161E2E')
        .border({ width: 1, color: 'rgba(255,255,255,0.04)' })

        // ---- 右列：电池环 + 柱状图 + 指标 ----
        Column({ space: 12 }) {
          // 电池健康度环形图 + 关键读数
          Row({ space: 12 }) {
            // 左：电池主卡
            Column() {
              Row() {
                Text('动力电池').fontSize(13).fontColor('#94A3B8').layoutWeight(1)
                Text('健康').fontSize(11).fontColor('#00FFA3')
                  .padding({ left: 8, right: 8, top: 2, bottom: 2 })
                  .backgroundColor('rgba(0,255,163,0.12)')
                  .borderRadius(8)
              }
              .width('100%')

              Stack({ alignContent: Alignment.Center }) {
                Progress({ value: this.battery, total: 100, type: ProgressType.Ring })
                  .width(118).height(118)
                  .style({ strokeWidth: 10, scaleCount: 0 })
                  .color('#00FFA3')
                  .backgroundColor('rgba(255,255,255,0.08)')
                Column() {
                  Text(`${this.battery.toFixed(0)}%`)
                    .fontSize(28).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text(`SOH ${this.batteryHealth}%`).fontSize(10).fontColor('#64748B')
                }
              }
              .margin({ top: 8 })
              .layoutWeight(1)

              Row() {
                Column() {
                  Text('续航').fontSize(10).fontColor('#64748B')
                  Text(`${this.range.toFixed(0)} km`).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#FFFFFF')
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
                Column() {
                  Text('功率').fontSize(10).fontColor('#64748B')
                  Text(`${this.chargingPower.toFixed(0)} kW`).fontSize(14).fontWeight(FontWeight.Medium).fontColor('#00F0FF')
                }.alignItems(HorizontalAlign.Start).layoutWeight(1)
              }
              .width('100%').margin({ top: 10 })
            }
            .layoutWeight(1)
            .padding(16)
            .borderRadius(20)
            .backgroundColor('#161E2E')
            .border({ width: 1, color: 'rgba(255,255,255,0.04)' })

            // 右：安全评分 + 胎压（两张卡 layoutWeight 1 撑满纵向空间）
            Column({ space: 12 }) {
              Column() {
                Row() {
                  Text('安全评级').fontSize(13).fontColor('#94A3B8').layoutWeight(1)
                  Text('优秀').fontSize(10).fontColor('#A78BFA')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('rgba(167,139,250,0.15)')
                    .borderRadius(6)
                }.width('100%')
                Column() {
                  Text(`${this.safetyScore}`)
                    .fontSize(42).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text('/ 100').fontSize(11).fontColor('#64748B').margin({ top: -2 })
                }.layoutWeight(1).justifyContent(FlexAlign.Center)
                Progress({ value: this.safetyScore, total: 100 })
                  .color('#A78BFA')
                  .backgroundColor('rgba(255,255,255,0.08)')
                  .height(4)
                Row() {
                  Text('本月驾驶零违规').fontSize(10).fontColor('#64748B').layoutWeight(1)
                  Text('↑ 2').fontSize(10).fontColor('#00FFA3')
                }.width('100%').margin({ top: 6 })
              }
              .width('100%')
              .layoutWeight(1)
              .padding(16)
              .borderRadius(20)
              .backgroundColor('#161E2E')
              .border({ width: 1, color: 'rgba(255,255,255,0.04)' })

              Column() {
                Row() {
                  Text('胎压监测').fontSize(13).fontColor('#94A3B8').layoutWeight(1)
                  Text('正常').fontSize(10).fontColor('#00FFA3')
                    .padding({ left: 6, right: 6, top: 2, bottom: 2 })
                    .backgroundColor('rgba(0,255,163,0.15)')
                    .borderRadius(6)
                }.width('100%')
                Column() {
                  Text(`${this.tirePressure.toFixed(2)}`)
                    .fontSize(32).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
                  Text('bar · 四轮均衡').fontSize(11).fontColor('#64748B')
                }.layoutWeight(1).justifyContent(FlexAlign.Center)
                // 四轮示意
                Row({ space: 8 }) {
                  this.TireDot('左前', this.tirePressure)
                  this.TireDot('右前', this.tirePressure + 0.02)
                  this.TireDot('左后', this.tirePressure - 0.01)
                  this.TireDot('右后', this.tirePressure)
                }.width('100%')
              }
              .width('100%')
              .layoutWeight(1)
              .padding(16)
              .borderRadius(20)
              .backgroundColor('#161E2E')
              .border({ width: 1, color: 'rgba(255,255,255,0.04)' })
            }
            .layoutWeight(1)
          }
          .width('100%')
          .layoutWeight(3)

          // 7日行驶里程柱状图
          Column() {
            Row() {
              Text('7 日行驶里程').fontSize(13).fontColor('#94A3B8').layoutWeight(1)
              Text(`总里程 ${this.odometer} km`).fontSize(10).fontColor('#64748B')
            }.width('100%')

            Row() {
              ForEach(this.weekMileage, (bar: MileageBar, idx: number) => {
                Column() {
                  // 柱子（从底部向上）
                  Column() {
                    Column()
                      .width('62%')
                      .height(`${Math.min(100, bar.value * 0.7)}%`)
                      .linearGradient({ angle: 0, colors: [['#00F0FF', 0.0], ['#00FFA3', 1.0]] })
                      .borderRadius({ topLeft: 6, topRight: 6 })
                  }
                  .layoutWeight(1)
                  .width('100%')
                  .justifyContent(FlexAlign.End)
                  .alignItems(HorizontalAlign.Center)

                  Text(bar.day).fontSize(10).fontColor('#64748B').margin({ top: 6 })
                  Text(`${bar.value}`).fontSize(9).fontColor('#94A3B8')
                }
                .layoutWeight(1)
                .height('100%')
              }, (bar: MileageBar, idx: number) => `${idx}-${bar.day}-${bar.value}`)
            }
            .width('100%')
            .layoutWeight(1)
            .margin({ top: 10 })
            .alignItems(VerticalAlign.Bottom)
          }
          .width('100%')
          .layoutWeight(2)
          .padding(16)
          .borderRadius(20)
          .backgroundColor('#161E2E')
          .border({ width: 1, color: 'rgba(255,255,255,0.04)' })
        }
        .layoutWeight(1.3)
        .height('100%')
      }
      .layoutWeight(1)
      .width('100%')
      .padding({ left: 20, right: 20, top: 4, bottom: 20 })
      .alignItems(VerticalAlign.Top)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#0B0F19')
  }

  @Builder
  HeaderPill(label: string, value: string, color: string) {
    Row({ space: 6 }) {
      Circle().width(6).height(6).fill(color)
      Text(label).fontSize(11).fontColor('#64748B')
      Text(value).fontSize(11).fontColor('#FFFFFF').fontWeight(FontWeight.Medium)
    }
    .padding({ left: 10, right: 10, top: 5, bottom: 5 })
    .borderRadius(999)
    .backgroundColor('rgba(255,255,255,0.04)')
    .border({ width: 1, color: 'rgba(255,255,255,0.06)' })
  }

  @Builder
  MiniMetric(title: string, value: string, icon: string, color: string) {
    Column() {
      Row() {
        Text(icon).fontSize(14)
        Text(title).fontSize(11).fontColor('#94A3B8').margin({ left: 6 })
      }.width('100%')
      Text(value)
        .fontSize(20).fontWeight(FontWeight.Bold).fontColor('#FFFFFF')
        .margin({ top: 6 })
      Row() {
        Column()
          .width('60%').height(3).borderRadius(2)
          .backgroundColor(color)
        Column()
          .layoutWeight(1).height(3).borderRadius(2).margin({ left: 4 })
          .backgroundColor('rgba(255,255,255,0.08)')
      }.width('100%').margin({ top: 10 })
    }
    .layoutWeight(1)
    .padding(12)
    .borderRadius(14)
    .backgroundColor('rgba(255,255,255,0.03)')
    .border({ width: 1, color: 'rgba(255,255,255,0.04)' })
  }

  @Builder
  TireDot(label: string, value: number) {
    Column() {
      Circle().width(8).height(8).fill('#00FFA3')
      Text(`${value.toFixed(2)}`).fontSize(9).fontColor('#FFFFFF').margin({ top: 4 })
      Text(label).fontSize(8).fontColor('#64748B').margin({ top: 1 })
    }
    .layoutWeight(1)
  }
}