/**
 * 收藏列表页面
 */
import { FavoriteService } from '../services/FavoriteService'
import { FavoritePlace } from '../models/BackendModels'
import router from '@ohos.router'
import promptAction from '@ohos.promptAction'

@Entry
@Component
struct FavoritesPage {
  @State favorites: FavoritePlace[] = []
  @State isLoading: boolean = false
  @State errorMessage: string = ''
  
  private favoriteService: FavoriteService = FavoriteService.getInstance()
  
  aboutToAppear() {
    this.loadFavorites()
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
        
        Text('我的收藏')
          .fontSize(20)
          .fontWeight(FontWeight.Bold)
          .layoutWeight(1)
          .textAlign(TextAlign.Center)
        
        // 占位，保持标题居中
        Text('      ')
      }
      .width('100%')
      .height(56)
      .padding({ left: 16, right: 16 })
      .backgroundColor('#FFFFFF')
      
      // 内容区域
      if (this.isLoading) {
        // 加载中
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
      } else if (this.errorMessage) {
        // 错误提示
        Column() {
          Text(this.errorMessage)
            .fontSize(14)
            .fontColor('#FF0000')
            .margin({ bottom: 20 })
          
          Button('重试')
            .onClick(() => {
              this.loadFavorites()
            })
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else if (this.favorites.length === 0) {
        // 空状态
        Column() {
          Text('暂无收藏')
            .fontSize(16)
            .fontColor('#999999')
        }
        .width('100%')
        .layoutWeight(1)
        .justifyContent(FlexAlign.Center)
      } else {
        // 收藏列表
        List() {
          ForEach(this.favorites, (item: FavoritePlace) => {
            ListItem() {
              this.FavoriteItem(item)
            }
          })
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
   * 收藏项组件
   */
  @Builder
  FavoriteItem(item: FavoritePlace) {
    Row() {
      Column() {
        // 名称
        Text(item.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
        
        // 地址
        Text(item.address)
          .fontSize(14)
          .fontColor('#666666')
          .maxLines(1)
          .textOverflow({ overflow: TextOverflow.Ellipsis })
          .margin({ top: 4 })
        
        // 添加时间
        Text(this.formatDate(item.createdAt))
          .fontSize(12)
          .fontColor('#999999')
          .margin({ top: 4 })
      }
      .layoutWeight(1)
      .alignItems(HorizontalAlign.Start)
      
      // 操作按钮
      Row() {
        Button('导航')
          .fontSize(14)
          .height(32)
          .backgroundColor('#007AFF')
          .onClick(() => {
            this.navigateToPlace(item)
          })
        
        Button('删除')
          .fontSize(14)
          .height(32)
          .backgroundColor('#FF3B30')
          .margin({ left: 10 })
          .onClick(() => {
            this.showDeleteConfirm(item)
          })
      }
    }
    .width('100%')
    .padding(16)
    .backgroundColor('#FFFFFF')
  }
  
  /**
   * 加载收藏列表
   */
  async loadFavorites() {
    this.isLoading = true
    this.errorMessage = ''
    
    try {
      const response = await this.favoriteService.getFavorites()
      
      if (response.code === 200 && response.data) {
        this.favorites = response.data
      } else {
        this.errorMessage = response.message || '加载失败'
      }
    } catch (err) {
      console.error('[FavoritesPage] 加载收藏列表失败:', err)
      this.errorMessage = '加载失败，请稍后重试'
    } finally {
      this.isLoading = false
    }
  }
  
  /**
   * 导航到地点
   */
  navigateToPlace(item: FavoritePlace) {
    console.log('[FavoritesPage] ========== 开始导航流程 ==========');
    console.log('[FavoritesPage] 导航到:', item.name);
    console.log('[FavoritesPage] 坐标:', item.latitude, item.longitude);
    
    // 使用 router 参数传递数据（更可靠）
    console.log('[FavoritesPage] 通过 router 参数传递导航目的地');
    router.back({
      url: 'pages/Index',
      params: {
        action: 'navigate',
        destination: item
      }
    });
    console.log('[FavoritesPage] ========== router.back() 已调用 ==========');
  }
  
  /**
   * 显示删除确认对话框
   */
  showDeleteConfirm(item: FavoritePlace) {
    promptAction.showDialog({
      title: '确认删除',
      message: `确定要删除收藏"${item.name}"吗？`,
      buttons: [
        { text: '取消', color: '#666666' },
        { text: '删除', color: '#FF3B30' }
      ]
    }).then((result) => {
      if (result.index === 1) {
        this.deleteFavorite(item.id)
      }
    })
  }
  
  /**
   * 删除收藏
   */
  async deleteFavorite(id: number) {
    try {
      const response = await this.favoriteService.deleteFavorite(id)
      
      if (response.code === 200) {
        promptAction.showToast({
          message: '删除成功',
          duration: 2000
        })
        // 刷新列表
        this.loadFavorites()
      } else {
        promptAction.showToast({
          message: response.message || '删除失败',
          duration: 2000
        })
      }
    } catch (err) {
      console.error('[FavoritesPage] 删除收藏失败:', err)
      promptAction.showToast({
        message: '删除失败',
        duration: 2000
      })
    }
  }
  
  /**
   * 格式化日期
   */
  formatDate(dateStr: string): string {
    try {
      const date = new Date(dateStr)
      const year = date.getFullYear()
      const month = String(date.getMonth() + 1).padStart(2, '0')
      const day = String(date.getDate()).padStart(2, '0')
      return `${year}-${month}-${day}`
    } catch (err) {
      return dateStr
    }
  }
}
