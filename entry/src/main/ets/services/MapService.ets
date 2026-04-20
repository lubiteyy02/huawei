/**
 * 地图服务 - 封装地图SDK核心功能
 * 使用高德地图Web服务API + JS API (WebView)
 * 定位方式：纯IP定位
 */
import { webview } from '@kit.ArkWeb';
import { AmapService } from './AmapService';
import { Location, RouteInfo, RouteStep, POIResult, MarkerType } from '../models/NavigationModels';

/**
 * 坐标点接口
 */
interface CoordinatePoint {
  latitude: number;
  longitude: number;
}

/**
 * WebView消息数据接口
 */
interface WebMessageData {
  action: string;
  path?: number[][];
  lng?: number;
  lat?: number;
  zoom?: number;
  title?: string;
}

/**
 * 地图服务类
 */
export class MapService {
  private static instance: MapService;
  private webController: webview.WebviewController | null = null;
  private amapService: AmapService;
  
  private constructor() {
    this.amapService = AmapService.getInstance();
  }
  
  static getInstance(): MapService {
    if (!MapService.instance) {
      MapService.instance = new MapService();
    }
    return MapService.instance;
  }
  
  /**
   * 设置WebView控制器
   */
  setWebController(controller: webview.WebviewController): void {
    this.webController = controller;
    console.log('[MapService] WebView控制器已设置');
  }
  
  /**
   * 向WebView发送消息
   */
  private sendMessageToWeb(action: string, data: Record<string, Object>): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    try {
      const messageData: WebMessageData = {
        action: action
      };
      
      // 合并data到messageData
      const keys = Object.keys(data);
      for (let i = 0; i < keys.length; i++) {
        const key = keys[i];
        const value = data[key];
        if (key === 'path' && Array.isArray(value)) {
          messageData.path = value as number[][];
        } else if (key === 'lng' && typeof value === 'number') {
          messageData.lng = value;
        } else if (key === 'lat' && typeof value === 'number') {
          messageData.lat = value;
        } else if (key === 'zoom' && typeof value === 'number') {
          messageData.zoom = value;
        } else if (key === 'title' && typeof value === 'string') {
          messageData.title = value;
        }
      }
      
      const message = JSON.stringify(messageData);
      console.log('[MapService] 发送消息到WebView:', action);
      if (action === 'drawRoute' && messageData.path) {
        console.log('[MapService] 路线坐标点数:', messageData.path.length);
        console.log('[MapService] 起点:', messageData.path[0]);
        console.log('[MapService] 终点:', messageData.path[messageData.path.length - 1]);
      }
      if (action === 'addMarker' || action === 'addCurrentLocationMarker') {
        console.log('[MapService] 标记位置: [', messageData.lng, ',', messageData.lat, ']');
      }
      
      // 使用JSON.stringify转义特殊字符，然后替换单引号避免JS语法错误
      const escapedMessage = message.replace(/\\/g, '\\\\').replace(/'/g, "\\'");
      const script = `window.postMessage('${escapedMessage}', '*')`;
      
      console.log('[MapService] 执行JS脚本长度:', script.length);
      this.webController.runJavaScript(script);
    } catch (err) {
      console.error('[MapService] Send message error:', String(err));
    }
  }
  
  /**
   * 创建包含数字的数据对象
   */
  private createNumberData(key1: string, value1: number, key2?: string, value2?: number, key3?: string, value3?: number): Record<string, Object> {
    const data: Record<string, Object> = {};
    data[key1] = value1 as Object;
    if (key2 !== undefined && value2 !== undefined) {
      data[key2] = value2 as Object;
    }
    if (key3 !== undefined && value3 !== undefined) {
      data[key3] = value3 as Object;
    }
    return data;
  }
  
  /**
   * 创建包含路径的数据对象
   */
  private createPathData(path: number[][]): Record<string, Object> {
    const data: Record<string, Object> = {};
    data['path'] = path as Object;
    return data;
  }
  
  /**
   * 创建空数据对象
   */
  private createEmptyData(): Record<string, Object> {
    const data: Record<string, Object> = {};
    return data;
  }
  
  /**
   * 获取当前位置
   * 直接使用默认坐标，不再优先尝试IP定位
   */
  async getCurrentLocation(): Promise<Location> {
    console.log('[MapService] 使用默认起点坐标');
    return {
      latitude: 30.486874173982763,
      longitude: 114.309994670642,
      address: '武汉市',
      name: '默认位置'
    };
  }
  
