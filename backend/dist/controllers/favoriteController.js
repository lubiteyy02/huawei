"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getFavorites = getFavorites;
exports.addFavorite = addFavorite;
exports.updateFavorite = updateFavorite;
exports.deleteFavorite = deleteFavorite;
const database_1 = require("../config/database");
/**
 * 获取收藏列表
 */
async function getFavorites(req, res) {
    try {
        const userId = req.userId;
        const { category } = req.query;
        let sql = 'SELECT * FROM favorites WHERE user_id = ?';
        const params = [userId];
        if (category) {
            sql += ' AND category = ?';
            params.push(category);
        }
        sql += ' ORDER BY created_at DESC';
        const favorites = await (0, database_1.query)(sql, params);
        res.json({
            code: 200,
            message: '获取成功',
            data: favorites
        });
    }
    catch (error) {
        console.error('Get favorites error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 添加收藏
 */
async function addFavorite(req, res) {
    try {
        console.log('=== 收藏请求开始 ===');
        console.log('userId:', req.userId);
        console.log('请求体:', JSON.stringify(req.body));
        const userId = req.userId;
        const { name, address, latitude, longitude, category, icon } = req.body;
        // 验证userId
        if (!userId) {
            console.error('❌ userId未定义');
            return res.status(401).json({
                code: 401,
                message: '用户未认证'
            });
        }
        // 验证参数
        if (!name || !address || !latitude || !longitude) {
            console.error('❌ 缺少必要参数:', { name, address, latitude, longitude });
            return res.status(400).json({
                code: 400,
                message: '缺少必要参数'
            });
        }
        console.log('✅ 参数验证通过');
        // 检查是否已收藏
        console.log('检查是否已收藏...');
        const existing = await (0, database_1.query)('SELECT id FROM favorites WHERE user_id = ? AND latitude = ? AND longitude = ?', [userId, latitude, longitude]);
        if (existing.length > 0) {
            console.log('⚠️ 该地点已收藏');
            return res.status(400).json({
                code: 400,
                message: '该地点已收藏'
            });
        }
        console.log('插入收藏记录...');
        const result = await (0, database_1.query)('INSERT INTO favorites (user_id, name, address, latitude, longitude, category, icon) VALUES (?, ?, ?, ?, ?, ?, ?)', [userId, name, address, latitude, longitude, category || 'custom', icon]);
        console.log('✅ 收藏成功, insertId:', result.insertId);
        console.log('=== 收藏请求结束 ===');
        res.status(201).json({
            code: 200,
            message: '收藏成功',
            data: {
                id: result.insertId
            }
        });
    }
    catch (error) {
        console.error('❌ Add favorite error:', error);
        console.error('错误堆栈:', error instanceof Error ? error.stack : 'No stack trace');
        res.status(500).json({
            code: 500,
            message: '服务器错误: ' + (error instanceof Error ? error.message : String(error))
        });
    }
}
/**
 * 更新收藏
 */
async function updateFavorite(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const { name, address, category, icon } = req.body;
        // 验证权限
        const favorites = await (0, database_1.query)('SELECT id FROM favorites WHERE id = ? AND user_id = ?', [id, userId]);
        if (favorites.length === 0) {
            return res.status(404).json({
                code: 404,
                message: '收藏不存在'
            });
        }
        const updates = [];
        const params = [];
        if (name) {
            updates.push('name = ?');
            params.push(name);
        }
        if (address) {
            updates.push('address = ?');
            params.push(address);
        }
        if (category) {
            updates.push('category = ?');
            params.push(category);
        }
        if (icon) {
            updates.push('icon = ?');
            params.push(icon);
        }
        if (updates.length === 0) {
            return res.status(400).json({
                code: 400,
                message: '没有要更新的内容'
            });
        }
        params.push(id, userId);
        await (0, database_1.query)(`UPDATE favorites SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`, params);
        res.json({
            code: 200,
            message: '更新成功'
        });
    }
    catch (error) {
        console.error('Update favorite error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 删除收藏
 */
async function deleteFavorite(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const result = await (0, database_1.query)('DELETE FROM favorites WHERE id = ? AND user_id = ?', [id, userId]);
        if (result.affectedRows === 0) {
            return res.status(404).json({
                code: 404,
                message: '收藏不存在'
            });
        }
        res.json({
            code: 200,
            message: '删除成功'
        });
    }
    catch (error) {
        console.error('Delete favorite error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
