# Backend Integration Design Document

## Overview

本设计文档描述了HarmonyOS导航应用前端与Node.js后端服务的集成架构。后端服务已完成开发，提供用户认证、收藏管理、导航历史、常去地点、位置共享和反馈等功能。前端将使用ArkTS和HarmonyOS原生API（@ohos.net.http、@ohos.data.preferences）实现完整的后端集成。

### 设计目标

1. **统一的HTTP通信层**：封装所有网络请求，提供一致的错误处理和认证机制
2. **可靠的数据持久化**：使用Preferences存储用户凭证和缓存数据
3. **清晰的服务层架构**：每个业务功能对应独立的服务类
4. **完善的错误处理**：网络异常、认证失败、数据解析错误等场景的统一处理
5. **离线数据支持**：关键数据的本地缓存，提升用户体验

### 技术栈

- **前端框架**：ArkTS (HarmonyOS)
- **HTTP客户端**：@ohos.net.http
- **数据持久化**：@ohos.data.preferences
- **后端服务**：Node.js + Express + TypeScript + MySQL
- **认证方式**：JWT (JSON Web Token)
- **数据格式**：JSON

## Architecture

### 系统架构图

```
┌─────────────────────────────────────────────────────────────┐
│                     HarmonyOS Frontend                       │
├─────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  UI Layer    │  │  UI Layer    │  │  UI Layer    │      │
│  │  LoginPage   │  │ FavoritesPage│  │  HistoryPage │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                  │
│  ┌─────────────────────────┴─────────────────────────────┐  │
│  │              Service Layer (业务逻辑层)                │  │
│  ├───────────────────────────────────────────────────────┤  │
│  │  AuthService  │  FavoriteService  │  HistoryService   │  │
│  │  LocationService  │  FeedbackService  │  CacheService │  │
│  └─────────────────────────┬─────────────────────────────┘  │
│                            │                                  │
│  ┌─────────────────────────┴─────────────────────────────┐  │
│  │           HttpService (HTTP通信层)                     │  │
│  │  - 请求封装  - Token管理  - 错误处理  - 超时控制     │  │
│  └─────────────────────────┬─────────────────────────────┘  │
│                            │                                  │
│  ┌─────────────────────────┴─────────────────────────────┐  │
│  │        @ohos.net.http (HarmonyOS HTTP API)            │  │
│  └─────────────────────────┬─────────────────────────────┘  │
│                            │                                  │
│  ┌─────────────────────────┴─────────────────────────────┐  │
│  │    @ohos.data.preferences (本地存储)                  │  │
│  │    - Token存储  - 用户信息  - 数据缓存               │  │
│  └───────────────────────────────────────────────────────┘  │
│                                                               │
└───────────────────────────┬───────────────────────────────────┘
                            │ HTTP/JSON
                            │
┌───────────────────────────┴───────────────────────────────────┐
│                    Backend Server                              │
├─────────────────────────────────────────────────────────────┤
│  Node.js + Express + TypeScript                              │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │   Auth API   │  │ Favorites API│  │  History API │      │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘      │
│         │                  │                  │               │
│         └──────────────────┼──────────────────┘               │
│                            │                                  │
│                    ┌───────┴────────┐                        │
│                    │  MySQL Database │                        │
│                    └─────────────────┘                        │
└─────────────────────────────────────────────────────────────┘
```

### 数据流向

1. **用户操作** → UI Layer
2. **UI Layer** → Service Layer (调用业务服务)
3. **Service Layer** → HttpService (发起HTTP请求)
4. **HttpService** → @ohos.net.http (执行网络请求)
5. **@ohos.net.http** → Backend Server (HTTP/JSON)
6. **Backend Server** → MySQL Database (数据持久化)
7. **响应数据** 按相反路径返回
8. **关键数据** → @ohos.data.preferences (本地缓存)

### 分层职责

#### UI Layer (UI层)
- 用户交互界面
- 数据展示和输入验证
- 调用Service Layer的方法
- 处理UI状态和加载提示

#### Service Layer (服务层)
- 业务逻辑封装
- 数据转换和验证
- 调用HttpService进行网络通信
- 管理本地缓存

#### HttpService (HTTP通信层)
- 统一的HTTP请求封装
- Token自动注入
- 错误统一处理
- 请求超时控制

#### Storage Layer (存储层)
- Token持久化
- 用户信息存储
- 数据缓存管理

## Components and Interfaces

### 1. HttpService (HTTP通信服务)

**职责**：封装所有HTTP请求，提供统一的网络通信接口

**接口定义**：

