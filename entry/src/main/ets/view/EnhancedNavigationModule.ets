/**
 * 增强版导航模块
 * 集成完整的导航功能：定位、路径规划、导航指引、POI搜索
 * 使用IP定位（简单可靠）
 */
import { webview } from '@kit.ArkWeb';
import { MapService, Location, POIResult } from '../services/MapService';
import { NavigationService, NavigationState, NavigationInfo } from '../services/NavigationService';
import { VoiceGuideService } from '../services/VoiceGuideService';
import { FavoriteService } from '../services/FavoriteService';
import { NavigationHistoryService } from '../services/NavigationHistoryService';
import { AuthService } from '../services/AuthService';
import { FavoritePlace } from '../models/BackendModels';
import promptAction from '@ohos.promptAction';

@Component
export struct EnhancedNavigationModule {
  // 外部传入的导航目的地
  @Prop @Watch('onDestinationChange') externalDestination: FavoritePlace | null = null;
  
  // 地图相关
  @State isMapLoaded: boolean = false;
  @State zoomLevel: number = 15;
  private webController: webview.WebviewController = new webview.WebviewController();
  
  // 定位相关
  @State latitude: number = 30.486874173982763;
  @State longitude: number = 114.309994670642;
  @State addressText: string = "正在定位...";
  
  // 导航相关
  @State isNavigating: boolean = false;
  @State navigationInfo: NavigationInfo | null = null;
  @State remainingDistance: string = '';
  @State remainingTime: string = '';
  @State nextInstruction: string = '';
  
  // 搜索相关
  @State showSearchPanel: boolean = false;
  @State searchKeyword: string = '';
  @State searchResults: POIResult[] = [];
  @State isSearching: boolean = false;
  @State showSearchHistory: boolean = false;
  @State searchHistory: string[] = [];
  
  // 服务实例
  private mapService: MapService = MapService.getInstance();
  private navigationService: NavigationService = NavigationService.getInstance();
  private voiceService: VoiceGuideService = VoiceGuideService.getInstance();
  private favoriteService: FavoriteService = FavoriteService.getInstance();
  private historyService: NavigationHistoryService = NavigationHistoryService.getInstance();
  private authService: AuthService = AuthService.getInstance();
  
  aboutToAppear() {
    // 监听导航状态变化
    this.navigationService.addListener((info) => {
      this.onNavigationUpdate(info);
    });
    
    // 检查是否有外部传入的导航目的地
    if (this.externalDestination) {
      this.handleExternalDestination();
    }
  }
  
  /**
   * 监听外部传入的导航目的地变化
   */
  onDestinationChange() {
    if (this.externalDestination) {
      this.handleExternalDestination();
    }
  }
  
  /**
   * 处理外部传入的导航目的地
   */
  handleExternalDestination() {
    if (!this.externalDestination) {
      return;
    }
    
    console.log('[Navigation] 收到外部导航目的地:', this.externalDestination.name);
    console.log('[Navigation] 坐标:', this.externalDestination.latitude, this.externalDestination.longitude);
    
    const destination: Location = {
      latitude: this.externalDestination.latitude,
      longitude: this.externalDestination.longitude
    };
    
    // 如果地图已加载,立即启动导航;否则等待地图加载
    if (this.isMapLoaded) {
      console.log('[Navigation] 地图已加载,立即启动导航');
      // 延迟一下,确保WebView完全准备好
      setTimeout(() => {
        this.startNavigation(destination);
      }, 500);
    } else {
      console.log('[Navigation] 等待地图加载...');
      // 等待地图加载完成后再启动导航
      let retryCount = 0;
      const maxRetries = 100; // 10秒超时
      const checkInterval = setInterval(() => {
        retryCount++;
        if (this.isMapLoaded) {
          console.log('[Navigation] 地图加载完成(重试', retryCount, '次),启动导航');
          clearInterval(checkInterval);
          // 延迟一下,确保WebView完全准备好
          setTimeout(() => {
            this.startNavigation(destination);
          }, 500);
        } else if (retryCount >= maxRetries) {
          console.error('[Navigation] 等待地图加载超时');
          clearInterval(checkInterval);
        }
      }, 100);
    }
  }
  
  aboutToDisappear() {
    this.voiceService.release();
  }
  
