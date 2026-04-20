import { Request, Response } from 'express';
import { query } from '../config/database';

interface Favorite {
  id: number;
  user_id: number;
  name: string;
  address: string;
  latitude: number;
  longitude: number;
  category: string;
  icon?: string;
  created_at: string;
}

/**
 * 获取收藏列表
 */
export async function getFavorites(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { category } = req.query;
    
    let sql = 'SELECT * FROM favorites WHERE user_id = ?';
    const params: any[] = [userId];
    
    if (category) {
      sql += ' AND category = ?';
      params.push(category);
    }
    
    sql += ' ORDER BY created_at DESC';
    
    const favorites = await query<Favorite[]>(sql, params);

    const formattedFavorites = favorites.map(item => ({
      id: item.id,
      userId: item.user_id,
      name: item.name,
      address: item.address,
      latitude: item.latitude,
      longitude: item.longitude,
      category: item.category,
      icon: item.icon,
      createdAt: item.created_at
    }));

    res.json({
      code: 200,
      message: '获取成功',
      data: formattedFavorites
    });
  } catch (error) {
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
export async function addFavorite(req: Request, res: Response) {
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
    if (!name || !address || latitude === undefined || latitude === null || longitude === undefined || longitude === null) {
      console.error('❌ 缺少必要参数:', { name, address, latitude, longitude });
      return res.status(400).json({
        code: 400,
        message: '缺少必要参数'
      });
    }
    
    console.log('✅ 参数验证通过');
    
    // 检查是否已收藏
    console.log('检查是否已收藏...');
    const existing = await query<Favorite[]>(
      'SELECT id FROM favorites WHERE user_id = ? AND latitude = ? AND longitude = ?',
      [userId, latitude, longitude]
    );
    
    if (existing.length > 0) {
      console.log('⚠️ 该地点已收藏');
      return res.status(400).json({
        code: 400,
        message: '该地点已收藏'
      });
    }
    
    console.log('插入收藏记录...');
    const result: any = await query(
      'INSERT INTO favorites (user_id, name, address, latitude, longitude, category, icon) VALUES (?, ?, ?, ?, ?, ?, ?)',
      [userId, name, address, latitude, longitude, category || 'custom', icon || null]
    );
    
    console.log('✅ 收藏成功, insertId:', result.insertId);
    console.log('=== 收藏请求结束 ===');
    
    res.status(201).json({
      code: 200,
      message: '收藏成功',
      data: {
        id: result.insertId
      }
    });
  } catch (error) {
    console.error('❌ Add favorite error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}

/**
 * 更新收藏
 */
export async function updateFavorite(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    const { name, address, category, icon } = req.body;
    
    // 验证权限
    const favorites = await query<Favorite[]>(
      'SELECT id FROM favorites WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
    if (favorites.length === 0) {
      return res.status(404).json({
        code: 404,
        message: '收藏不存在'
      });
    }
    
    const updates: string[] = [];
    const params: any[] = [];
    
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
    
    await query(
      `UPDATE favorites SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`,
      params
    );
    
    res.json({
      code: 200,
      message: '更新成功'
    });
  } catch (error) {
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
export async function deleteFavorite(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { id } = req.params;
    
    const result: any = await query(
      'DELETE FROM favorites WHERE id = ? AND user_id = ?',
      [id, userId]
    );
    
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
  } catch (error) {
    console.error('Delete favorite error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}
