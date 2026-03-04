"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.recordVisit = recordVisit;
exports.getFrequentLocations = getFrequentLocations;
exports.getRecommendedLocations = getRecommendedLocations;
exports.getLocationDetail = getLocationDetail;
exports.updateLocation = updateLocation;
exports.deleteLocation = deleteLocation;
exports.getVisitStats = getVisitStats;
const database_1 = require("../config/database");
/**
 * 记录地点访问
 */
async function recordVisit(req, res) {
    try {
        const userId = req.userId;
        const { name, address, latitude, longitude, timePattern } = req.body;
        // 验证参数
        if (!name || !latitude || !longitude) {
            return res.status(400).json({
                code: 400,
                message: '缺少必要参数'
            });
        }
        // 检查是否已存在（使用坐标判断，允许小范围误差）
        const existing = await (0, database_1.query)(`SELECT * FROM frequent_locations 
       WHERE user_id = ? 
       AND ABS(latitude - ?) < 0.001 
       AND ABS(longitude - ?) < 0.001`, [userId, latitude, longitude]);
        if (existing.length > 0) {
            // 更新访问次数和时间
            await (0, database_1.query)(`UPDATE frequent_locations 
         SET visit_count = visit_count + 1, 
             last_visit = CURRENT_TIMESTAMP,
             time_pattern = ?
         WHERE id = ?`, [timePattern, existing[0].id]);
            res.json({
                code: 200,
                message: '访问记录更新成功',
                data: {
                    id: existing[0].id,
                    visitCount: existing[0].visit_count + 1
                }
            });
        }
        else {
            // 新增记录
            const result = await (0, database_1.query)(`INSERT INTO frequent_locations 
         (user_id, name, address, latitude, longitude, visit_count, time_pattern) 
         VALUES (?, ?, ?, ?, ?, 1, ?)`, [userId, name, address, latitude, longitude, timePattern]);
            res.status(201).json({
                code: 200,
                message: '访问记录创建成功',
                data: {
                    id: result.insertId,
                    visitCount: 1
                }
            });
        }
    }
    catch (error) {
        console.error('Record visit error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取常去地点列表
 */
async function getFrequentLocations(req, res) {
    try {
        const userId = req.userId;
        const { limit = 10, minVisits = 2 } = req.query;
        const locations = await (0, database_1.query)(`SELECT * FROM frequent_locations 
       WHERE user_id = ? AND visit_count >= ? 
       ORDER BY visit_count DESC, last_visit DESC 
       LIMIT ?`, [userId, Number(minVisits), Number(limit)]);
        res.json({
            code: 200,
            message: '获取成功',
            data: locations
        });
    }
    catch (error) {
        console.error('Get frequent locations error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取智能推荐地点
 */
async function getRecommendedLocations(req, res) {
    try {
        const userId = req.userId;
        const { timePattern, limit = 5 } = req.query;
        let sql = `SELECT * FROM frequent_locations WHERE user_id = ?`;
        const params = [userId];
        if (timePattern) {
            sql += ' AND time_pattern = ?';
            params.push(timePattern);
        }
        sql += ' ORDER BY visit_count DESC, last_visit DESC LIMIT ?';
        params.push(Number(limit));
        const locations = await (0, database_1.query)(sql, params);
        res.json({
            code: 200,
            message: '获取成功',
            data: locations
        });
    }
    catch (error) {
        console.error('Get recommended locations error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取地点详情
 */
async function getLocationDetail(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const locations = await (0, database_1.query)('SELECT * FROM frequent_locations WHERE id = ? AND user_id = ?', [id, userId]);
        if (locations.length === 0) {
            return res.status(404).json({
                code: 404,
                message: '地点不存在'
            });
        }
        res.json({
            code: 200,
            message: '获取成功',
            data: locations[0]
        });
    }
    catch (error) {
        console.error('Get location detail error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 更新地点信息
 */
async function updateLocation(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const { name, address, timePattern } = req.body;
        // 验证权限
        const locations = await (0, database_1.query)('SELECT id FROM frequent_locations WHERE id = ? AND user_id = ?', [id, userId]);
        if (locations.length === 0) {
            return res.status(404).json({
                code: 404,
                message: '地点不存在'
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
        if (timePattern) {
            updates.push('time_pattern = ?');
            params.push(timePattern);
        }
        if (updates.length === 0) {
            return res.status(400).json({
                code: 400,
                message: '没有要更新的内容'
            });
        }
        params.push(id, userId);
        await (0, database_1.query)(`UPDATE frequent_locations SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`, params);
        res.json({
            code: 200,
            message: '更新成功'
        });
    }
    catch (error) {
        console.error('Update location error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 删除常去地点
 */
async function deleteLocation(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const result = await (0, database_1.query)('DELETE FROM frequent_locations WHERE id = ? AND user_id = ?', [id, userId]);
        if (result.affectedRows === 0) {
            return res.status(404).json({
                code: 404,
                message: '地点不存在'
            });
        }
        res.json({
            code: 200,
            message: '删除成功'
        });
    }
    catch (error) {
        console.error('Delete location error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取访问统计
 */
async function getVisitStats(req, res) {
    try {
        const userId = req.userId;
        // 总访问次数
        const totalResult = await (0, database_1.query)('SELECT SUM(visit_count) as total_visits, COUNT(*) as location_count FROM frequent_locations WHERE user_id = ?', [userId]);
        // 按时间规律统计
        const patternStats = await (0, database_1.query)(`SELECT time_pattern, COUNT(*) as count, SUM(visit_count) as total_visits 
       FROM frequent_locations 
       WHERE user_id = ? AND time_pattern IS NOT NULL 
       GROUP BY time_pattern`, [userId]);
        res.json({
            code: 200,
            message: '获取成功',
            data: {
                totalVisits: totalResult[0].total_visits || 0,
                locationCount: totalResult[0].location_count || 0,
                byPattern: patternStats
            }
        });
    }
    catch (error) {
        console.error('Get visit stats error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