  /**
   * IP定位
   */
  async startIPLocation() {
    try {
      console.log('[Navigation] 开始IP定位...');
      this.addressText = "IP定位中...";
      
      const location = await this.mapService.getCurrentLocation();
      
      this.latitude = location.latitude;
      this.longitude = location.longitude;
      this.addressText = location.address ? `IP定位 (${location.address})` : "默认位置(武汉)";
      
      console.log('[Navigation] IP定位完成:', this.latitude, this.longitude);
      
      // 更新地图标记
      const currentLocation: Location = {
        latitude: this.latitude,
        longitude: this.longitude
      };
      this.mapService.addCurrentLocationMarker(currentLocation);
      this.mapService.moveToLocation(currentLocation, this.zoomLevel);
      
    } catch (err) {
      console.error('[Navigation] IP定位失败:', err);
      this.addressText = "定位失败,使用默认位置";
    }
  }
  
  /**
   * 地图加载完成
   */
  onMapLoad() {
    this.isMapLoaded = true;
    this.mapService.setWebController(this.webController);
    
    // 移动地图到默认位置
    const defaultLocation: Location = {
      latitude: this.latitude,
      longitude: this.longitude
    };
    this.mapService.moveToLocation(defaultLocation, this.zoomLevel);
    
    // 延迟添加标记，确保WebView准备好
    setTimeout(() => {
      this.mapService.addCurrentLocationMarker(defaultLocation);
      console.log('[Navigation] 地图初始化完成');
    }, 300);
    
    // 启动IP定位
    setTimeout(() => {
      this.startIPLocation();
    }, 500);
  }
  
  /**
   * 缩放地图
   */
  changeZoom(delta: number): void {
    if (!this.webController) return;
    this.zoomLevel = Math.max(3, Math.min(20, this.zoomLevel + delta));
    try {
      const message = JSON.stringify({
        action: 'setZoom',
        zoom: this.zoomLevel
      });
      this.webController.runJavaScript(`window.postMessage('${message}', '*')`);
    } catch(e) {
      console.error('Change zoom error:', e);
    }
  }
  
  /**
   * 回到当前位置
   */
  backToCurrentLocation(): void {
    if (this.webController) {
      const currentLocation: Location = {
        latitude: this.latitude,
        longitude: this.longitude
      };
      this.mapService.moveToLocation(currentLocation, this.zoomLevel);
    }
  }
  
  /**
   * 开始导航
   */
  async startNavigation(destination: Location) {
    try {
      await this.navigationService.startNavigation(destination);
      this.isNavigating = true;
      this.showSearchPanel = false;
    } catch (err) {
      console.error('Start navigation error:', err);
    }
  }
  
  /**
   * 停止导航
   */
  stopNavigation() {
    this.navigationService.stopNavigation();
    this.isNavigating = false;
    this.navigationInfo = null;
    this.addressText = "实时定位";
  }
  
  /**
   * 导航状态更新
   */
  onNavigationUpdate(info: NavigationInfo) {
    this.navigationInfo = info;
    
    // 更新显示信息
    if (info.remainingDistance > 1000) {
      this.remainingDistance = `${(info.remainingDistance / 1000).toFixed(1)} 公里`;
    } else {
      this.remainingDistance = `${Math.round(info.remainingDistance)} 米`;
    }
    
    const hours = Math.floor(info.remainingTime / 3600);
    const minutes = Math.floor((info.remainingTime % 3600) / 60);
    if (hours > 0) {
      this.remainingTime = `${hours}小时${minutes}分钟`;
    } else {
      this.remainingTime = `${minutes}分钟`;
    }
    
    this.nextInstruction = info.nextInstruction;
    this.addressText = info.nextInstruction;
    
    // 到达目的地
    if (info.state === NavigationState.ARRIVED) {
      this.voiceService.speakArrival();
      setTimeout(() => {
        this.stopNavigation();
      }, 3000);
    }
  }
  
  /**
   * 搜索POI
   */
  async searchPOI() {
    if (!this.searchKeyword.trim()) return;
    
    this.isSearching = true;
    try {
      const currentLocation: Location = { latitude: this.latitude, longitude: this.longitude };
      const results = await this.mapService.searchPOI(
        this.searchKeyword,
        currentLocation,
        5000
      );
      this.searchResults = results;
    } catch (err) {
      console.error('Search error:', err);
    } finally {
      this.isSearching = false;
    }
  }
  
  /**
   * 选择POI并导航
   */
  selectPOI(poi: POIResult) {
    this.startNavigation(poi.location);
  }
  
