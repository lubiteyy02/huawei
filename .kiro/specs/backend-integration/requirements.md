# Requirements Document

## Introduction

本文档定义了HarmonyOS导航应用前端集成后端API的功能需求。后端服务已完成开发，包含用户认证、收藏管理、导航历史、常去地点、位置共享和反馈等功能。前端需要使用ArkTS和HarmonyOS原生API（@ohos.net.http、@ohos.data.preferences）实现与后端的完整集成。

## Glossary

- **Frontend**: HarmonyOS导航应用的前端部分，使用ArkTS开发
- **Backend**: Node.js + Express + TypeScript + MySQL后端服务，运行在http://localhost:3000
- **HttpService**: 前端HTTP请求封装服务，负责所有网络通信
- **AuthService**: 用户认证服务，管理登录、注册和token
- **JWT_Token**: JSON Web Token，用于用户身份验证的令牌
- **Preferences**: HarmonyOS的@ohos.data.preferences模块，用于本地数据持久化
- **API_Endpoint**: 后端API接口地址
- **Navigation_Record**: 导航历史记录
- **Favorite_Location**: 用户收藏的地点
- **Frequent_Location**: 系统识别的用户常去地点
- **Location_Share**: 用户之间的实时位置共享
- **Feedback**: 用户对导航路线的反馈信息

## Requirements

### Requirement 1: HTTP请求基础服务

**User Story:** 作为开发者，我需要一个统一的HTTP请求服务，以便所有API调用都能复用相同的配置和错误处理逻辑

#### Acceptance Criteria

1. THE HttpService SHALL 使用@ohos.net.http模块发送HTTP请求
2. WHEN 发送请求时，THE HttpService SHALL 自动在请求头中添加存储的JWT_Token
3. WHEN 请求返回401状态码时，THE HttpService SHALL 清除本地token并触发重新登录流程
4. WHEN 请求失败时，THE HttpService SHALL 返回包含错误码和错误信息的标准错误对象
5. THE HttpService SHALL 支持GET、POST、PUT、DELETE四种HTTP方法
6. WHEN 发送POST或PUT请求时，THE HttpService SHALL 自动设置Content-Type为application/json
7. THE HttpService SHALL 设置请求超时时间为30秒

### Requirement 2: 用户认证功能

**User Story:** 作为用户，我需要注册和登录账号，以便使用个性化的导航服务

#### Acceptance Criteria

1. WHEN 用户提交注册信息时，THE AuthService SHALL 调用POST /api/auth/register接口
2. WHEN 注册成功时，THE AuthService SHALL 将返回的JWT_Token存储到Preferences中
3. WHEN 用户提交登录信息时，THE AuthService SHALL 调用POST /api/auth/login接口
4. WHEN 登录成功时，THE AuthService SHALL 将JWT_Token和用户信息存储到Preferences中
5. THE AuthService SHALL 提供获取当前登录状态的方法
6. WHEN 用户登出时，THE AuthService SHALL 清除Preferences中的token和用户信息
7. WHEN 应用启动时，THE AuthService SHALL 从Preferences读取token并验证有效性
8. IF token无效或不存在，THEN THE AuthService SHALL 将用户状态设置为未登录

### Requirement 3: Token持久化存储

**User Story:** 作为用户，我希望登录状态能够保持，以便不需要每次打开应用都重新登录

#### Acceptance Criteria

1. THE AuthService SHALL 使用@ohos.data.preferences模块存储JWT_Token
2. WHEN token存储成功时，THE AuthService SHALL 返回成功状态
3. WHEN 读取token时，THE AuthService SHALL 处理Preferences不存在的情况
4. THE AuthService SHALL 提供清除token的方法
5. FOR ALL token操作，错误处理SHALL返回明确的错误信息

### Requirement 4: 收藏地点管理

**User Story:** 作为用户，我需要收藏常用地点，以便快速访问和导航到这些位置

#### Acceptance Criteria

1. WHEN 用户添加收藏时，THE FavoriteService SHALL 调用POST /api/favorites接口
2. WHEN 用户查询收藏列表时，THE FavoriteService SHALL 调用GET /api/favorites接口
3. WHEN 用户删除收藏时，THE FavoriteService SHALL 调用DELETE /api/favorites/:id接口
4. WHEN 收藏操作成功时，THE FavoriteService SHALL 更新本地收藏列表缓存
5. WHEN 收藏操作失败时，THE FavoriteService SHALL 返回错误信息给UI层
6. THE FavoriteService SHALL 支持按名称搜索收藏地点
7. WHEN 用户未登录时，THE FavoriteService SHALL 返回需要登录的提示

