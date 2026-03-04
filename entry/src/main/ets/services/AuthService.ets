/**
 * 认证服务 - 管理用户认证、注册、登录和登出
 */
import preferences from '@ohos.data.preferences';
import { HttpService } from './HttpService';
import { 
  ApiResponse, 
  UserInfo, 
  RegisterRequest, 
  LoginRequest, 
  UpdateProfileRequest 
} from '../models/BackendModels';
import { ApiConfig } from '../config/ApiConfig';

/**
 * 认证服务类
 */
export class AuthService {
  private static instance: AuthService;
  private httpService: HttpService;
  private currentUser: UserInfo | null = null;
  private preferencesInstance: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME = 'app_auth';
  
  private constructor() {
    this.httpService = HttpService.getInstance();
    this.initPreferences();
  }
  
  static getInstance(): AuthService {
    if (!AuthService.instance) {
      AuthService.instance = new AuthService();
    }
    return AuthService.instance;
  }
  
  /**
   * 初始化Preferences
   */
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext();
      this.preferencesInstance = await preferences.getPreferences(context, this.PREFERENCES_NAME);
      await this.loadUserInfo();
      console.log('[AuthService] Preferences初始化成功');
    } catch (err) {
      console.error('[AuthService] Preferences初始化失败:', JSON.stringify(err));
    }
  }

  /**
   * 用户注册
   */
  async register(phone: string, password: string, nickname?: string): Promise<ApiResponse<UserInfo>> {
    try {
      console.log('[AuthService] 注册用户:', phone);
      
      // 只包含有值的字段
      const requestData: RegisterRequest = { phone, password };
      if (nickname && nickname.trim() !== '') {
        requestData.nickname = nickname;
      }
      
      const response = await this.httpService.post<UserInfo>(
        ApiConfig.ENDPOINTS.AUTH_REGISTER,
        requestData,
        false  // 注册不需要认证
      );
      
      if (response.code === 200 && response.data) {
        // 保存token和用户信息
        if (response.data.token) {
          await this.httpService.setToken(response.data.token);
          await this.saveUserInfo(response.data);
          this.currentUser = response.data;
        }
      }
      
      return response;
    } catch (err) {
      console.error('[AuthService] 注册失败:', JSON.stringify(err));
      return err as ApiResponse<UserInfo>;
    }
  }
  
  /**
   * 用户登录
   */
  async login(phone: string, password: string): Promise<ApiResponse<UserInfo>> {
    try {
      console.log('[AuthService] 用户登录:', phone);
      
      const requestData: LoginRequest = { phone, password };
      
      const response = await this.httpService.post<UserInfo>(
        ApiConfig.ENDPOINTS.AUTH_LOGIN,
        requestData,
        false  // 登录不需要认证
      );
      
      if (response.code === 200 && response.data) {
        // 保存token和用户信息
        if (response.data.token) {
          await this.httpService.setToken(response.data.token);
          await this.saveUserInfo(response.data);
          this.currentUser = response.data;
        }
      }
      
      return response;
    } catch (err) {
      console.error('[AuthService] 登录失败:', err);
      return err as ApiResponse<UserInfo>;
    }
  }
  
  /**
   * 获取用户信息
   */
  async getProfile(): Promise<ApiResponse<UserInfo>> {
    try {
      console.log('[AuthService] 获取用户信息');
      
      const response = await this.httpService.get<UserInfo>(
        ApiConfig.ENDPOINTS.AUTH_PROFILE,
        true  // 需要认证
      );
      
      if (response.code === 200 && response.data) {
        await this.saveUserInfo(response.data);
        this.currentUser = response.data;
      }
      
      return response;
    } catch (err) {
      console.error('[AuthService] 获取用户信息失败:', err);
      return err as ApiResponse<UserInfo>;
    }
  }
  
  /**
   * 更新用户信息
   */
  async updateProfile(nickname?: string, avatar?: string): Promise<ApiResponse<void>> {
    try {
      console.log('[AuthService] 更新用户信息');
      
      // 只包含有值的字段
      const requestData: UpdateProfileRequest = {};
      if (nickname && nickname.trim() !== '') {
        requestData.nickname = nickname;
      }
      if (avatar && avatar.trim() !== '') {
        requestData.avatar = avatar;
      }
      
      const response = await this.httpService.put<void>(
        ApiConfig.ENDPOINTS.AUTH_PROFILE,
        requestData,
        true  // 需要认证
      );
      
      if (response.code === 200) {
        // 更新本地用户信息
        if (this.currentUser) {
          if (nickname) this.currentUser.nickname = nickname;
          if (avatar) this.currentUser.avatar = avatar;
          await this.saveUserInfo(this.currentUser);
        }
      }
      
      return response;
    } catch (err) {
      console.error('[AuthService] 更新用户信息失败:', err);
      return err as ApiResponse<void>;
    }
  }
  
  /**
   * 登出
   */
  async logout(): Promise<void> {
    try {
      console.log('[AuthService] 用户登出');
      
      // 清除token
      await this.httpService.clearToken();
      
      // 清除用户信息
      if (this.preferencesInstance) {
        await this.preferencesInstance.delete(ApiConfig.USER_KEY);
        await this.preferencesInstance.flush();
      }
      
      this.currentUser = null;
      console.log('[AuthService] 登出成功');
    } catch (err) {
      console.error('[AuthService] 登出失败:', err);
    }
  }
  
  /**
   * 检查登录状态
   */
  async isLoggedIn(): Promise<boolean> {
    const token = this.httpService.getToken();
    return token !== '' && token !== null && token !== undefined;
  }
  
  /**
   * 获取当前用户
   */
  async getCurrentUser(): Promise<UserInfo | null> {
    if (this.currentUser) {
      return this.currentUser;
    }
    
    // 尝试从本地存储加载
    await this.loadUserInfo();
    return this.currentUser;
  }
  
  /**
   * 保存用户信息到Preferences
   */
  private async saveUserInfo(userInfo: UserInfo): Promise<void> {
    try {
      if (this.preferencesInstance) {
        await this.preferencesInstance.put(ApiConfig.USER_KEY, JSON.stringify(userInfo));
        await this.preferencesInstance.flush();
        console.log('[AuthService] 用户信息已保存');
      }
    } catch (err) {
      console.error('[AuthService] 保存用户信息失败:', err);
    }
  }
  
  /**
   * 从Preferences加载用户信息
   */
  private async loadUserInfo(): Promise<void> {
    try {
      if (this.preferencesInstance) {
        const userInfoStr = await this.preferencesInstance.get(ApiConfig.USER_KEY, '');
        if (userInfoStr && userInfoStr !== '') {
          this.currentUser = JSON.parse(userInfoStr as string) as UserInfo;
          console.log('[AuthService] 用户信息已加载');
        }
      }
    } catch (err) {
      console.error('[AuthService] 加载用户信息失败:', err);
    }
  }
}
