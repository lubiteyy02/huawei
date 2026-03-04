"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.submitFeedback = submitFeedback;
exports.getFeedbackList = getFeedbackList;
exports.getFeedbackDetail = getFeedbackDetail;
exports.deleteFeedback = deleteFeedback;
exports.getFeedbackStats = getFeedbackStats;
const database_1 = require("../config/database");
/**
 * 提交导航反馈
 */
async function submitFeedback(req, res) {
    try {
        const userId = req.userId;
        const { navigationId, rating, feedbackType, content, locationLat, locationLng } = req.body;
        // 验证参数
        if (!feedbackType) {
            return res.status(400).json({
                code: 400,
                message: '缺少必要参数'
            });
        }
        // 验证反馈类型
        const validTypes = ['route', 'traffic', 'poi'];
        if (!validTypes.includes(feedbackType)) {
            return res.status(400).json({
                code: 400,
                message: '无效的反馈类型'
            });
        }
        // 验证评分
        if (rating && (rating < 1 || rating > 5)) {
            return res.status(400).json({
                code: 400,
                message: '评分必须在1-5之间'
            });
        }
        const result = await (0, database_1.query)(`INSERT INTO navigation_feedback 
       (user_id, navigation_id, rating, feedback_type, content, location_lat, location_lng) 
       VALUES (?, ?, ?, ?, ?, ?, ?)`, [userId, navigationId, rating, feedbackType, content, locationLat, locationLng]);
        res.status(201).json({
            code: 200,
            message: '反馈提交成功',
            data: {
                id: result.insertId
            }
        });
    }
    catch (error) {
        console.error('Submit feedback error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取反馈列表
 */
async function getFeedbackList(req, res) {
    try {
        const userId = req.userId;
        const { feedbackType, page = 1, pageSize = 20 } = req.query;
        const offset = (Number(page) - 1) * Number(pageSize);
        let sql = 'SELECT * FROM navigation_feedback WHERE user_id = ?';
        const params = [userId];
        if (feedbackType) {
            sql += ' AND feedback_type = ?';
            params.push(feedbackType);
        }
        sql += ' ORDER BY created_at DESC LIMIT ? OFFSET ?';
        params.push(Number(pageSize), offset);
        const feedbacks = await (0, database_1.query)(sql, params);
        // 获取总数
        let countSql = 'SELECT COUNT(*) as total FROM navigation_feedback WHERE user_id = ?';
        const countParams = [userId];
        if (feedbackType) {
            countSql += ' AND feedback_type = ?';
            countParams.push(feedbackType);
        }
        const countResult = await (0, database_1.query)(countSql, countParams);
        const total = countResult[0].total;
        res.json({
            code: 200,
            message: '获取成功',
            data: {
                list: feedbacks,
                total,
                page: Number(page),
                pageSize: Number(pageSize)
            }
        });
    }
    catch (error) {
        console.error('Get feedback list error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取反馈详情
 */
async function getFeedbackDetail(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const feedbacks = await (0, database_1.query)('SELECT * FROM navigation_feedback WHERE id = ? AND user_id = ?', [id, userId]);
        if (feedbacks.length === 0) {
            return res.status(404).json({
                code: 404,
                message: '反馈不存在'
            });
        }
        res.json({
            code: 200,
            message: '获取成功',
            data: feedbacks[0]
        });
    }
    catch (error) {
        console.error('Get feedback detail error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 删除反馈
 */
async function deleteFeedback(req, res) {
    try {
        const userId = req.userId;
        const { id } = req.params;
        const result = await (0, database_1.query)('DELETE FROM navigation_feedback WHERE id = ? AND user_id = ?', [id, userId]);
        if (result.affectedRows === 0) {
            return res.status(404).json({
                code: 404,
                message: '反馈不存在'
            });
        }
        res.json({
            code: 200,
            message: '删除成功'
        });
    }
    catch (error) {
        console.error('Delete feedback error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
/**
 * 获取反馈统计
 */
async function getFeedbackStats(req, res) {
    try {
        const userId = req.userId;
        // 按类型统计
        const typeStats = await (0, database_1.query)(`SELECT feedback_type, COUNT(*) as count, AVG(rating) as avg_rating 
       FROM navigation_feedback 
       WHERE user_id = ? 
       GROUP BY feedback_type`, [userId]);
        // 总数统计
        const totalResult = await (0, database_1.query)('SELECT COUNT(*) as total, AVG(rating) as avg_rating FROM navigation_feedback WHERE user_id = ?', [userId]);
        res.json({
            code: 200,
            message: '获取成功',
            data: {
                total: totalResult[0].total,
                avgRating: totalResult[0].avg_rating,
                byType: typeStats
            }
        });
    }
    catch (error) {
        console.error('Get feedback stats error:', error);
        res.status(500).json({
            code: 500,
            message: '服务器错误'
        });
    }
}
