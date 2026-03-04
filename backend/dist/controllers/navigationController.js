"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.getNavigationHistory = getNavigationHistory;
exports.saveNavigationHistory = saveNavigationHistory;
exports.deleteNavigationHistory = deleteNavigationHistory;
exports.clearNavigationHistory = clearNavigationHistory;
const database_1 = require("../config/database");
/**
 * 获取导航历史
 */
async function getNavigationHistory(req, res) {
    try {
        const userId = req.userId;
        const { page = 1, pageSize = 20 } = req.query;
        const offset = (Number(page) - 1) * Number(pageSize);
        // 获取总数
        const countResult = await (0, database_1.query)('SELECT COUNT(*) as total FROM navigation_history WHERE user_id = ?', [userId]);
        const total = countResult[0].total;
        // 获取列表
        const history = await (0, database_1.query)('SELECT * FROM navigation_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ? OFFSET ?', [userId, Number(pageSize), offset]);
        res.json({
            code: 200,
            message: '获取成功',
            data: {
                list: history,
                total,
                page: Number(page),
                pageSize: Number(pageSize)
            }
        });
    }
    catch (error) {
        console.error('Get navigation history error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 保存导航记录
 */
async function saveNavigationHistory(req, res) {
    try {
        const userId = req.userId;
        const { startName, startAddress, startLat, startLng, endName, endAddress, endLat, endLng, distance, duration } = req.body;
        // 验证参数
        if (!endName || !endAddress || !endLat || !endLng) {
            return res.status(400).json({
                code: 400,
                message: '缺少必要参数'
            });
        }
        const result = await (0, database_1.query)(`INSERT INTO navigation_history 
       (user_id, start_name, start_address, start_lat, start_lng, end_name, end_address, end_lat, end_lng, distance, duration) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`, [userId, startName, startAddress, startLat, startLng, endName, endAddress, endLat, endLng, distance, duration]);
        res.status(201).json({
            code: 200,
            message: '保存成功',
            data: {
                id: result.insertId
            }
        });
    }
    catch (error) {
        console.error('Save navigation history error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 删除导航历史
 */
async function deleteNavigationHistory(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const result = await (0, database_1.query)('DELETE FROM navigation_history WHERE id = ? AND user_id = ?', [id, userId]);
        if (result.affectedRows === 0) {
            return res.status(404).json({
                code: 404,
                message: '记录不存在'
            });
        }
        res.json({
            code: 200,
            message: '删除成功'
        });
    }
    catch (error) {
        console.error('Delete navigation history error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 清空导航历史
 */
async function clearNavigationHistory(req, res) {
    try {
        const userId = req.userId;
        await (0, database_1.query)('DELETE FROM navigation_history WHERE user_id = ?', [userId]);
        res.json({
            code: 200,
            message: '清空成功'
        });
    }
    catch (error) {
        console.error('Clear navigation history error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
