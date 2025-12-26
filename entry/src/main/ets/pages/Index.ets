import { NavigationModule } from './NavigationModule'
import { MediaModule } from './MediaModule'
import { CollaborationModule } from './CollaborationModule'
import { CarStatusModule } from './CarStatusModule'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isDockShow: boolean = false // 控制 Dock 是否展开
  private controller: TabsController = new TabsController()

  aboutToAppear() {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let windowClass = context.windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true);
    } catch (err) {
      console.error("Set full screen failed:", err);
    }
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) { // 对齐方式左下角

      // 1. 内容层 (全屏铺满)
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() { CarStatusModule() }
        TabContent() { NavigationModule() }
        TabContent() { MediaModule({ isPageVisible: this.currentIndex === 2 }) }
        TabContent() { CollaborationModule() }
      }
      .vertical(false)
      .barHeight(0)
      .scrollable(false)
      .width('100%')
      .height('100%')
      .expandSafeArea([SafeAreaType.SYSTEM], [SafeAreaEdge.TOP, SafeAreaEdge.BOTTOM])
      // 点击内容区域时，如果 Dock 打开着，就顺手关掉它
      .onClick(() => {
        if (this.isDockShow) {
          this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
            this.isDockShow = false;
          })
        }
      })

      // 2. 悬浮 Dock 栏
      Row() {
        this.DockItem("车辆状态", 0, "⚡️")
        this.DockItem("智能导航", 1, "🧭")
        this.DockItem("媒体娱乐", 2, "🎵")
        this.DockItem("超级协同", 3, "📱")
      }
      .width('80%')
      .height(80)
      .backgroundColor('rgba(15, 23, 42, 0.95)')
      .backdropBlur(50)
      .borderRadius(40)
      .border({ width: 1, color: 'rgba(255,255,255,0.15)' })
      .shadow({ radius: 30, color: 'rgba(0,0,0,0.6)', offsetY: 10 })
      .justifyContent(FlexAlign.SpaceEvenly)
      // 位置控制：显示时距离底部30，隐藏时往下沉150
      .position({ x: '10%', y: this.isDockShow ? '85%' : '100%' })
      .translate({ y: this.isDockShow ? -30 : 150 })
      .opacity(this.isDockShow ? 1 : 0)
      .zIndex(999)
      .animation({ duration: 400, curve: Curve.FastOutSlowIn })

      // 3. 系统菜单/Home 按钮 (永远悬浮在左下角)
      Button() {
        // 图标：如果是展开状态显示 "X"，收起状态显示 "菜单"
        Text(this.isDockShow ? "✕" : ":::")
          .fontSize(24)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Bold)
          .animation({ duration: 200 })
      }
      .width(56)
      .height(56)
      .borderRadius(28)
      .backgroundColor(this.isDockShow ? '#FF5E57' : 'rgba(30, 41, 59, 0.9)')
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.4)' })
      .border({ width: 1, color: 'rgba(255,255,255,0.2)' })
      .margin({ left: 20, bottom: 40 })
      .onClick(() => {
        // 切换 Dock 显示状态
        this.getUIContext().animateTo({ duration: 300, curve: Curve.EaseOut }, () => {
          this.isDockShow = !this.isDockShow;
        })
      })
      .zIndex(1000)
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }

  @Builder DockItem(title: string, index: number, icon: string) {
    Column() {
      Stack() {
        if (this.currentIndex === index) {
          Circle({ width: 44, height: 44 })
            .fill(this.getThemeColor(index)).opacity(0.15).blur(10)
        }
        Text(icon).fontSize(28)
          .scale(this.currentIndex === index ? { x: 1.1, y: 1.1 } : { x: 1, y: 1 })
      }.width(50).height(44).alignContent(Alignment.Center)

      Text(title).fontSize(10)
        .fontColor(this.currentIndex === index ? Color.White : 'rgba(255,255,255,0.5)')
        .margin({ top: 2 })
    }
    .height('100%').justifyContent(FlexAlign.Center).width(70)
    .onClick(() => {
      // 1. 更新 UI 选中态
      this.currentIndex = index
      // 2. 真正切换 Tabs 页面 (之前漏掉了这行)
      this.controller.changeIndex(index)
      // 3. 切换后收起 Dock
      this.getUIContext().animateTo({ duration: 300 }, () => {
        this.isDockShow = false;
      })
    })
  }

  getThemeColor(index: number): string {
    switch (index) {
      case 0: return '#00FFA3';
      case 1: return '#00E5FF';
      case 2: return '#FF0080';
      case 3: return '#FFD700';
      default: return '#FFFFFF';
    }
  }
}