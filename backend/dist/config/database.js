"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.pool = void 0;
exports.testConnection = testConnection;
exports.query = query;
const promise_1 = __importDefault(require("mysql2/promise"));
const dotenv_1 = __importDefault(require("dotenv"));
dotenv_1.default.config();
// 数据库连接池配置
exports.pool = promise_1.default.createPool({
    host: process.env.DB_HOST || 'localhost',
    port: parseInt(process.env.DB_PORT || '3306'),
    user: process.env.DB_USER || 'root',
    password: process.env.DB_PASSWORD || '',
    database: process.env.DB_NAME || 'car_navigation',
    waitForConnections: true,
    connectionLimit: 10,
    queueLimit: 0,
    enableKeepAlive: true,
    keepAliveInitialDelay: 0
});
// 测试数据库连接
async function testConnection() {
    try {
        const connection = await exports.pool.getConnection();
        console.log('✅ 数据库连接成功');
        connection.release();
        return true;
    }
    catch (error) {
        console.error('❌ 数据库连接失败:', error);
        return false;
    }
}
// 执行SQL查询
async function query(sql, params) {
    const [rows] = await exports.pool.execute(sql, params);
    return rows;
}
