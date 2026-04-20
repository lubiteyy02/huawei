/**
 * 注册页面
 */
import { AuthService } from '../services/AuthService'
import router from '@ohos.router'

@Entry
@Component
struct RegisterPage {
  @State phone: string = ''
  @State password: string = ''
  @State confirmPassword: string = ''
  @State nickname: string = ''
  @State errorMessage: string = ''
  @State isLoading: boolean = false
  
  private authService: AuthService = AuthService.getInstance()
  
  build() {
    Column() {
      // 返回按钮
      Row() {
        Button('< 返回')
          .backgroundColor(Color.Transparent)
          .fontColor('#333333')
          .onClick(() => {
            router.back({ url: 'pages/LoginPage' })
          })
      }
      .width('100%')
      .padding({ left: 20, top: 20 })
      
      // 标题
      Text('注册新账号')
        .fontSize(28)
        .fontWeight(FontWeight.Bold)
        .margin({ top: 40, bottom: 40 })
      
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
      
      // 昵称输入框
      Column() {
        Text('昵称（可选）')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请输入昵称' })
          .onChange((value: string) => {
            this.nickname = value
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
        
        TextInput({ placeholder: '请输入密码（至少6位）' })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.password = value
            this.errorMessage = ''
          })
          .width('100%')
          .height(48)
      }
      .width('85%')
      .margin({ bottom: 20 })
      
      // 确认密码输入框
      Column() {
        Text('确认密码')
          .fontSize(14)
          .fontColor('#666666')
          .alignSelf(ItemAlign.Start)
          .margin({ bottom: 8 })
        
        TextInput({ placeholder: '请再次输入密码' })
          .type(InputType.Password)
          .onChange((value: string) => {
            this.confirmPassword = value
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
      
      // 注册按钮
      Button(this.isLoading ? '注册中...' : '注册')
        .width('85%')
        .height(48)
        .fontSize(16)
        .margin({ top: 30 })
        .enabled(!this.isLoading)
        .onClick(() => {
          this.handleRegister()
        })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#FFFFFF')
  }
  
  /**
   * 处理注册
   */
  async handleRegister() {
    // 输入验证
    if (!this.phone || this.phone.trim() === '') {
      this.errorMessage = '请输入手机号'
      return
    }
    
    if (this.phone.length !== 11) {
      this.errorMessage = '请输入11位手机号'
      return
    }
    
    if (!this.password || this.password.trim() === '') {
      this.errorMessage = '请输入密码'
      return
    }
    
    if (this.password.length < 6) {
      this.errorMessage = '密码至少6位'
      return
    }
    
    if (!this.confirmPassword || this.confirmPassword.trim() === '') {
      this.errorMessage = '请确认密码'
      return
    }
    
    // 两次密码一致性验证
    if (this.password !== this.confirmPassword) {
      this.errorMessage = '两次输入的密码不一致'
      return
    }
    
    // 开始注册
    this.isLoading = true
    this.errorMessage = ''
    
    try {
      const response = await this.authService.register(
        this.phone,
        this.password,
        this.nickname || undefined
      )
      
      if (response.code === 200) {
        // 注册成功，自动登录并跳转到主页面
        console.log('[RegisterPage] 注册成功')
        router.replace({ url: 'pages/Index' })
      } else {
        // 注册失败，显示错误信息
        this.errorMessage = response.message || '注册失败'
      }
    } catch (err) {
      console.error('[RegisterPage] 注册异常:', err)
      this.errorMessage = '注册失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }
}
