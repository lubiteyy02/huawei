/**
 * 增强版导航模块
 * 集成完整的导航功能：定位、路径规划、导航指引、POI搜索
 */
import { map, mapCommon, MapComponent } from '@kit.MapKit';
import { geoLocationManager } from '@kit.LocationKit';
import { abilityAccessCtrl, common } from '@kit.AbilityKit';
import { MapService, Location, POIResult } from '../services/MapService';
import { NavigationService, NavigationState, NavigationInfo } from '../services/NavigationService';
import { VoiceGuideService } from '../services/VoiceGuideService';

@Component
export struct EnhancedNavigationModule {
  // 地图相关
  @State isMapLoaded: boolean = false;
  @State isNightMode: boolean = true;
  @State hasLocationPermission: boolean = false;
  @State zoomLevel: number = 15;
  private mapController: map.MapComponentController | null = null;
  
  // 定位相关
  @State latitude: number = 39.9042;
  @State longitude: number = 116.4074;
  @State speed: number = 0;
  @State userHeading: number = 0;
  @State addressText: string = "等待GPS信号...";
  
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
  
  // 服务实例
  private mapService: MapService = MapService.getInstance();
  private navigationService: NavigationService = NavigationService.getInstance();
  private voiceService: VoiceGuideService = VoiceGuideService.getInstance();
  private locationCallback: (location: geoLocationManager.Location) => void = (location) => { 
    this.updateLocationState(location); 
  };
  
  aboutToAppear() {
    this.reqPermissionsFromUser();
    // 监听导航状态变化
    this.navigationService.addListener((info) => {
      this.onNavigationUpdate(info);
    });
  }
  
  aboutToDisappear() {
    try {
      geoLocationManager.off('locationChange', this.locationCallback);
    } catch (err) {}
    this.voiceService.release();
  }
  
  /**
   * 请求定位权限
   */
  async reqPermissionsFromUser() {
    let atManager = abilityAccessCtrl.createAtManager();
    try {
      const context = this.getUIContext().getHostContext() as common.UIAbilityContext;
      const data = await atManager.requestPermissionsFromUser(context, [
        'ohos.permission.LOCATION',
        'ohos.permission.APPROXIMATELY_LOCATION'
      ]);
      if (data.authResults[0] === 0) {
        this.hasLocationPermission = true;
        if (this.mapController) this.startRealLocation();
      }
    } catch (err) {
      console.error('Permission error:', err);
    }
  }
  
  /**
   * 开始实时定位
   */
  async startRealLocation() {
    if (!this.mapController || !this.hasLocationPermission) return;
    try {
      this.mapController.setMyLocationEnabled(true);
      this.mapController.setZoomControlsEnabled(true);
      this.mapController.setMyLocationControlsEnabled(true);
      
      let req: geoLocationManager.LocationRequest = {
        priority: 0x203,
        scenario: 0x301,
        timeInterval: 1,
        distanceInterval: 0,
        maxAccuracy: 0
      };
      geoLocationManager.on('locationChange', req, this.locationCallback);
      this.addressText = "定位中...";
    } catch (err) {
      console.error('Location error:', err);
    }
  }
  
  /**
   * 更新位置状态
   */
  updateLocationState(location: geoLocationManager.Location) {
    this.latitude = location.latitude;
    this.longitude = location.longitude;
    this.speed = location.speed;
    this.userHeading = location.direction;
    
    if (!this.isNavigating) {
      this.addressText = "实时定位";
    }
  }
  
  /**
   * 地图加载完成
   */
  onMapLoad(controller: map.MapComponentController) {
    this.mapController = controller;
    this.isMapLoaded = true;
    this.mapService.setMapController(controller);
    
    try {
      this.mapController.setPadding({ top: 0, left: 0, right: 0, bottom: 200 });
    } catch(e) {}
    
    if (this.hasLocationPermission) this.startRealLocation();
    this.updateMapStyle();
  }
  
