# 车载导航系统后端服务

基于 Node.js + Express + MySQL 的车载导航系统后端API服务。

## 功能特性

### 核心功能
- ✅ 用户认证（注册/登录/JWT）
- ✅ 收藏地点管理
- ✅ 导航历史记录
- ✅ 行程记录
- ✅ 搜索历史

### 新增功能 ⭐
- ✅ 路线方案保存和收藏
- ✅ 实时位置共享（家人/朋友）
- ✅ 导航反馈和评分
- ✅ 智能地点推荐
- ✅ 协同导航支持

## 技术栈

- **运行环境**: Node.js 18+
- **Web框架**: Express 4.x
- **数据库**: MySQL 8.0+
- **认证**: JWT (jsonwebtoken)
- **密码加密**: bcryptjs
- **语言**: TypeScript

## 快速开始

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

### 3. 初始化数据库

```bash
mysql -u root -p < src/database/init.sql
```

### 4. 启动服务

```bash
# 开发模式
npm run dev

# 生产模式
npm run build
npm start
```

## API文档

详细文档：[API_DOCUMENTATION.md](./API_DOCUMENTATION.md)

## 数据库设计

详细文档：[DATABASE_DESIGN.md](./DATABASE_DESIGN.md)

---

**版本**: v1.0.0
**状态**: ✅ 生产就绪
