import { EnhancedNavigationModule } from '../view/EnhancedNavigationModule'
import { MediaModule } from '../view/MediaModule'
import { CollaborationModule } from '../view/CollaborationModule'
import { CarStatusModule } from '../view/CarStatusModule'
import { FavoritePlace } from '../models/BackendModels'
import { common } from '@kit.AbilityKit'
import { display } from '@kit.ArkUI'
import curves from '@ohos.curves'
import router from '@ohos.router'

interface ModuleConfig {
  title: string
  index: number
  angle: number
  icon: string
}

@Entry
@Component
struct Index {
  @State currentIndex: number = 0
  @State isExpanded: boolean = false
  private controller: TabsController = new TabsController()
  
  // 导航目的地参数
  @State navigationDestination: FavoritePlace | null = null
  // 事件式触发：业务方更新 navigationDestination 后将 navTriggerVersion 自增，本组件通过 @Watch 立即响应，避免 100ms 轮询
  @StorageProp('navTriggerVersion') @Watch('onNavTrigger') private navTriggerVersion: number = 0

  // === 坐标系统 ===
  @State ballX: number = 0
  @State ballY: number = 0
  @State screenWidthVp: number = 0
  @State screenHeightVp: number = 0

  // === 尺寸定义 ===
  private readonly BALL_SIZE: number = 60
  private readonly EXPAND_RADIUS: number = 90
  private readonly ITEM_SIZE: number = 56
  private readonly PANEL_SIZE: number = 260
  private readonly CENTER_BALL_SIZE: number = 74
  private readonly PANEL_ITEM_SIZE: number = 52

  private readonly menuItems: ModuleConfig[] = [
    { title: "车况", index: 0, angle: -90, icon: "🚗" },
    { title: "导航", index: 1, angle: -18, icon: "🧭" },
    { title: "娱乐", index: 2, angle: 54, icon: "🎵" },
    { title: "协同", index: 3, angle: 126, icon: "🤝" },
    { title: "我的", index: 4, angle: 198, icon: "👤" }
  ]

  private startX: number = 0
  private startY: number = 0
  private centerBallX: number = 0
  private centerBallY: number = 0

  aboutToAppear() {
    console.log('[Index] ========== aboutToAppear 开始 ==========');
    try {
      let context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      let windowClass = context.windowStage.getMainWindowSync();
      windowClass.setWindowLayoutFullScreen(true);

      let displayClass = display.getDefaultDisplaySync();
      this.screenWidthVp = displayClass.width / displayClass.densityPixels;
      this.screenHeightVp = displayClass.height / displayClass.densityPixels;

      this.ballX = this.screenWidthVp - this.BALL_SIZE - 30;
      this.ballY = this.screenHeightVp - this.BALL_SIZE - 120;
      
      console.log('[Index] 屏幕尺寸初始化完成:', this.screenWidthVp, 'x', this.screenHeightVp);
    } catch (err) {
      console.error('[Index] 初始化窗口失败:', err);
    }
    
    // 立即检查一次（处理冷启动时已经写入 AppStorage 的目的地）
    this.checkNavigationDestination();

    console.log('[Index] ========== aboutToAppear 完成 ==========');
  }

  aboutToDisappear() {}

  /**
   * AppStorage 中的 navTriggerVersion 变化时立即响应（事件式，无轮询）
   */
  onNavTrigger() {
    this.checkNavigationDestination();
  }
  
  onPageShow() {
    // 优先从 router 参数获取导航目的地
    try {
      const params = router.getParams() as Record<string, Object>;
      
      // 方式1：从收藏页面传递的参数格式 (action + destination)
      if (params && params['action'] === 'navigate') {
        const destination = params['destination'] as FavoritePlace;
        
        // 切换到导航Tab
        this.currentIndex = 1;
        this.controller.changeIndex(1);
        
        // 延迟设置导航目的地，确保Tab切换完成
        setTimeout(() => {
          this.navigationDestination = destination;
        }, 300);
        
        return;
      }
      
      // 方式2：从历史页面传递的参数格式 (navigationDestination)
      if (params && params['navigationDestination']) {
        const destination = params['navigationDestination'] as FavoritePlace;
        
        // 切换到导航Tab
        this.currentIndex = 1;
        this.controller.changeIndex(1);
        
        // 延迟设置导航目的地，确保Tab切换完成
        setTimeout(() => {
          this.navigationDestination = destination;
        }, 300);
        
        return;
      }
    } catch (err) {
      console.error('[Index] 获取 router 参数失败:', err);
    }
    
    // 备用方案：检查AppStorage中的导航目的地
    this.checkNavigationDestination();
  }
  
