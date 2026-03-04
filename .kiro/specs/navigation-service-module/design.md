# 导航服务模块 - 设计文档

## 概述 (Overview)

### 1.1 设计目标

本设计文档旨在解决导航服务模块中的核心问题:路线绘制和标记点显示功能的实现。当前系统已成功集成高德地图Web Service API进行路径规划和POI搜索,但在HarmonyOS MapKit上的可视化呈现存在缺陷。

**核心问题**:
- `MapService.drawRoute()` 方法仅移动相机到起点,未实际绘制路线
- `MapService.addMarker()` 方法仅移动相机,未实际添加标记点
- 缺少HarmonyOS MapKit的Polyline和Marker API的具体实现

**设计目标**:
1. 实现完整的路线绘制功能,在地图上显示导航路径
2. 实现标记点添加功能,显示起点、终点和POI位置
3. 提供清晰的视觉反馈,提升用户体验
4. 确保性能优化,避免大量坐标点导致的卡顿
5. 建立可维护的架构,便于后续功能扩展

### 1.2 技术栈

**前端 (HarmonyOS)**:
- 开发语言: ArkTS
- UI框架: ArkUI
- 地图显示: HarmonyOS MapKit (Petal Maps)
- 定位服务: @kit.LocationKit
- 网络请求: @ohos.net.http

**后端**:
- 运行时: Node.js + Express
- 数据库: MySQL 8.0
- 数据源: 高德地图Web Service API

**第三方服务**:
- 高德地图Web Service API (路径规划、POI搜索、地理编码)


### 1.3 系统边界

**系统内部**:
- 地图显示和交互
- 路线绘制和标记管理
- 导航状态管理
- 位置追踪和更新
- 语音播报控制
- 用户界面交互

**系统外部**:
- 高德地图API (路径规划、POI搜索)
- GPS定位服务
- 后端数据存储服务
- 语音合成服务

## 架构 (Architecture)

### 2.1 整体架构

系统采用分层架构,从下到上分为:

```
┌─────────────────────────────────────────────┐
│         UI Layer (EnhancedNavigationModule)  │
│  - 地图显示  - 搜索面板  - 导航面板         │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│           Service Layer                      │
│  ┌──────────────┐  ┌──────────────┐        │
│  │NavigationSvc │  │VoiceGuideSvc │        │
│  └──────────────┘  └──────────────┘        │
│  ┌──────────────┐  ┌──────────────┐        │
│  │  MapService  │  │  HttpService │        │
│  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│         Data Provider Layer                  │
│  ┌──────────────┐  ┌──────────────┐        │
│  │ AmapService  │  │  ApiService  │        │
│  └──────────────┘  └──────────────┘        │
└─────────────────────────────────────────────┘
                      ↓
┌─────────────────────────────────────────────┐
│         Platform Layer                       │
│  - MapKit  - LocationKit  - HTTP            │
└─────────────────────────────────────────────┘
```


### 2.2 数据流

**路径规划流程**:
```
用户输入目的地 → NavigationService.startNavigation()
    ↓
MapService.getCurrentLocation() → 获取当前位置
    ↓
MapService.planRoute() → AmapService.planRoute()
    ↓
高德API返回路线数据 (polyline, steps, distance, duration)
    ↓
MapService.drawRoute() → 解析polyline → 绘制Polyline到地图
    ↓
MapService.addMarker() → 添加起点/终点标记
    ↓
UI更新显示导航信息
```

**位置追踪流程**:
```
LocationKit定位更新 → NavigationService.onLocationUpdate()
    ↓
计算剩余距离和时间
    ↓
判断是否偏航 → 是 → 重新规划路线
    ↓
判断是否到达 → 是 → 停止导航
    ↓
更新UI显示 + 语音播报
```

### 2.3 关键设计决策

**决策1: 使用高德Web Service API而非SDK**
- 理由: HarmonyOS平台的高德地图SDK支持有限,Web Service API更稳定
- 权衡: 需要自行实现polyline解码和地图绘制

**决策2: MapService作为地图操作的唯一入口**
- 理由: 封装MapKit的复杂性,提供统一的接口
- 优势: 便于测试、维护和未来更换地图SDK

**决策3: 单例模式管理服务实例**
- 理由: 确保全局状态一致性,避免重复初始化
- 适用: MapService, NavigationService, AmapService

**决策4: 分离数据获取和显示逻辑**
- AmapService: 负责与高德API通信
- MapService: 负责地图显示和交互
- NavigationService: 负责导航状态管理


## 组件和接口 (Components and Interfaces)

### 3.1 MapService (地图服务)

**职责**:
- 封装HarmonyOS MapKit的核心功能
- 提供地图操作的统一接口
- 管理地图覆盖物(Polyline, Marker)
- 处理polyline编码解析

**核心方法**:

```typescript
class MapService {
  // 地图控制器管理
  setMapController(controller: map.MapComponentController): void
  
  // 定位相关
  getCurrentLocation(): Promise<Location>
  moveToLocation(location: Location, zoom: number): void
  
  // 路径规划
  planRoute(start: Location, end: Location, strategy: number): Promise<RouteInfo>
  
  // 地图绘制 (核心功能)
  drawRoute(routeInfo: RouteInfo): void
  addMarker(location: Location, title: string, type: MarkerType): string
  removeMarker(markerId: string): void
  clearOverlays(): void
  
  // POI搜索
  searchPOI(keyword: string, location: Location | null, radius: number): Promise<POIResult[]>
  searchNearby(location: Location, type: string, radius: number): Promise<POIResult[]>
  
  // 地理编码
  geocode(address: string): Promise<Location | null>
  regeocode(location: Location): Promise<string>
  
  // 私有方法
  private parsePolyline(polyline: string): mapCommon.LatLng[]
  private createPolylineOptions(points: mapCommon.LatLng[]): map.MapPolyline
  private createMarkerOptions(location: Location, title: string, type: MarkerType): map.MapMarker
}
```

**关键实现 - drawRoute()**:

当前问题: 只移动相机,未绘制路线