```typescript
class HttpService {
  // 单例模式
  static getInstance(): HttpService
  
  // Token管理
  setToken(token: string): void
  getToken(): string
  clearToken(): void
  
  // HTTP方法
  get<T>(url: string, needAuth?: boolean): Promise<ApiResponse<T>>
  post<T>(url: string, data: any, needAuth?: boolean): Promise<ApiResponse<T>>
  put<T>(url: string, data: any, needAuth?: boolean): Promise<ApiResponse<T>>
  delete<T>(url: string, needAuth?: boolean): Promise<ApiResponse<T>>
  
  // 私有方法
  private request<T>(method: RequestMethod, url: string, data?: any, needAuth?: boolean): Promise<ApiResponse<T>>
  private loadToken(): Promise<void>
  private saveToken(token: string): Promise<void>
}
```

**关键特性**：
- 单例模式，全局唯一实例
- 自动添加Authorization头
- 401响应自动清除token
- 30秒请求超时
- 统一错误处理

### 2. AuthService (认证服务)

**职责**：管理用户认证、注册、登录和登出

**接口定义**：

```typescript
class AuthService {
  static getInstance(): AuthService
  
  // 用户注册
  register(phone: string, password: string, nickname?: string): Promise<ApiResponse<UserInfo>>
  
  // 用户登录
  login(phone: string, password: string): Promise<ApiResponse<UserInfo>>
  
  // 获取用户信息
  getProfile(): Promise<ApiResponse<UserInfo>>
  
  // 更新用户信息
  updateProfile(nickname?: string, avatar?: string): Promise<ApiResponse<void>>
  
  // 登出
  logout(): Promise<void>
  
  // 检查登录状态
  isLoggedIn(): Promise<boolean>
  
  // 获取当前用户
  getCurrentUser(): Promise<UserInfo | null>
}
```

**API映射**：
- `POST /api/v1/auth/register` - 注册
- `POST /api/v1/auth/login` - 登录
- `GET /api/v1/auth/profile` - 获取用户信息

### 3. FavoriteService (收藏服务)

**职责**：管理用户收藏的地点

**接口定义**：

```typescript
class FavoriteService {
  static getInstance(): FavoriteService
  
  // 获取收藏列表
  getFavorites(category?: string): Promise<ApiResponse<FavoritePlace[]>>
  
  // 添加收藏
  addFavorite(place: FavoritePlace): Promise<ApiResponse<FavoritePlace>>
  
  // 更新收藏
  updateFavorite(id: number, updates: Partial<FavoritePlace>): Promise<ApiResponse<void>>
  
  // 删除收藏
  deleteFavorite(id: number): Promise<ApiResponse<void>>
  
  // 搜索收藏
  searchFavorites(keyword: string): Promise<FavoritePlace[]>
  
  // 缓存管理
  private cacheKey: string = 'favorites_cache'
  private getCachedFavorites(): Promise<FavoritePlace[]>
  private cacheFavorites(favorites: FavoritePlace[]): Promise<void>
}
```

**API映射**：
- `GET /api/v1/favorites` - 获取收藏列表
- `POST /api/v1/favorites` - 添加收藏
- `PUT /api/v1/favorites/:id` - 更新收藏
- `DELETE /api/v1/favorites/:id` - 删除收藏

### 4. NavigationHistoryService (导航历史服务)

**职责**：管理导航历史记录

**接口定义**：

```typescript
class NavigationHistoryService {
  static getInstance(): NavigationHistoryService
  
  // 获取历史记录
  getHistory(page?: number, pageSize?: number): Promise<ApiResponse<PageResponse<NavigationHistory>>>
  
  // 保存导航记录
  saveHistory(record: NavigationHistory): Promise<ApiResponse<void>>
  
  // 删除历史记录
  deleteHistory(id: number): Promise<ApiResponse<void>>
  
  // 清空历史记录
  clearHistory(): Promise<ApiResponse<void>>
  
  // 按日期筛选
  getHistoryByDateRange(startDate: string, endDate: string): Promise<ApiResponse<NavigationHistory[]>>
  
  // 缓存管理
  private cacheKey: string = 'history_cache'
  private getCachedHistory(): Promise<NavigationHistory[]>
  private cacheHistory(history: NavigationHistory[]): Promise<void>
}
```

**API映射**：
- `GET /api/v1/navigation/history` - 获取历史记录
- `POST /api/v1/navigation/history` - 保存历史记录
- `DELETE /api/v1/navigation/history/:id` - 删除历史记录
- `DELETE /api/v1/navigation/history` - 清空历史记录

### 5. FrequentLocationService (常去地点服务)

**职责**：管理和识别用户常去的地点

**接口定义**：

