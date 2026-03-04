---
inclusion: always
---

# 项目记忆

> 新对话开始时自动加载。

---

## 📌 项目概述

**项目名称**: 车载导航系统（HarmonyOS）
**技术栈**: 
- 前端：HarmonyOS/ArkTS + 高德地图API
- 后端：Node.js + Express + TypeScript + MySQL
**核心功能**: 用户认证、导航规划、位置共享、收藏管理、导航反馈

---

## 📋 当前任务

**状态**: 已完成项目架构全面分析
**当前任务**: 识别项目盲区和优化建议

### 最近完成
- ✅ 2026-03-31: 完成整个项目的深度分析，识别12个关键盲区

---

## 🔧 快速参考

**启动命令**:
- 后端开发: `cd backend && npm run dev`
- 后端生产: `cd backend && npm run build && npm start`
- 数据库初始化: `mysql -u root -p < backend/src/database/init.sql`

**核心文件**:
| 功能 | 文件 |
|-----|------|
| 前端主页 | `entry/src/main/ets/pages/Index.ets` |
| 导航模块 | `entry/src/main/ets/view/EnhancedNavigationModule.ets` |
| HTTP服务 | `entry/src/main/ets/services/HttpService.ets` |
| 后端入口 | `backend/src/server.ts` |
| 路由定义 | `backend/src/routes/index.ts` |
| 数据库配置 | `backend/src/config/database.ts` |
| 数据库初始化 | `backend/src/database/init.sql` |

**API配置**:
- BASE_URL: `http://192.168.6.191:3000/api/v1`
- 高德地图Key: `2455309b8d8bb76cfdfebccb98f20153` (需要移到后端)

---

## ⚠️ 已知盲区（优先级排序）

### P0 - 必须修复
1. **高德API Key硬编码** - 暴露在前端代码中，需移到后端
2. **IP定位精度不足** - 只能到城市级别，需集成GPS定位
3. **JWT Token无刷新机制** - 7天后需重新登录，体验差

### P1 - 重要优化
4. **错误处理不统一** - 需要统一错误码和错误处理中间件
5. **前端无请求重试** - 网络波动时用户体验差
6. **数据库连接池未优化** - 高并发时可能连接不足
7. **语音播报未实现** - 只是console.log模拟

### P2 - 性能优化
8. **缓存无自动清理** - 过期缓存会占用存储空间
9. **数据库索引不足** - 复杂查询可能慢
10. **导航历史无限增长** - 需要自动清理策略

### P3 - 体验优化
11. **位置共享无距离限制** - 可能返回很远的用户
12. **WebView地图性能** - 不如原生地图组件

---

## 📊 项目架构总结

### 前端架构
- **页面层**: 7个页面（Index, Login, Register, Favorites, History, UserCenter, TestMenu）
- **视图层**: 4个模块（Navigation, Media, Collaboration, CarStatus）
- **服务层**: 13个服务（Http, Api, Auth, Cache, Navigation, Map, Amap, Favorite, History, FrequentLocation, LocationShare, Feedback, VoiceGuide）
- **模型层**: 2个模型文件（BackendModels, NavigationModels）

### 后端架构
- **路由层**: 统一路由定义（routes/index.ts）
- **中间件层**: JWT认证中间件（middleware/auth.ts）
- **控制器层**: 7个控制器（auth, favorite, navigation, routePlan, location, feedback, frequentLocation）
- **数据库层**: MySQL连接池（config/database.ts）

### 数据库设计
- **10张表**: users, favorites, navigation_history, trip_records, route_plans, user_locations, location_shares, navigation_feedback, frequent_locations, search_history
- **关系**: 用户为中心，一对多关系，外键约束

---

## 📝 会话日志（最近5条）

- **2026-04-08 15:00**: 用户要求深度分析整个项目架构，识别所有文件和盲区
- **2026-04-08 15:10**: 使用context-gatherer子代理系统性分析项目
- **2026-04-08 15:20**: 完成前端、后端、数据库、API集成的全面分析，识别12个关键盲区
- **2026-04-08 15:30**: 检查项目运行环境，启动后端服务，验证数据库连接
- **2026-04-08 15:40**: 创建运行指南（RUN_GUIDE.md），项目已就绪可在DevEco Studio中运行
