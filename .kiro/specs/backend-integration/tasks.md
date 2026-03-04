# Implementation Plan: Backend Integration

## Overview

本实现计划将HarmonyOS导航应用前端与Node.js后端服务完整集成。实现包括HTTP通信层、用户认证、收藏管理、导航历史、常去地点、位置共享和反馈等功能。使用ArkTS和HarmonyOS原生API（@ohos.net.http、@ohos.data.preferences）构建完整的服务层架构。

## Tasks

- [x] 1. 创建项目基础结构和配置
  - 创建services目录结构：services/http、services/auth、services/cache等
  - 创建models目录并定义所有TypeScript接口
  - 创建utils目录用于工具函数
  - 创建ApiConfig配置类，定义BASE_URL、ENDPOINTS、TIMEOUT等配置
  - _Requirements: 14.1, 14.2, 14.3, 14.4, 14.5, 14.6_

- [ ]* 1.1 编写ApiConfig配置类的单元测试
  - 测试环境切换时BASE_URL正确性
  - 测试所有ENDPOINTS定义存在
  - _Requirements: 14.3, 14.6_

- [ ] 2. 实现CacheService缓存服务
  - [x] 2.1 实现CacheService核心功能
    - 使用@ohos.data.preferences实现set、get、remove、clear方法
    - 实现缓存元数据管理（timestamp、expireTime）
    - 实现isExpired方法检查缓存过期
    - 使用单例模式
    - _Requirements: 15.1, 15.2, 15.3, 15.4, 15.5, 15.6, 15.7_

  - [ ]* 2.2 编写CacheService的属性测试
    - **Property 26: 缓存写入后可读取**
    - **Validates: Requirements 15.1, 15.3**

  - [ ]* 2.3 编写CacheService的属性测试
    - **Property 28: 缓存过期时间设置**
    - **Validates: Requirements 15.5**

  - [ ]* 2.4 编写CacheService的单元测试
    - 测试clear方法清除所有缓存
    - 测试Preferences不存在时的错误处理
    - _Requirements: 15.7_

- [ ] 3. 实现HttpService HTTP通信服务
  - [x] 3.1 实现HttpService核心功能
    - 使用@ohos.net.http实现request方法
    - 实现GET、POST、PUT、DELETE四种HTTP方法
    - 实现token管理（setToken、getToken、clearToken）
    - 实现token自动注入到Authorization头
    - 实现30秒请求超时
    - 实现401响应自动清除token
    - 实现标准错误对象返回（code、message）
    - 实现POST/PUT请求自动设置Content-Type为application/json
    - 使用单例模式
    - _Requirements: 1.1, 1.2, 1.3, 1.4, 1.5, 1.6, 1.7_

  - [ ]* 3.2 编写HttpService的属性测试
    - **Property 1: Token自动注入**
    - **Validates: Requirements 1.2**

  - [ ]* 3.3 编写HttpService的属性测试
    - **Property 2: 请求失败返回标准错误对象**
    - **Validates: Requirements 1.4**

  - [ ]* 3.4 编写HttpService的属性测试
    - **Property 3: POST/PUT请求Content-Type设置**
    - **Validates: Requirements 1.6**

  - [ ]* 3.5 编写HttpService的单元测试
    - 测试401响应触发token清除
    - 测试网络超时返回"网络连接超时"错误
    - 测试服务器500错误返回"服务器错误"提示
    - 测试请求取消不显示错误提示
    - _Requirements: 1.3, 12.1, 12.2, 12.4_

- [ ] 4. 实现错误处理和数据序列化
  - [ ] 4.1 实现网络错误和HTTP状态码映射
    - 创建NetworkErrorMap和HttpStatusMap
    - 实现错误信息中文化
    - 实现错误日志记录
    - _Requirements: 12.1, 12.2, 12.3, 12.5, 12.6_

  - [ ] 4.2 实现数据序列化和反序列化
    - 实现JSON序列化和反序列化
    - 实现序列化失败错误处理
    - 实现反序列化失败错误处理
    - 实现null和undefined值处理
    - _Requirements: 13.1, 13.2, 13.3, 13.4, 13.5, 13.6_

  - [ ]* 4.3 编写数据序列化的属性测试
    - **Property 21: 数据序列化round trip**
    - **Validates: Requirements 13.1, 13.2**

  - [ ]* 4.4 编写数据序列化的属性测试
    - **Property 22: 序列化失败错误处理**
    - **Validates: Requirements 13.3**

  - [ ]* 4.5 编写数据序列化的属性测试
    - **Property 23: 反序列化失败错误处理**
    - **Validates: Requirements 13.4**

  - [ ]* 4.6 编写数据序列化的属性测试
    - **Property 24: API响应类型匹配**
    - **Validates: Requirements 13.5**

  - [ ]* 4.7 编写错误处理的属性测试
    - **Property 20: HTTP状态码错误信息映射**
    - **Validates: Requirements 12.5**