```typescript
class FrequentLocationService {
  static getInstance(): FrequentLocationService
  
  // 记录地点访问
  recordVisit(location: FrequentLocation): Promise<ApiResponse<void>>
  
  // 获取常去地点列表
  getFrequentLocations(limit?: number, minVisits?: number): Promise<ApiResponse<FrequentLocation[]>>
  
  // 获取智能推荐
  getRecommendations(timePattern?: string, limit?: number): Promise<ApiResponse<FrequentLocation[]>>
  
  // 获取访问统计
  getStats(): Promise<ApiResponse<FrequentLocationStats>>
  
  // 更新地点信息
  updateLocation(id: number, updates: Partial<FrequentLocation>): Promise<ApiResponse<void>>
  
  // 删除常去地点
  deleteLocation(id: number): Promise<ApiResponse<void>>
}
```

**API映射**：
- `POST /api/v1/frequent-locations/visit` - 记录访问
- `GET /api/v1/frequent-locations` - 获取常去地点
- `GET /api/v1/frequent-locations/recommended` - 获取推荐
- `GET /api/v1/frequent-locations/stats` - 获取统计
- `PUT /api/v1/frequent-locations/:id` - 更新地点
- `DELETE /api/v1/frequent-locations/:id` - 删除地点

### 6. LocationShareService (位置共享服务)

**职责**：管理用户之间的实时位置共享

**接口定义**：

```typescript
class LocationShareService {
  static getInstance(): LocationShareService
  
  // 更新用户位置
  updateLocation(location: UserLocation): Promise<ApiResponse<void>>
  
  // 获取用户位置
  getLocation(userId?: number): Promise<ApiResponse<UserLocation>>
  
  // 开启/关闭位置共享
  toggleSharing(isSharing: boolean): Promise<ApiResponse<void>>
  
  // 创建位置共享
  createShare(viewerId: number, expireHours?: number): Promise<ApiResponse<void>>
  
  // 获取共享列表
  getShares(type: 'sharing' | 'viewing'): Promise<ApiResponse<LocationShare[]>>
  
  // 取消位置共享
  cancelShare(shareId: number): Promise<ApiResponse<void>>
  
  // 获取附近用户
  getNearbyUsers(latitude: number, longitude: number, radius?: number): Promise<ApiResponse<NearbyUser[]>>
  
  // 自动更新位置（定时任务）
  private autoUpdateInterval: number = 30000  // 30秒
  startAutoUpdate(): void
  stopAutoUpdate(): void
}
```

**API映射**：
- `POST /api/v1/location` - 更新位置
- `GET /api/v1/location` - 获取自己的位置
- `GET /api/v1/location/:userId` - 获取其他用户位置
- `POST /api/v1/location/sharing/toggle` - 开启/关闭共享
- `POST /api/v1/location/sharing` - 创建共享
- `GET /api/v1/location/sharing` - 获取共享列表
- `DELETE /api/v1/location/sharing/:id` - 取消共享
- `GET /api/v1/location/nearby` - 获取附近用户

### 7. FeedbackService (反馈服务)

**职责**：管理用户对导航的反馈

**接口定义**：

```typescript
class FeedbackService {
  static getInstance(): FeedbackService
  
  // 提交反馈
  submitFeedback(feedback: NavigationFeedback): Promise<ApiResponse<void>>
  
  // 获取反馈列表
  getFeedbacks(feedbackType?: string, page?: number, pageSize?: number): Promise<ApiResponse<PageResponse<NavigationFeedback>>>
  
  // 获取反馈统计
  getStats(): Promise<ApiResponse<FeedbackStats>>
  
  // 获取反馈详情
  getFeedbackDetail(id: number): Promise<ApiResponse<NavigationFeedback>>
  
  // 删除反馈
  deleteFeedback(id: number): Promise<ApiResponse<void>>
}
```

**API映射**：
- `POST /api/v1/feedback` - 提交反馈
- `GET /api/v1/feedback` - 获取反馈列表
- `GET /api/v1/feedback/stats` - 获取统计
- `GET /api/v1/feedback/:id` - 获取详情
- `DELETE /api/v1/feedback/:id` - 删除反馈

### 8. CacheService (缓存服务)

**职责**：管理本地数据缓存

**接口定义**：

```typescript
class CacheService {
  static getInstance(): CacheService
  
  // 保存缓存
  set<T>(key: string, value: T, expireTime?: number): Promise<void>
  
  // 获取缓存
  get<T>(key: string): Promise<T | null>
  
  // 删除缓存
  remove(key: string): Promise<void>
  
  // 清除所有缓存
  clear(): Promise<void>
  
  // 检查缓存是否过期
  isExpired(key: string): Promise<boolean>
  
  // 获取缓存元数据
  private getCacheMetadata(key: string): Promise<CacheMetadata | null>
}

interface CacheMetadata {
  key: string
  timestamp: number
  expireTime?: number
}
```

