# 导航系统API文档

## 基础信息

- **Base URL**: `http://localhost:3000/api/v1`
- **认证方式**: Bearer Token (JWT)
- **Content-Type**: `application/json`

---

## 认证相关 API

### 1. 用户注册

**POST** `/auth/register`

**请求体**:
```json
{
  "phone": "13800138000",
  "password": "123456",
  "nickname": "用户昵称"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 1,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

### 2. 用户登录

**POST** `/auth/login`

**请求体**:
```json
{
  "phone": "13800138000",
  "password": "123456"
}
```

**响应**:
```json
{
  "code": 200,
  "message": "登录成功",
  "data": {
    "userId": 1,
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
    "user": {
      "id": 1,
      "phone": "13800138000",
      "nickname": "用户昵称",
      "avatar": null
    }
  }
}
```

### 3. 获取用户信息

**GET** `/auth/profile`

**Headers**: `Authorization: Bearer {token}`

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": 1,
    "phone": "13800138000",
    "nickname": "用户昵称",
    "avatar": null,
    "created_at": "2026-03-05T10:00:00.000Z"
  }
}
```

---

## 收藏地点 API

### 1. 获取收藏列表

**GET** `/favorites?category=home`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `category` (可选): 分类筛选 (home/work/custom)

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "name": "家",
      "address": "武汉市洪山区xxx",
      "latitude": 30.486874,
      "longitude": 114.309995,
      "category": "home",
      "icon": "home",
      "created_at": "2026-03-05T10:00:00.000Z"
    }
  ]
}
```

### 2. 添加收藏

**POST** `/favorites`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "公司",
  "address": "武汉市江汉区xxx",
  "latitude": 30.5,
  "longitude": 114.3,
  "category": "work",
  "icon": "work"
}
```

### 3. 更新收藏

**PUT** `/favorites/:id`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "新名称",
  "category": "custom"
}
```

### 4. 删除收藏

**DELETE** `/favorites/:id`

**Headers**: `Authorization: Bearer {token}`

---

## 导航历史 API

### 1. 获取导航历史

**GET** `/navigation/history?page=1&pageSize=20`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `page` (可选): 页码，默认1
- `pageSize` (可选): 每页数量，默认20

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": 1,
        "user_id": 1,
        "start_name": "家",
        "start_address": "武汉市洪山区xxx",
        "start_lat": 30.486874,
        "start_lng": 114.309995,
        "end_name": "公司",
        "end_address": "武汉市江汉区xxx",
        "end_lat": 30.5,
        "end_lng": 114.3,
        "distance": 5000,
        "duration": 900,
        "created_at": "2026-03-05T10:00:00.000Z"
      }
    ],
    "total": 50,
    "page": 1,
    "pageSize": 20
  }
}
```

### 2. 保存导航记录

**POST** `/navigation/history`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "startName": "家",
  "startAddress": "武汉市洪山区xxx",
  "startLat": 30.486874,
  "startLng": 114.309995,
  "endName": "公司",
  "endAddress": "武汉市江汉区xxx",
  "endLat": 30.5,
  "endLng": 114.3,
  "distance": 5000,
  "duration": 900
}
```

### 3. 删除导航历史

**DELETE** `/navigation/history/:id`

**Headers**: `Authorization: Bearer {token}`

### 4. 清空导航历史

**DELETE** `/navigation/history`

**Headers**: `Authorization: Bearer {token}`

---

## 路线方案 API ⭐ 新增

### 1. 获取路线方案列表

**GET** `/routes?isFavorite=true&page=1&pageSize=20`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `isFavorite` (可选): 是否只显示收藏 (true/false)
- `page` (可选): 页码，默认1
- `pageSize` (可选): 每页数量，默认20

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [
      {
        "id": 1,
        "user_id": 1,
        "name": "上班路线",
        "start_name": "家",
        "start_lat": 30.486874,
        "start_lng": 114.309995,
        "end_name": "公司",
        "end_lat": 30.5,
        "end_lng": 114.3,
        "waypoints": "[{\"name\":\"服务区\",\"lat\":30.49,\"lng\":114.31}]",
        "distance": 5000,
        "duration": 900,
        "strategy": 0,
        "polyline": "114.31,30.49;114.32,30.50;...",
        "steps": "[{\"instruction\":\"向东行驶100米\",\"distance\":100}]",
        "is_favorite": true,
        "use_count": 10,
        "created_at": "2026-03-05T10:00:00.000Z",
        "updated_at": "2026-03-05T10:00:00.000Z"
      }
    ],
    "total": 5,
    "page": 1,
    "pageSize": 20
  }
}
```

