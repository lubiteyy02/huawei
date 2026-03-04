# 导航系统数据库设计文档

## 数据库概述

数据库名称：`car_navigation`
字符集：`utf8mb4`
排序规则：`utf8mb4_unicode_ci`

---

## 核心表结构

### 1. 用户表 (users)

**用途**：存储用户基本信息和认证数据

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| phone | VARCHAR(20) | 手机号，唯一 |
| password | VARCHAR(255) | 加密密码 |
| nickname | VARCHAR(50) | 昵称 |
| avatar | VARCHAR(255) | 头像URL |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

**索引**：
- PRIMARY KEY (id)
- UNIQUE KEY (phone)
- INDEX idx_phone (phone)

---

### 2. 收藏地点表 (favorites)

**用途**：保存用户收藏的常用地点（家、公司等）

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| name | VARCHAR(100) | 地点名称 |
| address | VARCHAR(255) | 详细地址 |
| latitude | DECIMAL(10,7) | 纬度 |
| longitude | DECIMAL(10,7) | 经度 |
| category | VARCHAR(20) | 分类：home/work/custom |
| icon | VARCHAR(50) | 图标 |
| created_at | TIMESTAMP | 创建时间 |

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_user_id (user_id)
- INDEX idx_category (user_id, category)

---

### 3. 导航历史表 (navigation_history)

**用途**：记录用户的导航历史

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| start_name | VARCHAR(100) | 起点名称 |
| start_address | VARCHAR(255) | 起点地址 |
| start_lat | DECIMAL(10,7) | 起点纬度 |
| start_lng | DECIMAL(10,7) | 起点经度 |
| end_name | VARCHAR(100) | 终点名称 |
| end_address | VARCHAR(255) | 终点地址 |
| end_lat | DECIMAL(10,7) | 终点纬度 |
| end_lng | DECIMAL(10,7) | 终点经度 |
| distance | INT | 距离（米） |
| duration | INT | 时长（秒） |
| created_at | TIMESTAMP | 创建时间 |

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_user_created (user_id, created_at DESC)

---

### 4. 行程记录表 (trip_records)

**用途**：记录完整的行程轨迹和统计数据

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| start_time | TIMESTAMP | 开始时间 |
| end_time | TIMESTAMP | 结束时间 |
| total_distance | INT | 总距离（米） |
| total_duration | INT | 总时长（秒） |
| avg_speed | DECIMAL(5,2) | 平均速度（km/h） |
| max_speed | DECIMAL(5,2) | 最高速度（km/h） |
| trajectory | TEXT | 轨迹数据（JSON） |
| created_at | TIMESTAMP | 创建时间 |

**trajectory JSON格式**：
```json
[
  {
    "lat": 30.486874,
    "lng": 114.309995,
    "speed": 45.5,
    "timestamp": "2026-03-05T10:30:00Z"
  }
]
```

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_user_start (user_id, start_time DESC)

---

### 5. 路线方案表 (route_plans) ⭐ 新增

**用途**：保存用户规划的路线方案，支持收藏和重复使用

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| name | VARCHAR(100) | 路线名称 |
| start_name | VARCHAR(100) | 起点名称 |
| start_lat | DECIMAL(10,7) | 起点纬度 |
| start_lng | DECIMAL(10,7) | 起点经度 |
| end_name | VARCHAR(100) | 终点名称 |
| end_lat | DECIMAL(10,7) | 终点纬度 |
| end_lng | DECIMAL(10,7) | 终点经度 |
| waypoints | TEXT | 途经点（JSON数组） |
| distance | INT | 总距离（米） |
| duration | INT | 预计时长（秒） |
| strategy | TINYINT | 策略：0-推荐 1-避堵 2-避费 3-高速 |
| polyline | TEXT | 路线坐标串 |
| steps | TEXT | 导航步骤（JSON） |
| is_favorite | BOOLEAN | 是否收藏 |
| use_count | INT | 使用次数 |
| created_at | TIMESTAMP | 创建时间 |
| updated_at | TIMESTAMP | 更新时间 |

**waypoints JSON格式**：
```json
[
  {
    "name": "服务区",
    "lat": 30.5,
    "lng": 114.4
  }
]
```

**steps JSON格式**：
```json
[
  {
    "instruction": "向东行驶100米",
    "distance": 100,
    "duration": 20,
    "road": "中山大道"
  }
]
```

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_user_favorite (user_id, is_favorite)
- INDEX idx_user_created (user_id, created_at DESC)

---

### 6. 实时位置表 (user_locations) ⭐ 新增

**用途**：存储用户最新位置，支持位置共享和协同导航

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键，唯一 |
| latitude | DECIMAL(10,7) | 纬度 |
| longitude | DECIMAL(10,7) | 经度 |
| accuracy | DECIMAL(6,2) | 精度（米） |
| speed | DECIMAL(6,2) | 速度（km/h） |
| heading | DECIMAL(5,2) | 方向（度，0-360） |
| location_type | VARCHAR(20) | 定位类型：gps/network/ip |
| is_sharing | BOOLEAN | 是否共享位置 |
| updated_at | TIMESTAMP | 更新时间 |

**location_type说明**：
- `gps` - GPS定位（精度最高）
- `network` - 网络定位（WiFi+基站）
- `ip` - IP定位（精度最低）