  /**
   * 路径规划 - 使用高德地图API
   */
  async planRoute(start: Location, end: Location, strategy: number): Promise<RouteInfo> {
    try {
      console.log('开始路径规划');
      
      const route = await this.amapService.planRoute(start, end, strategy);
      
      if (route) {
        console.log('路径规划成功');
        return route;
      }
      
      throw new Error('路径规划失败: 未获取到路线数据');
    } catch (err) {
      console.error('Plan route error:', String(err));
      throw new Error('路径规划失败: ' + String(err));
    }
  }
  
  /**
   * POI搜索 - 使用高德地图API
   */
  async searchPOI(keyword: string, location: Location | null, radius: number): Promise<POIResult[]> {
    try {
      console.log('开始POI搜索:', keyword);
      
      const results = await this.amapService.searchPOI(keyword, location, radius);
      
      console.log('POI搜索结果:', results.length, '个');
      return results;
    } catch (err) {
      console.error('Search POI error:', String(err));
      return [];
    }
  }
  
  /**
   * 周边搜索
   */
  async searchNearby(location: Location, type: string, radius: number): Promise<POIResult[]> {
    try {
      return await this.amapService.searchNearby(location, type, radius);
    } catch (err) {
      console.error('Search nearby error:', String(err));
      return [];
    }
  }
  
  /**
   * 地理编码 - 地址转坐标
   */
  async geocode(address: string): Promise<Location | null> {
    try {
      return await this.amapService.geocode(address);
    } catch (err) {
      console.error('Geocode error:', String(err));
      return null;
    }
  }
  
  /**
   * 逆地理编码 - 坐标转地址
   */
  async regeocode(location: Location): Promise<string> {
    try {
      return await this.amapService.regeocode(location);
    } catch (err) {
      console.error('Regeocode error:', String(err));
      return '未知地址';
    }
  }
  
  /**
   * 在地图上绘制路线
   */
  drawRoute(routeInfo: RouteInfo): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    if (!routeInfo || !routeInfo.polyline) {
      console.error('[MapService] Invalid route info');
      return;
    }
    