**缓存策略**：
- 收藏列表：1小时过期
- 导航历史：最近50条，1小时过期
- 常去地点：2小时过期
- 用户信息：24小时过期

### 9. ApiConfig (API配置)

**职责**：集中管理API配置

**配置定义**：

```typescript
class ApiConfig {
  // 环境配置
  static readonly ENV: 'development' | 'production' = 'development'
  
  // 基础URL
  static readonly BASE_URL = ApiConfig.ENV === 'development' 
    ? 'http://localhost:3000/api/v1'
    : 'https://your-api.com/api/v1'
  
  // 超时配置
  static readonly TIMEOUT = 30000  // 30秒
  
  // Token存储key
  static readonly TOKEN_KEY = 'auth_token'
  static readonly USER_KEY = 'user_info'
  
  // API端点
  static readonly ENDPOINTS = {
    // 认证
    AUTH_REGISTER: '/auth/register',
    AUTH_LOGIN: '/auth/login',
    AUTH_PROFILE: '/auth/profile',
    
    // 收藏
    FAVORITES: '/favorites',
    FAVORITE_DETAIL: (id: number) => `/favorites/${id}`,
    
    // 导航历史
    NAVIGATION_HISTORY: '/navigation/history',
    NAVIGATION_HISTORY_DETAIL: (id: number) => `/navigation/history/${id}`,
    
    // 常去地点
    FREQUENT_LOCATIONS: '/frequent-locations',
    FREQUENT_LOCATIONS_VISIT: '/frequent-locations/visit',
    FREQUENT_LOCATIONS_RECOMMENDED: '/frequent-locations/recommended',
    FREQUENT_LOCATIONS_STATS: '/frequent-locations/stats',
    FREQUENT_LOCATIONS_DETAIL: (id: number) => `/frequent-locations/${id}`,
    
    // 位置共享
    LOCATION: '/location',
    LOCATION_USER: (userId: number) => `/location/${userId}`,
    LOCATION_SHARING_TOGGLE: '/location/sharing/toggle',
    LOCATION_SHARING: '/location/sharing',
    LOCATION_SHARING_DETAIL: (id: number) => `/location/sharing/${id}`,
    LOCATION_NEARBY: '/location/nearby',
    
    // 反馈
    FEEDBACK: '/feedback',
    FEEDBACK_STATS: '/feedback/stats',
    FEEDBACK_DETAIL: (id: number) => `/feedback/${id}`
  }
  
  // 缓存配置
  static readonly CACHE_EXPIRE_TIME = {
    FAVORITES: 3600000,      // 1小时
    HISTORY: 3600000,        // 1小时
    FREQUENT: 7200000,       // 2小时
    USER_INFO: 86400000      // 24小时
  }
}
```

## Data Models

### 前端数据模型

基于后端API响应，前端需要定义以下数据模型：

```typescript
// 用户信息
interface UserInfo {
  id: number
  phone: string
  nickname: string
  avatar?: string
  token?: string
  createdAt?: string
}

// 收藏地点
interface FavoritePlace {
  id: number
  userId: number
  name: string
  address: string
  latitude: number
  longitude: number
  category: 'home' | 'work' | 'custom'
  icon?: string
  createdAt: string
}

// 导航历史
interface NavigationHistory {
  id: number
  userId: number
  startName?: string
  startAddress?: string
  startLat?: number
  startLng?: number
  endName: string
  endAddress: string
  endLat: number
  endLng: number
  distance: number      // 米
  duration: number      // 秒
  createdAt: string
}

// 常去地点
interface FrequentLocation {
  id: number
  userId: number
  name: string
  address: string
  latitude: number
  longitude: number
  visitCount: number
  lastVisit: string
  timePattern?: string
}

// 常去地点统计
interface FrequentLocationStats {
  totalVisits: number
  locationCount: number
  byPattern: Array<{
    timePattern: string
    count: number
    totalVisits: number
  }>
}

// 用户位置
interface UserLocation {
  id: number
  userId: number
  latitude: number
  longitude: number
  accuracy: number      // 精度（米）
  speed?: number        // 速度（km/h）
  heading?: number      // 方向（度）
  locationType: 'gps' | 'network' | 'ip'
  isSharing: boolean
  updatedAt: string
}

// 位置共享关系
interface LocationShare {
  id: number
  sharerId: number
  viewerId: number
  expireTime?: string
  isActive: boolean
  createdAt: string
  nickname?: string     // 对方昵称
  phone?: string        // 对方手机号
}

// 附近用户
interface NearbyUser {
  id: number
  userId: number
  latitude: number
  longitude: number
  speed?: number
  heading?: number
  locationType: string
  isSharing: boolean
  updatedAt: string
  nickname: string
  avatar?: string
  distance: number      // 距离（米）
}

// 导航反馈
interface NavigationFeedback {
  id: number
  userId: number
  navigationId?: number
  rating: number        // 1-5星
  feedbackType: 'route' | 'traffic' | 'poi'
  content: string
  locationLat?: number
  locationLng?: number
  createdAt: string
}

// 反馈统计
interface FeedbackStats {
  total: number
  avgRating: number
  byType: Array<{
    feedbackType: string
    count: number
    avgRating: number
  }>
}

// API响应基础结构
interface ApiResponse<T> {
  code: number
  message: string
  data?: T
}

// 分页响应
interface PageResponse<T> {
  list: T[]
  total: number
  page: number
  pageSize: number
}
```