解决方案:
```typescript
drawRoute(routeInfo: RouteInfo): void {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return;
  }
  
  try {
    // 1. 解析polyline坐标
    const points = this.parsePolyline(routeInfo.polyline);
    
    if (points.length === 0) {
      console.error('No points to draw');
      return;
    }
    
    // 2. 创建Polyline选项
    const polylineOptions: map.MapPolyline = {
      points: points,
      clickable: false,
      startCap: mapCommon.CapStyle.ROUND,
      endCap: mapCommon.CapStyle.ROUND,
      geodesic: false,
      jointType: mapCommon.JointType.ROUND,
      visible: true,
      width: 10,
      zIndex: 10,
      gradient: false,
      color: 0xFF00E5FF  // 青色
    };
    
    // 3. 添加Polyline到地图
    this.currentPolyline = this.mapController.addPolyline(polylineOptions);
    
    // 4. 添加起点和终点标记
    if (points.length > 0) {
      this.addMarker(
        { latitude: points[0].latitude, longitude: points[0].longitude },
        '起点',
        MarkerType.START
      );
      
      const lastPoint = points[points.length - 1];
      this.addMarker(
        { latitude: lastPoint.latitude, longitude: lastPoint.longitude },
        '终点',
        MarkerType.END
      );
    }
    
    // 5. 调整相机视角以显示完整路线
    this.fitBounds(points);
    
  } catch (err) {
    console.error('Draw route error:', String(err));
  }
}
```


**关键实现 - addMarker()**:

当前问题: 只移动相机,未添加标记

解决方案:
```typescript
addMarker(location: Location, title: string, type: MarkerType): string {
  if (!this.mapController) {
    console.error('MapController not initialized');
    return '';
  }
  
  try {
    // 1. 创建Marker选项
    const markerOptions: map.MapMarker = {
      position: {
        latitude: location.latitude,
        longitude: location.longitude
      },
      title: title,
      clickable: true,
      visible: true,
      anchorU: 0.5,
      anchorV: 1.0,
      zIndex: 100
    };
    
    // 2. 根据类型设置不同的图标
    switch (type) {
      case MarkerType.START:
        markerOptions.icon = this.getStartIcon();
        break;
      case MarkerType.END:
        markerOptions.icon = this.getEndIcon();
        break;
      case MarkerType.POI:
        markerOptions.icon = this.getPOIIcon();
        break;
      case MarkerType.CURRENT:
        markerOptions.icon = this.getCurrentLocationIcon();
        break;
    }
    
    // 3. 添加Marker到地图
    const marker = this.mapController.addMarker(markerOptions);
    
    // 4. 保存marker引用以便后续管理
    const markerId = this.generateMarkerId();
    this.markers.set(markerId, marker);
    
    return markerId;
    
  } catch (err) {
    console.error('Add marker error:', String(err));
    return '';
  }
}
```

**辅助方法**:

```typescript
// 解析高德polyline编码
private parsePolyline(polyline: string): mapCommon.LatLng[] {
  const points: mapCommon.LatLng[] = [];
  
  if (!polyline || polyline.length === 0) {
    return points;
  }
  
  try {
    // 高德polyline格式: 经度,纬度;经度,纬度;...
    const coords = polyline.split(';');
    
    for (const coord of coords) {
      const [lngStr, latStr] = coord.split(',');
      const lng = parseFloat(lngStr);
      const lat = parseFloat(latStr);
      
      if (!isNaN(lng) && !isNaN(lat)) {
        points.push({ latitude: lat, longitude: lng });
      }
    }
    
    // 优化: 如果点太多,进行抽稀处理
    if (points.length > 500) {
      return this.simplifyPoints(points, 500);
    }
    
  } catch (err) {
    console.error('Parse polyline error:', String(err));
  }
  
  return points;
}

// 调整相机以显示完整路线
private fitBounds(points: mapCommon.LatLng[]): void {
  if (points.length === 0) return;
  
  // 计算边界
  let minLat = points[0].latitude;
  let maxLat = points[0].latitude;
  let minLng = points[0].longitude;
  let maxLng = points[0].longitude;
  
  for (const point of points) {
    minLat = Math.min(minLat, point.latitude);
    maxLat = Math.max(maxLat, point.latitude);
    minLng = Math.min(minLng, point.longitude);
    maxLng = Math.max(maxLng, point.longitude);
  }
  
  // 计算中心点和缩放级别
  const centerLat = (minLat + maxLat) / 2;
  const centerLng = (minLng + maxLng) / 2;
  
  // 根据边界范围计算合适的缩放级别
  const latDiff = maxLat - minLat;
  const lngDiff = maxLng - minLng;
  const maxDiff = Math.max(latDiff, lngDiff);
  
  let zoom = 15;
  if (maxDiff > 0.5) zoom = 10;
  else if (maxDiff > 0.2) zoom = 12;
  else if (maxDiff > 0.1) zoom = 13;
  else if (maxDiff > 0.05) zoom = 14;
  
  // 移动相机
  const cameraUpdate = map.newCameraPosition({
    target: { latitude: centerLat, longitude: centerLng },
    zoom: zoom
  });
  
  this.mapController?.animateCamera(cameraUpdate);
}

// 点抽稀算法 (Douglas-Peucker简化版)
private simplifyPoints(points: mapCommon.LatLng[], maxPoints: number): mapCommon.LatLng[] {
  if (points.length <= maxPoints) {
    return points;
  }
  
  const step = Math.ceil(points.length / maxPoints);
  const simplified: mapCommon.LatLng[] = [];
  
  for (let i = 0; i < points.length; i += step) {
    simplified.push(points[i]);
  }
  
  // 确保最后一个点被包含
  if (simplified[simplified.length - 1] !== points[points.length - 1]) {
    simplified.push(points[points.length - 1]);
  }
  
  return simplified;
}
```


### 3.2 NavigationService (导航服务)

**职责**:
- 管理导航状态机
- 协调MapService和VoiceGuideService
- 处理位置更新和偏航检测
- 计算剩余距离和时间
- 通知UI更新

**状态机**:

```
IDLE (空闲)
  ↓ startNavigation()
PLANNING (规划中)
  ↓ 路径规划成功
NAVIGATING (导航中)
  ↓ pauseNavigation()
PAUSED (暂停)
  ↓ resumeNavigation()
NAVIGATING
  ↓ 到达目的地
ARRIVED (已到达)
  ↓ stopNavigation()
IDLE
```

**核心方法**:

```typescript
class NavigationService {
  // 导航控制
  startNavigation(destination: Location): Promise<void>
  stopNavigation(): void
  pauseNavigation(): void
  resumeNavigation(): void
  replanRoute(): Promise<void>
  
  // 状态查询
  getNavigationInfo(): NavigationInfo | null
  isNavigating(): boolean
  
  // 监听器管理
  addListener(listener: (info: NavigationInfo) => void): void
  removeListener(listener: (info: NavigationInfo) => void): void
  
  // 私有方法
  private startLocationTracking(): void
  private stopLocationTracking(): void
  private onLocationUpdate(location: geoLocationManager.Location): void
  private calculateDistance(loc1: Location, loc2: Location): number
  private checkDeviation(): boolean
  private updateNavigationStep(): void
  private notifyListeners(): void
}
```