    try {
      console.log('[MapService] 开始绘制路线');
      console.log('[MapService] 路线距离:', routeInfo.distance, '米');
      console.log('[MapService] 预计时间:', routeInfo.duration, '秒');
      console.log('[MapService] Polyline原始数据:', routeInfo.polyline.substring(0, 100) + '...');
      
      // 解析路线坐标点
      const points = this.parsePolyline(routeInfo.polyline);
      
      if (points.length === 0) {
        console.error('[MapService] No points parsed from polyline');
        return;
      }
      
      console.log('[MapService] 解析到', points.length, '个坐标点');
      console.log('[MapService] 第一个点(起点):', points[0].latitude, points[0].longitude);
      console.log('[MapService] 最后一个点(终点):', points[points.length - 1].latitude, points[points.length - 1].longitude);
      
      // 转换为高德地图JS API格式 [lng, lat]
      const path: number[][] = [];
      for (const point of points) {
        path.push([point.longitude, point.latitude]);
      }
      
      console.log('[MapService] 转换后起点 [经度,纬度]:', path[0]);
      console.log('[MapService] 转换后终点 [经度,纬度]:', path[path.length - 1]);
      
      // 发送绘制路线消息到WebView
      const routeData = this.createPathData(path);
      this.sendMessageToWeb('drawRoute', routeData);
      
      console.log('[MapService] 路线绘制命令已发送');
      
    } catch (err) {
      console.error('[MapService] Draw route error:', String(err));
    }
  }
  
  /**
   * 解析高德地图的 polyline 编码
   * 简化版本：将坐标字符串转换为坐标点数组
   */
  private parsePolyline(polyline: string): CoordinatePoint[] {
    const points: CoordinatePoint[] = [];
    
    if (!polyline || polyline.length === 0) {
      return points;
    }
    
    try {
      // 高德的 polyline 格式：经度,纬度;经度,纬度;...
      const coords = polyline.split(';');
      
      for (let i = 0; i < coords.length; i++) {
        const coord = coords[i].split(',');
        if (coord.length === 2) {
          const lng = parseFloat(coord[0]);
          const lat = parseFloat(coord[1]);
          
          if (!isNaN(lng) && !isNaN(lat) && 
              lat >= -90 && lat <= 90 && 
              lng >= -180 && lng <= 180) {
            const point: CoordinatePoint = {
              latitude: lat,
              longitude: lng
            };
            points.push(point);
          }
        }
      }
      
      // 优化: 如果点太多,进行抽稀处理
      if (points.length > 500) {
        console.log('[MapService] 坐标点过多(', points.length, '),进行抽稀处理');
        return this.simplifyPoints(points, 500);
      }
      
    } catch (err) {
      console.error('[MapService] Parse polyline error:', String(err));
    }
    
    return points;
  }
  
  /**
   * 点抽稀算法 (简化版)
   */
  private simplifyPoints(points: CoordinatePoint[], maxPoints: number): CoordinatePoint[] {
    if (points.length <= maxPoints) {
      return points;
    }
    
    const step = Math.ceil(points.length / maxPoints);
    const simplified: CoordinatePoint[] = [];
    
    for (let i = 0; i < points.length; i += step) {
      simplified.push(points[i]);
    }
    
    // 确保最后一个点被包含
    const lastPoint = points[points.length - 1];
    const lastSimplified = simplified[simplified.length - 1];
    if (lastSimplified.latitude !== lastPoint.latitude || 
        lastSimplified.longitude !== lastPoint.longitude) {
      simplified.push(lastPoint);
    }
    
    console.log('[MapService] 抽稀后坐标点数量:', simplified.length);
    return simplified;
  }
  
  /**
   * 添加地图标记
   */
  addMarker(location: Location, title: string, type: MarkerType): string {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return '';
    }
    
    // 验证location有效性
    if (!location || 
        typeof location.latitude !== 'number' || 
        typeof location.longitude !== 'number' ||
        location.latitude < -90 || location.latitude > 90 ||
        location.longitude < -180 || location.longitude > 180) {
      console.error('[MapService] Invalid location:', location);
      return '';
    }
    
    try {
      console.log('[MapService] 添加标记:', title, 'at', location.latitude, location.longitude, 'type:', type);
      
      // 发送添加标记消息到WebView
      const markerData = this.createNumberData('lng', location.longitude, 'lat', location.latitude);
      markerData['title'] = title as Object;
      this.sendMessageToWeb('addMarker', markerData);
      
      return 'marker_' + Date.now();
      
    } catch (err) {
      console.error('[MapService] Add marker error:', String(err));
      return '';
    }
  }
  
  /**
   * 清除地图上的所有覆盖物
   */
  clearOverlays(): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    try {
      console.log('[MapService] 清除地图覆盖物');
      
      // 发送清除覆盖物消息到WebView
      const emptyData = this.createEmptyData();
      this.sendMessageToWeb('clearOverlays', emptyData);
      
    } catch (err) {
      console.error('[MapService] Clear overlays error:', String(err));
    }
  }
  
  /**
   * 移除指定标记
   */
  removeMarker(markerId: string): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    try {
      console.log('[MapService] 移除标记, ID:', markerId);
      // Note: 当前实现中标记由WebView管理,暂不支持单独移除
      // 可以通过clearOverlays清除所有标记
    } catch (err) {
      console.error('[MapService] Remove marker error:', String(err));
    }
  }
  
  /**
   * 移动地图到指定位置
   */
  moveToLocation(location: Location, zoom: number): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    try {
      console.log('[MapService] 移动地图到:', location.latitude, location.longitude, 'zoom:', zoom);
      
      // 发送移动地图消息到WebView
      const centerData = this.createNumberData('lng', location.longitude, 'lat', location.latitude, 'zoom', zoom);
      this.sendMessageToWeb('setCenter', centerData);
      
    } catch (err) {
      console.error('[MapService] Move to location error:', String(err));
    }
  }
  
  /**
   * 添加当前位置标记
   */
  addCurrentLocationMarker(location: Location): void {
    if (!this.webController) {
      console.error('[MapService] WebController not initialized');
      return;
    }
    
    try {
      console.log('[MapService] 添加当前位置标记:', location.latitude, location.longitude);
      
      // 发送添加当前位置标记消息到WebView
      const markerData = this.createNumberData('lng', location.longitude, 'lat', location.latitude);
      this.sendMessageToWeb('addCurrentLocationMarker', markerData);
      
    } catch (err) {
      console.error('[MapService] Add current location marker error:', String(err));
    }
  }
}

// 导出类型（从 NavigationModels 重新导出）
export { Location, RouteInfo, RouteStep, POIResult, MarkerType } from '../models/NavigationModels';

