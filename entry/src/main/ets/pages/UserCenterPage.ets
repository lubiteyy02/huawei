/**
 * 个人中心页面
 */
import router from '@ohos.router'
import { AuthService } from '../services/AuthService'
import { UserInfo } from '../models/BackendModels'

@Entry
@Component
struct UserCenterPage {
  private authService: AuthService = AuthService.getInstance()
  @State isLoggedIn: boolean = false
  @State currentUser: UserInfo | null = null
  
  async aboutToAppear() {
    this.isLoggedIn = await this.authService.isLoggedIn()
    if (this.isLoggedIn) {
      this.currentUser = await this.authService.getCurrentUser()
    }
  }
  
  async handleLogout() {
    await this.authService.logout()
    this.isLoggedIn = false
    this.currentUser = null
  }
  
  build() {
    Column() {
      // 顶部导航栏
      Row() {
        Button('返回')
          .fontSize(16)
          .backgroundColor(Color.Transparent)
          .fontColor('#FFFFFF')
          .onClick(() => {
            router.back({ url: 'pages/Index' })
          })
        
        Text('我的')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .fontColor('#FFFFFF')
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 占位，保持标题居中
        Text('')
          .width(60)
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#1A1A1A')
      
      // 用户信息区域
      Column() {
        if (this.isLoggedIn && this.currentUser) {
          // 已登录
          Column({ space: 12 }) {
            // 头像
            Text(this.currentUser.nickname?.charAt(0) || '用')
              .fontSize(40)
              .fontColor('#FFFFFF')
              .width(80)
              .height(80)
              .borderRadius(40)
              .backgroundColor('#4A90E2')
              .textAlign(TextAlign.Center)
              .lineHeight(80)
            
            // 昵称
            Text(this.currentUser.nickname || '用户')
              .fontSize(20)
              .fontWeight(FontWeight.Medium)
              .fontColor('#FFFFFF')
            
            // 手机号
            Text(this.currentUser.phone)
              .fontSize(14)
              .fontColor('#999999')
          }
          .padding({ top: 40, bottom: 40 })
        } else {
          // 未登录
          Column({ space: 16 }) {
            Text('👤')
              .fontSize(60)
            
            Text('未登录')
              .fontSize(18)
              .fontColor('#999999')
            
            Row({ space: 12 }) {
              Button('登录')
                .fontSize(16)
                .width(100)
                .height(40)
                .backgroundColor('#4A90E2')
                .onClick(() => {
                  router.push({ url: 'pages/LoginPage' })
                })
              
              Button('注册')
                .fontSize(16)
                .width(100)
                .height(40)
                .backgroundColor('#666666')
                .onClick(() => {
                  router.push({ url: 'pages/RegisterPage' })
                })
            }
          }
          .padding({ top: 40, bottom: 40 })
        }
      }
      .width('100%')
      .backgroundColor('#2A2A2A')
      
      // 功能列表
      Column() {
        // 我的收藏
        this.MenuItem('⭐', '我的收藏', async () => {
          if (!await this.authService.isLoggedIn()) {
            router.push({ url: 'pages/LoginPage' })
            return
          }
          router.push({ url: 'pages/FavoritesPage' })
        })
        
        Divider().color('#333333')
        
        // 导航历史
        this.MenuItem('📍', '导航历史', async () => {
          if (!await this.authService.isLoggedIn()) {
            router.push({ url: 'pages/LoginPage' })
            return
          }
          router.pushUrl({ url: 'pages/HistoryPage' })
        })
        
        if (this.isLoggedIn) {
          Divider().color('#333333')
          
          // 退出登录
          this.MenuItem('🚪', '退出登录', () => {
            this.handleLogout()
          })
        }
      }
      .width('100%')
      .backgroundColor('#1A1A1A')
      .margin({ top: 12 })
      .borderRadius(12)
      .padding({ left: 16, right: 16 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
  }
  
  @Builder
  MenuItem(icon: string, title: string, onClick: () => void | Promise<void>) {
    Row() {
      Text(icon)
        .fontSize(24)
        .margin({ right: 16 })
      
      Text(title)
        .fontSize(16)
        .fontColor('#FFFFFF')
        .layoutWeight(1)
      
      Text('›')
        .fontSize(24)
        .fontColor('#666666')
    }
    .width('100%')
    .height(56)
    .onClick(() => {
      void onClick()
    })
  }
}
