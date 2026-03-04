/**
 * 导航相关数据模型
 */

/**
 * 标记类型枚举
 */
export enum MarkerType {
  START = 'start',       // 起点
  END = 'end',           // 终点
  POI = 'poi',           // 兴趣点
  CURRENT = 'current'    // 当前位置
}

/**
 * 位置信息
 */
export interface Location {
  latitude: number;
  longitude: number;
  address?: string;
  name?: string;
}

/**
 * 路线信息
 */
export interface RouteInfo {
  id?: string;
  distance: number;        // 总距离（米）
  duration: number;        // 总时间（秒）
  polyline: string;        // 路线坐标编码
  steps: RouteStep[];      // 路线步骤
  strategy?: number;       // 路线策略
  tollDistance?: number;   // 收费路段距离
  tollCost?: number;       // 预计过路费
  trafficLights?: number;  // 红绿灯数量
}

/**
 * 路线步骤
 */
export interface RouteStep {
  instruction: string;     // 指令文字
  distance: number;        // 该步骤距离（米）
  duration: number;        // 该步骤时间（秒）
  road: string;            // 道路名称
  action: string;          // 动作类型：直行、左转、右转等
  orientation?: string;    // 方向：东、南、西、北
}

/**
 * POI（兴趣点）信息
 */
export interface POIInfo {
  id: string;
  name: string;
  address: string;
  location: Location;
  distance: number;        // 距离当前位置（米）
  category: string;        // 分类
  categoryCode?: string;   // 分类代码
  phone?: string;          // 电话
  rating?: number;         // 评分
  photos?: string[];       // 图片
  businessHours?: string;  // 营业时间
}

/**
 * POI搜索结果（别名）
 */
export type POIResult = POIInfo;

/**
 * 收藏地点
 */
export interface FavoritePlace {
  id?: number;
  userId?: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  category: 'home' | 'work' | 'custom';
  icon?: string;
  createdAt?: string;
}

/**
 * 导航历史记录
 */
export interface NavigationHistory {
  id?: number;
  userId?: number;
  startName?: string;
  startAddress?: string;
  startLat?: number;
  startLng?: number;
  endName: string;
  endAddress: string;
  endLat: number;
  endLng: number;
  distance?: number;       // 米
  duration?: number;       // 秒
  createdAt?: string;
}

/**
 * 行程记录
 */
export interface TripRecord {
  id?: number;
  userId?: number;
  startTime: string;
  endTime?: string;
  totalDistance?: number;  // 米
  totalDuration?: number;  // 秒
  avgSpeed?: number;       // km/h
  maxSpeed?: number;       // km/h
  trajectory?: TrajectoryPoint[];  // 轨迹点
  createdAt?: string;
}

/**
 * 轨迹点
 */
export interface TrajectoryPoint {
  latitude: number;
  longitude: number;
  timestamp: number;
  speed?: number;
  heading?: number;
}

/**
 * 搜索历史
 */
export interface SearchHistory {
  id?: number;
  userId?: number;
  keyword: string;
  resultCount?: number;
  createdAt?: string;
}

/**
 * 用户信息
 */
export interface UserInfo {
  id?: number;
  phone: string;
  nickname?: string;
  avatar?: string;
  token?: string;
  createdAt?: string;
}

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