**关键逻辑 - 偏航检测**:

```typescript
private checkDeviation(): boolean {
  if (!this.navigationInfo || !this.navigationInfo.route) {
    return false;
  }
  
  const currentLocation = this.navigationInfo.currentLocation;
  const route = this.navigationInfo.route;
  
  // 解析路线坐标点
  const routePoints = this.parsePolyline(route.polyline);
  
  // 计算当前位置到路线的最短距离
  let minDistance = Infinity;
  
  for (const point of routePoints) {
    const distance = this.calculateDistance(
      currentLocation,
      { latitude: point.latitude, longitude: point.longitude }
    );
    minDistance = Math.min(minDistance, distance);
  }
  
  // 如果距离超过100米,认为偏航
  const DEVIATION_THRESHOLD = 100;
  return minDistance > DEVIATION_THRESHOLD;
}
```


### 3.3 AmapService (高德地图API服务)

**职责**:
- 封装高德地图Web Service API调用
- 处理HTTP请求和响应
- 数据格式转换和错误处理

**API端点**:

| 功能 | 端点 | 方法 |
|------|------|------|
| 路径规划 | /v3/direction/driving | GET |
| POI搜索 | /v3/place/text | GET |
| 周边搜索 | /v3/place/around | GET |
| 地理编码 | /v3/geocode/geo | GET |
| 逆地理编码 | /v3/geocode/regeo | GET |
| 输入提示 | /v3/assistant/inputtips | GET |

**核心方法**:

```typescript
class AmapService {
  // 路径规划
  planRoute(origin: Location, destination: Location, strategy: number): Promise<RouteInfo | null>
  
  // POI搜索
  searchPOI(keyword: string, location: Location | null, radius: number): Promise<POIResult[]>
  searchNearby(location: Location, type: string, radius: number): Promise<POIResult[]>
  inputTips(keyword: string, location: Location | null): Promise<Array<Record<string, Object>>>
  
  // 地理编码
  geocode(address: string): Promise<Location | null>
  regeocode(location: Location): Promise<string>
  
  // 私有方法
  private request(url: string): Promise<Record<string, Object>>
  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number
}
```

**错误处理**:

```typescript
private async request(url: string): Promise<Record<string, Object>> {
  return new Promise<Record<string, Object>>((resolve, reject) => {
    const httpRequest = http.createHttp();
    
    httpRequest.request(url, {
      method: http.RequestMethod.GET,
      readTimeout: 30000,
      connectTimeout: 30000
    }, (err, data) => {
      if (err) {
        console.error('Amap request error:', err);
        httpRequest.destroy();
        reject(new Error(`网络请求失败: ${err.message}`));
        return;
      }
      
      try {
        const response = JSON.parse(data.result as string) as Record<string, Object>;
        const status = response['status'] as string;
        
        if (status === '1') {
          resolve(response);
        } else {
          const info = response['info'] as string;
          const infocode = response['infocode'] as string;
          reject(new Error(`API错误 [${infocode}]: ${info}`));
        }
      } catch (parseErr) {
        reject(new Error('响应解析失败'));
      } finally {
        httpRequest.destroy();
      }
    });
  });
}
```

### 3.4 VoiceGuideService (语音播报服务)

**职责**:
- 管理语音播报队列
- 控制播报时机和内容
- 处理语音合成

**核心方法**:

```typescript
class VoiceGuideService {
  // 播报控制
  speakTurnInstruction(instruction: string, distance: number): void
  speakArrival(): void
  speakDeviation(): void
  setVolume(volume: number): void
  setEnabled(enabled: boolean): void
  
  // 资源管理
  release(): void
  
  // 私有方法
  private speak(text: string): void
  private shouldSpeak(instruction: string): boolean
}
```


### 3.5 EnhancedNavigationModule (UI组件)

**职责**:
- 渲染地图和导航界面
- 处理用户交互
- 显示导航信息
- 管理搜索面板

**组件结构**:

```
EnhancedNavigationModule
├── MapComponent (地图层)
├── SearchBar (搜索栏)
├── ControlButtons (控制按钮)
│   ├── 日夜模式切换
│   ├── 放大/缩小
│   ├── 回到当前位置
│   └── 停止导航
├── NavigationPanel (导航信息面板)
│   ├── 剩余距离
│   ├── 预计时间
│   └── 下一步指令
├── LocationPanel (位置信息面板)
│   ├── 当前速度
│   ├── 地址信息
│   └── 坐标信息
└── SearchResultPanel (搜索结果面板)
    └── POIItem列表
```

**状态管理**:

```typescript
@Component
export struct EnhancedNavigationModule {
  // 地图状态
  @State isMapLoaded: boolean = false
  @State isNightMode: boolean = true
  @State hasLocationPermission: boolean = false
  @State zoomLevel: number = 15
  
  // 定位状态
  @State latitude: number = 39.9042
  @State longitude: number = 116.4074
  @State speed: number = 0
  @State userHeading: number = 0
  @State addressText: string = "等待GPS信号..."
  
  // 导航状态
  @State isNavigating: boolean = false
  @State navigationInfo: NavigationInfo | null = null
  @State remainingDistance: string = ''
  @State remainingTime: string = ''
  @State nextInstruction: string = ''
  
  // 搜索状态
  @State showSearchPanel: boolean = false
  @State searchKeyword: string = ''
  @State searchResults: POIResult[] = []
  @State isSearching: boolean = false
}
```

**关键交互流程**:

1. **搜索并导航**:
```
用户输入关键词 → 点击搜索 → searchPOI()
  ↓
显示搜索结果列表
  ↓
用户选择POI → selectPOI() → startNavigation()
  ↓
开始导航,显示导航面板
```

2. **导航过程**:
```
位置更新 → onNavigationUpdate()
  ↓
更新UI状态 (距离、时间、指令)
  ↓
语音播报 (如需要)
  ↓
检测到达 → 停止导航
```


## 数据模型 (Data Models)

### 4.1 核心数据模型

**Location (位置信息)**:
```typescript
interface Location {
  latitude: number;        // 纬度
  longitude: number;       // 经度
  address?: string;        // 地址
  name?: string;           // 名称
}
```