### 数据转换规则

1. **日期格式**：后端返回ISO 8601格式，前端转换为本地时间显示
2. **距离单位**：后端存储米，前端根据距离大小显示米或公里
3. **时长单位**：后端存储秒，前端转换为分钟或小时显示
4. **坐标精度**：保持7位小数精度
5. **空值处理**：后端null值转换为undefined或默认值


## Correctness Properties

*A property is a characteristic or behavior that should hold true across all valid executions of a system-essentially, a formal statement about what the system should do. Properties serve as the bridge between human-readable specifications and machine-verifiable correctness guarantees.*

### Property 1: Token自动注入

*For any* 需要认证的HTTP请求，当token存在时，请求头中应包含正确格式的Authorization字段（Bearer {token}）

**Validates: Requirements 1.2**

### Property 2: 请求失败返回标准错误对象

*For any* 失败的HTTP请求，返回的错误对象应包含code和message字段，且message不为空

**Validates: Requirements 1.4**

### Property 3: POST/PUT请求Content-Type设置

*For any* POST或PUT请求，请求头中应自动包含Content-Type: application/json

**Validates: Requirements 1.6**

### Property 4: Token持久化round trip

*For any* 有效的JWT token，存储到Preferences后再读取应得到相同的token值

**Validates: Requirements 2.2, 2.4, 3.2**

### Property 5: 登出清除所有认证数据

*For any* 已登录状态，执行登出操作后，Preferences中不应存在token和用户信息

**Validates: Requirements 2.6**

### Property 6: Token验证状态一致性

*For any* 应用启动场景，如果token无效或不存在，用户登录状态应为false

**Validates: Requirements 2.7, 2.8**

### Property 7: Token操作错误信息明确性

*For any* token操作（存储、读取、清除）失败时，返回的错误信息应非空且包含具体错误描述

**Validates: Requirements 3.5**

### Property 8: 收藏操作更新缓存

*For any* 成功的收藏操作（添加、更新、删除），本地缓存应反映最新的收藏列表状态

**Validates: Requirements 4.4**

### Property 9: 收藏搜索结果正确性

*For any* 收藏列表和搜索关键词，搜索结果中的所有项的name字段应包含该关键词（不区分大小写）

**Validates: Requirements 4.6**

### Property 10: 导航历史数据完整性

*For any* 保存的导航历史记录，应包含endName、endAddress、endLat、endLng四个必需字段

**Validates: Requirements 5.4**

### Property 11: 历史保存失败静默处理

*For any* 导航历史保存失败的场景，不应抛出异常或阻塞导航功能

**Validates: Requirements 5.5**

### Property 12: 常去地点按频率排序

*For any* 常去地点列表，列表应按visitCount降序排列

**Validates: Requirements 6.6**

### Property 13: 位置共享定时更新

*For any* 开启位置共享的会话，应每30秒（±2秒容差）自动调用位置更新接口

**Validates: Requirements 7.5**

### Property 14: 反馈自动附加位置信息

*For any* 提交的导航反馈，如果当前位置可用，反馈数据应包含locationLat和locationLng字段

**Validates: Requirements 8.3**

### Property 15: 登录输入验证

*For any* 空字符串或仅包含空白字符的用户名/密码，登录验证应拒绝并返回错误

**Validates: Requirements 9.3**

### Property 16: 注册密码一致性验证

*For any* 注册请求，如果两次密码输入不一致，验证应失败并返回明确的错误提示

**Validates: Requirements 9.7**

### Property 17: 删除收藏更新列表

*For any* 收藏列表，删除其中一项后，列表长度应减1且不包含被删除项

**Validates: Requirements 10.5**

### Property 18: 历史记录时间倒序

*For any* 导航历史列表，列表应按createdAt字段降序排列（最新的在前）

**Validates: Requirements 11.1**

