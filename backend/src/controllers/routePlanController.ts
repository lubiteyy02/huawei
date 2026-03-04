import { Request, Response } from 'express';
import { query } from '../config/database';

interface RoutePlan {
  id: number;
  user_id: number;
  name?: string;
  start_name: string;
  start_lat: number;
  start_lng: number;
  end_name: string;
  end_lat: number;
  end_lng: number;
  waypoints?: string;
  distance?: number;
  duration?: number;
  strategy: number;
  polyline?: string;
  steps?: string;
  is_favorite: boolean;
  use_count: number;
  created_at: string;
  updated_at: string;
}

/**
 * 获取路线方案列表
 */
export async function getRoutePlans(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { isFavorite, page = 1, pageSize = 20 } = req.query;
    
    const offset = (Number(page) - 1) * Number(pageSize);
    
    let sql = 'SELECT * FROM route_plans WHERE user_id = ?';
    const params: any[] = [userId];
    
    if (isFavorite === 'true') {
      sql += ' AND is_favorite = TRUE';
    }
    
    sql += ' ORDER BY use_count DESC, created_at DESC LIMIT ? OFFSET ?';
    params.push(Number(pageSize), offset);
    
    const plans = await query<RoutePlan[]>(sql, params);
    
    // 获取总数
    let countSql = 'SELECT COUNT(*) as total FROM route_plans WHERE user_id = ?';
    const countParams: any[] = [userId];
    if (isFavorite === 'true') {
      countSql += ' AND is_favorite = TRUE';
    }
    const countResult = await query<any[]>(countSql, countParams);
    const total = countResult[0].total;
    
    res.json({
      code: 200,
      message: '获取成功',
      data: {
        list: plans,
        total,
        page: Number(page),
        pageSize: Number(pageSize)
      }
    });
  } catch (error) {
    console.error('Get route plans error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 获取路线方案详情
 */
export async function getRoutePlanDetail(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    const plans = await query<RoutePlan[]>(
      'SELECT * FROM route_plans WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
    if (plans.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '路线方案不存在'
      });
    }
    
    res.json({
      code: 200,
      message: '获取成功',
      data: plans[0]
    });
  } catch (error) {
    console.error('Get route plan detail error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 保存路线方案
 */
export async function saveRoutePlan(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const {
      name,
      startName,
      startLat,
      startLng,
      endName,
      endLat,
      endLng,
      waypoints,
      distance,
      duration,
      strategy = 0,
      polyline,
      steps,
      isFavorite = false
    } = req.body;
    
    // 验证参数
    if (!startName || !startLat || !startLng || !endName || !endLat || !endLng) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    const result: any = await query(
      `INSERT INTO route_plans 
       (user_id, name, start_name, start_lat, start_lng, end_name, end_lat, end_lng, 
        waypoints, distance, duration, strategy, polyline, steps, is_favorite) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, name, startName, startLat, startLng, endName, endLat, endLng,
       waypoints ? JSON.stringify(waypoints) : null,
       distance, duration, strategy, polyline,
       steps ? JSON.stringify(steps) : null,
       isFavorite]
    );
    
    res.status(201).json({
      code: 200,
      message: '保存成功',
      data: {
        id: result.insertId
      }
    });
  } catch (error) {
    console.error('Save route plan error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 更新路线方案
 */
export async function updateRoutePlan(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const { name, isFavorite } = req.body;
    
    // 验证权限
    const plans = await query<RoutePlan[]>(
      'SELECT id FROM route_plans WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
    if (plans.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '路线方案不存在'
      });
    }
    
    const updates: string[] = [];
    const params: any[] = [];
    
    if (name !== undefined) {
      updates.push('name = ?');
      params.push(name);
    }
    if (isFavorite !== undefined) {
      updates.push('is_favorite = ?');
      params.push(isFavorite);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        code: 400,
        message: '没有要更新的内容'
      });
    }
    
    params.push(id, userId);
    
    await query(
      `UPDATE route_plans SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`,
      params
    );
    
    res.json({
      code: 200,
      message: '更新成功'
    });
  } catch (error) {
    console.error('Update route plan error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 使用路线方案（增加使用次数）
 */
export async function useRoutePlan(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    // 验证权限
    const plans = await query<RoutePlan[]>(
      'SELECT * FROM route_plans WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
    if (plans.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '路线方案不存在'
      });
    }
    
    // 增加使用次数
    await query(
      'UPDATE route_plans SET use_count = use_count + 1 WHERE id = ?',
      [id]
    );
    
    res.json({
      code: 200,
      message: '使用成功',
      data: plans[0]
    });
  } catch (error) {
    console.error('Use route plan error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 删除路线方案
 */
export async function deleteRoutePlan(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    const result: any = await query(
      'DELETE FROM route_plans WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({
        code: 404,
        message: '路线方案不存在'
      });
    }
    
    res.json({
      code: 200,
      message: '删除成功'
    });
  } catch (error) {
    console.error('Delete route plan error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}
