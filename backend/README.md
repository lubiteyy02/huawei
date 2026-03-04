# 车载导航系统后端API服务

基于Node.js + Express + MySQL的车载导航系统后端服务

## 📋 功能特性

- ✅ 用户注册登录（JWT认证）
- ✅ 收藏地点管理
- ✅ 导航历史记录
- ✅ 行程记录管理
- ✅ 搜索历史
- ✅ RESTful API设计
- ✅ 数据库连接池
- ✅ 跨域支持

## 🛠️ 技术栈

- **运行环境**: Node.js 18+
- **Web框架**: Express 4.x
- **数据库**: MySQL 8.0+
- **认证**: JWT (jsonwebtoken)
- **密码加密**: bcryptjs
- **语言**: TypeScript

## 📦 安装步骤

### 1. 安装依赖

```bash
cd backend
npm install
```

### 2. 配置环境变量

复制 `.env.example` 为 `.env` 并修改配置：

```bash
cp .env.example .env
```

编辑 `.env` 文件：

```env
# 服务器配置
PORT=3000
NODE_ENV=development

# 数据库配置
DB_HOST=localhost
DB_PORT=3306
DB_USER=root
DB_PASSWORD=your_password
DB_NAME=car_navigation

# JWT配置
JWT_SECRET=your_jwt_secret_key_change_this
JWT_EXPIRES_IN=7d
```

### 3. 初始化数据库

#### 方法一：使用MySQL客户端

```bash
mysql -u root -p < src/database/init.sql
```

#### 方法二：手动执行

1. 登录MySQL: `mysql -u root -p`
2. 复制 `src/database/init.sql` 内容并执行

### 4. 启动服务

#### 开发模式（热重载）

```bash
npm run dev
```

#### 生产模式

```bash
npm run build
npm start
```

服务将在 `http://localhost:3000` 启动

## 📡 API接口文档

### 基础信息

- **Base URL**: `http://localhost:3000/api/v1`
- **认证方式**: Bearer Token
- **请求头**: `Authorization: Bearer {token}`

### 1. 认证接口

#### 1.1 用户注册

```http
POST /api/v1/auth/register
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456",
  "nickname": "张三"
}
```

**响应示例**:
```json
{
  "code": 200,
  "message": "注册成功",
  "data": {
    "userId": 1,
    "phone": "13800138000",
    "nickname": "张三",
    "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9..."
  }
}
```

#### 1.2 用户登录

```http
POST /api/v1/auth/login
Content-Type: application/json

{
  "phone": "13800138000",
  "password": "123456"
}
```

#### 1.3 获取用户信息

```http
GET /api/v1/auth/profile
Authorization: Bearer {token}
```

#### 1.4 更新用户信息

```http
PUT /api/v1/auth/profile
Authorization: Bearer {token}
Content-Type: application/json

{
  "nickname": "新昵称",
  "avatar": "https://example.com/avatar.jpg"
}
```

### 2. 收藏接口

#### 2.1 获取收藏列表

```http
GET /api/v1/favorites?category=home
Authorization: Bearer {token}
```

**参数**:
- `category` (可选): home, work, custom

#### 2.2 添加收藏

```http
POST /api/v1/favorites
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "家",
  "address": "北京市海淀区中关村大街1号",
  "latitude": 39.9042,
  "longitude": 116.4074,
  "category": "home",
  "icon": "🏠"
}
```

#### 2.3 更新收藏

```http
PUT /api/v1/favorites/:id
Authorization: Bearer {token}
Content-Type: application/json

{
  "name": "新名称",
  "category": "custom"
}
```

#### 2.4 删除收藏

```http
DELETE /api/v1/favorites/:id
Authorization: Bearer {token}
```

### 3. 导航历史接口

#### 3.1 获取导航历史

```http
GET /api/v1/navigation/history?page=1&pageSize=20
Authorization: Bearer {token}
```

#### 3.2 保存导航记录

```http
POST /api/v1/navigation/history
Authorization: Bearer {token}
Content-Type: application/json

{
  "startName": "家",
  "startAddress": "北京市海淀区中关村大街1号",
  "startLat": 39.9042,
  "startLng": 116.4074,
  "endName": "公司",
  "endAddress": "北京市朝阳区建国门外大街1号",
  "endLat": 39.9100,
  "endLng": 116.4500,
  "distance": 15000,
  "duration": 1200
}
```

#### 3.3 删除导航历史

```http
DELETE /api/v1/navigation/history/:id
Authorization: Bearer {token}
```

#### 3.4 清空导航历史

```http
DELETE /api/v1/navigation/history
Authorization: Bearer {token}
```

## 🧪 测试

### 使用curl测试

```bash
# 注册
curl -X POST http://localhost:3000/api/v1/auth/register \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456","nickname":"测试用户"}'

# 登录
curl -X POST http://localhost:3000/api/v1/auth/login \
  -H "Content-Type: application/json" \
  -d '{"phone":"13800138000","password":"123456"}'

# 获取收藏（需要替换token）
curl -X GET http://localhost:3000/api/v1/favorites \
  -H "Authorization: Bearer YOUR_TOKEN_HERE"
```

### 使用Postman测试

1. 导入API集合
2. 设置环境变量 `baseUrl` = `http://localhost:3000/api/v1`
3. 登录后将token保存到环境变量
4. 测试其他接口

## 📁 项目结构

```
backend/
├── src/
│   ├── config/           # 配置文件
│   │   └── database.ts   # 数据库配置
│   ├── controllers/      # 控制器
│   │   ├── authController.ts
│   │   ├── favoriteController.ts
│   │   └── navigationController.ts
│   ├── middleware/       # 中间件
│   │   └── auth.ts       # JWT认证
│   ├── routes/           # 路由
│   │   └── index.ts
│   ├── database/         # 数据库脚本
│   │   └── init.sql
│   └── server.ts         # 服务入口
├── .env.example          # 环境变量示例
├── package.json
├── tsconfig.json
└── README.md
```

## 🚀 部署

### Docker部署（推荐）

1. 创建 `Dockerfile`:

```dockerfile
FROM node:18-alpine
WORKDIR /app
COPY package*.json ./
RUN npm install --production
COPY . .
RUN npm run build
EXPOSE 3000
CMD ["npm", "start"]
```

2. 构建镜像:

```bash
docker build -t car-navigation-backend .
```

3. 运行容器:

```bash
docker run -d -p 3000:3000 --name car-nav-api car-navigation-backend
```

### 传统部署

1. 安装Node.js 18+
2. 安装MySQL 8.0+
3. 克隆代码并安装依赖
4. 配置环境变量
5. 初始化数据库
6. 使用PM2启动:

```bash
npm install -g pm2
npm run build
pm2 start dist/server.js --name car-nav-api
```

## 🔒 安全建议

1. **生产环境必须修改**:
   - `JWT_SECRET`: 使用强随机字符串
   - 数据库密码
   
2. **启用HTTPS**: 使用Nginx反向代理

3. **限流**: 添加rate-limiting中间件

4. **输入验证**: 使用joi或express-validator

## 📝 常见问题

### Q: 数据库连接失败？
A: 检查MySQL是否启动，`.env`配置是否正确

### Q: JWT token过期？
A: 重新登录获取新token，或调整`JWT_EXPIRES_IN`

### Q: 跨域问题？
A: 已配置cors中间件，检查前端请求头

## 📄 License

MIT
