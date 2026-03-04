/**
 * 高德地图API服务
 * 文档: https://lbs.amap.com/api/webservice/summary
 */
import http from '@ohos.net.http';
import { Location, RouteInfo, RouteStep, POIResult } from '../models/NavigationModels';

// 高德地图API配置
const AMAP_KEY = '2455309b8d8bb76cfdfebccb98f20153';  // TODO: 替换为你的API Key
const AMAP_BASE_URL = 'https://restapi.amap.com/v3';

/**
 * 高德地图服务类
 */
export class AmapService {
  private static instance: AmapService;
  
  private constructor() {}
  
  static getInstance(): AmapService {
    if (!AmapService.instance) {
      AmapService.instance = new AmapService();
    }
    return AmapService.instance;
  }
  
  /**
   * 发送HTTP请求
   */
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
          reject(err);
          return;
        }
        
        try {
          const response = JSON.parse(data.result as string) as Record<string, Object>;
          const status = response['status'] as string;
          if (status === '1') {
            resolve(response);
          } else {
            const info = response['info'] as string;
            reject(new Error(info || '请求失败'));
          }
        } catch (parseErr) {
          reject(new Error('响应解析失败'));
        } finally {
          httpRequest.destroy();
        }
      });
    });
  }
  
  /**
   * IP定位 - 通过IP地址获取大致位置(不需要GPS)
   */
  async getLocationByIP(): Promise<Location | null> {
    try {
      const url = `${AMAP_BASE_URL}/ip?key=${AMAP_KEY}`;
      console.log('[AmapService] IP定位请求:', url);
      
      const response: Record<string, Object> = await this.request(url);
      
      const province = response['province'] as string;
      const city = response['city'] as string;
      const rectangle = response['rectangle'] as string;
      
      console.log('[AmapService] IP定位结果 - 省份:', province, '城市:', city);
      
      if (rectangle && rectangle.length > 0) {
        // rectangle格式: "经度1,纬度1;经度2,纬度2"
        const parts = rectangle.split(';');
        if (parts.length >= 1) {
          const coords = parts[0].split(',');
          const lng = parseFloat(coords[0]);
          const lat = parseFloat(coords[1]);
          
          console.log('[AmapService] IP定位坐标:', lat, lng);
          
          return {
            latitude: lat,
            longitude: lng,
            address: province + city,
            name: 'IP定位'
          };
        }
      }
      
      return null;
    } catch (err) {
      console.error('[AmapService] IP定位失败:', JSON.stringify(err));
      return null;
    }
  }
  
  /**
   * 地理编码 - 地址转坐标
   */
  async geocode(address: string): Promise<Location | null> {
    try {
      const url = `${AMAP_BASE_URL}/geocode/geo?key=${AMAP_KEY}&address=${encodeURIComponent(address)}`;
      const response: Record<string, Object> = await this.request(url);
      
      const geocodes = response['geocodes'] as Array<Record<string, Object>>;
      if (geocodes && geocodes.length > 0) {
        const geo: Record<string, Object> = geocodes[0];
        const locationStr = geo['location'] as string;
        const parts: string[] = locationStr.split(',');
        const lng: number = parseFloat(parts[0]);
        const lat: number = parseFloat(parts[1]);
        
        return {
          latitude: lat,
          longitude: lng,
          address: geo['formatted_address'] as string,
          name: address
        };
      }
      
      return null;
    } catch (err) {
      console.error('Geocode error:', JSON.stringify(err));
      return null;
    }
  }
  
  /**
   * 逆地理编码 - 坐标转地址
   */
  async regeocode(location: Location): Promise<string> {
    try {
      const url = `${AMAP_BASE_URL}/geocode/regeo?key=${AMAP_KEY}&location=${location.longitude},${location.latitude}`;
      const response: Record<string, Object> = await this.request(url);
      
      const regeocode = response['regeocode'] as Record<string, Object>;
      if (regeocode) {
        return regeocode['formatted_address'] as string;
      }
      
      return '未知地址';
    } catch (err) {
      console.error('Regeocode error:', JSON.stringify(err));
      return '未知地址';
    }
  }
  
  /**
   * 路径规划 - 驾车
   */
  async planRoute(origin: Location, destination: Location, strategy: number): Promise<RouteInfo | null> {
    try {
      const originStr = `${origin.longitude},${origin.latitude}`;
      const destStr = `${destination.longitude},${destination.latitude}`;
      
      const url = `${AMAP_BASE_URL}/direction/driving?key=${AMAP_KEY}&origin=${originStr}&destination=${destStr}&strategy=${strategy}&extensions=all`;
      
      console.log('[AmapService] 请求路径规划 URL:', url);
      
      const response: Record<string, Object> = await this.request(url);
      
      console.log('[AmapService] 路径规划响应 status:', response['status']);
      
      const route = response['route'] as Record<string, Object>;
      if (route) {
        const paths = route['paths'] as Array<Record<string, Object>>;
        console.log('[AmapService] paths 数量:', paths ? paths.length : 0);
        
        if (paths && paths.length > 0) {
          const path: Record<string, Object> = paths[0];
          
          console.log('[AmapService] path 对象 keys:', Object.keys(path).join(', '));
          console.log('[AmapService] polyline 值:', path['polyline']);
          console.log('[AmapService] polyline 类型:', typeof path['polyline']);
          
          // 解析路线步骤
          const steps: RouteStep[] = [];
          const pathSteps = path['steps'] as Array<Record<string, Object>>;
          if (pathSteps) {
            for (let i = 0; i < pathSteps.length; i++) {
              const step: Record<string, Object> = pathSteps[i];
              const roadValue = step['road'];
              const actionValue = step['action'];
              steps.push({
                instruction: step['instruction'] as string,
                distance: parseInt(step['distance'] as string),
                duration: parseInt(step['duration'] as string),
                road: (roadValue !== null && roadValue !== undefined) ? (roadValue as string) : '',
                action: (actionValue !== null && actionValue !== undefined) ? (actionValue as string) : ''
              });
            }
          }
          
          const tollDistValue = path['toll_distance'];
          const tollsValue = path['tolls'];
          const trafficValue = path['traffic_lights'];
          
          // 获取 polyline，如果不存在则从 steps 中拼接
          let polyline = path['polyline'] as string;
          
          if (!polyline || polyline.length === 0) {
            console.log('[AmapService] polyline 为空，尝试从 steps 中获取');
            // 从 steps 中拼接 polyline
            const polylines: string[] = [];
            if (pathSteps) {
              for (let i = 0; i < pathSteps.length; i++) {
                const step: Record<string, Object> = pathSteps[i];
                const stepPolyline = step['polyline'] as string;
                if (stepPolyline && stepPolyline.length > 0) {
                  polylines.push(stepPolyline);
                }
              }
            }
            polyline = polylines.join(';');
            console.log('[AmapService] 拼接后的 polyline 长度:', polyline.length);
          }
          
          console.log('[AmapService] 最终 polyline 长度:', polyline ? polyline.length : 0);
          
          return {
            distance: parseInt(path['distance'] as string),
            duration: parseInt(path['duration'] as string),
            polyline: polyline || '',
            steps: steps,
            strategy: strategy,
            tollDistance: parseInt((tollDistValue !== null && tollDistValue !== undefined) ? (tollDistValue as string) : '0'),
            tollCost: parseInt((tollsValue !== null && tollsValue !== undefined) ? (tollsValue as string) : '0'),
            trafficLights: parseInt((trafficValue !== null && trafficValue !== undefined) ? (trafficValue as string) : '0')
          };
        }
      }
      
      console.log('[AmapService] 路径规划失败: 没有找到有效路径');
      return null;
    } catch (err) {
      console.error('Plan route error:', JSON.stringify(err));
      return null;
    }
  }
  
  /**
   * POI搜索 - 关键词搜索
   */
  async searchPOI(keyword: string, location: Location | null, radius: number): Promise<POIResult[]> {
    try {
      let url = `${AMAP_BASE_URL}/place/text?key=${AMAP_KEY}&keywords=${encodeURIComponent(keyword)}`;
      
      if (location !== null) {
        url += `&location=${location.longitude},${location.latitude}&radius=${radius}&sortrule=distance`;
      }
      
      const response: Record<string, Object> = await this.request(url);
      
      const results: POIResult[] = [];
      
      const pois = response['pois'] as Array<Record<string, Object>>;
      if (pois && pois.length > 0) {
        for (let i = 0; i < pois.length; i++) {
          const poi: Record<string, Object> = pois[i];
          const locationStr = poi['location'] as string;
          const parts: string[] = locationStr.split(',');
          const lng: number = parseFloat(parts[0]);
          const lat: number = parseFloat(parts[1]);
          
          // 计算距离
          let distance = 0;
          if (location !== null) {
            distance = this.calculateDistance(
              location.latitude,
              location.longitude,
              lat,
              lng
            );
          }
          
          const addressValue = poi['address'];
          const pnameValue = poi['pname'];
          const citynameValue = poi['cityname'];
          const adnameValue = poi['adname'];
          
          let address = '';
          if (addressValue !== null && addressValue !== undefined) {
            address = addressValue as string;
          } else {
            const pname = (pnameValue !== null && pnameValue !== undefined) ? (pnameValue as string) : '';
            const cityname = (citynameValue !== null && citynameValue !== undefined) ? (citynameValue as string) : '';
            const adname = (adnameValue !== null && adnameValue !== undefined) ? (adnameValue as string) : '';
            address = pname + cityname + adname;
          }
          
          const telValue = poi['tel'];
          const typecodeValue = poi['typecode'];
          
          results.push({
            id: poi['id'] as string,
            name: poi['name'] as string,
            address: address,
            location: {
              latitude: lat,
              longitude: lng
            },
            distance: distance,
            category: poi['type'] as string,
            categoryCode: (typecodeValue !== null && typecodeValue !== undefined) ? (typecodeValue as string) : undefined,
            phone: (telValue !== null && telValue !== undefined) ? (telValue as string) : undefined
          });
        }
      }
      
      return results;
    } catch (err) {
      console.error('Search POI error:', JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * POI周边搜索
   */
  async searchNearby(location: Location, type: string, radius: number): Promise<POIResult[]> {
    try {
      const url = `${AMAP_BASE_URL}/place/around?key=${AMAP_KEY}&location=${location.longitude},${location.latitude}&keywords=${encodeURIComponent(type)}&radius=${radius}&sortrule=distance`;
      
      const response: Record<string, Object> = await this.request(url);
      
      const results: POIResult[] = [];
      
      const pois = response['pois'] as Array<Record<string, Object>>;
      if (pois && pois.length > 0) {
        for (let i = 0; i < pois.length; i++) {
          const poi: Record<string, Object> = pois[i];
          const locationStr = poi['location'] as string;
          const parts: string[] = locationStr.split(',');
          const lng: number = parseFloat(parts[0]);
          const lat: number = parseFloat(parts[1]);
          
          const distance = this.calculateDistance(
            location.latitude,
            location.longitude,
            lat,
            lng
          );
          
          const addressValue = poi['address'];
          const telValue = poi['tel'];
          
          results.push({
            id: poi['id'] as string,
            name: poi['name'] as string,
            address: (addressValue !== null && addressValue !== undefined) ? (addressValue as string) : '',
            location: {
              latitude: lat,
              longitude: lng
            },
            distance: distance,
            category: poi['type'] as string,
            phone: (telValue !== null && telValue !== undefined) ? (telValue as string) : undefined
          });
        }
      }
      
      return results;
    } catch (err) {
      console.error('Search nearby error:', JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * 输入提示 - 搜索建议
   */
  async inputTips(keyword: string, location: Location | null): Promise<Array<Record<string, Object>>> {
    try {
      let url = `${AMAP_BASE_URL}/assistant/inputtips?key=${AMAP_KEY}&keywords=${encodeURIComponent(keyword)}`;
      
      if (location !== null) {
        url += `&location=${location.longitude},${location.latitude}`;
      }
      
      const response: Record<string, Object> = await this.request(url);
      
      const tips = response['tips'] as Array<Record<string, Object>>;
      return tips || [];
    } catch (err) {
      console.error('Input tips error:', JSON.stringify(err));
      return [];
    }
  }
  
  /**
   * 计算两点距离（Haversine公式）
   */
  private calculateDistance(lat1: number, lng1: number, lat2: number, lng2: number): number {
    const R = 6371000; // 地球半径（米）
    const dLat = (lat2 - lat1) * Math.PI / 180;
    const dLng = (lng2 - lng1) * Math.PI / 180;
    
    const a = Math.sin(dLat / 2) * Math.sin(dLat / 2) +
              Math.cos(lat1 * Math.PI / 180) * Math.cos(lat2 * Math.PI / 180) *
              Math.sin(dLng / 2) * Math.sin(dLng / 2);
    
    const c = 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    
    return Math.round(R * c);
  }
}
