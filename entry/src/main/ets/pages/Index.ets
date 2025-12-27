import { NavigationModule } from './NavigationModule'
import { MediaModule } from './MediaModule'
import { CollaborationModule } from './CollaborationModule'
import { CarStatusModule } from './CarStatusModule'
import { common } from '@kit.AbilityKit'

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isExpanded: boolean = false // 控制侧边栏展开
  private controller: TabsController = new TabsController()

  aboutToAppear() {
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let windowClass = context.windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true);
    } catch (err) {}
  }

  build() {
    Stack({ alignContent: Alignment.BottomStart }) {

      // 1. 内容层 (全屏铺满，不留左侧空白)
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
      .onClick(() => {
        // 点击内容区自动收起菜单
        if (this.isExpanded) {
          this.getUIContext().animateTo({ duration: 300, curve: Curve.FastOutSlowIn }, () => {
            this.isExpanded = false;
          })
        }
      })

      // 2. 灵动侧边栏 (悬浮在左下角)
      Column() {
        if (this.isExpanded) {
          Column({ space: 20 }) {
            this.MenuItem(0, "⚡️", "车况")
            this.MenuItem(1, "🧭", "导航")
            this.MenuItem(2, "🎵", "媒体")
            this.MenuItem(3, "📱", "互联")
          }
          .margin({ bottom: 20 })
          .transition({ type: TransitionType.Insert, opacity: 0, translate: { y: 20 } })
          .transition({ type: TransitionType.Delete, opacity: 0, translate: { y: 20 } })
        }

        // 触发按钮
        Button() {
          Text(this.isExpanded ? "✕" : ":::")
            .fontSize(24).fontColor(Color.White).fontWeight(FontWeight.Bold)
        }
        .width(56).height(56).borderRadius(28)
        .backgroundColor(this.isExpanded ? 'rgba(255, 255, 255, 0.2)' : 'transparent')
        .onClick(() => {
          this.getUIContext().animateTo({ duration: 350, curve: Curve.FastOutSlowIn }, () => {
            this.isExpanded = !this.isExpanded;
          })
        })
      }
      .width(72)
      .padding({ top: 10, bottom: 8 })
      .backgroundColor('rgba(15, 23, 42, 0.9)')
      .backdropBlur(60)
      .borderRadius(40)
      .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
      .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)', offsetX: 10, offsetY: 10 })
      .margin({ left: 24, bottom: 40 }) // 固定位置
      .clip(true)
      .zIndex(999)
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }

  @Builder MenuItem(index: number, icon: string, label: string) {
    Column() {
      if (this.currentIndex === index) {
        Circle({ width: 6, height: 6 }).fill('#00E5FF').margin({ bottom: 4 })
      }
      Button() { Text(icon).fontSize(26) }
      .width(50).height(50).type(ButtonType.Circle)
      .backgroundColor(this.currentIndex === index ? 'rgba(0, 229, 255, 0.15)' : 'transparent')
      .onClick(() => {
        this.currentIndex = index;
        this.controller.changeIndex(index);
      })
      Text(label).fontSize(10).fontColor(this.currentIndex === index ? '#00E5FF' : 'rgba(255,255,255,0.5)').margin({ top: -2 })
    }
  }
}