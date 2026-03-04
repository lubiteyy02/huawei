# 🚗 车载导航系统 - 完整部署指南

## 📋 项目概述

这是一个基于鸿蒙HarmonyOS Next的车载信息娱乐系统，包含完整的导航功能。

### 技术架构

```
┌─────────────────────────────────────┐
│   HarmonyOS 前端应用 (ArkTS)         │
│   - 地图显示与交互                    │
│   - 实时定位                         │
│   - 路径规划与导航                    │
│   - POI搜索                          │
└─────────────────────────────────────┘
              ↓ HTTPS
┌─────────────────────────────────────┐
│   后端API服务 (Node.js + Express)    │
│   - 用户认证                         │
│   - 数据管理                         │
│   - 业务逻辑                         │
└─────────────────────────────────────┘
              ↓
┌─────────────────────────────────────┐
│   MySQL数据库                        │
│   - 用户数据                         │
│   - 收藏地点                         │
│   - 历史记录                         │
└─────────────────────────────────────┘
```

## 🎯 第一部分：后端部署

### 1.1 环境准备

#### 安装Node.js

```bash
# Windows
# 下载并安装: https://nodejs.org/ (推荐LTS版本 18.x)

# 验证安装
node --version  # 应显示 v18.x.x
npm --version   # 应显示 9.x.x
```

#### 安装MySQL

```bash
# Windows
# 下载并安装: https://dev.mysql.com/downloads/mysql/

# 安装后启动MySQL服务
net start MySQL80
```

### 1.2 数据库初始化

#### 方法一：使用MySQL Workbench（推荐新手）

1. 打开MySQL Workbench
2. 连接到本地MySQL服务器
3. 打开 `backend/src/database/init.sql` 文件
4. 点击"执行"按钮运行脚本

#### 方法二：使用命令行

```bash
# 登录MySQL
mysql -u root -p

# 执行初始化脚本
source D:/path/to/backend/src/database/init.sql

# 或者直接执行
mysql -u root -p < backend/src/database/init.sql
```

#### 验证数据库

```sql
-- 查看数据库
SHOW DATABASES;

-- 使用数据库
USE car_navigation;

-- 查看表
SHOW TABLES;

-- 查看测试数据
SELECT * FROM users;
```

### 1.3 后端配置

#### 1. 进入后端目录

```bash
cd backend
```

#### 2. 安装依赖

```bash
npm install
```

#### 3. 配置环境变量

```bash
# 复制配置文件
copy .env.example .env

# 编辑 .env 文件
notepad .env
```

修改以下配置：

```env
# 服务器配置
PORT=3000
NODE_ENV=development

# 数据库配置（根据你的MySQL配置修改）
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=你的MySQL密码
DB_NAME=car_navigation

# JWT配置（生产环境必须修改）
JWT_SECRET=your_super_secret_key_change_this_in_production
JWT_EXPIRES_IN=7d
```

### 1.4 启动后端服务

#### 开发模式（推荐）

```bash
npm run dev
```

看到以下输出表示启动成功：

```
🚀 ========================================
🚀 车载导航系统后端服务已启动
🚀 运行环境: development
🚀 服务地址: http://localhost:3000
🚀 API文档: http://localhost:3000/api/v1
🚀 健康检查: http://localhost:3000/health
🚀 ========================================
```

#### 生产模式

```bash
npm run build
npm start
```

### 1.5 测试后端API

#### 使用浏览器测试

访问: `http://localhost:3000/health`

应该看到：

```json
{
  "status": "ok",
  "timestamp": "2026-03-04T00:00:00.000Z"
}
```

#### 使用Postman测试

1. **注册用户**

```http
POST http://localhost:3000/api/v1/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456",
  "nickname": "测试用户"
}
```

2. **登录获取token**

```http
POST http://localhost:3000/api/v1/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456"
}
```

复制返回的 `token`

3. **测试收藏接口**

