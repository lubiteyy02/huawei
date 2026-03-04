/**
 * 测试菜单页面 - 用于测试后端集成功能
 */
import router from '@ohos.router'
import { AuthService } from '../services/AuthService'

@Entry
@Component
struct TestMenuPage {
  private authService: AuthService = AuthService.getInstance()
  @State isLoggedIn: boolean = false
  @State currentUser: string = ''
  
  async aboutToAppear() {
    // 检查登录状态
    this.isLoggedIn = await this.authService.isLoggedIn()
    if (this.isLoggedIn) {
      const user = await this.authService.getCurrentUser()
      if (user) {
        this.currentUser = user.nickname || user.phone
      }
    }
  }
  
  build() {
    Column() {
      // 标题
      Text('后端集成功能测试')
        .fontSize(24)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 20 })
      
      // 登录状态
      if (this.isLoggedIn) {
        Row() {
          Text(`已登录：${this.currentUser}`)
            .fontSize(14)
            .fontColor('#666666')
          
          Button('登出')
            .fontSize(14)
            .height(32)
            .margin({ left: 10 })
            .onClick(async () => {
              await this.authService.logout()
              this.isLoggedIn = false
              this.currentUser = ''
            })
        }
        .margin({ bottom: 30 })
      } else {
        Text('未登录')
          .fontSize(14)
          .fontColor('#999999')
          .margin({ bottom: 30 })
      }
      
      // 测试菜单
      Column({ space: 15 }) {
        // 认证功能
        Text('认证功能')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 20 })
        
        Button('登录页面')
          .width('85%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/LoginPage' })
          })
        
        Button('注册页面')
          .width('85%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/RegisterPage' })
          })
        
        // 数据功能
        Text('数据功能')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 30 })
        
        Button('我的收藏')
          .width('85%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/FavoritesPage' })
          })
        
        Button('导航历史')
          .width('85%')
          .onClick(() => {
            router.pushUrl({ url: 'pages/HistoryPage' })
          })
        
        // 返回主页
        Text('其他')
          .fontSize(18)
          .fontWeight(FontWeight.Medium)
          .alignSelf(ItemAlign.Start)
          .margin({ left: 20, top: 30 })
        
        Button('返回主页')
          .width('85%')
          .backgroundColor('#F5F5F5')
          .fontColor('#333333')
          .onClick(() => {
            router.pushUrl({ url: 'pages/Index' })
          })
      }
      .width('100%')
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
}
