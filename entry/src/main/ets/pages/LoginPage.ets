/**
 * 登录页面
 */
import { AuthService } from '../services/AuthService'
import router from '@ohos.router'

@Entry
@Component
struct LoginPage {
  @State phone: string = ''
  @State password: string = ''
  @State errorMessage: string = ''
  @State isLoading: boolean = false
  
  private authService: AuthService = AuthService.getInstance()
  
  build() {
    Column() {
      // 标题
      Text('车载导航系统')
        .fontSize(32)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 80, bottom: 60 })
      
      // 手机号输入框
      Column() {
        Text('手机号')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入手机号' })
          .type(InputType.PhoneNumber)
          .maxLength(11)
          .onChange((value: string) => {
            this.phone = value
            this.errorMessage = ''
          })
          .width('100%')
          .height(48)
      }
      .width('85%')
      .margin({ bottom: 20 })
      
      // 密码输入框
      Column() {
        Text('密码')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入密码' })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value
            this.errorMessage = ''
          })
          .width('100%')
          .height(48)
      }
      .width('85%')
      .margin({ bottom: 10 })
      
      // 错误提示
      if (this.errorMessage) {
        Text(this.errorMessage)
          .fontSize(14)
          .fontColor('#FF0000')
          .width('85%')
          .margin({ bottom: 20 })
      }
      
      // 登录按钮
      Button(this.isLoading ? '登录中...' : '登录')
        .width('85%')
        .height(48)
        .fontSize(16)
        .margin({ top: 30 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleLogin()
        })
      
      // 注册按钮
      Button('注册新账号')
        .width('85%')
        .height(48)
        .fontSize(16)
        .margin({ top: 15 })
        .backgroundColor('#F5F5F5')
        .fontColor('#333333')
        .enabled(!this.isLoading)
        .onClick(() => {
          router.pushUrl({ url: 'pages/RegisterPage' })
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
  
  /**
   * 处理登录
   */
  async handleLogin() {
    // 输入验证
    if (!this.phone || this.phone.trim() === '') {
      this.errorMessage = '请输入手机号'
      return
    }
    
    if (!this.password || this.password.trim() === '') {
      this.errorMessage = '请输入密码'
      return
    }
    
    if (this.phone.length !== 11) {
      this.errorMessage = '请输入11位手机号'
      return
    }
    
    // 开始登录
    this.isLoading = true
    this.errorMessage = ''
    
    try {
      const response = await this.authService.login(this.phone, this.password)
      
      if (response.code === 200) {
        // 登录成功，跳转到主页面
        console.log('[LoginPage] 登录成功')
        router.replaceUrl({ url: 'pages/Index' })
      } else {
        // 登录失败，显示错误信息
        this.errorMessage = response.message || '登录失败'
      }
    } catch (err) {
      console.error('[LoginPage] 登录异常:', err)
      this.errorMessage = '登录失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }
}
