/**
 * API服务 - 封装所有后端API调用
 */
import { HttpService } from './HttpService';
import {
  UserInfo,
  FavoritePlace,
  NavigationHistory,
  TripRecord,
  SearchHistory,
  PageResponse
} from '../models/NavigationModels';

export class ApiService {
  private static instance: ApiService;
  private http: HttpService;
  
  private constructor() {
    this.http = HttpService.getInstance();
  }
  
  static getInstance(): ApiService {
    if (!ApiService.instance) {
      ApiService.instance = new ApiService();
    }
    return ApiService.instance;
  }
  
  // ==================== 认证相关 ====================
  
  /**
   * 用户注册
   */
  async register(phone: string, password: string, nickname?: string): Promise<UserInfo> {
    const response = await this.http.post<UserInfo>(
      '/auth/register',
      { phone, password, nickname },
      false
    );
    
    if (response.code === 200 && response.data) {
      // 保存token
      if (response.data.token) {
        this.http.setToken(response.data.token);
      }
      return response.data;
    }
    
    throw new Error(response.message || '注册失败');
  }
  
  /**
   * 用户登录
   */
  async login(phone: string, password: string): Promise<UserInfo> {
    const response = await this.http.post<UserInfo>(
      '/auth/login',
      { phone, password },
      false
    );
    
    if (response.code === 200 && response.data) {
      // 保存token
      if (response.data.token) {
        this.http.setToken(response.data.token);
      }
      return response.data;
    }
    
    throw new Error(response.message || '登录失败');
  }
  
  /**
   * 获取用户信息
   */
  async getProfile(): Promise<UserInfo> {
    const response = await this.http.get<UserInfo>('/auth/profile');
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    throw new Error(response.message || '获取用户信息失败');
  }
  
  /**
   * 更新用户信息
   */
  async updateProfile(nickname?: string, avatar?: string): Promise<void> {
    const response = await this.http.put('/auth/profile', { nickname, avatar });
    
    if (response.code !== 200) {
      throw new Error(response.message || '更新失败');
    }
  }
  
  /**
   * 登出
   */
  logout(): void {
    this.http.clearToken();
  }
  
  // ==================== 收藏相关 ====================
  
  /**
   * 获取收藏列表
   */
  async getFavorites(category?: string): Promise<FavoritePlace[]> {
    let url = '/favorites';
    if (category) {
      url += `?category=${category}`;
    }
    
    const response = await this.http.get<FavoritePlace[]>(url);
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    return [];
  }
  
  /**
   * 添加收藏
   */
  async addFavorite(favorite: FavoritePlace): Promise<number> {
    const response = await this.http.post<{ id: number }>('/favorites', favorite);
    
    if (response.code === 200 && response.data) {
      return response.data.id;
    }
    
    throw new Error(response.message || '添加收藏失败');
  }
  
  /**
   * 更新收藏
   */
  async updateFavorite(id: number, favorite: Partial<FavoritePlace>): Promise<void> {
    const response = await this.http.put(`/favorites/${id}`, favorite);
    
    if (response.code !== 200) {
      throw new Error(response.message || '更新失败');
    }
  }
  
  /**
   * 删除收藏
   */
  async deleteFavorite(id: number): Promise<void> {
    const response = await this.http.delete(`/favorites/${id}`);
    
    if (response.code !== 200) {
      throw new Error(response.message || '删除失败');
    }
  }
  
  // ==================== 导航历史相关 ====================
  
  /**
   * 获取导航历史
   */
  async getNavigationHistory(page: number = 1, pageSize: number = 20): Promise<PageResponse<NavigationHistory>> {
    const response = await this.http.get<PageResponse<NavigationHistory>>(
      `/navigation/history?page=${page}&pageSize=${pageSize}`
    );
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    return { list: [], total: 0, page, pageSize };
  }
  
  /**
   * 保存导航记录
   */
  async saveNavigationHistory(history: NavigationHistory): Promise<number> {
    const response = await this.http.post<{ id: number }>('/navigation/history', history);
    
    if (response.code === 200 && response.data) {
      return response.data.id;
    }
    
    throw new Error(response.message || '保存失败');
  }
  
  /**
   * 删除导航历史
   */
  async deleteNavigationHistory(id: number): Promise<void> {
    const response = await this.http.delete(`/navigation/history/${id}`);
    
    if (response.code !== 200) {
      throw new Error(response.message || '删除失败');
    }
  }
  
  /**
   * 清空导航历史
   */
  async clearNavigationHistory(): Promise<void> {
    const response = await this.http.delete('/navigation/history');
    
    if (response.code !== 200) {
      throw new Error(response.message || '清空失败');
    }
  }
  
  // ==================== 行程记录相关 ====================
  
  /**
   * 获取行程列表
   */
  async getTripRecords(page: number = 1, pageSize: number = 20): Promise<PageResponse<TripRecord>> {
    const response = await this.http.get<PageResponse<TripRecord>>(
      `/trips?page=${page}&pageSize=${pageSize}`
    );
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    return { list: [], total: 0, page, pageSize };
  }
  
  /**
   * 获取行程详情
   */
  async getTripRecord(id: number): Promise<TripRecord | null> {
    const response = await this.http.get<TripRecord>(`/trips/${id}`);
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    return null;
  }
  
  /**
   * 创建行程记录
   */
  async createTripRecord(trip: TripRecord): Promise<number> {
    const response = await this.http.post<{ id: number }>('/trips', trip);
    
    if (response.code === 200 && response.data) {
      return response.data.id;
    }
    
    throw new Error(response.message || '创建失败');
  }
  
  /**
   * 更新行程记录
   */
  async updateTripRecord(id: number, trip: Partial<TripRecord>): Promise<void> {
    const response = await this.http.put(`/trips/${id}`, trip);
    
    if (response.code !== 200) {
      throw new Error(response.message || '更新失败');
    }
  }
  
  // ==================== 搜索历史相关 ====================
  
  /**
   * 获取搜索历史
   */
  async getSearchHistory(): Promise<SearchHistory[]> {
    const response = await this.http.get<SearchHistory[]>('/search/history');
    
    if (response.code === 200 && response.data) {
      return response.data;
    }
    
    return [];
  }
  
  /**
   * 保存搜索记录
   */
  async saveSearchHistory(keyword: string, resultCount: number = 0): Promise<void> {
    await this.http.post('/search/history', { keyword, resultCount });
  }
  
  /**
   * 清空搜索历史
   */
  async clearSearchHistory(): Promise<void> {
    const response = await this.http.delete('/search/history');
    
    if (response.code !== 200) {
      throw new Error(response.message || '清空失败');
    }
  }
}