- [ ] 5. Checkpoint - 确保基础服务测试通过
  - 确保HttpService、CacheService、错误处理的所有测试通过，询问用户是否有问题

- [ ] 6. 实现AuthService用户认证服务
  - [x] 6.1 实现AuthService核心功能
    - 实现register方法调用POST /api/v1/auth/register
    - 实现login方法调用POST /api/v1/auth/login
    - 实现getProfile方法调用GET /api/v1/auth/profile
    - 实现updateProfile方法调用PUT /api/v1/auth/profile
    - 实现logout方法清除token和用户信息
    - 实现isLoggedIn方法检查登录状态
    - 实现getCurrentUser方法获取当前用户
    - 实现token和用户信息的Preferences持久化
    - 实现应用启动时从Preferences读取token并验证
    - 使用单例模式
    - _Requirements: 2.1, 2.2, 2.3, 2.4, 2.5, 2.6, 2.7, 2.8, 3.1, 3.2, 3.3, 3.4, 3.5_

  - [ ]* 6.2 编写AuthService的属性测试
    - **Property 4: Token持久化round trip**
    - **Validates: Requirements 2.2, 2.4, 3.2**

  - [ ]* 6.3 编写AuthService的属性测试
    - **Property 5: 登出清除所有认证数据**
    - **Validates: Requirements 2.6**

  - [ ]* 6.4 编写AuthService的属性测试
    - **Property 6: Token验证状态一致性**
    - **Validates: Requirements 2.7, 2.8**

  - [ ]* 6.5 编写AuthService的属性测试
    - **Property 7: Token操作错误信息明确性**
    - **Validates: Requirements 3.5**

  - [ ]* 6.6 编写AuthService的单元测试
    - 测试注册调用正确的API端点
    - 测试登录调用正确的API端点
    - 测试登出清除Preferences数据
    - _Requirements: 2.1, 2.3, 2.6_

- [ ] 7. 实现FavoriteService收藏服务
  - [x] 7.1 实现FavoriteService核心功能
    - 实现getFavorites方法调用GET /api/v1/favorites
    - 实现addFavorite方法调用POST /api/v1/favorites
    - 实现updateFavorite方法调用PUT /api/v1/favorites/:id
    - 实现deleteFavorite方法调用DELETE /api/v1/favorites/:id
    - 实现searchFavorites方法按名称搜索
    - 实现收藏列表缓存（使用CacheService）
    - 实现未登录时返回提示
    - 使用单例模式
    - _Requirements: 4.1, 4.2, 4.3, 4.4, 4.5, 4.6, 4.7_

  - [ ]* 7.2 编写FavoriteService的属性测试
    - **Property 8: 收藏操作更新缓存**
    - **Validates: Requirements 4.4**

  - [ ]* 7.3 编写FavoriteService的属性测试
    - **Property 9: 收藏搜索结果正确性**
    - **Validates: Requirements 4.6**

  - [ ]* 7.4 编写FavoriteService的单元测试
    - 测试未登录返回"需要登录"提示
    - 测试API调用映射正确性
    - _Requirements: 4.7_

- [ ] 8. 实现NavigationHistoryService导航历史服务
  - [x] 8.1 实现NavigationHistoryService核心功能
    - 实现getHistory方法调用GET /api/v1/navigation/history（支持分页）
    - 实现saveHistory方法调用POST /api/v1/navigation/history
    - 实现deleteHistory方法调用DELETE /api/v1/navigation/history/:id
    - 实现clearHistory方法调用DELETE /api/v1/navigation/history
    - 实现getHistoryByDateRange方法按日期筛选
    - 实现历史记录缓存（最近50条）
    - 实现保存失败静默处理
    - 使用单例模式
    - _Requirements: 5.1, 5.2, 5.3, 5.4, 5.5, 5.6_

  - [ ]* 8.2 编写NavigationHistoryService的属性测试
    - **Property 10: 导航历史数据完整性**
    - **Validates: Requirements 5.4**

  - [ ]* 8.3 编写NavigationHistoryService的属性测试
    - **Property 11: 历史保存失败静默处理**
    - **Validates: Requirements 5.5**

  - [ ]* 8.4 编写NavigationHistoryService的单元测试
    - 测试API调用映射正确性
    - 测试保存失败不抛出异常
    - _Requirements: 5.1, 5.2, 5.5_