### Property 19: 历史日期筛选正确性

*For any* 日期范围筛选，返回的历史记录的createdAt应在指定的开始和结束日期之间

**Validates: Requirements 11.4**

### Property 20: HTTP状态码错误信息映射

*For any* HTTP状态码（400, 401, 403, 404, 500等），应有对应的中文错误信息

**Validates: Requirements 12.5**

### Property 21: 数据序列化round trip

*For any* 可序列化的JavaScript对象，序列化为JSON后再反序列化应得到等价的对象

**Validates: Requirements 13.1, 13.2**

### Property 22: 序列化失败错误处理

*For any* 无法序列化的数据（如循环引用对象），应返回包含"序列化"关键词的错误信息

**Validates: Requirements 13.3**

### Property 23: 反序列化失败错误处理

*For any* 无效的JSON字符串，反序列化应返回包含"解析"或"反序列化"关键词的错误信息

**Validates: Requirements 13.4**

### Property 24: API响应类型匹配

*For any* API响应，反序列化后的对象应包含ApiResponse接口定义的code和message字段

**Validates: Requirements 13.5**

### Property 25: 环境配置切换

*For any* 环境变量（development/production），ApiConfig.BASE_URL应返回对应环境的URL

**Validates: Requirements 14.3, 14.6**

### Property 26: 缓存写入后可读取

*For any* 缓存数据，写入CacheService后立即读取应得到相同的数据

**Validates: Requirements 15.1, 15.3**

### Property 27: 网络不可用时使用缓存

*For any* 网络不可用的场景，服务应尝试从缓存读取数据而不是直接失败

**Validates: Requirements 15.2, 15.4**

### Property 28: 缓存过期时间设置

*For any* 缓存项，应包含timestamp和expireTime元数据

**Validates: Requirements 15.5**

### Property 29: 过期缓存自动刷新

*For any* 过期的缓存项，当网络可用时，下次访问应触发数据刷新

**Validates: Requirements 15.6**

## Error Handling

### 错误分类

系统将错误分为以下几类：

1. **网络错误**
   - 连接超时
   - 连接失败
   - 网络不可用
   - DNS解析失败

2. **HTTP错误**
   - 400 Bad Request - 请求参数错误
   - 401 Unauthorized - 未授权，token无效或过期
   - 403 Forbidden - 无权限
   - 404 Not Found - 资源不存在
   - 500 Internal Server Error - 服务器内部错误
   - 503 Service Unavailable - 服务不可用

3. **数据错误**
   - JSON解析失败
   - 数据验证失败
   - 类型不匹配

4. **存储错误**
   - Preferences读写失败
   - 缓存操作失败

### 错误处理策略

#### HttpService层错误处理

```typescript
// 网络错误映射
const NetworkErrorMap = {
  'TIMEOUT': '网络连接超时，请检查网络后重试',
  'CONNECTION_FAILED': '无法连接到服务器，请检查网络设置',
  'NETWORK_UNAVAILABLE': '网络不可用，请检查网络连接',
  'DNS_FAILED': '域名解析失败，请检查网络设置'
}

// HTTP状态码映射
const HttpStatusMap = {
  400: '请求参数错误',
  401: '登录已过期，请重新登录',
  403: '无权限访问',
  404: '请求的资源不存在',
  500: '服务器错误，请稍后重试',
  503: '服务暂时不可用，请稍后重试'
}
```

#### Service层错误处理

1. **静默失败场景**
   - 导航历史保存失败
   - 非关键数据缓存失败
   - 统计数据上报失败

2. **用户提示场景**
   - 登录/注册失败
   - 收藏操作失败
   - 数据加载失败

3. **自动重试场景**
   - 位置更新失败（最多重试3次）
   - 缓存刷新失败（延迟重试）

#### 401错误特殊处理

当收到401响应时：
1. 清除本地token和用户信息
2. 更新登录状态为未登录
3. 触发登录页面导航
4. 显示"登录已过期"提示

### 错误日志

所有错误应记录到控制台，包含：
- 错误时间戳
- 错误类型
- 错误详情
- 请求上下文（URL、方法、参数）

```typescript
console.error(`[${new Date().toISOString()}] ${errorType}:`, {
  message: error.message,
  url: requestUrl,
  method: requestMethod,
  params: requestParams
})
```

## Testing Strategy

### 测试方法论

本项目采用**双重测试策略**，结合单元测试和属性测试，确保全面的代码覆盖和正确性验证。

#### 单元测试 (Unit Tests)

**用途**：
- 验证特定的示例场景
- 测试边缘情况和错误条件
- 验证组件集成点
- 快速回归测试

**工具**：
- 测试框架：Jest 或 HarmonyOS测试框架
- Mock工具：用于模拟HTTP请求和Preferences

