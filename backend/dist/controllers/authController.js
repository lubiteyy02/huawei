"use strict";
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
exports.register = register;
exports.login = login;
exports.getProfile = getProfile;
exports.updateProfile = updateProfile;
const bcryptjs_1 = __importDefault(require("bcryptjs"));
const database_1 = require("../config/database");
const auth_1 = require("../middleware/auth");
/**
 * 用户注册
 */
async function register(req, res) {
    try {
        const { phone, password, nickname } = req.body;
        // 验证参数
        if (!phone || !password) {
            return res.status(400).json({
                code: 400,
                message: '手机号和密码不能为空'
            });
        }
        // 检查手机号是否已注册
        const existingUsers = await (0, database_1.query)('SELECT id FROM users WHERE phone = ?', [phone]);
        if (existingUsers.length > 0) {
            return res.status(400).json({
                code: 400,
                message: '该手机号已注册'
            });
        }
        // 加密密码
        const hashedPassword = await bcryptjs_1.default.hash(password, 10);
        // 插入用户
        const result = await (0, database_1.query)('INSERT INTO users (phone, password, nickname) VALUES (?, ?, ?)', [phone, hashedPassword, nickname || `用户${phone.slice(-4)}`]);
        const userId = result.insertId;
        // 生成token
        const token = (0, auth_1.generateToken)(userId);
        res.status(201).json({
            code: 200,
            message: '注册成功',
            data: {
                userId,
                phone,
                nickname: nickname || `用户${phone.slice(-4)}`,
                token
            }
        });
    }
    catch (error) {
        console.error('Register error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 用户登录
 */
async function login(req, res) {
    try {
        const { phone, password } = req.body;
        // 验证参数
        if (!phone || !password) {
            return res.status(400).json({
                code: 400,
                message: '手机号和密码不能为空'
            });
        }
        // 查询用户
        const users = await (0, database_1.query)('SELECT id, phone, password, nickname, avatar FROM users WHERE phone = ?', [phone]);
        if (users.length === 0) {
            return res.status(401).json({
                code: 401,
                message: '手机号或密码错误'
            });
        }
        const user = users[0];
        // 验证密码
        const isPasswordValid = await bcryptjs_1.default.compare(password, user.password);
        if (!isPasswordValid) {
            return res.status(401).json({
                code: 401,
                message: '手机号或密码错误'
            });
        }
        // 生成token
        const token = (0, auth_1.generateToken)(user.id);
        res.json({
            code: 200,
            message: '登录成功',
            data: {
                userId: user.id,
                phone: user.phone,
                nickname: user.nickname,
                avatar: user.avatar,
                token
            }
        });
    }
    catch (error) {
        console.error('Login error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取用户信息
 */
async function getProfile(req, res) {
    try {
        const userId = req.userId;
        const users = await (0, database_1.query)('SELECT id, phone, nickname, avatar, created_at FROM users WHERE id = ?', [userId]);
        if (users.length === 0) {
            return res.status(404).json({
                code: 404,
                message: '用户不存在'
            });
        }
        res.json({
            code: 200,
            message: '获取成功',
            data: users[0]
        });
    }
    catch (error) {
        console.error('Get profile error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 更新用户信息
 */
async function updateProfile(req, res) {
    try {
        const userId = req.userId;
        const { nickname, avatar } = req.body;
        const updates = [];
        const params = [];
        if (nickname) {
            updates.push('nickname = ?');
            params.push(nickname);
        }
        if (avatar) {
            updates.push('avatar = ?');
            params.push(avatar);
        }
        if (updates.length === 0) {
            return res.status(400).json({
                code: 400,
                message: '没有要更新的内容'
            });
        }
        params.push(userId);
        await (0, database_1.query)(`UPDATE users SET ${updates.join(', ')} WHERE id = ?`, params);
        res.json({
            code: 200,
            message: '更新成功'
        });
    }
    catch (error) {
        console.error('Update profile error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