- [ ] 9. Checkpoint - 确保核心服务测试通过
  - 确保AuthService、FavoriteService、NavigationHistoryService的所有测试通过，询问用户是否有问题

- [ ] 10. 实现FrequentLocationService常去地点服务
  - [x] 10.1 实现FrequentLocationService核心功能
    - 实现recordVisit方法调用POST /api/v1/frequent-locations/visit
    - 实现getFrequentLocations方法调用GET /api/v1/frequent-locations
    - 实现getRecommendations方法调用GET /api/v1/frequent-locations/recommended
    - 实现getStats方法调用GET /api/v1/frequent-locations/stats
    - 实现updateLocation方法调用PUT /api/v1/frequent-locations/:id
    - 实现deleteLocation方法调用DELETE /api/v1/frequent-locations/:id
    - 实现按visitCount降序排序
    - 使用单例模式
    - _Requirements: 6.1, 6.2, 6.3, 6.4, 6.5, 6.6_

  - [ ]* 10.2 编写FrequentLocationService的属性测试
    - **Property 12: 常去地点按频率排序**
    - **Validates: Requirements 6.6**

  - [ ]* 10.3 编写FrequentLocationService的单元测试
    - 测试API调用映射正确性
    - 测试排序逻辑
    - _Requirements: 6.1, 6.2, 6.6_

- [ ] 11. 实现LocationShareService位置共享服务
  - [x] 11.1 实现LocationShareService核心功能
    - 实现updateLocation方法调用POST /api/v1/location
    - 实现getLocation方法调用GET /api/v1/location或GET /api/v1/location/:userId
    - 实现toggleSharing方法调用POST /api/v1/location/sharing/toggle
    - 实现createShare方法调用POST /api/v1/location/sharing
    - 实现getShares方法调用GET /api/v1/location/sharing
    - 实现cancelShare方法调用DELETE /api/v1/location/sharing/:id
    - 实现getNearbyUsers方法调用GET /api/v1/location/nearby
    - 实现startAutoUpdate和stopAutoUpdate方法（30秒定时更新）
    - 实现24小时自动停止共享
    - 使用单例模式
    - _Requirements: 7.1, 7.2, 7.3, 7.4, 7.5, 7.6, 7.7_

  - [ ]* 11.2 编写LocationShareService的属性测试
    - **Property 13: 位置共享定时更新**
    - **Validates: Requirements 7.5**

  - [ ]* 11.3 编写LocationShareService的单元测试
    - 测试API调用映射正确性
    - 测试定时器启动和停止
    - 测试24小时自动停止逻辑
    - _Requirements: 7.1, 7.2, 7.5, 7.6_

- [ ] 12. 实现FeedbackService反馈服务
  - [x] 12.1 实现FeedbackService核心功能
    - 实现submitFeedback方法调用POST /api/v1/feedback
    - 实现getFeedbacks方法调用GET /api/v1/feedback（支持分页和类型筛选）
    - 实现getStats方法调用GET /api/v1/feedback/stats
    - 实现getFeedbackDetail方法调用GET /api/v1/feedback/:id
    - 实现deleteFeedback方法调用DELETE /api/v1/feedback/:id
    - 实现自动附加当前位置信息
    - 使用单例模式
    - _Requirements: 8.1, 8.2, 8.3, 8.4, 8.5, 8.6_

  - [ ]* 12.2 编写FeedbackService的属性测试
    - **Property 14: 反馈自动附加位置信息**
    - **Validates: Requirements 8.3**

  - [ ]* 12.3 编写FeedbackService的单元测试
    - 测试API调用映射正确性
    - 测试位置信息自动附加
    - _Requirements: 8.1, 8.3_

- [ ] 13. Checkpoint - 确保扩展服务测试通过
  - 确保FrequentLocationService、LocationShareService、FeedbackService的所有测试通过，询问用户是否有问题

