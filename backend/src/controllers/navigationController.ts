import { Request, Response } from 'express';
import { query } from '../config/database';

interface NavigationHistory {
  id: number;
  user_id: number;
  start_name?: string;
  start_address?: string;
  start_lat?: number;
  start_lng?: number;
  end_name: string;
  end_address: string;
  end_lat: number;
  end_lng: number;
  distance?: number;
  duration?: number;
  created_at: string;
}

/**
 * 获取导航历史
 */
export async function getNavigationHistory(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { page = 1, pageSize = 20 } = req.query;
    
    const pageNum = Number(page);
    const pageSizeNum = Number(pageSize);
    const offset = (pageNum - 1) * pageSizeNum;
    
    // 获取总数
    const countResult = await query<any[]>(
      'SELECT COUNT(*) as total FROM navigation_history WHERE user_id = ?',
      [userId]
    );
    const total = countResult[0].total;
    
    // 获取列表（注意：MySQL prepared statements 不支持 LIMIT/OFFSET 占位符）
    const history = await query<NavigationHistory[]>(
      `SELECT * FROM navigation_history WHERE user_id = ? ORDER BY created_at DESC LIMIT ${pageSizeNum} OFFSET ${offset}`,
      [userId]
    );
    
    // 转换字段名：下划线转驼峰
    const formattedHistory = history.map(item => ({
      id: item.id,
      userId: item.user_id,
      startName: item.start_name,
      startAddress: item.start_address,
      startLat: item.start_lat,
      startLng: item.start_lng,
      endName: item.end_name,
      endAddress: item.end_address,
      endLat: item.end_lat,
      endLng: item.end_lng,
      distance: item.distance,
      duration: item.duration,
      createdAt: item.created_at
    }));
    
    res.json({
      code: 200,
      message: '获取成功',
      data: {
        list: formattedHistory,
        total,
        page: pageNum,
        pageSize: pageSizeNum
      }
    });
  } catch (error) {
    console.error('[navigationController] Get navigation history error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 保存导航记录
 */
export async function saveNavigationHistory(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const {
      startName,
      startAddress,
      startLat,
      startLng,
      endName,
      endAddress,
      endLat,
      endLng,
      distance,
      duration
    } = req.body;
    
    // 验证参数
    if (!endName || !endAddress || !endLat || !endLng) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    const result: any = await query(
      `INSERT INTO navigation_history 
       (user_id, start_name, start_address, start_lat, start_lng, end_name, end_address, end_lat, end_lng, distance, duration) 
       VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)`,
      [userId, startName, startAddress, startLat, startLng, endName, endAddress, endLat, endLng, distance, duration]
    );
    
    res.status(201).json({
      code: 200,
      message: '保存成功',
      data: {
        id: result.insertId
      }
    });
  } catch (error) {
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
export async function deleteNavigationHistory(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    const result: any = await query(
      'DELETE FROM navigation_history WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
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
  } catch (error) {
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
export async function clearNavigationHistory(req: Request, res: Response) {
  try {
    const userId = req.userId;
    
    await query(
      'DELETE FROM navigation_history WHERE user_id = ?',
      [userId]
    );
    
    res.json({
      code: 200,
      message: '清空成功'
    });
  } catch (error) {
    console.error('Clear navigation history error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}