### Requirement 5: 导航历史记录

**User Story:** 作为用户，我需要查看导航历史记录，以便回顾之前去过的地方

#### Acceptance Criteria

1. WHEN 导航开始时，THE NavigationHistoryService SHALL 自动调用POST /api/navigation/history接口保存记录
2. WHEN 用户查询历史时，THE NavigationHistoryService SHALL 调用GET /api/navigation/history接口
3. THE NavigationHistoryService SHALL 支持分页查询历史记录
4. THE NavigationHistoryService SHALL 记录起点、终点、导航时间和距离信息
5. WHEN 保存历史失败时，THE NavigationHistoryService SHALL 静默失败不影响导航功能
6. THE NavigationHistoryService SHALL 提供按日期范围筛选历史记录的功能

### Requirement 6: 常去地点智能识别

**User Story:** 作为用户，我希望系统能识别我的常去地点，以便快速导航到这些位置

#### Acceptance Criteria

1. WHEN 用户查询常去地点时，THE FrequentLocationService SHALL 调用GET /api/frequent-locations接口
2. WHEN 用户手动添加常去地点时，THE FrequentLocationService SHALL 调用POST /api/frequent-locations接口
3. WHEN 用户更新地点标签时，THE FrequentLocationService SHALL 调用PUT /api/frequent-locations/:id接口
4. WHEN 用户删除常去地点时，THE FrequentLocationService SHALL 调用DELETE /api/frequent-locations/:id接口
5. THE FrequentLocationService SHALL 支持为常去地点设置自定义标签（如"家"、"公司"）
6. THE FrequentLocationService SHALL 按访问频率排序常去地点列表

### Requirement 7: 实时位置共享

**User Story:** 作为用户，我需要与朋友共享我的实时位置，以便他们知道我在哪里

#### Acceptance Criteria

1. WHEN 用户开启位置共享时，THE LocationShareService SHALL 调用POST /api/locations接口创建共享会话
2. WHEN 位置更新时，THE LocationShareService SHALL 调用PUT /api/locations/:id接口更新位置
3. WHEN 用户查询共享位置时，THE LocationShareService SHALL 调用GET /api/locations接口
4. WHEN 用户停止共享时，THE LocationShareService SHALL 调用DELETE /api/locations/:id接口
5. THE LocationShareService SHALL 每30秒自动更新一次位置信息
6. WHEN 位置共享会话超过24小时时，THE LocationShareService SHALL 自动停止共享
7. THE LocationShareService SHALL 支持查看其他用户共享给我的位置

### Requirement 8: 导航反馈提交

**User Story:** 作为用户，我需要提交导航问题反馈，以便帮助改进导航服务质量

#### Acceptance Criteria

1. WHEN 用户提交反馈时，THE FeedbackService SHALL 调用POST /api/feedback接口
2. THE FeedbackService SHALL 支持提交路线问题、地点错误、导航异常等类型的反馈
3. THE FeedbackService SHALL 自动附加当前位置和导航上下文信息
4. WHEN 用户查询反馈历史时，THE FeedbackService SHALL 调用GET /api/feedback接口
5. THE FeedbackService SHALL 支持上传截图作为反馈附件
6. WHEN 反馈提交成功时，THE FeedbackService SHALL 显示感谢提示

### Requirement 9: 登录注册UI界面

**User Story:** 作为用户，我需要友好的登录注册界面，以便轻松完成账号操作

#### Acceptance Criteria

1. THE LoginPage SHALL 提供用户名和密码输入框
2. THE LoginPage SHALL 提供登录和注册按钮
3. WHEN 用户点击登录按钮时，THE LoginPage SHALL 验证输入不为空
4. WHEN 登录成功时，THE LoginPage SHALL 跳转到主页面
5. WHEN 登录失败时，THE LoginPage SHALL 显示错误提示信息
6. THE RegisterPage SHALL 提供用户名、密码和确认密码输入框
7. WHEN 用户注册时，THE RegisterPage SHALL 验证两次密码输入一致
8. WHEN 注册成功时，THE RegisterPage SHALL 自动登录并跳转到主页面

