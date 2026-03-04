/**
 * 位置共享服务 - 管理用户之间的实时位置共享
 */
import { HttpService } from './HttpService';
import { ApiResponse, UserLocation, LocationShare, NearbyUser } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 位置共享服务类
 */
export class LocationShareService {
  private static instance: LocationShareService;
  private httpService: HttpService;
  private autoUpdateTimer: number = -1;
  private readonly AUTO_UPDATE_INTERVAL = 30000;  // 30秒
  private shareStartTime: number = 0;
  private readonly MAX_SHARE_DURATION = 24 * 60 * 60 * 1000;  // 24小时
  
  private constructor() {
    this.httpService = HttpService.getInstance();
  }
  
  static getInstance(): LocationShareService {
    if (!LocationShareService.instance) {
      LocationShareService.instance = new LocationShareService();
    }
    return LocationShareService.instance;
  }
  
  /**
   * 更新用户位置
   */
  async updateLocation(location: Partial<UserLocation>): Promise<ApiResponse<void>> {
    try {
      console.log('[LocationShareService] 更新用户位置');
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.LOCATION,
        location,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 更新用户位置失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 获取用户位置
   */
  async getLocation(userId?: number): Promise<ApiResponse<UserLocation>> {
    try {
      console.log('[LocationShareService] 获取用户位置, userId:', userId);
      
      const url = userId 
        ? ApiConfig.ENDPOINTS.LOCATION_USER(userId)
        : ApiConfig.ENDPOINTS.LOCATION;
      
      const response = await this.httpService.get<UserLocation>(url, true);
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 获取用户位置失败:', err);
      return err as ApiResponse<UserLocation>;
    }
  }
  
  /**
   * 开启/关闭位置共享
   */
  async toggleSharing(isSharing: boolean): Promise<ApiResponse<void>> {
    try {
      console.log('[LocationShareService] 切换位置共享:', isSharing);
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.LOCATION_SHARING_TOGGLE,
        { isSharing },
        true
      );
      
      // 开启共享时启动自动更新
      if (response.code === 200 && isSharing) {
        this.startAutoUpdate();
      } else if (response.code === 200 && !isSharing) {
        this.stopAutoUpdate();
      }
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 切换位置共享失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 创建位置共享
   */
  async createShare(viewerId: number, expireHours?: number): Promise<ApiResponse<void>> {
    try {
      console.log('[LocationShareService] 创建位置共享, viewerId:', viewerId);
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.LOCATION_SHARING,
        { viewerId, expireHours },
        true
      );
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 创建位置共享失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 获取共享列表
   */
  async getShares(type: 'sharing' | 'viewing'): Promise<ApiResponse<LocationShare[]>> {
    try {
      console.log('[LocationShareService] 获取共享列表, type:', type);
      
      const url = `${ApiConfig.ENDPOINTS.LOCATION_SHARING}?type=${type}`;
      const response = await this.httpService.get<LocationShare[]>(url, true);
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 获取共享列表失败:', err);
      return err as ApiResponse<LocationShare[]>;
    }
  }
  
  /**
   * 取消位置共享
   */
  async cancelShare(shareId: number): Promise<ApiResponse<void>> {
    try {
      console.log('[LocationShareService] 取消位置共享, shareId:', shareId);
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.LOCATION_SHARING_DETAIL(shareId),
        true
      );
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 取消位置共享失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 获取附近用户
   */
  async getNearbyUsers(latitude: number, longitude: number, radius?: number): Promise<ApiResponse<NearbyUser[]>> {
    try {
      console.log('[LocationShareService] 获取附近用户');
      
      let url = `${ApiConfig.ENDPOINTS.LOCATION_NEARBY}?latitude=${latitude}&longitude=${longitude}`;
      if (radius) {
        url += `&radius=${radius}`;
      }
      
      const response = await this.httpService.get<NearbyUser[]>(url, true);
      
      return response;
    } catch (err) {
      console.error('[LocationShareService] 获取附近用户失败:', err);
      return err as ApiResponse<NearbyUser[]>;
    }
  }
  
  /**
   * 启动自动更新位置
   */
  startAutoUpdate(): void {
    // 如果已经在运行，先停止
    if (this.autoUpdateTimer !== -1) {
      this.stopAutoUpdate();
    }
    
    console.log('[LocationShareService] 启动自动更新位置');
    this.shareStartTime = Date.now();
    
    // 使用武汉默认坐标
    const defaultLocation: Partial<UserLocation> = {
      latitude: 30.486874173982763,
      longitude: 114.309994670642,
      accuracy: 100,
      locationType: 'ip',
      isSharing: true
    };
    
    // 立即更新一次
    this.updateLocation(defaultLocation);
    
    // 设置定时器，每30秒更新一次
    this.autoUpdateTimer = setInterval(() => {
      // 检查是否超过24小时
      const elapsed = Date.now() - this.shareStartTime;
      if (elapsed >= this.MAX_SHARE_DURATION) {
        console.log('[LocationShareService] 共享超过24小时，自动停止');
        this.stopAutoUpdate();
        this.toggleSharing(false);
        return;
      }
      
      // 更新位置
      this.updateLocation(defaultLocation);
    }, this.AUTO_UPDATE_INTERVAL);
  }
  
  /**
   * 停止自动更新位置
   */
  stopAutoUpdate(): void {
    if (this.autoUpdateTimer !== -1) {
      console.log('[LocationShareService] 停止自动更新位置');
      clearInterval(this.autoUpdateTimer);
      this.autoUpdateTimer = -1;
      this.shareStartTime = 0;
    }
  }
}
