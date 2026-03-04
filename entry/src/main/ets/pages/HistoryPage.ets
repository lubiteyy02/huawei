/**
 * 导航历史页面
 */
import { NavigationHistoryService } from '../services/NavigationHistoryService'
import { NavigationHistory } from '../models/BackendModels'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct HistoryPage {
  @State historyList: NavigationHistory[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  @State currentPage: number = 1
  @State hasMore: boolean = true
  
  private historyService: NavigationHistoryService = NavigationHistoryService.getInstance()
  
  aboutToAppear() {
    this.loadHistory()
  }
  
  build() {
    Column() {
      // 标题栏
      Row() {
        Button('< 返回')
          .backgroundColor(Color.Transparent)
          .fontColor('#333333')
          .onClick(() => {
            router.back()
          })
        
        Text('导航历史')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        Button('清空')
          .fontSize(14)
          .backgroundColor(Color.Transparent)
          .fontColor('#FF3B30')
          .onClick(() => {
            this.showClearConfirm()
          })
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      // 内容区域
      if (this.isLoading && this.historyList.length === 0) {
        // 首次加载中
        Column() {
          LoadingProgress()
            .width(50)
            .height(50)
          Text('加载中...')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ top: 10 })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.errorMessage && this.historyList.length === 0) {
        // 错误提示
        Column() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .margin({ bottom: 20 })
          
          Button('重试')
            .onClick(() => {
              this.loadHistory()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.historyList.length === 0) {
        // 空状态
        Column() {
          Text('暂无导航历史')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 历史列表
        List() {
          ForEach(this.historyList, (item: NavigationHistory) => {
            ListItem() {
              this.HistoryItem(item)
            }
          })
          
          // 加载更多
          if (this.hasMore) {
            ListItem() {
              Row() {
                if (this.isLoading) {
                  LoadingProgress()
                    .width(30)
                    .height(30)
                  Text('加载中...')
                    .fontSize(14)
                    .fontColor('#999999')
                    .margin({ left: 10 })
                } else {
                  Button('加载更多')
                    .fontSize(14)
                    .onClick(() => {
                      this.loadMore()
                    })
                }
              }
              .width('100%')
              .height(60)
              .justifyContent(FlexAlign.Center)
            }
          }
        }
        .width('100%')
        .layoutWeight(1)
        .divider({ strokeWidth: 1, color: '#F0F0F0' })
      }
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#F5F5F5')
  }
  
  /**
   * 历史记录项组件
   */
  @Builder
  HistoryItem(item: NavigationHistory) {
    Row() {
      Column() {
        // 起点和终点
        Row() {
          Text(item.startName || '当前位置')
            .fontSize(14)
            .fontColor('#666666')
          
          Text(' → ')
            .fontSize(14)
            .fontColor('#999999')
            .margin({ left: 5, right: 5 })
          
          Text(item.endName)
            .fontSize(14)
            .fontWeight(FontWeight.Medium)
        }
        
        // 地址
        Text(item.endAddress)
          .fontSize(12)
          .fontColor('#999999')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
        
        // 距离和时长
        Row() {
          Text(this.formatDistance(item.distance))
            .fontSize(12)
            .fontColor('#999999')
          
          Text(' | ')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 5, right: 5 })
          
          Text(this.formatDuration(item.duration))
            .fontSize(12)
            .fontColor('#999999')
          
          Text(' | ')
            .fontSize(12)
            .fontColor('#999999')
            .margin({ left: 5, right: 5 })
          
          Text(this.formatDate(item.createdAt))
            .fontSize(12)
            .fontColor('#999999')
        }
        .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 重新导航按钮
      Button('再次导航')
        .fontSize(14)
        .height(32)
        .backgroundColor('#007AFF')
        .onClick(() => {
          this.navigateAgain(item)
        })
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }
  
  /**
   * 加载历史记录
   */
  async loadHistory() {
    this.isLoading = true
    this.errorMessage = ''
    this.currentPage = 1
    
    try {
      const response = await this.historyService.getHistory(this.currentPage, 20)
      
      if (response.code === 200 && response.data) {
        this.historyList = response.data.list
        this.hasMore = this.historyList.length < response.data.total
      } else {
        this.errorMessage = response.message || '加载失败'
      }
    } catch (err) {
      console.error('[HistoryPage] 加载历史记录失败:', err)
      this.errorMessage = '加载失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 加载更多
   */
  async loadMore() {
    if (this.isLoading || !this.hasMore) {
      return
    }
    
    this.isLoading = true
    this.currentPage++
    
    try {
      const response = await this.historyService.getHistory(this.currentPage, 20)
      
      if (response.code === 200 && response.data) {
        this.historyList = this.historyList.concat(response.data.list)
        this.hasMore = this.historyList.length < response.data.total
      }
    } catch (err) {
      console.error('[HistoryPage] 加载更多失败:', err)
      this.currentPage--
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 再次导航
   */
  navigateAgain(item: NavigationHistory) {
    // 使用 router 参数传递导航目的地数据
    router.back({
      url: 'pages/Index',
      params: {
        navigationDestination: {
          name: item.endName,
          address: item.endAddress,
          latitude: item.endLat,
          longitude: item.endLng
        }
      }
    })
  }
  
  /**
   * 显示清空确认对话框
   */
  showClearConfirm() {
    promptAction.showDialog({
      title: '确认清空',
      message: '确定要清空所有导航历史吗？',
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '清空', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.clearHistory()
      }
    })
  }
  
  /**
   * 清空历史记录
   */
  async clearHistory() {
    try {
      const response = await this.historyService.clearHistory()
      
      if (response.code === 200) {
        promptAction.showToast({
          message: '清空成功',
          duration: 2000
        })
        this.historyList = []
      } else {
        promptAction.showToast({
          message: response.message || '清空失败',
          duration: 2000
        })
      }
    } catch (err) {
      console.error('[HistoryPage] 清空历史失败:', err)
      promptAction.showToast({
        message: '清空失败',
        duration: 2000
      })
    }
  }
  
  /**
   * 格式化距离
   */
  formatDistance(meters: number): string {
    if (meters < 1000) {
      return `${meters}米`
    } else {
      return `${(meters / 1000).toFixed(1)}公里`
    }
  }
  
  /**
   * 格式化时长
   */
  formatDuration(seconds: number): string {
    if (seconds < 60) {
      return `${seconds}秒`
    } else if (seconds < 3600) {
      return `${Math.floor(seconds / 60)}分钟`
    } else {
      const hours = Math.floor(seconds / 3600)
      const minutes = Math.floor((seconds % 3600) / 60)
      return `${hours}小时${minutes}分钟`
    }
  }
  
  /**
   * 格式化日期
   */
  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr)
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      const hour = String(date.getHours()).padStart(2, '0')
      const minute = String(date.getMinutes()).padStart(2, '0')
      return `${month}-${day} ${hour}:${minute}`
    } catch (err) {
      return dateStr
    }
  }
}
