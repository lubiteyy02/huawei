/**
 * 收藏服务 - 管理用户收藏的地点
 */
import { HttpService } from './HttpService';
import { CacheService } from './CacheService';
import { ApiResponse, FavoritePlace } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 收藏服务类
 */
export class FavoriteService {
  private static instance: FavoriteService;
  private httpService: HttpService;
  private cacheService: CacheService;
  private readonly CACHE_KEY = 'favorites_cache';
  
  private constructor() {
    this.httpService = HttpService.getInstance();
    this.cacheService = CacheService.getInstance();
  }
  
  static getInstance(): FavoriteService {
    if (!FavoriteService.instance) {
      FavoriteService.instance = new FavoriteService();
    }
    return FavoriteService.instance;
  }
  
  /**
   * 获取收藏列表
   */
  async getFavorites(category?: string): Promise<ApiResponse<FavoritePlace[]>> {
    try {
      console.log('[FavoriteService] 获取收藏列表, category:', category);
      
      // 检查是否登录
      const token = this.httpService.getToken();
      if (!token) {
        return {
          code: 401,
          message: '需要登录'
        };
      }
      
      // 构建URL
      let url = ApiConfig.ENDPOINTS.FAVORITES;
      if (category) {
        url += `?category=${category}`;
      }
      
      const response = await this.httpService.get<FavoritePlace[]>(url, true);
      
      // 成功时缓存数据
      if (response.code === 200 && response.data) {
        await this.cacheFavorites(response.data);
      }
      
      return response;
    } catch (err) {
      console.error('[FavoriteService] 获取收藏列表失败:', err);
      
      // 网络失败时尝试从缓存读取
      const cachedData = await this.getCachedFavorites();
      if (cachedData && cachedData.length > 0) {
        console.log('[FavoriteService] 使用缓存数据');
        return {
          code: 200,
          message: '从缓存加载',
          data: cachedData
        };
      }
      
      return err as ApiResponse<FavoritePlace[]>;
    }
  }
  
  /**
   * 添加收藏
   */
  async addFavorite(place: Partial<FavoritePlace>): Promise<ApiResponse<FavoritePlace>> {
    try {
      console.log('[FavoriteService] 添加收藏:', place.name);
      console.log('[FavoriteService] 完整数据:', JSON.stringify(place));
      
      // 检查是否登录
      const token = this.httpService.getToken();
      console.log('[FavoriteService] Token存在:', !!token);
      if (!token) {
        return {
          code: 401,
          message: '需要登录'
        };
      }
      
      const response = await this.httpService.post<FavoritePlace>(
        ApiConfig.ENDPOINTS.FAVORITES,
        place,
        true
      );
      
      console.log('[FavoriteService] 响应代码:', response.code);
      console.log('[FavoriteService] 响应消息:', response.message);
      console.log('[FavoriteService] 完整响应:', JSON.stringify(response));
      
      // 成功时清除缓存，下次重新加载
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      console.error('[FavoriteService] 添加收藏失败 - 错误类型:', typeof err);
      console.error('[FavoriteService] 添加收藏失败 - 详情:', JSON.stringify(err));
      return err as ApiResponse<FavoritePlace>;
    }
  }
  
  /**
   * 更新收藏
   */
  async updateFavorite(id: number, updates: Partial<FavoritePlace>): Promise<ApiResponse<void>> {
    try {
      console.log('[FavoriteService] 更新收藏:', id);
      
      // 检查是否登录
      const token = this.httpService.getToken();
      if (!token) {
        return {
          code: 401,
          message: '需要登录'
        };
      }
      
      const response = await this.httpService.put<void>(
        ApiConfig.ENDPOINTS.FAVORITE_DETAIL(id),
        updates,
        true
      );
      
      // 成功时清除缓存
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      console.error('[FavoriteService] 更新收藏失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 删除收藏
   */
  async deleteFavorite(id: number): Promise<ApiResponse<void>> {
    try {
      console.log('[FavoriteService] 删除收藏:', id);
      
      // 检查是否登录
      const token = this.httpService.getToken();
      if (!token) {
        return {
          code: 401,
          message: '需要登录'
        };
      }
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.FAVORITE_DETAIL(id),
        true
      );
      
      // 成功时清除缓存
      if (response.code === 200) {
        await this.cacheService.remove(this.CACHE_KEY);
      }
      
      return response;
    } catch (err) {
      console.error('[FavoriteService] 删除收藏失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 搜索收藏
   */
  async searchFavorites(keyword: string): Promise<FavoritePlace[]> {
    try {
      console.log('[FavoriteService] 搜索收藏:', keyword);
      
      // 先获取所有收藏
      const response = await this.getFavorites();
      
      if (response.code === 200 && response.data) {
        // 按名称搜索（不区分大小写）
        const lowerKeyword = keyword.toLowerCase();
        return response.data.filter(place => 
          place.name.toLowerCase().includes(lowerKeyword)
        );
      }
      
      return [];
    } catch (err) {
      console.error('[FavoriteService] 搜索收藏失败:', err);
      return [];
    }
  }
  
  /**
   * 从缓存获取收藏列表
   */
  private async getCachedFavorites(): Promise<FavoritePlace[]> {
    try {
      const cached = await this.cacheService.get<FavoritePlace[]>(this.CACHE_KEY);
      return cached || [];
    } catch (err) {
      console.error('[FavoriteService] 读取缓存失败:', err);
      return [];
    }
  }
  
  /**
   * 缓存收藏列表
   */
  private async cacheFavorites(favorites: FavoritePlace[]): Promise<void> {
    try {
      await this.cacheService.set(
        this.CACHE_KEY,
        favorites,
        ApiConfig.CACHE_EXPIRE_TIME.FAVORITES
      );
      console.log('[FavoriteService] 收藏列表已缓存');
    } catch (err) {
      console.error('[FavoriteService] 缓存收藏列表失败:', err);
    }
  }
}