**RouteInfo (路线信息)**:
```typescript
interface RouteInfo {
  id?: string;
  distance: number;        // 总距离(米)
  duration: number;        // 总时间(秒)
  polyline: string;        // 路线坐标编码
  steps: RouteStep[];      // 路线步骤
  strategy?: number;       // 路线策略
  tollDistance?: number;   // 收费路段距离
  tollCost?: number;       // 预计过路费
  trafficLights?: number;  // 红绿灯数量
}
```

**RouteStep (路线步骤)**:
```typescript
interface RouteStep {
  instruction: string;     // 指令文字
  distance: number;        // 该步骤距离(米)
  duration: number;        // 该步骤时间(秒)
  road: string;            // 道路名称
  action: string;          // 动作类型
  orientation?: string;    // 方向
}
```

**POIResult (POI搜索结果)**:
```typescript
interface POIResult {
  id: string;
  name: string;
  address: string;
  location: Location;
  distance: number;        // 距离当前位置(米)
  category: string;        // 分类
  categoryCode?: string;   // 分类代码
  phone?: string;          // 电话
  rating?: number;         // 评分
  photos?: string[];       // 图片
  businessHours?: string;  // 营业时间
}
```

**NavigationInfo (导航信息)**:
```typescript
interface NavigationInfo {
  state: NavigationState;
  currentLocation: Location;
  destination: Location;
  route: RouteInfo | null;
  remainingDistance: number;  // 剩余距离(米)
  remainingTime: number;      // 剩余时间(秒)
  currentStepIndex: number;   // 当前步骤索引
  nextInstruction: string;    // 下一个指令
}
```

**NavigationState (导航状态枚举)**:
```typescript
enum NavigationState {
  IDLE = 0,           // 空闲
  PLANNING = 1,       // 规划中
  NAVIGATING = 2,     // 导航中
  PAUSED = 3,         // 暂停
  ARRIVED = 4         // 已到达
}
```

**MarkerType (标记类型枚举)**:
```typescript
enum MarkerType {
  START = 'start',       // 起点
  END = 'end',           // 终点
  POI = 'poi',           // 兴趣点
  CURRENT = 'current'    // 当前位置
}
```


### 4.2 数据库模型 (后端)

**用户表 (users)**:
```sql
CREATE TABLE users (
  id INT PRIMARY KEY AUTO_INCREMENT,
  phone VARCHAR(20) UNIQUE NOT NULL,
  nickname VARCHAR(50),
  avatar VARCHAR(255),
  password_hash VARCHAR(255),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP ON UPDATE CURRENT_TIMESTAMP
);
```

**收藏地点表 (favorite_places)**:
```sql
CREATE TABLE favorite_places (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  name VARCHAR(100) NOT NULL,
  address VARCHAR(255),
  latitude DECIMAL(10, 7) NOT NULL,
  longitude DECIMAL(10, 7) NOT NULL,
  category ENUM('home', 'work', 'custom') DEFAULT 'custom',
  icon VARCHAR(50),
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id)
);
```

**导航历史表 (navigation_history)**:
```sql
CREATE TABLE navigation_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  start_name VARCHAR(100),
  start_address VARCHAR(255),
  start_lat DECIMAL(10, 7),
  start_lng DECIMAL(10, 7),
  end_name VARCHAR(100) NOT NULL,
  end_address VARCHAR(255) NOT NULL,
  end_lat DECIMAL(10, 7) NOT NULL,
  end_lng DECIMAL(10, 7) NOT NULL,
  distance INT,
  duration INT,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);
```

**搜索历史表 (search_history)**:
```sql
CREATE TABLE search_history (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  keyword VARCHAR(100) NOT NULL,
  result_count INT DEFAULT 0,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_created_at (created_at)
);
```

**行程记录表 (trip_records)**:
```sql
CREATE TABLE trip_records (
  id INT PRIMARY KEY AUTO_INCREMENT,
  user_id INT NOT NULL,
  start_time TIMESTAMP NOT NULL,
  end_time TIMESTAMP,
  total_distance INT,
  total_duration INT,
  avg_speed DECIMAL(5, 2),
  max_speed DECIMAL(5, 2),
  trajectory JSON,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
  INDEX idx_user_id (user_id),
  INDEX idx_start_time (start_time)
);
```

### 4.3 API响应格式

**统一响应格式**:
```typescript
interface ApiResponse<T> {
  code: number;      // 状态码: 200成功, 400客户端错误, 500服务器错误
  message: string;   // 消息
  data?: T;          // 数据
}
```

**分页响应格式**:
```typescript
interface PageResponse<T> {
  list: T[];         // 数据列表
  total: number;     // 总数
  page: number;      // 当前页
  pageSize: number;  // 每页大小
}
```

**示例 - 获取收藏列表响应**:
```json
{
  "code": 200,
  "message": "success",
  "data": {
    "list": [
      {
        "id": 1,
        "name": "家",
        "address": "北京市朝阳区xxx",
        "latitude": 39.9042,
        "longitude": 116.4074,
        "category": "home",
        "createdAt": "2024-01-01T00:00:00Z"
      }
    ],
    "total": 1,
    "page": 1,
    "pageSize": 20
  }
}
```


## 正确性属性 (Correctness Properties)

*属性是一个特征或行为,应该在系统的所有有效执行中保持为真——本质上是关于系统应该做什么的形式化陈述。属性作为人类可读规范和机器可验证正确性保证之间的桥梁。*

### Property Reflection (属性反思)

在从验收标准生成属性之前,我进行了冗余分析:

**识别的冗余**:
1. "显示预计距离和时间" 和 "显示路线详细信息" 可以合并为一个综合属性,验证RouteInfo的所有字段都被正确提取
2. "距离计算对称性" 和 "距离非负性" 是独立的数学属性,保留两者
3. "支持关键词搜索" 和 "支持周边搜索" 是不同的搜索模式,保留两者
4. "收藏数据云端同步" 本质上是一个往返属性,可以简化表述

**保留的属性**: 经过反思,以下属性提供独特的验证价值,无冗余。


### 核心属性

### Property 1: 路线绘制完整性

*对于任意*有效的RouteInfo对象,调用drawRoute()后,地图上应该存在一个Polyline对象,其坐标点数量大于0,并且起点和终点标记应该被添加到地图上。

**Validates: Requirements FR-2.2.2.1**

### Property 2: Polyline解析正确性

*对于任意*高德地图返回的polyline编码字符串,parsePolyline()解析后得到的坐标点列表,每个点的经纬度都应该在有效范围内(纬度-90到90,经度-180到180),并且点的数量应该大于0。

