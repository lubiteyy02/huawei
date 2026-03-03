import { Request, Response } from 'express';
import bcrypt from 'bcryptjs';
import { query } from '../config/database';
import { generateToken } from '../middleware/auth';

interface User {
  id: number;
  phone: string;
  password: string;
  nickname?: string;
  avatar?: string;
}

/**
 * 用户注册
 */
export async function register(req: Request, res: Response) {
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
    const existingUsers = await query<User[]>(
      'SELECT id FROM users WHERE phone = ?',
      [phone]
    );
    
    if (existingUsers.length > 0) {
      return res.status(400).json({
        code: 400,
        message: '该手机号已注册'
      });
    }
    
    // 加密密码
    const hashedPassword = await bcrypt.hash(password, 10);
    
    // 插入用户
    const result: any = await query(
      'INSERT INTO users (phone, password, nickname) VALUES (?, ?, ?)',
      [phone, hashedPassword, nickname || `用户${phone.slice(-4)}`]
    );
    
    const userId = result.insertId;
    
    // 生成token
    const token = generateToken(userId);
    
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
  } catch (error) {
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
export async function login(req: Request, res: Response) {
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
    const users = await query<User[]>(
      'SELECT id, phone, password, nickname, avatar FROM users WHERE phone = ?',
      [phone]
    );
    
    if (users.length === 0) {
      return res.status(401).json({
        code: 401,
        message: '手机号或密码错误'
      });
    }
    
    const user = users[0];
    
    // 验证密码
    const isPasswordValid = await bcrypt.compare(password, user.password);
    
    if (!isPasswordValid) {
      return res.status(401).json({
        code: 401,
        message: '手机号或密码错误'
      });
    }
    
    // 生成token
    const token = generateToken(user.id);
    
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
  } catch (error) {
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
export async function getProfile(req: Request, res: Response) {
  try {
    const userId = req.userId;
    
    const users = await query<User[]>(
      'SELECT id, phone, nickname, avatar, created_at FROM users WHERE id = ?',
      [userId]
    );
    
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
  } catch (error) {
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
export async function updateProfile(req: Request, res: Response) {
  try {
    const userId = req.userId;
    const { nickname, avatar } = req.body;
    
    const updates: string[] = [];
    const params: any[] = [];
    
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
    
    await query(
      `UPDATE users SET ${updates.join(', ')} WHERE id = ?`,
      params
    );
    
    res.json({
      code: 200,
      message: '更新成功'
    });
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      code: 500,
      message: '服务器错误'
    });
  }
}
