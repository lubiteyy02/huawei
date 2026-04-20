/**
 * 导航服务 - 管理导航状态和逻辑
 * 使用默认起点坐标作为导航起点
 */
import { MapService, Location, RouteInfo } from './MapService';

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
      // 直接使用默认起点坐标，不再依赖定位优先级逻辑
      const currentLocation: Location = {
        latitude: 30.486874173982763,
        longitude: 114.309994670642
      };
      
      console.log('[NavigationService] 默认起点:', currentLocation.latitude, currentLocation.longitude);
      console.log('[NavigationService] 终点:', destination.latitude, destination.longitude);
      
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
      const route = await this.mapService.planRoute(currentLocation, destination, 0);
      
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
      
      console.log('[NavigationService] 导航已启动（默认起点，无实时追踪）');
      
    } catch (err) {
      console.error('Start navigation error:', err);
      throw new Error('导航启动失败: ' + String(err));
    }
  }
  
  /**
   * 停止导航
   */
  stopNavigation(): void {
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
      this.notifyListeners();
    }
  }
  
  /**
   * 恢复导航
   */
  resumeNavigation(): void {
    if (this.navigationInfo && this.navigationInfo.state === NavigationState.PAUSED) {
      this.navigationInfo.state = NavigationState.NAVIGATING;
      this.notifyListeners();
    }
  }
  
  /**
   * 重新规划路线
   */
  async replanRoute(): Promise<void> {
    if (!this.navigationInfo) return;
    
    try {
      const currentLocation: Location = {
        latitude: 30.486874173982763,
        longitude: 114.309994670642
      };
      const route = await this.mapService.planRoute(currentLocation, this.navigationInfo.destination, 0);
      
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
