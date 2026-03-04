/**
 * 反馈服务 - 管理用户对导航的反馈
 */
import { HttpService } from './HttpService';
import { ApiResponse, NavigationFeedback, FeedbackStats, PageResponse } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 反馈服务类
 */
export class FeedbackService {
  private static instance: FeedbackService;
  private httpService: HttpService;
  private currentLocation: { latitude: number, longitude: number } | null = null;
  
  private constructor() {
    this.httpService = HttpService.getInstance();
    // 设置默认位置（武汉）
    this.currentLocation = {
      latitude: 30.486874173982763,
      longitude: 114.309994670642
    };
  }
  
  static getInstance(): FeedbackService {
    if (!FeedbackService.instance) {
      FeedbackService.instance = new FeedbackService();
    }
    return FeedbackService.instance;
  }
  
  /**
   * 设置当前位置（供外部调用）
   */
  setCurrentLocation(latitude: number, longitude: number): void {
    this.currentLocation = { latitude, longitude };
  }
  
  /**
   * 提交反馈
   */
  async submitFeedback(feedback: Partial<NavigationFeedback>): Promise<ApiResponse<void>> {
    try {
      console.log('[FeedbackService] 提交反馈');
      
      // 自动附加当前位置信息
      if (this.currentLocation && !feedback.locationLat && !feedback.locationLng) {
        feedback.locationLat = this.currentLocation.latitude;
        feedback.locationLng = this.currentLocation.longitude;
        console.log('[FeedbackService] 自动附加位置信息');
      }
      
      const response = await this.httpService.post<void>(
        ApiConfig.ENDPOINTS.FEEDBACK,
        feedback,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FeedbackService] 提交反馈失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 获取反馈列表（支持分页和类型筛选）
   */
  async getFeedbacks(
    feedbackType?: string,
    page: number = 1,
    pageSize: number = 20
  ): Promise<ApiResponse<PageResponse<NavigationFeedback>>> {
    try {
      console.log('[FeedbackService] 获取反馈列表');
      
      // 构建URL参数
      let url = `${ApiConfig.ENDPOINTS.FEEDBACK}?page=${page}&pageSize=${pageSize}`;
      if (feedbackType) {
        url += `&feedbackType=${feedbackType}`;
      }
      
      const response = await this.httpService.get<PageResponse<NavigationFeedback>>(url, true);
      
      return response;
    } catch (err) {
      console.error('[FeedbackService] 获取反馈列表失败:', err);
      return err as ApiResponse<PageResponse<NavigationFeedback>>;
    }
  }
  
  /**
   * 获取反馈统计
   */
  async getStats(): Promise<ApiResponse<FeedbackStats>> {
    try {
      console.log('[FeedbackService] 获取反馈统计');
      
      const response = await this.httpService.get<FeedbackStats>(
        ApiConfig.ENDPOINTS.FEEDBACK_STATS,
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FeedbackService] 获取反馈统计失败:', err);
      return err as ApiResponse<FeedbackStats>;
    }
  }
  
  /**
   * 获取反馈详情
   */
  async getFeedbackDetail(id: number): Promise<ApiResponse<NavigationFeedback>> {
    try {
      console.log('[FeedbackService] 获取反馈详情, id:', id);
      
      const response = await this.httpService.get<NavigationFeedback>(
        ApiConfig.ENDPOINTS.FEEDBACK_DETAIL(id),
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FeedbackService] 获取反馈详情失败:', err);
      return err as ApiResponse<NavigationFeedback>;
    }
  }
  
  /**
   * 删除反馈
   */
  async deleteFeedback(id: number): Promise<ApiResponse<void>> {
    try {
      console.log('[FeedbackService] 删除反馈, id:', id);
      
      const response = await this.httpService.delete<void>(
        ApiConfig.ENDPOINTS.FEEDBACK_DETAIL(id),
        true
      );
      
      return response;
    } catch (err) {
      console.error('[FeedbackService] 删除反馈失败:', err);
      return err as ApiResponse<void>;
    }
  }
}