**Validates: Requirements FR-2.2.2.1 (核心实现)**

### Property 3: 标记添加和移除往返

*对于任意*有效的Location和标记类型,调用addMarker()返回的markerId,使用该ID调用removeMarker()后,该标记应该不再存在于地图上。

**Validates: Requirements FR-2.4.2.3 (核心实现)**

### Property 4: 距离计算对称性

*对于任意*两个有效的Location对象A和B,calculateDistance(A, B)的结果应该等于calculateDistance(B, A)的结果(允许浮点误差在0.1米内)。

**Validates: Requirements FR-2.3.1.2, FR-2.4.2.1 (核心实现)**

### Property 5: 距离计算非负性

*对于任意*两个有效的Location对象,calculateDistance()的返回值应该总是大于或等于0。

**Validates: Requirements FR-2.3.1.2, FR-2.4.2.1 (核心实现)**

### Property 6: 路径规划成功性

*对于任意*有效的起点和终点Location,调用planRoute()应该返回一个RouteInfo对象,其distance大于0,duration大于0,并且polyline字符串非空。

**Validates: Requirements FR-2.2.1.1**

### Property 7: 偏航检测正确性

*对于任意*导航状态,如果当前位置距离路线上所有点的最小距离超过100米,checkDeviation()应该返回true;如果最小距离小于等于100米,应该返回false。

**Validates: Requirements FR-2.3.3.1**

### Property 8: 到达检测正确性

*对于任意*导航状态,如果剩余距离小于50米,导航状态应该转换为ARRIVED;如果剩余距离大于等于50米,状态应该保持为NAVIGATING。

**Validates: Requirements FR-2.3.4.1**

### Property 9: POI搜索结果距离排序

*对于任意*POI搜索结果列表,如果按距离排序,结果列表中的每个元素的distance字段应该小于或等于下一个元素的distance字段。

**Validates: Requirements FR-2.4.2.2**

### Property 10: 收藏数据持久化

*对于任意*有效的FavoritePlace对象,调用保存接口后,使用相同的userId查询收藏列表,应该能找到该收藏记录,并且其name、address、latitude、longitude字段与原始对象相同。

**Validates: Requirements FR-2.5.1.1**

### Property 11: 收藏删除正确性

*对于任意*已存在的收藏记录ID,调用删除接口后,使用该ID查询应该返回null或不存在,并且该记录不应该出现在收藏列表中。

**Validates: Requirements FR-2.5.1.2**

### Property 12: 导航历史自动记录

*对于任意*完成的导航(状态从NAVIGATING转换到ARRIVED),系统应该自动在数据库中创建一条NavigationHistory记录,包含起点、终点、距离和时间信息。

**Validates: Requirements FR-2.5.2.1**

### Property 13: 位置更新字段完整性

*对于任意*从LocationKit接收到的位置更新,系统应该正确提取并更新latitude、longitude、speed和heading字段,并且这些字段的值应该在有效范围内。

**Validates: Requirements FR-2.1.1.4**

### Property 14: 路线信息字段完整性

*对于任意*从高德API返回的RouteInfo,UI显示时应该包含distance、duration、tollDistance、tollCost和trafficLights所有字段的信息。

**Validates: Requirements FR-2.2.2.2, FR-2.2.2.3**

### Property 15: 途经点数量限制

*对于任意*路径规划请求,如果途经点数量小于等于3,请求应该被接受;如果途经点数量大于3,请求应该被拒绝并返回错误信息。

**Validates: Requirements FR-2.2.1.2**

### Property 16: 密码加密存储

*对于任意*用户注册或修改密码操作,存储到数据库的password_hash字段应该不等于原始密码明文,并且长度应该大于原始密码长度(表明经过哈希处理)。

**Validates: Requirements 3.4.1**

### Property 17: 数据同步往返一致性

*对于任意*在本地创建的收藏记录,上传到云端后再下载,下载的记录应该与本地记录的关键字段(name、address、latitude、longitude)完全一致。

**Validates: Requirements FR-2.6.3.1**


## 错误处理 (Error Handling)

### 5.1 错误分类

**网络错误**:
- API请求超时
- 网络连接失败
- API返回错误状态码

**定位错误**:
- 权限被拒绝
- GPS信号弱或无信号
- 定位服务未开启

**数据错误**:
- 无效的坐标数据
- 空的polyline字符串
- 解析失败

**业务错误**:
- 路径规划失败(起终点太近或无法到达)
- 搜索无结果
- 数据库操作失败

### 5.2 错误处理策略

**MapService错误处理**:

```typescript
drawRoute(routeInfo: RouteInfo): void {
  if (!this.mapController) {
    console.error('[MapService] MapController not initialized');
    throw new Error('地图未初始化');
  }
  
  if (!routeInfo || !routeInfo.polyline) {
    console.error('[MapService] Invalid route info');
    throw new Error('路线数据无效');
  }
  
  try {
    const points = this.parsePolyline(routeInfo.polyline);
    
    if (points.length === 0) {
      console.error('[MapService] No points parsed from polyline');
      throw new Error('路线坐标解析失败');
    }
    
    // 绘制逻辑...
    
  } catch (err) {
    console.error('[MapService] Draw route error:', String(err));
    // 清理可能的部分绘制
    this.clearOverlays();
    throw err;
  }
}
```

**AmapService错误处理**:

```typescript
async planRoute(origin: Location, destination: Location, strategy: number): Promise<RouteInfo | null> {
  // 参数验证
  if (!this.isValidLocation(origin) || !this.isValidLocation(destination)) {
    console.error('[AmapService] Invalid location parameters');
    return null;
  }
  
  try {
    const url = this.buildRouteUrl(origin, destination, strategy);
    const response = await this.request(url);
    
    // 解析响应...
    
    return routeInfo;
    
  } catch (err) {
    console.error('[AmapService] Plan route error:', JSON.stringify(err));
    
    // 根据错误类型返回友好提示
    if (err.message.includes('网络')) {
      throw new Error('网络连接失败,请检查网络设置');
    } else if (err.message.includes('API错误')) {
      throw new Error('路径规划服务暂时不可用');
    } else {
      throw new Error('路径规划失败,请稍后重试');
    }
  }
}

private isValidLocation(loc: Location): boolean {
  return loc &&
         typeof loc.latitude === 'number' &&
         typeof loc.longitude === 'number' &&
         loc.latitude >= -90 && loc.latitude <= 90 &&
         loc.longitude >= -180 && loc.longitude <= 180;
}
```

