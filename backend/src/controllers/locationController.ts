import { Request, Response } from 'express';
import { query } from '../config/database';

interface UserLocation {
  id: number;
  user_id: number;
  latitude: number;
  longitude: number;
  accuracy?: number;
  speed?: number;
  heading?: number;
  location_type: string;
  is_sharing: boolean;
  updated_at: string;
}

interface LocationShare {
  id: number;
  sharer_id: number;
  viewer_id: number;
  expire_time?: string;
  is_active: boolean;
  created_at: string;
}

/**
 * 更新用户位置
 */
export async function updateLocation(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const {
      latitude,
      longitude,
      accuracy,
      speed,
      heading,
      locationType = 'ip',
      isSharing = false
    } = req.body;
    
    // 验证参数
    if (!latitude || !longitude) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    // 检查是否已存在
    const existing = await query<UserLocation[]>(
      'SELECT id FROM user_locations WHERE user_id = ?',
      [userId]
    );
    
    if (existing.length > 0) {
      // 更新
      await query(
        `UPDATE user_locations 
         SET latitude = ?, longitude = ?, accuracy = ?, speed = ?, heading = ?, 
             location_type = ?, is_sharing = ?, updated_at = CURRENT_TIMESTAMP 
         WHERE user_id = ?`,
        [latitude, longitude, accuracy, speed, heading, locationType, isSharing, userId]
      );
    } else {
      // 插入
      await query(
        `INSERT INTO user_locations 
         (user_id, latitude, longitude, accuracy, speed, heading, location_type, is_sharing) 
         VALUES (?, ?, ?, ?, ?, ?, ?, ?)`,
        [userId, latitude, longitude, accuracy, speed, heading, locationType, isSharing]
      );
    }
    
    res.json({
      code: 200,
      message: '位置更新成功'
    });
  } catch (error) {
    console.error('Update location error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 获取用户位置
 */
export async function getLocation(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { targetUserId } = req.params;
    
    const targetId = targetUserId || userId;
    
    // 如果查询其他用户位置，需要检查共享权限
    if (targetId !== userId) {
      const shares = await query<LocationShare[]>(
        'SELECT * FROM location_shares WHERE sharer_id = ? AND viewer_id = ? AND is_active = TRUE',
        [targetId, userId]
      );
      
      if (shares.length === 0) {
        return res.status(403).json({
          code: 403,
          message: '无权查看该用户位置'
        });
      }
      
      // 检查是否过期
      const share = shares[0];
      if (share.expire_time && new Date(share.expire_time) < new Date()) {
        return res.status(403).json({
          code: 403,
          message: '位置共享已过期'
        });
      }
    }
    
    const locations = await query<UserLocation[]>(
      'SELECT * FROM user_locations WHERE user_id = ?',
      [targetId]
    );
    
    if (locations.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '位置信息不存在'
      });
    }
    
    res.json({
      code: 200,
      message: '获取成功',
      data: locations[0]
    });
  } catch (error) {
    console.error('Get location error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 开启/关闭位置共享
 */
export async function toggleLocationSharing(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { isSharing } = req.body;
    
    if (isSharing === undefined) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    await query(
      'UPDATE user_locations SET is_sharing = ? WHERE user_id = ?',
      [isSharing, userId]
    );
    
    res.json({
      code: 200,
      message: isSharing ? '位置共享已开启' : '位置共享已关闭'
    });
  } catch (error) {
    console.error('Toggle location sharing error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 创建位置共享
 */
export async function createLocationShare(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { viewerId, expireHours } = req.body;
    
    if (!viewerId) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    // 检查是否已存在
    const existing = await query<LocationShare[]>(
      'SELECT id FROM location_shares WHERE sharer_id = ? AND viewer_id = ?',
      [userId, viewerId]
    );
    
    let expireTime = null;
    if (expireHours) {
      const expire = new Date();
      expire.setHours(expire.getHours() + expireHours);
      expireTime = expire.toISOString().slice(0, 19).replace('T', ' ');
    }
    
    if (existing.length > 0) {
      // 更新
      await query(
        'UPDATE location_shares SET expire_time = ?, is_active = TRUE WHERE sharer_id = ? AND viewer_id = ?',
        [expireTime, userId, viewerId]
      );
    } else {
      // 插入
      await query(
        'INSERT INTO location_shares (sharer_id, viewer_id, expire_time, is_active) VALUES (?, ?, ?, TRUE)',
        [userId, viewerId, expireTime]
      );
    }
    
    res.status(201).json({
      code: 200,
      message: '位置共享创建成功'
    });
  } catch (error) {
    console.error('Create location share error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 获取位置共享列表
 */
export async function getLocationShares(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { type = 'sharing' } = req.query; // sharing: 我分享的, viewing: 我查看的
    
    let sql = '';
    if (type === 'sharing') {
      sql = `SELECT ls.*, u.nickname, u.phone 
             FROM location_shares ls 
             LEFT JOIN users u ON ls.viewer_id = u.id 
             WHERE ls.sharer_id = ? AND ls.is_active = TRUE 
             ORDER BY ls.created_at DESC`;
    } else {
      sql = `SELECT ls.*, u.nickname, u.phone 
             FROM location_shares ls 
             LEFT JOIN users u ON ls.sharer_id = u.id 
             WHERE ls.viewer_id = ? AND ls.is_active = TRUE 
             ORDER BY ls.created_at DESC`;
    }
    
    const shares = await query<any[]>(sql, [userId]);
    
    res.json({
      code: 200,
      message: '获取成功',
      data: shares
    });
  } catch (error) {
    console.error('Get location shares error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 取消位置共享
 */
export async function cancelLocationShare(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    const result: any = await query(
      'UPDATE location_shares SET is_active = FALSE WHERE id = ? AND sharer_id = ?',
      [id, userId]
    );
    
    if (result.affectedRows === 0) {
      return res.status(404).json({
        code: 404,
        message: '共享记录不存在'
      });
    }
    
    res.json({
      code: 200,
      message: '取消成功'
    });
  } catch (error) {
    console.error('Cancel location share error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 获取附近共享位置的用户
 */
export async function getNearbySharedUsers(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { latitude, longitude, radius = 5000 } = req.query; // radius单位：米
    
    if (!latitude || !longitude) {
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    // 获取我可以查看的用户列表
    const shares = await query<LocationShare[]>(
      'SELECT sharer_id FROM location_shares WHERE viewer_id = ? AND is_active = TRUE',
      [userId]
    );
    
    if (shares.length === 0) {
      return res.json({
        code: 200,
        message: '获取成功',
        data: []
      });
    }
    
    const sharerIds = shares.map(s => s.sharer_id);
    
    // 计算距离并筛选
    const sql = `
      SELECT ul.*, u.nickname, u.avatar,
             (6371000 * acos(cos(radians(?)) * cos(radians(ul.latitude)) * 
              cos(radians(ul.longitude) - radians(?)) + 
              sin(radians(?)) * sin(radians(ul.latitude)))) AS distance
      FROM user_locations ul
      LEFT JOIN users u ON ul.user_id = u.id
      WHERE ul.user_id IN (${sharerIds.join(',')}) AND ul.is_sharing = TRUE
      HAVING distance <= ?
      ORDER BY distance ASC
    `;
    
    const nearbyUsers = await query<any[]>(sql, [latitude, longitude, latitude, radius]);
    
    res.json({
      code: 200,
      message: '获取成功',
      data: nearbyUsers
    });
  } catch (error) {
    console.error('Get nearby shared users error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}
