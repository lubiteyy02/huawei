/**
 * 缓存服务
 * 使用HarmonyOS Preferences API实现本地数据缓存
 */
import preferences from '@ohos.data.preferences';
import { CacheMetadata } from '../models/BackendModels';

export class CacheService {
  private static instance: CacheService;
  private preferencesInstance: preferences.Preferences | null = null;
  private readonly PREFERENCES_NAME = 'app_cache';
  private readonly METADATA_SUFFIX = '_metadata';
  
  private constructor() {
    this.initPreferences();
  }
  
  /**
   * 获取单例实例
   */
  static getInstance(): CacheService {
    if (!CacheService.instance) {
      CacheService.instance = new CacheService();
    }
    return CacheService.instance;
  }
  
  /**
   * 初始化Preferences
   */
  private async initPreferences(): Promise<void> {
    try {
      const context = getContext();
      this.preferencesInstance = await preferences.getPreferences(context, this.PREFERENCES_NAME);
      console.log('[CacheService] Preferences初始化成功');
    } catch (err) {
      console.error('[CacheService] Preferences初始化失败:', JSON.stringify(err));
    }
  }
  
  /**
   * 确保Preferences已初始化
   */
  private async ensurePreferences(): Promise<preferences.Preferences> {
    if (!this.preferencesInstance) {
      await this.initPreferences();
    }
    if (!this.preferencesInstance) {
      throw new Error('Preferences未初始化');
    }
    return this.preferencesInstance;
  }
  
  /**
   * 保存缓存
   * @param key 缓存键
   * @param value 缓存值
   * @param expireTime 过期时间（毫秒），可选
   */
  async set<T>(key: string, value: T, expireTime?: number): Promise<void> {
    try {
      const prefs = await this.ensurePreferences();
      
      // 保存数据
      const jsonValue = JSON.stringify(value);
      await prefs.put(key, jsonValue);
      
      // 保存元数据
      const metadata: CacheMetadata = {
        key,
        timestamp: Date.now(),
        expireTime
      };
      await prefs.put(key + this.METADATA_SUFFIX, JSON.stringify(metadata));
      
      await prefs.flush();
      console.log(`[CacheService] 缓存已保存: ${key}`);
    } catch (err) {
      console.error(`[CacheService] 保存缓存失败: ${key}`, err);
      throw new Error(`保存缓存失败: ${String(err)}`);
    }
  }
  
  /**
   * 获取缓存
   * @param key 缓存键
   * @returns 缓存值，如果不存在或已过期返回null
   */
  async get<T>(key: string): Promise<T | null> {
    try {
      const prefs = await this.ensurePreferences();
      
      // 检查是否过期
      const isExpired = await this.isExpired(key);
      if (isExpired) {
        console.log(`[CacheService] 缓存已过期: ${key}`);
        await this.remove(key);
        return null;
      }
      
      // 获取数据
      const jsonValue = await prefs.get(key, '');
      if (!jsonValue || jsonValue === '') {
        return null;
      }
      
      const value = JSON.parse(jsonValue as string) as T;
      console.log(`[CacheService] 缓存命中: ${key}`);
      return value;
    } catch (err) {
      console.error(`[CacheService] 获取缓存失败: ${key}`, err);
      return null;
    }
  }
  
  /**
   * 删除缓存
   * @param key 缓存键
   */
  async remove(key: string): Promise<void> {
    try {
      const prefs = await this.ensurePreferences();
      await prefs.delete(key);
      await prefs.delete(key + this.METADATA_SUFFIX);
      await prefs.flush();
      console.log(`[CacheService] 缓存已删除: ${key}`);
    } catch (err) {
      console.error(`[CacheService] 删除缓存失败: ${key}`, err);
    }
  }
  
  /**
   * 清除所有缓存
   */
  async clear(): Promise<void> {
    try {
      const prefs = await this.ensurePreferences();
      await prefs.clear();
      await prefs.flush();
      console.log('[CacheService] 所有缓存已清除');
    } catch (err) {
      console.error('[CacheService] 清除缓存失败:', err);
      throw new Error(`清除缓存失败: ${String(err)}`);
    }
  }
  
  /**
   * 检查缓存是否过期
   * @param key 缓存键
   * @returns true表示已过期，false表示未过期
   */
  async isExpired(key: string): Promise<boolean> {
    try {
      const metadata = await this.getCacheMetadata(key);
      if (!metadata) {
        return true;
      }
      
      // 如果没有设置过期时间，则永不过期
      if (!metadata.expireTime) {
        return false;
      }
      
      const now = Date.now();
      const expireAt = metadata.timestamp + metadata.expireTime;
      return now > expireAt;
    } catch (err) {
      console.error(`[CacheService] 检查过期失败: ${key}`, err);
      return true;
    }
  }
  
  /**
   * 获取缓存元数据
   * @param key 缓存键
   * @returns 缓存元数据，如果不存在返回null
   */
  private async getCacheMetadata(key: string): Promise<CacheMetadata | null> {
    try {
      const prefs = await this.ensurePreferences();
      const metadataJson = await prefs.get(key + this.METADATA_SUFFIX, '');
      
      if (!metadataJson || metadataJson === '') {
        return null;
      }
      
      return JSON.parse(metadataJson as string) as CacheMetadata;
    } catch (err) {
      console.error(`[CacheService] 获取元数据失败: ${key}`, err);
      return null;
    }
  }
}