**NavigationService错误处理**:

```typescript
async startNavigation(destination: Location): Promise<void> {
  try {
    // 更新状态为规划中
    this.updateNavigationInfo({
      state: NavigationState.PLANNING,
      // ...
    });
    
    const currentLocation = await this.mapService.getCurrentLocation();
    const route = await this.mapService.planRoute(currentLocation, destination, 0);
    
    if (!route) {
      throw new Error('无法规划到达该地点的路线');
    }
    
    this.mapService.drawRoute(route);
    
    // 更新状态为导航中
    this.updateNavigationInfo({
      state: NavigationState.NAVIGATING,
      // ...
    });
    
    this.startLocationTracking();
    
  } catch (err) {
    console.error('[NavigationService] Start navigation error:', err);
    
    // 恢复到空闲状态
    this.navigationInfo = null;
    this.notifyListeners();
    
    // 向上层抛出友好的错误信息
    throw new Error('导航启动失败: ' + (err.message || '未知错误'));
  }
}
```

### 5.3 用户提示

**错误提示映射**:

| 错误类型 | 用户提示 |
|---------|---------|
| 定位权限被拒绝 | "需要定位权限才能使用导航功能,请在设置中开启" |
| GPS信号弱 | "GPS信号较弱,定位可能不准确" |
| 网络连接失败 | "网络连接失败,请检查网络设置" |
| 路径规划失败 | "无法规划路线,请检查起终点是否正确" |
| 搜索无结果 | "未找到相关地点,请尝试其他关键词" |
| 地图加载失败 | "地图加载失败,请稍后重试" |

### 5.4 日志记录

**日志级别**:
- ERROR: 系统错误,需要立即关注
- WARN: 警告信息,可能影响功能
- INFO: 一般信息,记录关键操作
- DEBUG: 调试信息,开发时使用

**日志格式**:
```
[时间] [级别] [模块] 消息内容
[2024-01-01 12:00:00] [ERROR] [MapService] Draw route error: Invalid polyline
```

**关键操作日志**:
- 导航开始/结束
- 路径规划请求/响应
- 偏航检测和重新规划
- API调用失败
- 数据库操作失败


## 测试策略 (Testing Strategy)

### 6.1 测试方法

本项目采用**双重测试方法**:

1. **单元测试**: 验证特定示例、边界情况和错误条件
2. **属性测试**: 通过随机输入验证通用属性

两者互补,共同确保全面覆盖:
- 单元测试捕获具体的bug和边界情况
- 属性测试验证通用正确性和处理大量输入

### 6.2 属性测试配置

**测试框架选择**:
- 语言: ArkTS/TypeScript
- 框架: 使用 fast-check (JavaScript/TypeScript的属性测试库)
- 最小迭代次数: 100次/属性

**安装**:
```bash
npm install --save-dev fast-check @types/fast-check
```

**属性测试标签格式**:
```typescript
// Feature: navigation-service-module, Property 1: 路线绘制完整性
```

### 6.3 测试用例设计

#### 6.3.1 MapService测试

**单元测试**:

```typescript
import { describe, it, expect, beforeEach } from '@ohos/hypium';
import { MapService } from '../services/MapService';

describe('MapService', () => {
  let mapService: MapService;
  
  beforeEach(() => {
    mapService = MapService.getInstance();
  });
  
  // 示例测试: 已知坐标的距离计算
  it('should calculate distance between Beijing and Shanghai correctly', () => {
    const beijing = { latitude: 39.9042, longitude: 116.4074 };
    const shanghai = { latitude: 31.2304, longitude: 121.4737 };
    
    const distance = mapService['calculateDistance'](beijing, shanghai);
    
    // 北京到上海约1067公里
    expect(distance).toBeGreaterThan(1000000);
    expect(distance).toBeLessThan(1200000);
  });
  
  // 边界测试: 空polyline
  it('should handle empty polyline gracefully', () => {
    const points = mapService['parsePolyline']('');
    expect(points.length).toBe(0);
  });
  
  // 边界测试: 无效polyline格式
  it('should handle invalid polyline format', () => {
    const points = mapService['parsePolyline']('invalid;format;data');
    expect(points.length).toBe(0);
  });
});
```

**属性测试**:

```typescript
import * as fc from 'fast-check';

describe('MapService Properties', () => {
  // Feature: navigation-service-module, Property 4: 距离计算对称性
  it('distance calculation should be symmetric', () => {
    fc.assert(
      fc.property(
        fc.record({
          latitude: fc.double({ min: -90, max: 90 }),
          longitude: fc.double({ min: -180, max: 180 })
        }),
        fc.record({
          latitude: fc.double({ min: -90, max: 90 }),
          longitude: fc.double({ min: -180, max: 180 })
        }),
        (loc1, loc2) => {
          const mapService = MapService.getInstance();
          const dist1 = mapService['calculateDistance'](loc1, loc2);
          const dist2 = mapService['calculateDistance'](loc2, loc1);
          
          // 允许0.1米的浮点误差
          return Math.abs(dist1 - dist2) < 0.1;
        }
      ),
      { numRuns: 100 }
    );
  });
  
  // Feature: navigation-service-module, Property 5: 距离计算非负性
  it('distance calculation should always be non-negative', () => {
    fc.assert(
      fc.property(
        fc.record({
          latitude: fc.double({ min: -90, max: 90 }),
          longitude: fc.double({ min: -180, max: 180 })
        }),
        fc.record({
          latitude: fc.double({ min: -90, max: 90 }),
          longitude: fc.double({ min: -180, max: 180 })
        }),
        (loc1, loc2) => {
          const mapService = MapService.getInstance();
          const distance = mapService['calculateDistance'](loc1, loc2);
          return distance >= 0;
        }
      ),
      { numRuns: 100 }
    );
  });
  
  // Feature: navigation-service-module, Property 2: Polyline解析正确性
  it('parsed polyline points should have valid coordinates', () => {
    fc.assert(
      fc.property(
        fc.array(
          fc.tuple(
            fc.double({ min: -180, max: 180 }),
            fc.double({ min: -90, max: 90 })
          ),
          { minLength: 1, maxLength: 100 }
        ),
        (coords) => {
          // 构造polyline字符串
          const polyline = coords.map(([lng, lat]) => `${lng},${lat}`).join(';');
          
          const mapService = MapService.getInstance();
          const points = mapService['parsePolyline'](polyline);
          
          // 验证所有点的坐标都在有效范围内
          return points.length > 0 &&
                 points.every(p => 
                   p.latitude >= -90 && p.latitude <= 90 &&
                   p.longitude >= -180 && p.longitude <= 180
                 );
        }
      ),
      { numRuns: 100 }
    );
  });
});
```


