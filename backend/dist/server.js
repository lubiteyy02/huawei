"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const cors_1 = __importDefault(require("cors"));
const dotenv_1 = __importDefault(require("dotenv"));
const routes_1 = __importDefault(require("./routes"));
const database_1 = require("./config/database");
// 加载环境变量
dotenv_1.default.config();
const app = (0, express_1.default)();
const PORT = process.env.PORT || 3000;
// 中间件
app.use((0, cors_1.default)()); // 允许跨域
app.use(express_1.default.json()); // 解析JSON请求体
app.use(express_1.default.urlencoded({ extended: true })); // 解析URL编码请求体
// 请求日志
app.use((req, res, next) => {
    console.log(`${new Date().toISOString()} - ${req.method} ${req.path}`);
    next();
});
// API路由
app.use('/api/v1', routes_1.default);
// 健康检查
app.get('/health', (req, res) => {
    res.json({
        status: 'ok',
        timestamp: new Date().toISOString()
    });
});
// 404处理
app.use((req, res) => {
    res.status(404).json({
        code: 404,
        message: '接口不存在'
    });
});
// 错误处理
app.use((err, req, res, next) => {
    console.error('Server error:', err);
    res.status(500).json({
        code: 500,
        message: '服务器内部错误'
    });
});
// 启动服务器
async function startServer() {
    try {
        // 测试数据库连接
        const dbConnected = await (0, database_1.testConnection)();
        if (!dbConnected) {
            console.error('❌ 数据库连接失败，服务器启动中止');
            process.exit(1);
        }
        // 启动HTTP服务
        app.listen(PORT, () => {
            console.log('');
            console.log('🚀 ========================================');
            console.log(`🚀 车载导航系统后端服务已启动`);
            console.log(`🚀 运行环境: ${process.env.NODE_ENV || 'development'}`);
            console.log(`🚀 服务地址: http://localhost:${PORT}`);
            console.log(`🚀 API文档: http://localhost:${PORT}/api/v1`);
            console.log(`🚀 健康检查: http://localhost:${PORT}/health`);
            console.log('🚀 ========================================');
            console.log('');
        });
    }
    catch (error) {
        console.error('❌ 服务器启动失败:', error);
        process.exit(1);
    }
}
// 优雅关闭
process.on('SIGTERM', () => {
    console.log('收到SIGTERM信号，正在关闭服务器...');
    process.exit(0);
});
process.on('SIGINT', () => {
    console.log('收到SIGINT信号，正在关闭服务器...');
    process.exit(0);
});
// 启动
startServer();
