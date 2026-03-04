"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.authMiddleware = authMiddleware;
exports.generateToken = generateToken;
const jsonwebtoken_1 = __importDefault(require("jsonwebtoken"));
const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';
/**
 * JWT认证中间件
 */
function authMiddleware(req, res, next) {
    try {
        // 从请求头获取token
        const authHeader = req.headers.authorization;
        if (!authHeader || !authHeader.startsWith('Bearer ')) {
            return res.status(401).json({
                code: 401,
                message: '未提供认证令牌'
            });
        }
        const token = authHeader.substring(7); // 移除 "Bearer " 前缀
        // 验证token
        const decoded = jsonwebtoken_1.default.verify(token, JWT_SECRET);
        // 将用户ID添加到请求对象
        req.userId = decoded.userId;
        next();
    }
    catch (error) {
        if (error instanceof jsonwebtoken_1.default.TokenExpiredError) {
            return res.status(401).json({
                code: 401,
                message: '认证令牌已过期'
            });
        }
        return res.status(401).json({
            code: 401,
            message: '无效的认证令牌'
        });
    }
}
/**
 * 生成JWT token
 */
function generateToken(userId) {
    return jsonwebtoken_1.default.sign({ userId }, JWT_SECRET, { expiresIn: process.env.JWT_EXPIRES_IN || '7d' });
}