#### 6.3.2 NavigationService测试

**单元测试**:

```typescript
describe('NavigationService', () => {
  let navigationService: NavigationService;
  
  beforeEach(() => {
    navigationService = NavigationService.getInstance();
  });
  
  // 示例测试: 导航状态转换
  it('should transition to NAVIGATING state after successful route planning', async () => {
    const destination = { latitude: 39.9, longitude: 116.4 };
    
    await navigationService.startNavigation(destination);
    
    const info = navigationService.getNavigationInfo();
    expect(info?.state).toBe(NavigationState.NAVIGATING);
  });
  
  // 边界测试: 停止未开始的导航
  it('should handle stopping navigation when not navigating', () => {
    expect(() => {
      navigationService.stopNavigation();
    }).not.toThrow();
  });
});
```

**属性测试**:

```typescript
describe('NavigationService Properties', () => {
  // Feature: navigation-service-module, Property 8: 到达检测正确性
  it('should detect arrival when remaining distance is less than threshold', () => {
    fc.assert(
      fc.property(
        fc.record({
          latitude: fc.double({ min: -90, max: 90 }),
          longitude: fc.double({ min: -180, max: 180 })
        }),
        fc.integer({ min: 0, max: 200 }),
        (destination, distanceOffset) => {
          const navigationService = NavigationService.getInstance();
          
          // 模拟导航信息
          const mockInfo: NavigationInfo = {
            state: NavigationState.NAVIGATING,
            currentLocation: destination,
            destination: destination,
            route: null,
            remainingDistance: distanceOffset,
            remainingTime: 0,
            currentStepIndex: 0,
            nextInstruction: ''
          };
          
          // 如果距离<50米,应该检测到到达
          const shouldArrive = distanceOffset < 50;
          
          // 这里需要实际调用检测逻辑
          // 简化示例,实际需要mock或重构代码以便测试
          return true;
        }
      ),
      { numRuns: 100 }
    );
  });
});
```

#### 6.3.3 AmapService测试

**单元测试**:

```typescript
describe('AmapService', () => {
  let amapService: AmapService;
  
  beforeEach(() => {
    amapService = AmapService.getInstance();
  });
  
  // 集成测试: 实际API调用(需要网络)
  it('should plan route between two locations', async () => {
    const origin = { latitude: 39.9042, longitude: 116.4074 };
    const destination = { latitude: 31.2304, longitude: 121.4737 };
    
    const route = await amapService.planRoute(origin, destination, 0);
    
    expect(route).not.toBeNull();
    expect(route?.distance).toBeGreaterThan(0);
    expect(route?.duration).toBeGreaterThan(0);
    expect(route?.polyline).not.toBe('');
  }, 10000); // 10秒超时
  
  // 错误测试: 无效坐标
  it('should handle invalid coordinates gracefully', async () => {
    const invalid = { latitude: 999, longitude: 999 };
    const valid = { latitude: 39.9, longitude: 116.4 };
    
    const route = await amapService.planRoute(invalid, valid, 0);
    expect(route).toBeNull();
  });
});
```

**属性测试**:

```typescript
describe('AmapService Properties', () => {
  // Feature: navigation-service-module, Property 6: 路径规划成功性
  it('route planning should return valid route info for valid locations', () => {
    fc.assert(
      fc.asyncProperty(
        fc.record({
          latitude: fc.double({ min: 20, max: 50 }),
          longitude: fc.double({ min: 100, max: 130 })
        }),
        fc.record({
          latitude: fc.double({ min: 20, max: 50 }),
          longitude: fc.double({ min: 100, max: 130 })
        }),
        async (origin, destination) => {
          // 确保起终点不同
          if (Math.abs(origin.latitude - destination.latitude) < 0.01 &&
              Math.abs(origin.longitude - destination.longitude) < 0.01) {
            return true; // 跳过太近的点
          }
          
          const amapService = AmapService.getInstance();
          const route = await amapService.planRoute(origin, destination, 0);
          
          if (route === null) {
            return true; // API可能失败,不算测试失败
          }
          
          return route.distance > 0 &&
                 route.duration > 0 &&
                 route.polyline.length > 0;
        }
      ),
      { numRuns: 20 } // 减少API调用次数
    );
  });
});
```

### 6.4 测试覆盖率目标

- 代码覆盖率: > 80%
- 分支覆盖率: > 75%
- 核心服务(MapService, NavigationService, AmapService): > 90%

### 6.5 测试执行

**本地测试**:
```bash
# 运行所有测试
npm test

# 运行特定测试文件
npm test -- MapService.test.ts

# 生成覆盖率报告
npm test -- --coverage
```

**CI/CD集成**:
- 每次提交自动运行测试
- PR合并前必须通过所有测试
- 覆盖率不得低于设定目标

### 6.6 Mock和测试工具

**需要Mock的依赖**:
- MapKit API (地图控制器、Polyline、Marker)
- LocationKit API (定位服务)
- HTTP请求 (高德API调用)
- 数据库操作

**Mock示例**:

```typescript
// Mock MapComponentController
class MockMapController {
  private polylines: any[] = [];
  private markers: any[] = [];
  
  addPolyline(options: any): any {
    const polyline = { id: Date.now(), options };
    this.polylines.push(polyline);
    return polyline;
  }
  
  addMarker(options: any): any {
    const marker = { id: Date.now(), options };
    this.markers.push(marker);
    return marker;
  }
  
  removePolyline(polyline: any): void {
    const index = this.polylines.indexOf(polyline);
    if (index > -1) {
      this.polylines.splice(index, 1);
    }
  }
  
  getPolylines(): any[] {
    return this.polylines;
  }
  
  getMarkers(): any[] {
    return this.markers;
  }
}
```

### 6.7 性能测试

虽然单元测试不适合测试性能,但我们需要单独的性能测试:

**性能测试场景**:
1. 大量坐标点的polyline解析(1000+点)
2. 频繁的位置更新处理(1秒/次,持续10分钟)
3. 多个标记的添加和移除(100+标记)
4. 内存泄漏检测(长时间导航)

**性能基准**:
- Polyline解析(500点): < 100ms
- 位置更新处理: < 50ms
- 标记添加: < 20ms
- 内存增长: < 10MB/小时


