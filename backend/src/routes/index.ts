import express from 'express';
import { authMiddleware } from '../middleware/auth';
import * as authController from '../controllers/authController';
import * as favoriteController from '../controllers/favoriteController';
import * as navigationController from '../controllers/navigationController';

const router = express.Router();

// ========== 认证相关路由（无需token） ==========
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);

// ========== 用户相关路由（需要token） ==========
router.get('/auth/profile', authMiddleware, authController.getProfile);
router.put('/auth/profile', authMiddleware, authController.updateProfile);

// ========== 收藏相关路由（需要token） ==========
router.get('/favorites', authMiddleware, favoriteController.getFavorites);
router.post('/favorites', authMiddleware, favoriteController.addFavorite);
router.put('/favorites/:id', authMiddleware, favoriteController.updateFavorite);
router.delete('/favorites/:id', authMiddleware, favoriteController.deleteFavorite);

// ========== 导航历史相关路由（需要token） ==========
router.get('/navigation/history', authMiddleware, navigationController.getNavigationHistory);
router.post('/navigation/history', authMiddleware, navigationController.saveNavigationHistory);
router.delete('/navigation/history/:id', authMiddleware, navigationController.deleteNavigationHistory);
router.delete('/navigation/history', authMiddleware, navigationController.clearNavigationHistory);

export default router;
