/**
 * 导航历史服务 - 管理导航历史记录
 */
import { HttpService } from './HttpService';
import { CacheService } from './CacheService';
import { ApiResponse, NavigationHistory, PageResponse } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 导航历史服务类
 */
export class NavigationHistoryService {
  private static instance: NavigationHistoryService;
  private httpService: HttpService;
  private cacheService: CacheService;
  private readonly CACHE_KEY = 'history_cache';
  
  private constructor() {
    this.httpService = HttpService.getInstance();
    this.cacheService = CacheService.getInstance();
  }
  
  static getInstance(): NavigationHistoryService {
    if (!NavigationHistoryService.instance) {
      NavigationHistoryService.instance = new NavigationHistoryService();
    }
    return NavigationHistoryService.instance;
  }
  
  /**
   * 获取历史记录（支持分页）
   */
  async getHistory(page: number = 1, pageSize: number = 50): Promise<ApiResponse<PageResponse<NavigationHistory>>> {
    try {
      console.log('[NavigationHistoryService] 获取历史记录, page:', page, 'pageSize:', pageSize);
      
      const url = `${ApiConfig.ENDPOINTS.NAVIGATION_HISTORY}?page=${page}&pageSize=${pageSize}`;
      console.log('[NavigationHistoryService] 请求URL:', ApiConfig.BASE_URL + url);
      
      const response = await this.httpService.get<PageResponse<NavigationHistory>>(url, true);
      
      console.log('[NavigationHistoryService] 响应状态码:', response.code);
      console.log('[NavigationHistoryService] 响应消息:', response.message);
      
      // 成功时缓存数据（只缓存第一页的最近50条）
      if (response.code === 200 && response.data && page === 1) {
        await this.cacheHistory(response.data.list);
      }
      
      return response;
    } catch (err) {
      console.error('[NavigationHistoryService] 获取历史记录失败:', JSON.stringify(err));
      
      // 网络失败时尝试从缓存读取
      if (page === 1) {
        const cachedData = await this.getCachedHistory();
        if (cachedData && cachedData.length > 0) {
          console.log('[NavigationHistoryService] 使用缓存数据');
          return {
            code: 200,
            message: '从缓存加载',
            data: {
              list: cachedData,
              total: cachedData.length,
              page: 1,
              pageSize: cachedData.length
            }
          };
        }
      }
      
      return err as ApiResponse<PageResponse<NavigationHistory>>;
    }
  }
  
  /**
   * 保存导航记录
   */
  async saveHistory(record: Partial<NavigationHistory>): Promise<ApiResponse<void>> {
    try {
      console.log('[NavigationHistoryService] 保存导航记录');
      
      // 验证必需字段
      if (!record.endName || !record.endAddress || 
          record.endLat === undefined || record.endLng === undefined) {
        console.error('[NavigationHistoryService] 缺少必需字段');
        return {
          code: 400,
          message: '缺少必需字段：endName, endAddress, endLat, endLng'
        };
      }
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.NAVIGATION_HISTORY,
        record,
        true
      );
      
      // 成功时清除缓存
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      // 静默失败 - 不抛出异常，不阻塞导航功能
      console.error('[NavigationHistoryService] 保存导航记录失败（静默）:', err);
      return {
        code: -1,
        message: '保存失败（已静默处理）'
      };
    }
  }
  
  /**
   * 删除历史记录
   */
  async deleteHistory(id: number): Promise<ApiResponse<void>> {
    try {
      console.log('[NavigationHistoryService] 删除历史记录:', id);
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.NAVIGATION_HISTORY_DETAIL(id),
        true
      );
      
      // 成功时清除缓存
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      console.error('[NavigationHistoryService] 删除历史记录失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 清空历史记录
   */
  async clearHistory(): Promise<ApiResponse<void>> {
    try {
      console.log('[NavigationHistoryService] 清空历史记录');
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.NAVIGATION_HISTORY,
        true
      );
      
      // 成功时清除缓存
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      console.error('[NavigationHistoryService] 清空历史记录失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 按日期范围筛选历史记录
   */
  async getHistoryByDateRange(startDate: string, endDate: string): Promise<ApiResponse<NavigationHistory[]>> {
    try {
      console.log('[NavigationHistoryService] 按日期筛选:', startDate, '-', endDate);
      
      const url = `${ApiConfig.ENDPOINTS.NAVIGATION_HISTORY}?startDate=${startDate}&endDate=${endDate}`;
      const response = await this.httpService.get<NavigationHistory[]>(url, true);
      
      return response;
    } catch (err) {
      console.error('[NavigationHistoryService] 按日期筛选失败:', err);
      return err as ApiResponse<NavigationHistory[]>;
    }
  }
  
  /**
   * 从缓存获取历史记录
   */
  private async getCachedHistory(): Promise<NavigationHistory[]> {
    try {
      const cached = await this.cacheService.get<NavigationHistory[]>(this.CACHE_KEY);
      return cached || [];
    } catch (err) {
      console.error('[NavigationHistoryService] 读取缓存失败:', err);
      return [];
    }
  }
  
  /**
   * 缓存历史记录（最近50条）
   */
  private async cacheHistory(history: NavigationHistory[]): Promise<void> {
    try {
      // 只缓存最近50条
      const toCache = history.slice(0, 50);
      await this.cacheService.set(
        this.CACHE_KEY,
        toCache,
        ApiConfig.CACHE_EXPIRE_TIME.HISTORY
      );
      console.log('[NavigationHistoryService] 历史记录已缓存');
    } catch (err) {
      console.error('[NavigationHistoryService] 缓存历史记录失败:', err);
    }
  }
}