**重点测试场景**：
1. 401响应触发token清除和重新登录
2. 网络超时返回特定错误信息
3. 服务器500错误返回特定错误信息
4. 请求取消不显示错误提示
5. Preferences不存在时的处理
6. 空输入验证
7. 配置项存在性验证

#### 属性测试 (Property-Based Tests)

**用途**：
- 验证通用规则在所有输入下都成立
- 发现边缘情况和意外输入
- 确保系统行为的一致性
- 验证数据转换的正确性

**工具**：
- JavaScript/TypeScript: fast-check
- 配置：每个属性测试运行最少100次迭代

**测试标签格式**：
```typescript
// Feature: backend-integration, Property 1: Token自动注入
test('Token自动注入', () => {
  fc.assert(
    fc.property(
      fc.string(), // 生成随机token
      fc.string(), // 生成随机URL
      (token, url) => {
        // 测试逻辑
      }
    ),
    { numRuns: 100 }
  )
})
```

### 测试覆盖目标

- **HttpService**: 90%+ 代码覆盖率
- **AuthService**: 85%+ 代码覆盖率
- **其他Service**: 80%+ 代码覆盖率
- **CacheService**: 90%+ 代码覆盖率

### 关键测试场景

#### 1. HttpService测试

**单元测试**：
- 测试GET、POST、PUT、DELETE方法可用
- 测试401响应清除token
- 测试超时错误信息
- 测试各种HTTP状态码的错误映射

**属性测试**：
- Property 1: Token自动注入
- Property 2: 请求失败返回标准错误对象
- Property 3: POST/PUT请求Content-Type设置
- Property 20: HTTP状态码错误信息映射
- Property 21: 数据序列化round trip
- Property 22-24: 序列化/反序列化错误处理

#### 2. AuthService测试

**单元测试**：
- 测试注册调用正确的API
- 测试登录调用正确的API
- 测试登出清除数据

**属性测试**：
- Property 4: Token持久化round trip
- Property 5: 登出清除所有认证数据
- Property 6: Token验证状态一致性
- Property 7: Token操作错误信息明确性

#### 3. FavoriteService测试

**单元测试**：
- 测试未登录返回提示
- 测试API调用映射

**属性测试**：
- Property 8: 收藏操作更新缓存
- Property 9: 收藏搜索结果正确性
- Property 17: 删除收藏更新列表

#### 4. NavigationHistoryService测试

**单元测试**：
- 测试API调用映射
- 测试保存失败静默处理

**属性测试**：
- Property 10: 导航历史数据完整性
- Property 11: 历史保存失败静默处理
- Property 18: 历史记录时间倒序
- Property 19: 历史日期筛选正确性

#### 5. CacheService测试

**单元测试**：
- 测试清除所有缓存方法存在
- 测试过期时间设置

**属性测试**：
- Property 26: 缓存写入后可读取
- Property 27: 网络不可用时使用缓存
- Property 28: 缓存过期时间设置
- Property 29: 过期缓存自动刷新

### Mock策略

#### HTTP请求Mock

```typescript
// Mock成功响应
const mockSuccessResponse = (data: any) => ({
  code: 200,
  message: '成功',
  data
})

// Mock错误响应
const mockErrorResponse = (code: number, message: string) => ({
  code,
  message
})

// Mock网络错误
const mockNetworkError = (errorType: string) => {
  throw new Error(errorType)
}
```

#### Preferences Mock

```typescript
// Mock Preferences存储
const mockPreferences = new Map<string, any>()

const mockPreferencesAPI = {
  get: (key: string) => mockPreferences.get(key),
  put: (key: string, value: any) => mockPreferences.set(key, value),
  delete: (key: string) => mockPreferences.delete(key),
  clear: () => mockPreferences.clear()
}
```

### 集成测试

除了单元测试和属性测试，还需要进行端到端集成测试：

1. **完整登录流程**
   - 注册 → 登录 → 获取用户信息 → 登出

2. **收藏管理流程**
   - 添加收藏 → 查询列表 → 更新收藏 → 删除收藏

3. **导航流程**
   - 开始导航 → 保存历史 → 查询历史

4. **位置共享流程**
   - 开启共享 → 更新位置 → 查询位置 → 关闭共享

5. **离线场景**
   - 加载数据 → 断网 → 从缓存读取 → 联网 → 刷新数据

### 测试数据生成

使用fast-check生成器：