### Requirement 10: 收藏列表UI界面

**User Story:** 作为用户，我需要查看和管理我的收藏地点列表，以便快速访问常用位置

#### Acceptance Criteria

1. THE FavoritesPage SHALL 显示所有收藏地点的列表
2. WHEN 列表为空时，THE FavoritesPage SHALL 显示空状态提示
3. WHEN 用户点击收藏项时，THE FavoritesPage SHALL 显示地点详情和导航按钮
4. WHEN 用户点击删除按钮时，THE FavoritesPage SHALL 显示确认对话框
5. WHEN 删除确认后，THE FavoritesPage SHALL 从列表中移除该项并刷新显示
6. THE FavoritesPage SHALL 支持下拉刷新收藏列表
7. THE FavoritesPage SHALL 显示每个收藏的名称、地址和添加时间

### Requirement 11: 导航历史UI界面

**User Story:** 作为用户，我需要查看导航历史记录，以便回顾之前的行程

#### Acceptance Criteria

1. THE HistoryPage SHALL 按时间倒序显示导航历史记录
2. THE HistoryPage SHALL 显示每条记录的起点、终点、时间和距离
3. WHEN 用户点击历史记录时，THE HistoryPage SHALL 提供重新导航选项
4. THE HistoryPage SHALL 支持按日期筛选历史记录
5. THE HistoryPage SHALL 支持分页加载更多历史记录
6. WHEN 加载历史失败时，THE HistoryPage SHALL 显示错误提示和重试按钮

### Requirement 12: 网络错误处理

**User Story:** 作为用户，当网络出现问题时，我需要看到清晰的错误提示，以便了解发生了什么

#### Acceptance Criteria

1. WHEN 网络请求超时时，THE HttpService SHALL 返回"网络连接超时"错误
2. WHEN 服务器返回500错误时，THE HttpService SHALL 返回"服务器错误"提示
3. WHEN 网络不可用时，THE HttpService SHALL 返回"网络不可用"提示
4. WHEN 请求被取消时，THE HttpService SHALL 不显示错误提示
5. THE HttpService SHALL 为每种HTTP状态码提供对应的中文错误信息
6. WHEN 后端服务不可达时，THE HttpService SHALL 返回"无法连接到服务器"提示

### Requirement 13: 数据序列化与反序列化

**User Story:** 作为开发者，我需要可靠的数据转换机制，以便前后端数据格式保持一致

#### Acceptance Criteria

1. THE HttpService SHALL 将请求数据序列化为JSON格式
2. THE HttpService SHALL 将响应数据反序列化为TypeScript对象
3. WHEN 序列化失败时，THE HttpService SHALL 返回序列化错误信息
4. WHEN 反序列化失败时，THE HttpService SHALL 返回解析错误信息
5. FOR ALL API响应，反序列化后的对象类型SHALL与定义的接口类型匹配
6. THE HttpService SHALL 处理后端返回的null和undefined值

### Requirement 14: 配置管理

**User Story:** 作为开发者，我需要集中管理API配置，以便在不同环境间切换

#### Acceptance Criteria

1. THE ApiConfig SHALL 定义后端服务的基础URL
2. THE ApiConfig SHALL 定义所有API端点路径
3. THE ApiConfig SHALL 支持开发环境和生产环境的配置切换
4. THE ApiConfig SHALL 定义请求超时时间配置
5. THE ApiConfig SHALL 定义token存储的key名称
6. WHEN 环境切换时，THE ApiConfig SHALL 自动使用对应环境的配置

### Requirement 15: 离线数据缓存

**User Story:** 作为用户，当网络不可用时，我希望仍能查看之前加载的数据，以便不影响基本使用

#### Acceptance Criteria

1. WHEN 收藏列表加载成功时，THE FavoriteService SHALL 将数据缓存到Preferences
2. WHEN 网络不可用时，THE FavoriteService SHALL 从缓存读取收藏列表
3. WHEN 历史记录加载成功时，THE NavigationHistoryService SHALL 缓存最近的50条记录
4. WHEN 网络不可用时，THE NavigationHistoryService SHALL 从缓存读取历史记录
5. THE CacheService SHALL 为每个缓存项设置过期时间
6. WHEN 缓存过期时，THE CacheService SHALL 在网络可用时自动刷新数据
7. THE CacheService SHALL 提供清除所有缓存的方法
