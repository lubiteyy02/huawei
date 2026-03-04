/**
 * 常去地点服务 - 管理和识别用户常去的地点
 */
import { HttpService } from './HttpService';
import { ApiResponse, FrequentLocation, FrequentLocationStats } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 常去地点服务类
 */
export class FrequentLocationService {
  private static instance: FrequentLocationService;
  private httpService: HttpService;
  
  private constructor() {
    this.httpService = HttpService.getInstance();
  }
  
  static getInstance(): FrequentLocationService {
    if (!FrequentLocationService.instance) {
      FrequentLocationService.instance = new FrequentLocationService();
    }
    return FrequentLocationService.instance;
  }
  
  /**
   * 记录地点访问
   */
  async recordVisit(location: Partial<FrequentLocation>): Promise<ApiResponse<void>> {
    try {
      console.log('[FrequentLocationService] 记录地点访问:', location.name);
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS_VISIT,
        location,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 记录地点访问失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 获取常去地点列表
   */
  async getFrequentLocations(limit?: number, minVisits?: number): Promise<ApiResponse<FrequentLocation[]>> {
    try {
      console.log('[FrequentLocationService] 获取常去地点列表');
      
      // 构建URL参数
      let url = ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS;
      const params: string[] = [];
      if (limit) params.push(`limit=${limit}`);
      if (minVisits) params.push(`minVisits=${minVisits}`);
      if (params.length > 0) {
        url += `?${params.join('&')}`;
      }
      
      const response = await this.httpService.get<FrequentLocation[]>(url, true);
      
      // 按visitCount降序排序
      if (response.code === 200 && response.data) {
        response.data.sort((a, b) => b.visitCount - a.visitCount);
      }
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 获取常去地点列表失败:', err);
      return err as ApiResponse<FrequentLocation[]>;
    }
  }
  
  /**
   * 获取智能推荐
   */
  async getRecommendations(timePattern?: string, limit?: number): Promise<ApiResponse<FrequentLocation[]>> {
    try {
      console.log('[FrequentLocationService] 获取智能推荐');
      
      // 构建URL参数
      let url = ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS_RECOMMENDED;
      const params: string[] = [];
      if (timePattern) params.push(`timePattern=${timePattern}`);
      if (limit) params.push(`limit=${limit}`);
      if (params.length > 0) {
        url += `?${params.join('&')}`;
      }
      
      const response = await this.httpService.get<FrequentLocation[]>(url, true);
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 获取智能推荐失败:', err);
      return err as ApiResponse<FrequentLocation[]>;
    }
  }
  
  /**
   * 获取访问统计
   */
  async getStats(): Promise<ApiResponse<FrequentLocationStats>> {
    try {
      console.log('[FrequentLocationService] 获取访问统计');
      
      const response = await this.httpService.get<FrequentLocationStats>(
        ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS_STATS,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 获取访问统计失败:', err);
      return err as ApiResponse<FrequentLocationStats>;
    }
  }
  
  /**
   * 更新地点信息
   */
  async updateLocation(id: number, updates: Partial<FrequentLocation>): Promise<ApiResponse<void>> {
    try {
      console.log('[FrequentLocationService] 更新地点信息:', id);
      
      const response = await this.httpService.put<void>(
        ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS_DETAIL(id),
        updates,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 更新地点信息失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 删除常去地点
   */
  async deleteLocation(id: number): Promise<ApiResponse<void>> {
    try {
      console.log('[FrequentLocationService] 删除常去地点:', id);
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.FREQUENT_LOCATIONS_DETAIL(id),
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FrequentLocationService] 删除常去地点失败:', err);
      return err as ApiResponse<void>;
    }
  }
}