  /**
   * 检查并处理导航目的地（同步执行，无延迟）
   */
  checkNavigationDestination() {
    const navDest = AppStorage.get<FavoritePlace>('navigationDestination');
    if (!navDest) return;
    // 清除标志，避免重复触发
    AppStorage.delete('navigationDestination');
    AppStorage.delete('shouldSwitchToNavigation');
    // 切到导航 Tab
    this.currentIndex = 1;
    this.controller.changeIndex(1);
    // 先置 null 再赋新值，确保 @Prop externalDestination 必然变化
    this.navigationDestination = null;
    this.navigationDestination = navDest;
  }

  /**
   * 单次 animateTo 同时驱动 isExpanded + 必要的 ballX/Y 修正，
   * 让所有依赖这些状态的子组件（菜单 position/scale/opacity、主球加号旋转）共享同一条 spring 曲线，
   * 避免两次 animateTo 引起的不同步抖动。
   */
  toggleExpand() {
    let nextBallX: number = this.ballX;
    let nextBallY: number = this.ballY;
    if (!this.isExpanded) {
      const safePadding = this.EXPAND_RADIUS + (this.ITEM_SIZE / 2) + 10;
      const cX = this.ballX + (this.BALL_SIZE / 2);
      const cY = this.ballY + (this.BALL_SIZE / 2);
      const nCX = Math.max(safePadding, Math.min(cX, this.screenWidthVp - safePadding));
      const nCY = Math.max(safePadding, Math.min(cY, this.screenHeightVp - safePadding));
      nextBallX = nCX - (this.BALL_SIZE / 2);
      nextBallY = nCY - (this.BALL_SIZE / 2);
    }
    // 0.42 / 0.82 比原来 0.5/0.7 更紧凑，开合感更敏捷
    this.getUIContext().animateTo({ curve: curves.springMotion(0.42, 0.82) }, () => {
      this.isExpanded = !this.isExpanded;
      this.ballX = nextBallX;
      this.ballY = nextBallY;
    });
  }

  build() {
    Stack({ alignContent: Alignment.TopStart }) {
      // 1. 内容层
      Tabs({ barPosition: BarPosition.End, controller: this.controller }) {
        TabContent() { CarStatusModule() }.backgroundColor('#000000')
        TabContent() { 
          EnhancedNavigationModule({ 
            externalDestination: this.navigationDestination 
          }) 
        }.backgroundColor('#000000')
        TabContent() { MediaModule({ isPageVisible: this.currentIndex === 2 }) }.backgroundColor('#000000')
        TabContent() { CollaborationModule() }.backgroundColor('#000000')
      }
      .barHeight(0).scrollable(false).width('100%').height('100%')

      // 2. 遮罩层 (点击此处收缩)
      if (this.isExpanded) {
        Rect().width('100%').height('100%')
          .fill('rgba(0,0,0,0.01)') // 几乎隐形，只为了拦截点击
          .onClick(() => {
            // 点击空白处 -> 收缩
            this.toggleExpand()
          })
          .zIndex(9998)
      }

      // 3. 子菜单项
      ForEach(this.menuItems, (item: ModuleConfig) => {
        this.PureGlassItem(item)
      })

      // 4. 主悬浮球 (点击此处也可以收缩)
      this.PureMainBall()
    }
    .width('100%').height('100%').backgroundColor('#000000')
  }