- [ ] 14. 实现登录注册UI界面
  - [x] 14.1 创建LoginPage登录页面
    - 创建用户名和密码输入框
    - 创建登录和注册按钮
    - 实现输入验证（不为空）
    - 实现登录成功跳转到主页面
    - 实现登录失败显示错误提示
    - 调用AuthService.login方法
    - _Requirements: 9.1, 9.2, 9.3, 9.4, 9.5_

  - [x] 14.2 创建RegisterPage注册页面
    - 创建用户名、密码和确认密码输入框
    - 实现两次密码一致性验证
    - 实现注册成功自动登录并跳转
    - 调用AuthService.register方法
    - _Requirements: 9.6, 9.7, 9.8_

  - [ ]* 14.3 编写登录注册UI的属性测试
    - **Property 15: 登录输入验证**
    - **Validates: Requirements 9.3**

  - [ ]* 14.4 编写登录注册UI的属性测试
    - **Property 16: 注册密码一致性验证**
    - **Validates: Requirements 9.7**

- [ ] 15. 实现收藏列表UI界面
  - [x] 15.1 创建FavoritesPage收藏页面
    - 显示所有收藏地点列表
    - 实现空状态提示
    - 实现点击收藏项显示详情和导航按钮
    - 实现删除按钮和确认对话框
    - 实现删除后刷新列表
    - 实现下拉刷新
    - 显示收藏的名称、地址和添加时间
    - 调用FavoriteService的方法
    - _Requirements: 10.1, 10.2, 10.3, 10.4, 10.5, 10.6, 10.7_

  - [ ]* 15.2 编写收藏列表UI的属性测试
    - **Property 17: 删除收藏更新列表**
    - **Validates: Requirements 10.5**

- [ ] 16. 实现导航历史UI界面
  - [x] 16.1 创建HistoryPage历史页面
    - 按时间倒序显示导航历史记录
    - 显示每条记录的起点、终点、时间和距离
    - 实现点击历史记录提供重新导航选项
    - 实现按日期筛选
    - 实现分页加载更多
    - 实现加载失败显示错误提示和重试按钮
    - 调用NavigationHistoryService的方法
    - _Requirements: 11.1, 11.2, 11.3, 11.4, 11.5, 11.6_

  - [ ]* 16.2 编写导航历史UI的属性测试
    - **Property 18: 历史记录时间倒序**
    - **Validates: Requirements 11.1**

  - [ ]* 16.3 编写导航历史UI的属性测试
    - **Property 19: 历史日期筛选正确性**
    - **Validates: Requirements 11.4**

- [ ] 17. 实现离线缓存功能
  - [ ] 17.1 在FavoriteService中集成离线缓存
    - 加载成功时缓存收藏列表
    - 网络不可用时从缓存读取
    - _Requirements: 15.1, 15.2_

  - [ ] 17.2 在NavigationHistoryService中集成离线缓存
    - 加载成功时缓存最近50条记录
    - 网络不可用时从缓存读取
    - _Requirements: 15.3, 15.4_

  - [ ] 17.3 实现缓存过期和自动刷新
    - 为每个缓存项设置过期时间
    - 缓存过期时网络可用自动刷新
    - _Requirements: 15.5, 15.6_

  - [ ]* 17.4 编写离线缓存的属性测试
    - **Property 27: 网络不可用时使用缓存**
    - **Validates: Requirements 15.2, 15.4**

  - [ ]* 17.5 编写离线缓存的属性测试
    - **Property 29: 过期缓存自动刷新**
    - **Validates: Requirements 15.6**

- [ ] 18. 集成和联调
  - [ ] 18.1 将所有服务集成到主应用
    - 在应用启动时初始化所有服务
    - 在主页面添加导航到登录、收藏、历史页面的入口
    - 实现未登录时跳转到登录页面
    - 实现导航开始时自动保存历史记录

  - [ ] 18.2 端到端测试
    - 测试完整登录流程：注册 → 登录 → 获取用户信息 → 登出
    - 测试收藏管理流程：添加 → 查询 → 更新 → 删除
    - 测试导航流程：开始导航 → 保存历史 → 查询历史
    - 测试位置共享流程：开启 → 更新 → 查询 → 关闭
    - 测试离线场景：加载数据 → 断网 → 从缓存读取 → 联网 → 刷新

- [ ] 19. Final Checkpoint - 确保所有功能正常
  - 确保所有测试通过，所有功能正常工作，询问用户是否有问题或需要调整

## Notes

- 任务标记`*`的为可选测试任务，可以跳过以加快MVP开发
- 每个任务都引用了具体的需求编号，确保可追溯性
- Checkpoint任务确保增量验证，及时发现问题
- 属性测试验证通用正确性属性，单元测试验证具体场景
- 所有服务使用单例模式，确保全局唯一实例
- 优先实现基础设施（HttpService、CacheService），再实现业务服务
- UI界面在服务层完成后实现，确保业务逻辑与UI分离