## 实现路线图 (Implementation Roadmap)

### 7.1 优先级划分

**P0 - 核心功能(必须实现)**:
1. 修复MapService.drawRoute() - 实现Polyline绘制
2. 修复MapService.addMarker() - 实现Marker添加
3. 完善parsePolyline() - 正确解析高德polyline编码
4. 实现fitBounds() - 自动调整地图视角
5. 实现clearOverlays() - 清除地图覆盖物

**P1 - 重要功能(应该实现)**:
1. 偏航检测和重新规划
2. 语音播报功能
3. POI搜索和标记
4. 导航历史记录
5. 错误处理和用户提示

**P2 - 增强功能(可以实现)**:
1. 多路线对比
2. 途经点支持
3. 行程记录和回放
4. 离线地图缓存
5. 数据云端同步

### 7.2 实施步骤

**阶段1: 修复核心绘制功能(1-2天)**

1. 研究HarmonyOS MapKit的Polyline和Marker API文档
2. 实现MapService.drawRoute()的完整逻辑
3. 实现MapService.addMarker()的完整逻辑
4. 实现覆盖物管理(添加、移除、清除)
5. 编写单元测试验证功能

**关键代码修改**:

```typescript
// MapService.ets
export class MapService {
  private currentPolyline: any = null;
  private markers: Map<string, any> = new Map();
  
  drawRoute(routeInfo: RouteInfo): void {
    // 清除旧路线
    this.clearOverlays();
    
    // 解析坐标
    const points = this.parsePolyline(routeInfo.polyline);
    
    // 创建并添加Polyline
    const polylineOptions: map.MapPolyline = {
      points: points,
      width: 10,
      color: 0xFF00E5FF,
      // ... 其他选项
    };
    this.currentPolyline = this.mapController!.addPolyline(polylineOptions);
    
    // 添加起终点标记
    this.addMarker(
      { latitude: points[0].latitude, longitude: points[0].longitude },
      '起点',
      MarkerType.START
    );
    this.addMarker(
      { latitude: points[points.length-1].latitude, longitude: points[points.length-1].longitude },
      '终点',
      MarkerType.END
    );
    
    // 调整视角
    this.fitBounds(points);
  }
  
  addMarker(location: Location, title: string, type: MarkerType): string {
    const markerOptions: map.MapMarker = {
      position: { latitude: location.latitude, longitude: location.longitude },
      title: title,
      icon: this.getMarkerIcon(type),
      // ... 其他选项
    };
    
    const marker = this.mapController!.addMarker(markerOptions);
    const markerId = this.generateMarkerId();
    this.markers.set(markerId, marker);
    
    return markerId;
  }
  
  clearOverlays(): void {
    // 清除Polyline
    if (this.currentPolyline) {
      this.mapController!.removePolyline(this.currentPolyline);
      this.currentPolyline = null;
    }
    
    // 清除所有Marker
    for (const marker of this.markers.values()) {
      this.mapController!.removeMarker(marker);
    }
    this.markers.clear();
  }
}
```

**阶段2: 完善导航逻辑(2-3天)**

1. 实现偏航检测算法
2. 实现自动重新规划
3. 完善导航状态管理
4. 优化位置更新处理
5. 添加属性测试

**阶段3: 用户体验优化(2-3天)**

1. 实现语音播报
2. 优化UI交互
3. 添加错误提示
4. 性能优化(点抽稀、内存管理)
5. 完善日志记录

**阶段4: 数据持久化(2-3天)**

1. 实现收藏功能
2. 实现历史记录
3. 实现行程记录
4. 后端API开发
5. 数据同步功能

### 7.3 技术难点和解决方案

**难点1: HarmonyOS MapKit API文档不完善**

解决方案:
- 参考官方示例代码
- 查看API类型定义文件
- 通过实验验证API行为
- 建立内部文档记录

**难点2: 高德polyline编码格式**

解决方案:
- 高德使用简单的"经度,纬度;经度,纬度"格式
- 已实现parsePolyline()方法
- 需要处理大量坐标点的性能优化

**难点3: 偏航检测算法**

解决方案:
- 使用点到线段的最短距离算法
- 设置合理的偏航阈值(100米)
- 避免频繁重新规划(设置冷却时间)

**难点4: 内存管理**

解决方案:
- 及时清除不用的覆盖物
- 对大量坐标点进行抽稀
- 使用WeakMap管理引用
- 定期检查内存使用

### 7.4 验收标准

**功能验收**:
- [ ] 路线能在地图上正确显示
- [ ] 起终点标记正确显示
- [ ] 导航过程中位置实时更新
- [ ] 偏航时自动重新规划
- [ ] 到达目的地时正确提示
- [ ] POI搜索和标记功能正常
- [ ] 收藏和历史记录功能正常

**质量验收**:
- [ ] 所有单元测试通过
- [ ] 所有属性测试通过
- [ ] 代码覆盖率 > 80%
- [ ] 无严重bug
- [ ] 性能符合要求

**用户体验验收**:
- [ ] 界面响应流畅
- [ ] 错误提示清晰
- [ ] 操作逻辑直观
- [ ] 语音播报准确及时

## 附录 (Appendix)

### A. 参考资料

1. **HarmonyOS开发文档**
   - MapKit API参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/
   - LocationKit API参考: https://developer.huawei.com/consumer/cn/doc/harmonyos-references-V5/

2. **高德地图API文档**
   - Web服务API: https://lbs.amap.com/api/webservice/summary
   - 路径规划: https://lbs.amap.com/api/webservice/guide/api/direction
   - POI搜索: https://lbs.amap.com/api/webservice/guide/api/search

3. **属性测试资源**
   - fast-check文档: https://github.com/dubzzz/fast-check
   - 属性测试模式: https://fsharpforfunandprofit.com/posts/property-based-testing/

### B. 术语表

| 术语 | 说明 |
|------|------|
| Polyline | 折线,用于在地图上绘制路线 |
| Marker | 标记点,用于在地图上标注位置 |
| POI | Point of Interest,兴趣点 |
| Haversine | 计算球面两点距离的公式 |
| 偏航 | 车辆偏离规划路线 |
| 抽稀 | 减少坐标点数量以提升性能 |

### C. 变更历史

| 版本 | 日期 | 作者 | 变更说明 |
|------|------|------|----------|
| 1.0 | 2024-01-01 | Kiro | 初始版本 |

---

**文档状态**: 待审核
**下一步**: 用户审核设计文档,提供反馈