### 2. 获取路线方案详情

**GET** `/routes/:id`

**Headers**: `Authorization: Bearer {token}`

### 3. 保存路线方案

**POST** `/routes`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "上班路线",
  "startName": "家",
  "startLat": 30.486874,
  "startLng": 114.309995,
  "endName": "公司",
  "endLat": 30.5,
  "endLng": 114.3,
  "waypoints": [
    {
      "name": "服务区",
      "lat": 30.49,
      "lng": 114.31
    }
  ],
  "distance": 5000,
  "duration": 900,
  "strategy": 0,
  "polyline": "114.31,30.49;114.32,30.50;...",
  "steps": [
    {
      "instruction": "向东行驶100米",
      "distance": 100,
      "duration": 20,
      "road": "中山大道"
    }
  ],
  "isFavorite": true
}
```

**strategy说明**:
- `0` - 推荐路线
- `1` - 避免拥堵
- `2` - 避免收费
- `3` - 高速优先

### 4. 更新路线方案

**PUT** `/routes/:id`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "新名称",
  "isFavorite": true
}
```

### 5. 使用路线方案

**POST** `/routes/:id/use`

**Headers**: `Authorization: Bearer {token}`

**说明**: 增加路线使用次数，返回路线详情

### 6. 删除路线方案

**DELETE** `/routes/:id`

**Headers**: `Authorization: Bearer {token}`

---

## 位置相关 API ⭐ 新增

### 1. 更新用户位置

**POST** `/location`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "latitude": 30.486874,
  "longitude": 114.309995,
  "accuracy": 10.5,
  "speed": 45.5,
  "heading": 90.0,
  "locationType": "ip",
  "isSharing": false
}
```

**locationType说明**:
- `gps` - GPS定位
- `network` - 网络定位（WiFi+基站）
- `ip` - IP定位

### 2. 获取用户位置

**GET** `/location` - 获取自己的位置

**GET** `/location/:targetUserId` - 获取其他用户位置（需要共享权限）

**Headers**: `Authorization: Bearer {token}`

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "id": 1,
    "user_id": 1,
    "latitude": 30.486874,
    "longitude": 114.309995,
    "accuracy": 10.5,
    "speed": 45.5,
    "heading": 90.0,
    "location_type": "ip",
    "is_sharing": false,
    "updated_at": "2026-03-05T10:00:00.000Z"
  }
}
```

### 3. 开启/关闭位置共享

**POST** `/location/sharing/toggle`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "isSharing": true
}
```

### 4. 创建位置共享

**POST** `/location/sharing`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "viewerId": 2,
  "expireHours": 24
}
```

**说明**: 
- `viewerId` - 允许查看的用户ID
- `expireHours` - 过期时间（小时），不传则永久有效

### 5. 获取位置共享列表

**GET** `/location/sharing?type=sharing`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `type`: `sharing` (我分享的) 或 `viewing` (我查看的)

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "sharer_id": 1,
      "viewer_id": 2,
      "expire_time": "2026-03-06T10:00:00.000Z",
      "is_active": true,
      "created_at": "2026-03-05T10:00:00.000Z",
      "nickname": "好友昵称",
      "phone": "13800138001"
    }
  ]
}
```

### 6. 取消位置共享

**DELETE** `/location/sharing/:id`

**Headers**: `Authorization: Bearer {token}`

### 7. 获取附近共享位置的用户

**GET** `/location/nearby?latitude=30.486874&longitude=114.309995&radius=5000`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `latitude` - 当前纬度
- `longitude` - 当前经度
- `radius` - 搜索半径（米），默认5000

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "user_id": 2,
      "latitude": 30.49,
      "longitude": 114.31,
      "speed": 30.0,
      "heading": 45.0,
      "location_type": "gps",
      "is_sharing": true,
      "updated_at": "2026-03-05T10:00:00.000Z",
      "nickname": "好友昵称",
      "avatar": "https://...",
      "distance": 450.5
    }
  ]
}
```

---

## 反馈相关 API ⭐ 新增

### 1. 提交导航反馈