  /**
   * 更新地图样式
   */
  updateMapStyle() {
    if (!this.mapController) return;
    try {
      this.mapController.setDayNightMode(
        this.isNightMode ? mapCommon.DayNightMode.NIGHT : mapCommon.DayNightMode.DAY
      );
    } catch (e) {}
  }
  
  /**
   * 缩放地图
   */
  changeZoom(delta: number): void {
    if (!this.mapController) return;
    this.zoomLevel = Math.max(3, Math.min(20, this.zoomLevel + delta));
    try {
      let cameraUpdate = map.newCameraPosition({
        target: { latitude: this.latitude, longitude: this.longitude },
        zoom: this.zoomLevel,
        tilt: 45,
        bearing: this.userHeading
      });
      this.mapController.animateCamera(cameraUpdate);
    } catch(e) {}
  }
  
  /**
   * 回到当前位置
   */
  backToCurrentLocation(): void {
    if(this.hasLocationPermission && this.mapController) {
      this.mapService.moveToLocation({
        latitude: this.latitude,
        longitude: this.longitude
      }, this.zoomLevel);
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
      const results = await this.mapService.searchPOI(
        this.searchKeyword,
        { latitude: this.latitude, longitude: this.longitude }
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
  
  build() {
    Stack({ alignContent: Alignment.Bottom }) {
      // 1. 地图层
      Stack() {
        MapComponent({
          mapOptions: {
            position: { target: { latitude: 39.9, longitude: 116.4 }, zoom: 15 },
            mapType: mapCommon.MapType.STANDARD
          },
          mapCallback: (err, controller) => {
            if (!err && controller) this.onMapLoad(controller);
          }
        })
        .width('100%').height('100%')
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
    Row() {
      TextInput({ placeholder: '搜索地点、地址', text: this.searchKeyword })
        .layoutWeight(1)
        .height(48)
        .backgroundColor(Color.White)
        .borderRadius(24)
        .padding({ left: 20, right: 20 })
        .onChange((value: string): void => {
          this.searchKeyword = value;
        })
        .onSubmit((): void => {
          this.showSearchPanel = true;
          this.searchPOI();
        })
      
      Button('搜索')
        .height(48)
        .backgroundColor('#00E5FF')
        .borderRadius(24)
        .margin({ left: 10 })
        .onClick((): void => {
          this.showSearchPanel = true;
          this.searchPOI();
        })
    }
    .width('90%')
    .padding(16)
    .position({ x: '5%', y: 60 })
  }
  
  /**
   * 控制按钮
   */
  @Builder
  ControlButtons(): void {
    Column({ space: 15 }) {
      this.MapBtn(this.isNightMode ? "☀️" : "🌙", (): void => {
        this.isNightMode = !this.isNightMode;
        this.updateMapStyle();
      })
      this.MapBtn("＋", (): void => this.changeZoom(1))
      this.MapBtn("－", (): void => this.changeZoom(-1))
      this.MapBtn("◎", (): void => this.backToCurrentLocation())
      
      if (this.isNavigating) {
        this.MapBtn("■", (): void => this.stopNavigation())
      }
    }
    .alignItems(HorizontalAlign.End)
    .position({ x: '100%', y: '40%' })
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
        Text(`${(this.speed * 3.6).toFixed(0)}`)
          .fontSize(32)
          .fontWeight(FontWeight.Bold)
          .fontColor('#00E5FF')
        Text("km/h")
          .fontSize(12)
          .fontColor('rgba(255,255,255,0.6)')
      }
      .margin({ right: 20 })
      
      Divider().vertical(true).height(30).color('rgba(255,255,255,0.2)')
      
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
      .margin({ left: 20 })
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
      
      Button('导航')
        .height(36)
        .backgroundColor('#00E5FF')
        .borderRadius(18)
        .onClick(() => {
          this.selectPOI(poi);
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
