/**
 * 后端数据模型定义
 * 定义所有与后端API交互的数据结构
 */

// ==================== 通用响应结构 ====================

/**
 * API响应基础结构
 */
export interface ApiResponse<T> {
  code: number;
  message: string;
  data?: T;
}

/**
 * 分页响应
 */
export interface PageResponse<T> {
  list: T[];
  total: number;
  page: number;
  pageSize: number;
}

// ==================== 用户相关 ====================

/**
 * 用户信息
 */
export interface UserInfo {
  id: number;
  phone: string;
  nickname: string;
  avatar?: string;
  token?: string;
  createdAt?: string;
}

/**
 * 用户注册请求
 */
export interface RegisterRequest {
  phone: string;
  password: string;
  nickname?: string;
}

/**
 * 用户登录请求
 */
export interface LoginRequest {
  phone: string;
  password: string;
}

/**
 * 更新用户信息请求
 */
export interface UpdateProfileRequest {
  nickname?: string;
  avatar?: string;
}

// ==================== 收藏相关 ====================

/**
 * 收藏地点
 */
export interface FavoritePlace {
  id: number;
  userId: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  category: 'home' | 'work' | 'custom';
  icon?: string;
  createdAt: string;
}

// ==================== 导航历史相关 ====================

/**
 * 导航历史
 */
export interface NavigationHistory {
  id: number;
  userId: number;
  startName?: string;
  startAddress?: string;
  startLat?: number;
  startLng?: number;
  endName: string;
  endAddress: string;
  endLat: number;
  endLng: number;
  distance: number;      // 米
  duration: number;      // 秒
  createdAt: string;
}

// ==================== 常去地点相关 ====================

/**
 * 常去地点
 */
export interface FrequentLocation {
  id: number;
  userId: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  visitCount: number;
  lastVisit: string;
  timePattern?: string;
}

/**
 * 常去地点时间模式统计
 */
export interface PatternStats {
  timePattern: string;
  count: number;
  totalVisits: number;
}

/**
 * 常去地点统计
 */
export interface FrequentLocationStats {
  totalVisits: number;
  locationCount: number;
  byPattern: Array<PatternStats>;
}

// ==================== 位置共享相关 ====================

/**
 * 用户位置
 */
export interface UserLocation {
  id: number;
  userId: number;
  latitude: number;
  longitude: number;
  accuracy: number;      // 精度（米）
  speed?: number;        // 速度（km/h）
  heading?: number;      // 方向（度）
  locationType: 'gps' | 'network' | 'ip';
  isSharing: boolean;
  updatedAt: string;
}

/**
 * 位置共享关系
 */
export interface LocationShare {
  id: number;
  sharerId: number;
  viewerId: number;
  expireTime?: string;
  isActive: boolean;
  createdAt: string;
  nickname?: string;     // 对方昵称
  phone?: string;        // 对方手机号
}

/**
 * 附近用户
 */
export interface NearbyUser {
  id: number;
  userId: number;
  latitude: number;
  longitude: number;
  speed?: number;
  heading?: number;
  locationType: string;
  isSharing: boolean;
  updatedAt: string;
  nickname: string;
  avatar?: string;
  distance: number;      // 距离（米）
}

// ==================== 反馈相关 ====================

/**
 * 导航反馈
 */
export interface NavigationFeedback {
  id: number;
  userId: number;
  navigationId?: number;
  rating: number;        // 1-5星
  feedbackType: 'route' | 'traffic' | 'poi';
  content: string;
  locationLat?: number;
  locationLng?: number;
  createdAt: string;
}

/**
 * 反馈类型统计
 */
export interface FeedbackTypeStats {
  feedbackType: string;
  count: number;
  avgRating: number;
}

/**
 * 反馈统计
 */
export interface FeedbackStats {
  total: number;
  avgRating: number;
  byType: Array<FeedbackTypeStats>;
}

// ==================== 缓存相关 ====================

/**
 * 缓存元数据
 */
export interface CacheMetadata {
  key: string;
  timestamp: number;
  expireTime?: number;
}
