/**
 * 导航服务 - 管理导航状态和逻辑
 */
import { MapService, Location, RouteInfo } from './MapService';
import { geoLocationManager } from '@kit.LocationKit';

export enum NavigationState {
  IDLE = 0,           // 空闲
  PLANNING = 1,       // 规划中
  NAVIGATING = 2,     // 导航中
  PAUSED = 3,         // 暂停
  ARRIVED = 4         // 已到达
}

export interface NavigationInfo {
  state: NavigationState;
  currentLocation: Location;
  destination: Location;
  route: RouteInfo | null;
  remainingDistance: number;  // 剩余距离（米）
  remainingTime: number;      // 剩余时间（秒）
  currentStepIndex: number;   // 当前步骤索引
  nextInstruction: string;    // 下一个指令
}

/**
 * 导航服务类
 */
export class NavigationService {
  private static instance: NavigationService;
  private mapService: MapService;
  private navigationInfo: NavigationInfo | null = null;
  private locationCallback: ((location: geoLocationManager.Location) => void) | null = null;
  private listeners: ((info: NavigationInfo) => void)[] = [];
  
  private constructor() {
    this.mapService = MapService.getInstance();
  }
  
  static getInstance(): NavigationService {
    if (!NavigationService.instance) {
      NavigationService.instance = new NavigationService();
    }
    return NavigationService.instance;
  }
  
  /**
   * 开始导航
   */
  async startNavigation(destination: Location): Promise<void> {
    try {
      // 获取当前位置
      const currentLocation = await this.mapService.getCurrentLocation();
      
      // 更新状态为规划中
      this.updateNavigationInfo({
        state: NavigationState.PLANNING,
        currentLocation,
        destination,
        route: null,
        remainingDistance: 0,
        remainingTime: 0,
        currentStepIndex: 0,
        nextInstruction: '正在规划路线...'
      });
      
      // 规划路线
      const route = await this.mapService.planRoute(currentLocation, destination);
      
      // 绘制路线
      this.mapService.drawRoute(route);
      
      // 更新状态为导航中
      this.updateNavigationInfo({
        state: NavigationState.NAVIGATING,
        currentLocation,
        destination,
        route,
        remainingDistance: route.distance,
        remainingTime: route.duration,
        currentStepIndex: 0,
        nextInstruction: route.steps[0]?.instruction || '开始导航'
      });
      
      // 开始监听位置变化
      this.startLocationTracking();
      
    } catch (err) {
      console.error('Start navigation error:', err);
      throw new Error('导航启动失败');
    }
  }
  
  /**
   * 停止导航
   */
  stopNavigation(): void {
    this.stopLocationTracking();
    this.mapService.clearOverlays();
    this.navigationInfo = null;
    this.notifyListeners();
  }
  
  /**
   * 暂停导航
   */
  pauseNavigation(): void {
    if (this.navigationInfo) {
      this.navigationInfo.state = NavigationState.PAUSED;
      this.stopLocationTracking();
      this.notifyListeners();
    }
  }
  
  /**
   * 恢复导航
   */
  resumeNavigation(): void {
    if (this.navigationInfo && this.navigationInfo.state === NavigationState.PAUSED) {
      this.navigationInfo.state = NavigationState.NAVIGATING;
      this.startLocationTracking();
      this.notifyListeners();
    }
  }
  
  /**
   * 重新规划路线
   */
  async replanRoute(): Promise<void> {
    if (!this.navigationInfo) return;
    
    try {
      const currentLocation = await this.mapService.getCurrentLocation();
      const route = await this.mapService.planRoute(currentLocation, this.navigationInfo.destination);
      
      this.mapService.clearOverlays();
      this.mapService.drawRoute(route);
      
      if (this.navigationInfo) {
        this.navigationInfo.currentLocation = currentLocation;
        this.navigationInfo.route = route;
        this.navigationInfo.remainingDistance = route.distance;
        this.navigationInfo.remainingTime = route.duration;
        this.navigationInfo.currentStepIndex = 0;
        this.navigationInfo.nextInstruction = route.steps[0]?.instruction || '';
        this.notifyListeners();
      }
    } catch (err) {
      console.error('Replan route error:', err);
    }
  }
  
