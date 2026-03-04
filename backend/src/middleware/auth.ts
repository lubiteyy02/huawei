import { Request, Response, NextFunction } from 'express';
import jwt from 'jsonwebtoken';

// 扩展Request类型，添加userId
declare global {
  namespace Express {
    interface Request {
      userId?: number;
    }
  }
}

const JWT_SECRET = process.env.JWT_SECRET || 'your_jwt_secret_key';

/**
 * JWT认证中间件
 */
export function authMiddleware(req: Request, res: Response, next: NextFunction) {
  try {
    // 从请求头获取token
    const authHeader = req.headers.authorization;
    
    if (!authHeader || !authHeader.startsWith('Bearer ')) {
      return res.status(401).json({
        code: 401,
        message: '未提供认证令牌'
      });
    }
    
    const token = authHeader.substring(7); // 移除 "Bearer " 前缀
    
    // 验证token
    const decoded = jwt.verify(token, JWT_SECRET) as { userId: number };
    
    // 将用户ID添加到请求对象
    req.userId = decoded.userId;
    
    next();
  } catch (error) {
    if (error instanceof jwt.TokenExpiredError) {
      return res.status(401).json({
        code: 401,
        message: '认证令牌已过期'
      });
    }
    
    return res.status(401).json({
      code: 401,
      message: '无效的认证令牌'
    });
  }
}

/**
 * 生成JWT token
 */
export function generateToken(userId: number): string {
  return jwt.sign(
    { userId },
    JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' } as jwt.SignOptions
  );
}