```http
GET http://localhost:3000/api/v1/favorites
Authorization: Bearer 你的token
```

## 🎯 第二部分：前端开发

### 2.1 环境准备

#### 安装DevEco Studio

1. 下载: https://developer.huawei.com/consumer/cn/deveco-studio/
2. 安装并配置HarmonyOS SDK
3. 配置模拟器或连接真机

### 2.2 项目配置

#### 1. 打开项目

使用DevEco Studio打开项目根目录

#### 2. 配置API地址

编辑 `entry/src/main/ets/services/HttpService.ets`:

```typescript
// 开发环境 - 使用本机IP（不要用localhost）
const BASE_URL = 'http://192.168.1.100:3000/api/v1';

// 生产环境
// const BASE_URL = 'https://your-api.com/api/v1';
```

**重要**: 
- 如果使用模拟器，需要使用电脑的局域网IP
- 查看IP: `ipconfig` (Windows) 或 `ifconfig` (Mac/Linux)
- 确保手机/模拟器与电脑在同一网络

#### 3. 配置权限

编辑 `entry/src/main/module.json5`，确保包含以下权限：

```json
{
  "module": {
    "requestPermissions": [
      {
        "name": "ohos.permission.LOCATION",
        "reason": "$string:location_reason",
        "usedScene": {
          "abilities": ["EntryAbility"],
          "when": "inuse"
        }
      },
      {
        "name": "ohos.permission.APPROXIMATELY_LOCATION",
        "reason": "$string:location_reason"
      },
      {
        "name": "ohos.permission.INTERNET",
        "reason": "$string:internet_reason"
      }
    ]
  }
}
```

### 2.3 集成地图SDK

#### 选择地图服务商

**选项1: 高德地图**
1. 注册高德开放平台账号: https://lbs.amap.com/
2. 创建应用获取API Key
3. 下载HarmonyOS SDK

**选项2: 百度地图**
1. 注册百度地图开放平台: https://lbsyun.baidu.com/
2. 创建应用获取API Key
3. 下载HarmonyOS SDK

#### 配置SDK

1. 将SDK文件放入 `entry/libs/` 目录
2. 在 `entry/oh-package.json5` 中添加依赖
3. 在代码中初始化SDK

### 2.4 运行前端应用

#### 1. 同步项目

点击 DevEco Studio 顶部的 "Sync" 按钮

#### 2. 选择设备

- 使用模拟器: 启动HarmonyOS模拟器
- 使用真机: 连接鸿蒙设备并开启开发者模式

#### 3. 运行应用

点击 "Run" 按钮或按 `Shift + F10`

## 🎯 第三部分：功能测试

### 3.1 测试流程

#### 1. 用户注册登录

1. 启动应用
2. 点击"注册"按钮
3. 输入手机号和密码
4. 注册成功后自动登录

#### 2. 测试定位功能

1. 授予位置权限
2. 等待GPS定位
3. 查看当前位置标记
4. 查看速度和坐标信息

#### 3. 测试搜索功能

1. 点击搜索框
2. 输入"加油站"
3. 查看搜索结果列表
4. 点击结果查看详情

#### 4. 测试导航功能

1. 搜索目的地
2. 点击"导航"按钮
3. 查看路线规划
4. 开始导航
5. 查看导航指引

#### 5. 测试收藏功能

1. 搜索地点
2. 点击"收藏"按钮
3. 设置收藏名称
4. 在收藏列表查看

### 3.2 常见问题排查

#### 问题1: 后端连接失败

**症状**: 前端无法调用API

**解决方案**:
1. 检查后端是否启动: `http://localhost:3000/health`
2. 检查IP地址是否正确
3. 检查防火墙是否阻止3000端口
4. 使用 `ping` 测试网络连通性

#### 问题2: 定位失败

**症状**: 无法获取GPS位置

**解决方案**:
1. 检查是否授予位置权限
2. 模拟器需要设置模拟位置
3. 真机需要开启GPS
4. 检查网络连接

