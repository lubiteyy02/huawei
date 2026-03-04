/**
 * HTTP服务 - 封装网络请求
 * 统一处理HTTP通信、Token管理、错误处理
 */
import http from '@ohos.net.http';
import preferences from '@ohos.data.preferences';
import { ApiResponse } from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * HTTP服务类
 */
export class HttpService {
  private static instance: HttpService;
  private token: string = '';
  private preferencesInstance: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME = 'app_auth';
  
  private constructor() {
    // 从本地存储加载token
    this.initPreferences();
  }
  
  static getInstance(): HttpService {
    if (!HttpService.instance) {
      HttpService.instance = new HttpService();
    }
    return HttpService.instance;
  }
  
  /**
   * 初始化Preferences
   */
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext();
      this.preferencesInstance = await preferences.getPreferences(context, this.PREFERENCES_NAME);
      await this.loadToken();
      console.log('[HttpService] Preferences初始化成功');
    } catch (err) {
      console.error('[HttpService] Preferences初始化失败:', JSON.stringify(err));
    }
  }
  
  /**
   * 设置认证token
   */
  async setToken(token: string): Promise<void> {
    this.token = token;
    await this.saveToken(token);
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
  async clearToken(): Promise<void> {
    this.token = '';
    try {
      if (this.preferencesInstance) {
        await this.preferencesInstance.delete(ApiConfig.TOKEN_KEY);
        await this.preferencesInstance.flush();
        console.log('[HttpService] Token已清除');
      }
    } catch (err) {
      console.error('[HttpService] 清除Token失败:', JSON.stringify(err));
    }
  }
  
  /**
   * 保存token到Preferences
   */
  private async saveToken(token: string): Promise<void> {
    try {
      if (this.preferencesInstance) {
        await this.preferencesInstance.put(ApiConfig.TOKEN_KEY, token);
        await this.preferencesInstance.flush();
        console.log('[HttpService] Token已保存');
      }
    } catch (err) {
      console.error('[HttpService] 保存Token失败:', JSON.stringify(err));
    }
  }
  
  /**
   * 从Preferences加载token
   */
  private async loadToken(): Promise<void> {
    try {
      if (this.preferencesInstance) {
        const token = await this.preferencesInstance.get(ApiConfig.TOKEN_KEY, '');
        if (token && token !== '') {
          this.token = token as string;
          console.log('[HttpService] Token已加载');
        }
      }
    } catch (err) {
      console.error('[HttpService] 加载Token失败:', JSON.stringify(err));
    }
  }
  
  /**
   * 发送HTTP请求
   */
  private async request<T>(
    method: http.RequestMethod,
    url: string,
    data?: Object,
    needAuth: boolean = true
  ): Promise<ApiResponse<T>> {
    return new Promise((resolve, reject) => {
      const httpRequest = http.createHttp();
      
      const fullUrl = `${ApiConfig.BASE_URL}${url}`;
      console.log(`[HttpService] ========== 请求详情 ==========`);
      console.log(`[HttpService] 方法: ${method}`);
      console.log(`[HttpService] BASE_URL: ${ApiConfig.BASE_URL}`);
      console.log(`[HttpService] 路径: ${url}`);
      console.log(`[HttpService] 完整URL: ${fullUrl}`);
      console.log(`[HttpService] ================================`);
      
      const headers: Record<string, string> = {
        'Content-Type': 'application/json'
      };
      
      // 添加认证头
      if (needAuth && this.token) {
        headers['Authorization'] = `Bearer ${this.token}`;
      }
      
      const options: http.HttpRequestOptions = {
        method,
        header: headers,
        readTimeout: ApiConfig.TIMEOUT,
        connectTimeout: ApiConfig.TIMEOUT
      };
      
      // 添加请求体
      if (data && (method === http.RequestMethod.POST || method === http.RequestMethod.PUT)) {
        options.extraData = JSON.stringify(data);
        console.log('[HttpService] 请求数据:', JSON.stringify(data));
      }
      
      console.log('[HttpService] 开始发送请求...');
      
      httpRequest.request(fullUrl, options, (err: Error, data: http.HttpResponse) => {
        console.log('[HttpService] 收到响应回调');
        
        if (err) {
          console.error('[HttpService] ========== 错误详情 ==========');
          console.error('[HttpService] 请求失败:', JSON.stringify(err));
          console.error('[HttpService] ================================');
          const errorMessage = this.getErrorMessage(err);
          reject({
            code: -1,
            message: errorMessage
          });
          httpRequest.destroy();
          return;
        }
        
        try {
          const responseCode = data.responseCode;
          const resultString = data.result as string;
          
          console.log(`[HttpService] ========== 响应详情 ==========`);
          console.log(`[HttpService] HTTP状态码: ${responseCode}`);
          console.log(`[HttpService] 响应内容: ${resultString}`);
          console.log(`[HttpService] 响应头: ${JSON.stringify(data.header)}`);
          console.log(`[HttpService] ================================`);
          
          // 尝试解析响应体
          let response: ApiResponse<T>;
          try {
            response = JSON.parse(resultString) as ApiResponse<T>;
          } catch (parseErr) {
            console.error('[HttpService] 响应解析失败:', JSON.stringify(parseErr));
            // 如果解析失败，使用HTTP状态码生成错误信息
            reject({
              code: responseCode,
              message: this.getHttpStatusMessage(responseCode)
            });
            httpRequest.destroy();
            return;
          }
          
          // 处理HTTP状态码
          if (responseCode !== 200 && responseCode !== 201) {
            // 返回后端的实际错误信息
            reject(response);
            httpRequest.destroy();
            return;
          }
          
          // 处理401未授权
          if (response.code === 401) {
            console.log('[HttpService] Token无效，清除本地token');
            this.clearToken();
          }
          
          console.log(`[HttpService] 请求成功: ${response.code} ${response.message}`);
          resolve(response);
        } catch (parseErr) {
          console.error('[HttpService] 响应解析失败:', JSON.stringify(parseErr));
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
   * 获取错误信息
   */
  private getErrorMessage(err: Error): string {
    const errorStr = JSON.stringify(err);
    const errorObj = JSON.parse(errorStr) as Record<string, Object>;
    const errorCode = errorObj['code'] as number;
    
    // 网络错误映射
    const errorMap: Record<number, string> = {
      2300001: '协议不支持',
      2300003: 'URL格式错误',
      2300005: '无法解析远程主机名',
      2300006: '无法连接到服务器',
      2300007: '无法连接到代理服务器',
      2300008: '无效的服务器响应',
      2300009: '远程服务器拒绝访问',
      2300023: '写入数据失败',
      2300025: '上传失败',
      2300026: '读取数据失败',
      2300027: '内存不足',
      2300028: '操作超时',
      2300047: '请求数量过多',
      2300052: '服务器返回空数据',
      2300055: '发送网络数据失败',
      2300056: '接收网络数据失败',
      2300058: '本地SSL证书问题',
      2300059: '无法使用指定的SSL加密',
      2300060: '远程SSL证书无效',
      2300077: 'SSL CA证书无效',
      2300078: '远程服务器无法访问'
    };
    
    return errorMap[errorCode] || '网络请求失败';
  }
  
  /**
   * 获取HTTP状态码对应的错误信息
   */
  private getHttpStatusMessage(statusCode: number): string {
    const statusMap: Record<number, string> = {
      400: '请求参数错误',
      401: '登录已过期，请重新登录',
      403: '无权限访问',
      404: '请求的资源不存在',
      500: '服务器错误，请稍后重试',
      502: '网关错误',
      503: '服务暂时不可用，请稍后重试',
      504: '网关超时'
    };
    
    return statusMap[statusCode] || `请求失败 (${statusCode})`;
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
  async post<T>(url: string, data: Object, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.POST, url, data, needAuth);
  }
  
  /**
   * PUT请求
   */
  async put<T>(url: string, data: Object, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.PUT, url, data, needAuth);
  }
  
  /**
   * DELETE请求
   */
  async delete<T>(url: string, needAuth: boolean = true): Promise<ApiResponse<T>> {
    return this.request<T>(http.RequestMethod.DELETE, url, undefined, needAuth);
  }
}