**索引**：
- PRIMARY KEY (id)
- UNIQUE KEY uk_user_id (user_id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_sharing (is_sharing, updated_at)

---

### 7. 位置共享关系表 (location_shares) ⭐ 新增

**用途**：管理用户之间的位置共享关系

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| sharer_id | BIGINT | 分享者ID，外键 |
| viewer_id | BIGINT | 查看者ID，外键 |
| expire_time | TIMESTAMP | 过期时间 |
| is_active | BOOLEAN | 是否激活 |
| created_at | TIMESTAMP | 创建时间 |

**使用场景**：
- 家人位置共享
- 朋友聚会导航
- 车队协同行驶

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (sharer_id) → users(id)
- FOREIGN KEY (viewer_id) → users(id)
- UNIQUE KEY uk_share_view (sharer_id, viewer_id)
- INDEX idx_viewer_active (viewer_id, is_active)

---

### 8. 导航反馈表 (navigation_feedback) ⭐ 新增

**用途**：收集用户对导航的反馈，用于改进服务

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| navigation_id | BIGINT | 导航历史ID，外键 |
| rating | TINYINT | 评分（1-5星） |
| feedback_type | VARCHAR(20) | 反馈类型 |
| content | TEXT | 反馈内容 |
| location_lat | DECIMAL(10,7) | 反馈位置纬度 |
| location_lng | DECIMAL(10,7) | 反馈位置经度 |
| created_at | TIMESTAMP | 创建时间 |

**feedback_type类型**：
- `route` - 路线问题
- `traffic` - 路况问题
- `poi` - 地点信息问题

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- FOREIGN KEY (navigation_id) → navigation_history(id)
- INDEX idx_user_created (user_id, created_at DESC)
- INDEX idx_type (feedback_type)

---

### 9. 常用地点统计表 (frequent_locations) ⭐ 新增

**用途**：统计用户常去的地点，用于智能推荐

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| name | VARCHAR(100) | 地点名称 |
| address | VARCHAR(255) | 地址 |
| latitude | DECIMAL(10,7) | 纬度 |
| longitude | DECIMAL(10,7) | 经度 |
| visit_count | INT | 访问次数 |
| last_visit | TIMESTAMP | 最后访问时间 |
| time_pattern | VARCHAR(50) | 时间规律 |

**time_pattern示例**：
- "工作日早上" - 每周一到周五 7:00-9:00
- "周末下午" - 周六日 14:00-18:00
- "每天晚上" - 每天 18:00-22:00

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- UNIQUE KEY uk_user_location (user_id, latitude, longitude)
- INDEX idx_user_count (user_id, visit_count DESC)

---

### 10. 搜索历史表 (search_history)

**用途**：记录用户的搜索历史

| 字段 | 类型 | 说明 |
|------|------|------|
| id | BIGINT | 主键，自增 |
| user_id | BIGINT | 用户ID，外键 |
| keyword | VARCHAR(100) | 搜索关键词 |
| result_count | INT | 结果数量 |
| created_at | TIMESTAMP | 创建时间 |

**索引**：
- PRIMARY KEY (id)
- FOREIGN KEY (user_id) → users(id)
- INDEX idx_user_created (user_id, created_at DESC)
- INDEX idx_keyword (keyword)

---

## 数据库关系图

```
users (用户表)
  ├── favorites (收藏地点)
  ├── navigation_history (导航历史)
  ├── trip_records (行程记录)
  ├── route_plans (路线方案) ⭐
  ├── user_locations (实时位置) ⭐
  ├── location_shares (位置共享) ⭐
  │   └── sharer_id → users
  │   └── viewer_id → users
  ├── navigation_feedback (导航反馈) ⭐
  ├── frequent_locations (常用地点) ⭐
  └── search_history (搜索历史)
```

---

## 功能支持

### ✅ 已实现功能

1. **用户认证** - users表
2. **收藏地点** - favorites表
3. **导航历史** - navigation_history表
4. **行程记录** - trip_records表
5. **搜索历史** - search_history表

### ⭐ 新增功能

6. **路线方案保存** - route_plans表
   - 保存常用路线
   - 收藏路线
   - 统计使用次数

7. **实时位置共享** - user_locations + location_shares表
   - 位置实时更新
   - 家人位置共享
   - 协同导航

8. **导航反馈** - navigation_feedback表
   - 路线评分
   - 问题反馈
   - 改进建议

9. **智能推荐** - frequent_locations表
   - 常去地点统计
   - 时间规律分析
   - 智能推荐目的地

---

## 性能优化建议

### 索引优化

1. **复合索引**：
   - (user_id, created_at DESC) - 用于用户历史查询
   - (user_id, is_favorite) - 用于收藏查询
   - (is_sharing, updated_at) - 用于位置共享查询

2. **唯一索引**：
   - (user_id) on user_locations - 每个用户只有一条最新位置
   - (sharer_id, viewer_id) on location_shares - 防止重复共享关系

### 数据清理策略

1. **导航历史** - 保留最近6个月
2. **搜索历史** - 保留最近3个月
3. **行程记录** - 保留最近1年
4. **位置共享** - 自动清理过期记录

### 缓存策略

1. **Redis缓存**：
   - 用户实时位置（TTL: 5分钟）
   - 常用地点（TTL: 1小时）
   - 路线方案（TTL: 30分钟）

---

## 安全考虑

1. **密码加密** - 使用bcrypt加密
2. **位置隐私** - 位置共享需要双方同意
3. **数据脱敏** - 敏感信息加密存储
4. **访问控制** - 用户只能访问自己的数据

---

## 扩展性

### 未来可能的扩展

1. **社交功能**：
   - 好友表
   - 动态分享表
   - 评论点赞表

2. **商业功能**：
   - 广告表
   - 优惠券表
   - 会员表

3. **数据分析**：
   - 用户行为分析表
   - 路况数据表
   - 热力图数据表

---

**创建时间**: 2026-03-05
**版本**: v1.0
**状态**: ✅ 已完成