#### 问题3: 地图不显示

**症状**: 地图区域空白

**解决方案**:
1. 检查地图SDK是否正确集成
2. 检查API Key是否有效
3. 检查网络权限
4. 查看控制台错误日志

#### 问题4: 数据库连接失败

**症状**: 后端启动报错

**解决方案**:
1. 检查MySQL服务是否启动
2. 检查 `.env` 配置是否正确
3. 检查数据库是否已创建
4. 检查用户权限

## 🎯 第四部分：生产部署

### 4.1 后端生产部署

#### 使用PM2部署

```bash
# 安装PM2
npm install -g pm2

# 构建项目
cd backend
npm run build

# 启动服务
pm2 start dist/server.js --name car-nav-api

# 查看状态
pm2 status

# 查看日志
pm2 logs car-nav-api

# 设置开机自启
pm2 startup
pm2 save
```

#### 使用Docker部署

```bash
# 构建镜像
cd backend
docker build -t car-nav-api .

# 运行容器
docker run -d \
  -p 3000:3000 \
  --name car-nav-api \
  -e DB_HOST=your_db_host \
  -e DB_PASSWORD=your_db_password \
  car-nav-api

# 查看日志
docker logs -f car-nav-api
```

### 4.2 配置Nginx反向代理

```nginx
server {
    listen 80;
    server_name your-domain.com;

    location /api/ {
        proxy_pass http://localhost:3000/api/;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
        proxy_set_header X-Forwarded-For $proxy_add_x_forwarded_for;
    }
}
```

### 4.3 配置HTTPS

```bash
# 使用Let's Encrypt获取免费证书
certbot --nginx -d your-domain.com
```

### 4.4 前端打包发布

1. 在DevEco Studio中选择 "Build > Build Hap(s)/App(s)"
2. 选择Release模式
3. 配置签名证书
4. 生成HAP包
5. 上传到华为应用市场

## 📊 性能优化建议

### 后端优化

1. **数据库优化**
   - 添加索引
   - 使用连接池
   - 定期清理历史数据

2. **缓存优化**
   - 使用Redis缓存热点数据
   - 缓存用户信息
   - 缓存搜索结果

3. **接口优化**
   - 实现分页查询
   - 压缩响应数据
   - 使用CDN加速

### 前端优化

1. **地图优化**
   - 使用离线地图
   - 缓存地图瓦片
   - 延迟加载POI

2. **定位优化**
   - 调整定位频率
   - 使用低功耗模式
   - 缓存位置信息

3. **网络优化**
   - 请求合并
   - 数据压缩
   - 离线缓存

## 📝 维护建议

### 日常维护

1. **监控日志**
   - 定期查看错误日志
   - 监控API响应时间
   - 跟踪用户行为

2. **数据备份**
   - 每日自动备份数据库
   - 保留最近30天备份
   - 测试恢复流程

3. **安全更新**
   - 定期更新依赖包
   - 修复安全漏洞
   - 更新SSL证书

### 故障处理

1. **服务器宕机**
   - 检查进程状态
   - 查看错误日志
   - 重启服务

2. **数据库故障**
   - 检查连接数
   - 优化慢查询
   - 恢复备份

3. **性能下降**
   - 分析慢接口
   - 优化数据库查询
   - 增加服务器资源

## 🎓 学习资源

### 官方文档

- HarmonyOS开发文档: https://developer.huawei.com/consumer/cn/doc/
- Node.js文档: https://nodejs.org/docs/
- MySQL文档: https://dev.mysql.com/doc/
- Express文档: https://expressjs.com/

### 推荐教程

- 鸿蒙应用开发入门
- TypeScript基础教程
- RESTful API设计规范
- MySQL性能优化

## 📞 技术支持

如有问题，请查看：
1. 项目README文档
2. 后端API文档
3. 常见问题FAQ
4. GitHub Issues

---

**祝你开发顺利！🎉**