  // === 纯净磨砂子菜单 ===
  // 关键：去掉外层 .animation()，让 position/scale/opacity 跟随 toggleExpand 中的 animateTo 块统一过渡，
  // 避免拖动时 ballX/Y 每帧变化触发独立 spring，造成 5 个 item 各自抖动。
  // 同时去掉昂贵的 backgroundBlurStyle，子菜单只用半透明色。
  @Builder
  PureGlassItem(item: ModuleConfig): void {
    Column({ space: 4 }) {
      Stack({ alignContent: Alignment.Center }) {
        Text(item.icon)
          .fontSize(24)
          .fontColor(this.currentIndex === item.index ? '#FFFFFF' : 'rgba(255,255,255,0.85)')
      }
      .width(this.ITEM_SIZE).height(this.ITEM_SIZE)
      .backgroundColor(this.currentIndex === item.index ? 'rgba(255, 255, 255, 0.28)' : 'rgba(40, 40, 40, 0.55)')
      .borderRadius(this.ITEM_SIZE / 2)
      .border({ width: 0.5, color: 'rgba(255,255,255,0.18)' })
      .onClick(() => {
        if (item.index === 4) {
          router.pushUrl({ url: 'pages/UserCenterPage' })
          this.toggleExpand()
        } else {
          this.currentIndex = item.index
          this.controller.changeIndex(item.index)
          // 选中后顺手收起菜单，减少误点 + 视觉更利落
          this.toggleExpand()
        }
      })

      Text(item.title)
        .fontSize(10).fontColor('rgba(255,255,255,0.75)').fontWeight(FontWeight.Regular)
        .opacity(this.isExpanded ? 1 : 0)
    }
    .position({
      x: this.ballX + (this.BALL_SIZE / 2) - (this.ITEM_SIZE / 2) +
        (this.isExpanded ? (this.EXPAND_RADIUS - 8) * Math.cos(item.angle * Math.PI / 180) : 0),
      y: this.ballY + (this.BALL_SIZE / 2) - (this.ITEM_SIZE / 2) +
        (this.isExpanded ? (this.EXPAND_RADIUS - 8) * Math.sin(item.angle * Math.PI / 180) : 0)
    })
    .zIndex(9999)
    .scale({ x: this.isExpanded ? 1 : 0.45, y: this.isExpanded ? 1 : 0.45 })
    .opacity(this.isExpanded ? 1 : 0)
    // 收起态用 hitTestBehavior 阻止接收点击，避免折叠后透明 item 误吃事件
    .hitTestBehavior(this.isExpanded ? HitTestMode.Default : HitTestMode.None)
  }

  // === 纯净主球 ===
  @Builder
  PureMainBall(): void {
    Stack({ alignContent: Alignment.Center }) {
      Text("＋")
        .fontSize(26).fontColor('#FFFFFF').fontWeight(FontWeight.Lighter)
        // 不写 .animation()：让旋转跟随 toggleExpand 的 animateTo 块的 springMotion 一起过渡
        .rotate({ angle: this.isExpanded ? 135 : 0 })
        .margin({ bottom: 2 })
    }
    .width(this.BALL_SIZE).height(this.BALL_SIZE)
    .backgroundColor('rgba(40, 40, 40, 0.5)')
    .backgroundBlurStyle(BlurStyle.Thick)
    .borderRadius(this.BALL_SIZE / 2)
    .clip(true)
    .border({ width: 0.5, color: 'rgba(255,255,255,0.2)' })
    .shadow({ radius: 10, color: 'rgba(0,0,0,0.2)', offsetY: 4 })
    .position({ x: this.ballX, y: this.ballY })
    .zIndex(10000)
    .onClick(() => {
      this.toggleExpand()
    })
    .gesture(
      PanGesture()
        .onActionStart(() => {
          if (this.isExpanded) this.toggleExpand()
          this.startX = this.ballX; this.startY = this.ballY
        })
        .onActionUpdate((e) => {
          let rX = this.startX + e.offsetX; let rY = this.startY + e.offsetY
          this.ballX = Math.max(0, Math.min(rX, this.screenWidthVp - this.BALL_SIZE))
          this.ballY = Math.max(0, Math.min(rY, this.screenHeightVp - this.BALL_SIZE))
        })
    )
  }
}