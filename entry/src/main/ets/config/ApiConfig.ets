/**
 * API配置类
 * 集中管理所有API端点和配置
 */

/**
 * API端点接口
 */
interface ApiEndpoints {
  AUTH_REGISTER: string;
  AUTH_LOGIN: string;
  AUTH_PROFILE: string;
  FAVORITES: string;
  FAVORITE_DETAIL: (id: number) => string;
  NAVIGATION_HISTORY: string;
  NAVIGATION_HISTORY_DETAIL: (id: number) => string;
  FREQUENT_LOCATIONS: string;
  FREQUENT_LOCATIONS_VISIT: string;
  FREQUENT_LOCATIONS_RECOMMENDED: string;
  FREQUENT_LOCATIONS_STATS: string;
  FREQUENT_LOCATIONS_DETAIL: (id: number) => string;
  LOCATION: string;
  LOCATION_USER: (userId: number) => string;
  LOCATION_SHARING_TOGGLE: string;
  LOCATION_SHARING: string;
  LOCATION_SHARING_DETAIL: (id: number) => string;
  LOCATION_NEARBY: string;
  FEEDBACK: string;
  FEEDBACK_STATS: string;
  FEEDBACK_DETAIL: (id: number) => string;
  MEDIA_RESOURCES: string;
}

/**
 * 缓存过期时间配置接口
 */
interface CacheExpireConfig {
  FAVORITES: number;
  HISTORY: number;
  FREQUENT: number;
  USER_INFO: number;
  MEDIA: number;
}

export class ApiConfig {
  static readonly ENV: 'development' | 'production' = 'development';
  static readonly DEV_HOST = 'http://192.168.26.191:3002';
  static readonly PROD_HOST = 'https://your-domain.com';
  static readonly BASE_URL = ApiConfig.ENV === 'development'
    ? `${ApiConfig.DEV_HOST}/api/v1`
    : `${ApiConfig.PROD_HOST}/api/v1`;
  static readonly TIMEOUT = 30000;
  static readonly TOKEN_KEY = 'auth_token';
  static readonly USER_KEY = 'user_info';

  static readonly ENDPOINTS: ApiEndpoints = {
    AUTH_REGISTER: '/auth/register',
    AUTH_LOGIN: '/auth/login',
    AUTH_PROFILE: '/auth/profile',
    FAVORITES: '/favorites',
    FAVORITE_DETAIL: (id: number): string => `/favorites/${id}`,
    NAVIGATION_HISTORY: '/navigation/history',
    NAVIGATION_HISTORY_DETAIL: (id: number): string => `/navigation/history/${id}`,
    FREQUENT_LOCATIONS: '/frequent-locations',
    FREQUENT_LOCATIONS_VISIT: '/frequent-locations/visit',
    FREQUENT_LOCATIONS_RECOMMENDED: '/frequent-locations/recommended',
    FREQUENT_LOCATIONS_STATS: '/frequent-locations/stats',
    FREQUENT_LOCATIONS_DETAIL: (id: number): string => `/frequent-locations/${id}`,
    LOCATION: '/location',
    LOCATION_USER: (userId: number): string => `/location/${userId}`,
    LOCATION_SHARING_TOGGLE: '/location/sharing/toggle',
    LOCATION_SHARING: '/location/sharing',
    LOCATION_SHARING_DETAIL: (id: number): string => `/location/sharing/${id}`,
    LOCATION_NEARBY: '/location/nearby',
    FEEDBACK: '/feedback',
    FEEDBACK_STATS: '/feedback/stats',
    FEEDBACK_DETAIL: (id: number): string => `/feedback/${id}`,
    MEDIA_RESOURCES: '/media/resources'
  };

  static readonly CACHE_EXPIRE_TIME: CacheExpireConfig = {
    FAVORITES: 3600000,
    HISTORY: 3600000,
    FREQUENT: 7200000,
    USER_INFO: 86400000,
    MEDIA: 86400000
  };
}