  /**
   * 获取当前导航信息
   */
  getNavigationInfo(): NavigationInfo | null {
    return this.navigationInfo;
  }
  
  /**
   * 添加导航状态监听器
   */
  addListener(listener: (info: NavigationInfo) => void): void {
    this.listeners.push(listener);
  }
  
  /**
   * 移除导航状态监听器
   */
  removeListener(listener: (info: NavigationInfo) => void): void {
    const index = this.listeners.indexOf(listener);
    if (index > -1) {
      this.listeners.splice(index, 1);
    }
  }
  
  /**
   * 开始位置追踪
   */
  private startLocationTracking(): void {
    this.locationCallback = (location: geoLocationManager.Location) => {
      this.onLocationUpdate(location);
    };
    
    try {
      const request: geoLocationManager.LocationRequest = {
        priority: 0x203,
        scenario: 0x301,
        timeInterval: 1,
        distanceInterval: 0,
        maxAccuracy: 0
      };
      geoLocationManager.on('locationChange', request, this.locationCallback);
    } catch (err) {
      console.error('Start location tracking error:', err);
    }
  }
  
  /**
   * 停止位置追踪
   */
  private stopLocationTracking(): void {
    if (this.locationCallback) {
      try {
        geoLocationManager.off('locationChange', this.locationCallback);
      } catch (err) {
        console.error('Stop location tracking error:', err);
      }
      this.locationCallback = null;
    }
  }
  
  /**
   * 位置更新回调
   */
  private onLocationUpdate(location: geoLocationManager.Location): void {
    if (!this.navigationInfo || this.navigationInfo.state !== NavigationState.NAVIGATING) {
      return;
    }
    
    const currentLocation: Location = {
      latitude: location.latitude,
      longitude: location.longitude
    };
    
    // 更新当前位置
    this.navigationInfo.currentLocation = currentLocation;
    
    // 计算剩余距离（简化计算，实际应使用地图SDK）
    const distance = this.calculateDistance(
      currentLocation,
      this.navigationInfo.destination
    );
    
    this.navigationInfo.remainingDistance = distance;
    
    // 检查是否到达
    if (distance < 50) {  // 50米内认为到达
      this.navigationInfo.state = NavigationState.ARRIVED;
      this.navigationInfo.nextInstruction = '您已到达目的地';
      this.stopLocationTracking();
    }
    
    // 检查是否偏航（简化判断）
    // TODO: 实际应使用地图SDK判断偏航
    
    this.notifyListeners();
  }
  
  /**
   * 计算两点距离（简化版，使用Haversine公式）
   */
  private calculateDistance(loc1: Location, loc2: Location): number {
    const R = 6371000; // 地球半径（米）
    const lat1 = loc1.latitude * Math.PI / 180;
    const lat2 = loc2.latitude * Math.PI / 180;
    const deltaLat = (loc2.latitude - loc1.latitude) * Math.PI / 180;
    const deltaLng = (loc2.longitude - loc1.longitude) * Math.PI / 180;
    
    const a = Math.sin(deltaLat / 2) * Math.sin(deltaLat / 2) +
              Math.cos(lat1) * Math.cos(lat2) *
              Math.sin(deltaLng / 2) * Math.sin(deltaLng / 2);
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return R * c;
  }
  
  /**
   * 更新导航信息
   */
  private updateNavigationInfo(info: NavigationInfo): void {
    this.navigationInfo = info;
    this.notifyListeners();
  }
  
  /**
   * 通知所有监听器
   */
  private notifyListeners(): void {
    if (this.navigationInfo) {
      this.listeners.forEach(listener => {
        try {
          listener(this.navigationInfo!);
        } catch (err) {
          console.error('Listener error:', err);
        }
      });
    }
  }
}