**POST** `/feedback`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "navigationId": 1,
  "rating": 5,
  "feedbackType": "route",
  "content": "路线规划很准确",
  "locationLat": 30.486874,
  "locationLng": 114.309995
}
```

**feedbackType说明**:
- `route` - 路线问题
- `traffic` - 路况问题
- `poi` - 地点信息问题

**rating**: 1-5星评分

### 2. 获取反馈列表

**GET** `/feedback?feedbackType=route&page=1&pageSize=20`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `feedbackType` (可选): 反馈类型筛选
- `page` (可选): 页码，默认1
- `pageSize` (可选): 每页数量，默认20

### 3. 获取反馈统计

**GET** `/feedback/stats`

**Headers**: `Authorization: Bearer {token}`

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "total": 50,
    "avgRating": 4.5,
    "byType": [
      {
        "feedback_type": "route",
        "count": 20,
        "avg_rating": 4.8
      },
      {
        "feedback_type": "traffic",
        "count": 15,
        "avg_rating": 4.2
      },
      {
        "feedback_type": "poi",
        "count": 15,
        "avg_rating": 4.5
      }
    ]
  }
}
```

### 4. 获取反馈详情

**GET** `/feedback/:id`

**Headers**: `Authorization: Bearer {token}`

### 5. 删除反馈

**DELETE** `/feedback/:id`

**Headers**: `Authorization: Bearer {token}`

---

## 常去地点 API ⭐ 新增

### 1. 记录地点访问

**POST** `/frequent-locations/visit`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "星巴克",
  "address": "武汉市洪山区xxx",
  "latitude": 30.486874,
  "longitude": 114.309995,
  "timePattern": "工作日早上"
}
```

**timePattern示例**:
- "工作日早上" - 周一到周五 7:00-9:00
- "周末下午" - 周六日 14:00-18:00
- "每天晚上" - 每天 18:00-22:00

### 2. 获取常去地点列表

**GET** `/frequent-locations?limit=10&minVisits=2`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `limit` (可选): 返回数量，默认10
- `minVisits` (可选): 最少访问次数，默认2

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": [
    {
      "id": 1,
      "user_id": 1,
      "name": "星巴克",
      "address": "武汉市洪山区xxx",
      "latitude": 30.486874,
      "longitude": 114.309995,
      "visit_count": 15,
      "last_visit": "2026-03-05T10:00:00.000Z",
      "time_pattern": "工作日早上"
    }
  ]
}
```

### 3. 获取智能推荐地点

**GET** `/frequent-locations/recommended?timePattern=工作日早上&limit=5`

**Headers**: `Authorization: Bearer {token}`

**Query参数**:
- `timePattern` (可选): 时间规律筛选
- `limit` (可选): 返回数量，默认5

### 4. 获取访问统计

**GET** `/frequent-locations/stats`

**Headers**: `Authorization: Bearer {token}`

**响应**:
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "totalVisits": 150,
    "locationCount": 10,
    "byPattern": [
      {
        "time_pattern": "工作日早上",
        "count": 3,
        "total_visits": 45
      },
      {
        "time_pattern": "周末下午",
        "count": 2,
        "total_visits": 30
      }
    ]
  }
}
```

### 5. 获取地点详情

**GET** `/frequent-locations/:id`

**Headers**: `Authorization: Bearer {token}`

### 6. 更新地点信息

**PUT** `/frequent-locations/:id`

**Headers**: `Authorization: Bearer {token}`

**请求体**:
```json
{
  "name": "新名称",
  "address": "新地址",
  "timePattern": "工作日下午"
}
```

### 7. 删除常去地点

**DELETE** `/frequent-locations/:id`

**Headers**: `Authorization: Bearer {token}`

---

## 错误码说明

| 错误码 | 说明 |
|--------|------|
| 200 | 成功 |
| 400 | 请求参数错误 |
| 401 | 未授权（token无效或过期） |
| 403 | 无权限 |
| 404 | 资源不存在 |
| 500 | 服务器内部错误 |

---

## 通用响应格式

### 成功响应
```json
{
  "code": 200,
  "message": "操作成功",
  "data": {}
}
```

### 错误响应
```json
{
  "code": 400,
  "message": "错误描述"
}
```

---

## 认证说明

除了注册和登录接口外，所有API都需要在请求头中携带JWT token：

```
Authorization: Bearer eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...
```

Token在登录成功后返回，有效期为7天。

---

## 分页说明

支持分页的接口统一使用以下参数：
- `page`: 页码，从1开始
- `pageSize`: 每页数量

响应格式：
```json
{
  "code": 200,
  "message": "获取成功",
  "data": {
    "list": [],
    "total": 100,
    "page": 1,
    "pageSize": 20
  }
}
```

---

**文档版本**: v1.0
**更新时间**: 2026-03-05
**状态**: ✅ 已完成