  /**
   * 收藏当前位置或POI
   */
  async addToFavorites(name: string, address: string, location: Location) {
    try {
      console.log('[Navigation] 开始收藏:', name);
      console.log('[Navigation] 地址:', address);
      console.log('[Navigation] 坐标:', location.latitude, location.longitude);
      
      const isLoggedIn = await this.authService.isLoggedIn();
      console.log('[Navigation] 登录状态:', isLoggedIn);
      
      if (!isLoggedIn) {
        console.log('[Navigation] 未登录，提示用户登录');
        promptAction.showToast({
          message: '请先登录',
          duration: 2000
        });
        return;
      }
      
      const response = await this.favoriteService.addFavorite({
        name: name,
        address: address,
        latitude: location.latitude,
        longitude: location.longitude
      });
      
      console.log('[Navigation] 收藏响应代码:', response.code);
      console.log('[Navigation] 收藏响应消息:', response.message);
      console.log('[Navigation] 完整响应:', JSON.stringify(response));
      
      if (response.code === 200) {
        console.log('[Navigation] 收藏成功');
        promptAction.showToast({
          message: '收藏成功',
          duration: 2000
        });
      } else {
        console.error('[Navigation] 收藏失败:', response.message);
        promptAction.showToast({
          message: response.message || '收藏失败',
          duration: 2000
        });
      }
    } catch (err) {
      console.error('[Navigation] 收藏异常 - 类型:', typeof err);
      console.error('[Navigation] 收藏异常 - 详情:', JSON.stringify(err));
      promptAction.showToast({
        message: '收藏失败，请稍后重试',
        duration: 2000
      });
    }
  }
  
  /**
   * 加载搜索历史
   */
  async loadSearchHistory() {
    try {
      const response = await this.historyService.getHistory();
      // 提取最近5条搜索记录的目的地名称
      if (response.data && response.data.list) {
        this.searchHistory = response.data.list.slice(0, 5).map(item => item.endName);
      } else {
        this.searchHistory = [];
      }
    } catch (err) {
      console.error('[Navigation] 加载搜索历史失败:', err);
      this.searchHistory = [];
    }
  }
  
  /**
   * 保存导航历史
   */
  async saveNavigationHistory(destination: Location, destinationName: string) {
    try {
      const isLoggedIn = await this.authService.isLoggedIn();
      if (!isLoggedIn) {
        return;
      }
      
      await this.historyService.saveHistory({
        startLat: this.latitude,
        startLng: this.longitude,
        startName: '当前位置',
        startAddress: this.addressText,
        endLat: destination.latitude,
        endLng: destination.longitude,
        endName: destinationName,
        endAddress: destinationName,
        distance: 0, // 实际距离由后端计算
        duration: 0  // 实际时长由后端计算
      });
      
      console.log('[Navigation] 导航历史已保存');
    } catch (err) {
      console.error('[Navigation] 保存导航历史失败:', err);
    }
  }
  
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 地图层 - 使用WebView加载高德地图
      Stack() {
        Web({ src: $rawfile('amap.html'), controller: this.webController })
          .width('100%')
          .height('100%')
          .onPageEnd(() => {
            console.log('地图页面加载完成');
            this.onMapLoad();
          })
          .onErrorReceive((event) => {
            console.error('地图加载错误:', event?.error);
          })
          .onConsole((event) => {
            // 转发WebView的console日志到ArkTS
            if (event && event.message) {
              const msg = event.message;
              const message = msg.getMessage();
              const sourceId = msg.getSourceId();
              const lineNumber = msg.getLineNumber();
              
              // 输出WebView日志，包含来源信息
              console.log('[WebView]', message, 'at', sourceId, ':', lineNumber);
            }
            return false;
          })
      }
      
      // 2. 顶部搜索栏
      if (!this.isNavigating) {
        this.SearchBar()
      }
      
      // 3. 右侧控制按钮
      this.ControlButtons()
      
      // 4. 底部信息面板
      if (this.isNavigating && this.navigationInfo) {
        this.NavigationPanel()
      } else {
        this.LocationPanel()
      }
      