```typescript
// 生成随机用户信息
const userInfoArbitrary = fc.record({
  phone: fc.string({ minLength: 11, maxLength: 11 }),
  password: fc.string({ minLength: 6, maxLength: 20 }),
  nickname: fc.string({ minLength: 1, maxLength: 50 })
})

// 生成随机收藏地点
const favoritePlaceArbitrary = fc.record({
  name: fc.string({ minLength: 1, maxLength: 100 }),
  address: fc.string({ minLength: 1, maxLength: 255 }),
  latitude: fc.double({ min: -90, max: 90 }),
  longitude: fc.double({ min: -180, max: 180 }),
  category: fc.constantFrom('home', 'work', 'custom')
})

// 生成随机导航历史
const navigationHistoryArbitrary = fc.record({
  endName: fc.string({ minLength: 1, maxLength: 100 }),
  endAddress: fc.string({ minLength: 1, maxLength: 255 }),
  endLat: fc.double({ min: -90, max: 90 }),
  endLng: fc.double({ min: -180, max: 180 }),
  distance: fc.integer({ min: 0, max: 1000000 }),
  duration: fc.integer({ min: 0, max: 86400 })
})
```

### 持续集成

测试应集成到CI/CD流程中：

1. **提交前检查**
   - 运行所有单元测试
   - 运行快速属性测试（50次迭代）

2. **Pull Request检查**
   - 运行所有单元测试
   - 运行完整属性测试（100次迭代）
   - 检查代码覆盖率

3. **发布前检查**
   - 运行所有测试
   - 运行集成测试
   - 运行性能测试

### 性能测试

关键性能指标：

1. **HTTP请求响应时间**
   - 目标：< 3秒（正常网络）
   - 超时：30秒

2. **缓存读写性能**
   - 目标：< 100ms

3. **数据序列化/反序列化**
   - 目标：< 50ms（1KB数据）

4. **位置更新频率**
   - 目标：30秒间隔，误差 < 2秒

## Implementation Notes

### 开发优先级

#### Phase 1: 基础设施（第1-2周）
1. HttpService完整实现
2. CacheService完整实现
3. ApiConfig配置管理
4. 错误处理机制

#### Phase 2: 核心功能（第3-4周）
1. AuthService实现
2. FavoriteService实现
3. NavigationHistoryService实现
4. 登录注册UI

#### Phase 3: 扩展功能（第5-6周）
1. FrequentLocationService实现
2. LocationShareService实现
3. FeedbackService实现
4. 收藏和历史UI

#### Phase 4: 测试和优化（第7-8周）
1. 单元测试编写
2. 属性测试编写
3. 集成测试
4. 性能优化

### 技术债务管理

需要注意的技术债务：

1. **现有HttpService的TODO项**
   - 实现Preferences持久化存储
   - 完善token加载逻辑

2. **错误处理增强**
   - 添加错误重试机制
   - 实现指数退避策略

3. **缓存策略优化**
   - 实现LRU缓存淘汰
   - 添加缓存大小限制

4. **性能优化**
   - 请求去重
   - 请求合并
   - 响应压缩

### 安全考虑

1. **Token安全**
   - Token存储使用加密
   - Token传输使用HTTPS
   - Token定期刷新机制

2. **数据验证**
   - 所有用户输入验证
   - API响应数据验证
   - 防止XSS和注入攻击

3. **隐私保护**
   - 位置数据加密传输
   - 敏感信息不记录日志
   - 用户数据本地加密存储

### 兼容性考虑

1. **HarmonyOS版本**
   - 最低支持版本：HarmonyOS 3.0
   - 推荐版本：HarmonyOS 4.0+

2. **API兼容性**
   - 后端API版本：v1
   - 向后兼容策略：保持v1接口稳定

3. **数据迁移**
   - 缓存格式变更时的迁移策略
   - 用户数据升级机制

### 监控和日志

1. **关键指标监控**
   - API请求成功率
   - 平均响应时间
   - 错误率统计
   - 缓存命中率

2. **日志级别**
   - ERROR: 错误和异常
   - WARN: 警告信息
   - INFO: 关键操作
   - DEBUG: 调试信息（仅开发环境）

3. **日志格式**
```typescript
[时间戳] [级别] [模块] 消息内容
[2024-01-01 10:00:00] [ERROR] [HttpService] 请求失败: 网络超时
```

### 文档维护

需要维护的文档：

1. **API文档**
   - 所有Service的接口文档
   - 参数说明和返回值
   - 使用示例

2. **架构文档**
   - 系统架构图
   - 数据流图
   - 组件关系图

3. **测试文档**
   - 测试策略
   - 测试用例
   - 覆盖率报告

4. **部署文档**
   - 环境配置
   - 部署流程
   - 故障排查

---

**文档版本**: v1.0  
**创建时间**: 2024-01-01  
**最后更新**: 2024-01-01  
**状态**: ✅ 设计完成，待评审
