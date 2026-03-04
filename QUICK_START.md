# 🚀 快速开始指南

## 5分钟快速启动项目

### 前置条件

- ✅ 已安装 Node.js 18+
- ✅ 已安装 MySQL 8.0+
- ✅ 已安装 DevEco Studio

---

## 第一步：启动后端服务（2分钟）

### 1. 初始化数据库

```bash
# 登录MySQL
mysql -u root -p

# 执行初始化脚本（复制粘贴整个文件内容）
# 文件位置: backend/src/database/init.sql
```

### 2. 配置后端

```bash
# 进入后端目录
cd backend

# 安装依赖
npm install

# 复制配置文件
copy .env.example .env

# 编辑 .env 文件，修改数据库密码
notepad .env
```

修改这一行：
```env
DB_PASSWORD=你的MySQL密码
```

### 3. 启动后端

```bash
npm run dev
```

看到这个输出就成功了：
```
🚀 车载导航系统后端服务已启动
🚀 服务地址: http://localhost:3000
```

### 4. 测试后端

打开浏览器访问: `http://localhost:3000/health`

应该看到：
```json
{
  "status": "ok",
  "timestamp": "..."
}
```

---

## 第二步：运行前端应用（3分钟）

### 1. 配置API地址

编辑文件: `entry/src/main/ets/services/HttpService.ets`

找到这一行：
```typescript
const BASE_URL = 'http://localhost:3000/api/v1';
```

**如果使用模拟器**，改为你的电脑IP：
```typescript
const BASE_URL = 'http://192.168.1.100:3000/api/v1';  // 改成你的IP
```

查看你的IP地址：
```bash
# Windows
ipconfig

# 找到 IPv4 地址，例如: 192.168.1.100
```

### 2. 打开项目

1. 启动 DevEco Studio
2. 打开项目根目录
3. 等待项目同步完成

### 3. 运行应用

1. 点击顶部的 "Run" 按钮
2. 选择模拟器或真机
3. 等待应用安装启动

---

## 第三步：测试功能（1分钟）

### 1. 测试注册登录

1. 应用启动后，点击"注册"
2. 输入手机号: `13800138000`
3. 输入密码: `123456`
4. 点击注册

### 2. 测试导航功能

1. 授予位置权限
2. 等待定位成功
3. 点击搜索框
4. 输入"加油站"
5. 点击搜索结果
6. 点击"导航"按钮

---

## 常见问题

### Q1: 后端启动失败？

**错误**: `数据库连接失败`

**解决**:
1. 检查MySQL是否启动: `net start MySQL80`
2. 检查 `.env` 中的密码是否正确
3. 检查数据库是否已创建: `SHOW DATABASES;`

---

### Q2: 前端无法连接后端？

**错误**: `网络请求失败`

**解决**:
1. 检查后端是否启动
2. 检查IP地址是否正确
3. 检查防火墙是否阻止3000端口
4. 使用 `ping 192.168.1.100` 测试网络

---

### Q3: 定位失败？

**错误**: `无法获取位置`

**解决**:
1. 检查是否授予位置权限
2. 模拟器需要设置模拟位置
3. 真机需要开启GPS

---

## 测试账号

数据库已预置测试账号：

- 手机号: `13800138000`
- 密码: `123456`

- 手机号: `13800138001`
- 密码: `123456`

---

## 下一步

✅ 项目已成功运行！

现在你可以：

1. **查看完整文档**
   - `DEPLOYMENT_GUIDE.md` - 详细部署指南
   - `PROJECT_SUMMARY.md` - 项目总结
   - `backend/README.md` - 后端API文档

2. **开始开发**
   - 集成真实的地图SDK
   - 完善导航功能
   - 优化UI界面

3. **学习代码**
   - 前端服务层: `entry/src/main/ets/services/`
   - 后端控制器: `backend/src/controllers/`
   - 数据库设计: `backend/src/database/init.sql`

---

## 需要帮助？

- 📖 查看详细文档
- 🐛 检查常见问题
- 💬 查看代码注释

**祝你开发顺利！** 🎉
