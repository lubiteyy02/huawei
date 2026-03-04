/**
 * HTTP服务 - 封装网络请求
 */
import http from '@ohos.net.http';
import { ApiResponse } from '../models/NavigationModels';

// API基础配置
const BASE_URL = 'http://localhost:3000/api/v1';  // 开发环境
// const BASE_URL = 'https://your-api.com/api/v1';  // 生产环境

/**
 * HTTP服务类
 */
export class HttpService {
  private static instance: HttpService;
  private token: string = '';
  
  private constructor() {
    // 从本地存储加载token
    this.loadToken();
  }
  
  static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }
  
  /**
   * 设置认证token
   */
  setToken(token: string): void {
    this.token = token;
    // 保存到本地存储
    // TODO: 使用Preferences持久化存储
  }
  
  /**
   * 获取token
   */
  getToken(): string {
    return this.token;
  }
  
  /**
   * 清除token
   */
  clearToken(): void {
    this.token = '';
    // TODO: 清除本地存储
  }
  
  /**
   * 加载token
   */
  private loadToken(): void {
    // TODO: 从Preferences加载token
  }
  
  /**
   * 发送HTTP请求
   */
  private async request<T>(
    method: http.RequestMethod,
    url: string,
    data?: any,
    needAuth: boolean = true
  ): Promise<ApiResponse<T>> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      
      const fullUrl = `${BASE_URL}${url}`;
      
      const options: http.HttpRequestOptions = {
        method,
        header: {
          'Content-Type': 'application/json'
        },
        readTimeout: 30000,
        connectTimeout: 30000
      };
      
      // 添加认证头
      if (needAuth && this.token) {
        options.header!['Authorization'] = `Bearer ${this.token}`;
      }
      
      // 添加请求体
      if (data && (method === http.RequestMethod.POST || method === http.RequestMethod.PUT)) {
        options.extraData = JSON.stringify(data);
      }
      
      httpRequest.request(fullUrl, options, (err, data) => {
        if (err) {
          console.error('HTTP request error:', err);
          reject({
            code: -1,
            message: '网络请求失败'
          });
          return;
        }
        
        try {
          const response = JSON.parse(data.result as string);
          
          // 处理401未授权
          if (response.code === 401) {
            this.clearToken();
          }
          
          resolve(response);
        } catch (parseErr) {
          reject({
            code: -1,
            message: '响应解析失败'
          });
        } finally {
          httpRequest.destroy();
        }
      });
    });
  }
  
  /**
   * GET请求
   */
  async get<T>(url: string, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.GET, url, undefined, needAuth);
  }
  
  /**
   * POST请求
   */
  async post<T>(url: string, data: any, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.POST, url, data, needAuth);
  }
  
  /**
   * PUT请求
   */
  async put<T>(url: string, data: any, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.PUT, url, data, needAuth);
  }
  
  /**
   * DELETE请求
   */
  async delete<T>(url: string, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.DELETE, url, undefined, needAuth);
  }
}