      // 5. 搜索结果面板
      if (this.showSearchPanel) {
        this.SearchResultPanel()
      }
    }
  }
  
  /**
   * 搜索栏
   */
  @Builder
  SearchBar(): void {
    Column() {
      Row() {
        TextInput({ placeholder: '搜索地点、地址' })
          .layoutWeight(1)
          .height(48)
          .backgroundColor(Color.White)
          .borderRadius(24)
          .padding({ left: 20, right: 20 })
          .onChange((value: string): void => {
            this.searchKeyword = value;
          })
          .onFocus(() => {
            // 获得焦点时加载搜索历史
            this.showSearchHistory = true;
            this.loadSearchHistory();
          })
          .onBlur(() => {
            // 延迟隐藏，以便点击历史记录
            setTimeout(() => {
              this.showSearchHistory = false;
            }, 200);
          })
          .onSubmit((): void => {
            this.showSearchPanel = true;
            this.showSearchHistory = false;
            this.searchPOI();
            return;
          })
        
        // 收藏按钮
        Button() {
          Text('⭐')
            .fontSize(20)
        }
        .height(48)
        .width(48)
        .backgroundColor('rgba(255,255,255,0.9)')
        .borderRadius(24)
        .margin({ left: 10 })
        .onClick(async () => {
          // 收藏当前位置
          await this.addToFavorites(
            '当前位置',
            this.addressText,
            { latitude: this.latitude, longitude: this.longitude }
          );
        })
        
        Button('搜索')
          .height(48)
          .backgroundColor('#00E5FF')
          .borderRadius(24)
          .margin({ left: 10 })
          .onClick((): void => {
            this.showSearchPanel = true;
            this.showSearchHistory = false;
            this.searchPOI();
          })
      }
      .width('90%')
      
      // 搜索历史面板
      if (this.showSearchHistory && this.searchHistory.length > 0) {
        Column() {
          Text('搜索历史')
            .fontSize(14)
            .fontColor('#666')
            .width('100%')
            .padding({ left: 15, top: 10, bottom: 5 })
          
          ForEach(this.searchHistory, (keyword: string) => {
            Row() {
              Text('🕐')
                .fontSize(16)
                .margin({ right: 10 })
              
              Text(keyword)
                .fontSize(14)
                .fontColor('#333')
                .layoutWeight(1)
            }
            .width('100%')
            .height(40)
            .padding({ left: 15, right: 15 })
            .onClick(() => {
              this.searchKeyword = keyword;
              this.showSearchPanel = true;
              this.showSearchHistory = false;
              this.searchPOI();
            })
          })
        }
        .width('90%')
        .backgroundColor(Color.White)
        .borderRadius(12)
        .margin({ top: 10 })
        .padding({ bottom: 10 })
      }
    }
    .width('100%')
    .alignItems(HorizontalAlign.Center)
    .padding(16)
    .position({ x: '5%', y: 60 })
  }
  
  @Builder
  ControlButtons(): void {
    Column({ space: 15 }) {
      this.MapBtn("＋", (): void => this.changeZoom(1))
      
      this.MapBtn("－", (): void => this.changeZoom(-1))
      
      this.MapBtn("◎", (): void => this.backToCurrentLocation())
      
      if (this.isNavigating) {
        this.MapBtn("■", (): void => this.stopNavigation())
      }
    }
    .alignItems(HorizontalAlign.Center)
    .position({ x: '100%', y: '50%' })
    .markAnchor({ x: '100%', y: '50%' })
    .padding({ right: 20 })
  }
  
  /**
   * 导航信息面板
   */
  @Builder
  NavigationPanel(): void {
    Column({ space: 12 }) {
      // 剩余信息
      Row() {
        Column() {
          Text(this.remainingDistance)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00E5FF')
          Text("剩余距离")
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.6)')
        }
        .margin({ right: 30 })
        
        Column() {
          Text(this.remainingTime)
            .fontSize(28)
            .fontWeight(FontWeight.Bold)
            .fontColor('#00FFA3')
          Text("预计时间")
            .fontSize(12)
            .fontColor('rgba(255,255,255,0.6)')
        }
      }
      
      Divider().color('rgba(255,255,255,0.2)')
      
      // 下一步指令
      Row() {
        Text("➤")
          .fontSize(24)
          .fontColor('#00E5FF')
          .margin({ right: 15 })
        Text(this.nextInstruction)
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
          .maxLines(2)
      }
      .width('100%')
    }
    .width('90%')
    .padding(20)
    .backgroundColor('rgba(15, 23, 42, 0.95)')
    .backdropBlur(30)
    .borderRadius(24)
    .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
    .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)', offsetY: 10 })
    .margin({ bottom: 40 })
  }
  
  /**
   * 位置信息面板
   */
  @Builder
  LocationPanel(): void {
    Row() {
      Column() {
        Text(this.addressText)
          .fontSize(16)
          .fontColor(Color.White)
          .fontWeight(FontWeight.Medium)
        Text(`Lat: ${this.latitude.toFixed(4)}  Lng: ${this.longitude.toFixed(4)}`)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
    }
    .padding({ left: 30, right: 30, top: 16, bottom: 16 })
    .backgroundColor('rgba(15, 23, 42, 0.9)')
    .backdropBlur(30)
    .borderRadius(24)
    .border({ width: 1, color: 'rgba(255,255,255,0.1)' })
    .shadow({ radius: 30, color: 'rgba(0,0,0,0.5)', offsetY: 10 })
    .margin({ bottom: 40 })
  }
  
  /**
   * 搜索结果面板
   */
  @Builder
  SearchResultPanel(): void {
    Column() {
      // 标题栏
      Row() {
        Text('搜索结果')
          .fontSize(18)
          .fontWeight(FontWeight.Bold)
          .fontColor(Color.White)
          .layoutWeight(1)
        
        Button('✕')
          .type(ButtonType.Circle)
          .width(32)
          .height(32)
          .fontSize(16)
          .backgroundColor('rgba(255,255,255,0.1)')
          .onClick(() => {
            this.showSearchPanel = false;
          })
      }
      .width('100%')
      .padding(16)
      
      Divider().color('rgba(255,255,255,0.1)')
      
      // 结果列表
      if (this.isSearching) {
        LoadingProgress()
          .width(40)
          .height(40)
          .color('#00E5FF')
          .margin({ top: 40 })
      } else if (this.searchResults.length === 0) {
        Text('暂无结果')
          .fontSize(14)
          .fontColor('rgba(255,255,255,0.5)')
          .margin({ top: 40 })
      } else {
        List({ space: 0 }) {
          ForEach(this.searchResults, (poi: POIResult) => {
            ListItem() {
              this.POIItem(poi)
            }
          })
        }
        .width('100%')
        .layoutWeight(1)
      }
    }
    .width('100%')
    .height('50%')
    .backgroundColor('rgba(15, 23, 42, 0.98)')
    .backdropBlur(30)
    .borderRadius({ topLeft: 24, topRight: 24 })
    .position({ x: 0, y: '50%' })
  }
  
  /**
   * POI列表项
   */
  @Builder
  POIItem(poi: POIResult): void {
    Row() {
      Column() {
        Text(poi.name)
          .fontSize(16)
          .fontWeight(FontWeight.Medium)
          .fontColor(Color.White)
        Text(poi.address)
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
          .margin({ top: 4 })
        Text(`${(poi.distance / 1000).toFixed(1)}km`)
          .fontSize(12)
          .fontColor('#00E5FF')
          .margin({ top: 4 })
      }
      .alignItems(HorizontalAlign.Start)
      .layoutWeight(1)
      
      // 收藏按钮
      Button() {
        Text('⭐')
          .fontSize(18)
      }
      .height(36)
      .width(36)
      .backgroundColor('rgba(255,255,255,0.1)')
      .borderRadius(18)
      .margin({ right: 8 })
      .onClick(async () => {
        await this.addToFavorites(poi.name, poi.address, poi.location);
      })
      
      Button('导航')
        .height(36)
        .backgroundColor('#00E5FF')
        .borderRadius(18)
        .onClick(() => {
          this.selectPOI(poi);
          // 保存导航历史
          this.saveNavigationHistory(poi.location, poi.name);
        })
    }
    .width('100%')
    .padding(16)
    .borderRadius(12)
    .backgroundColor('rgba(255,255,255,0.05)')
    .margin({ left: 16, right: 16, top: 8 })
  }
  
  /**
   * 地图按钮
   */
  @Builder
  MapBtn(text: string, action: () => void): void {
    Button(text)
      .type(ButtonType.Circle)
      .width(50)
      .height(50)
      .fontSize(20)
      .fontColor(Color.White)
      .backgroundColor('rgba(30, 41, 59, 0.9)')
      .shadow({ radius: 10, color: 'rgba(0,0,0,0.3)' })
      .onClick(action)
  }
}
