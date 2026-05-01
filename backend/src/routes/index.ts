import express from 'express';
import { authMiddleware } from '../middleware/auth';
import * as authController from '../controllers/authController';
import * as favoriteController from '../controllers/favoriteController';
import * as navigationController from '../controllers/navigationController';
import * as routePlanController from '../controllers/routePlanController';
import * as locationController from '../controllers/locationController';
import * as feedbackController from '../controllers/feedbackController';
import * as frequentLocationController from '../controllers/frequentLocationController';
import * as mediaController from '../controllers/mediaController';
import * as collaborationController from '../controllers/collaborationController';

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

// ========== 路线方案相关路由（需要token） ==========
router.get('/routes', authMiddleware, routePlanController.getRoutePlans);
router.get('/routes/:id', authMiddleware, routePlanController.getRoutePlanDetail);
router.post('/routes', authMiddleware, routePlanController.saveRoutePlan);
router.put('/routes/:id', authMiddleware, routePlanController.updateRoutePlan);
router.post('/routes/:id/use', authMiddleware, routePlanController.useRoutePlan);
router.delete('/routes/:id', authMiddleware, routePlanController.deleteRoutePlan);

// ========== 位置相关路由（需要token） ==========
router.post('/location', authMiddleware, locationController.updateLocation);
router.get('/location', authMiddleware, locationController.getLocation);
router.get('/location/:targetUserId', authMiddleware, locationController.getLocation);
router.post('/location/sharing/toggle', authMiddleware, locationController.toggleLocationSharing);
router.post('/location/sharing', authMiddleware, locationController.createLocationShare);
router.get('/location/sharing', authMiddleware, locationController.getLocationShares);
router.delete('/location/sharing/:id', authMiddleware, locationController.cancelLocationShare);
router.get('/location/nearby', authMiddleware, locationController.getNearbySharedUsers);

// ========== 反馈相关路由（需要token） ==========
router.post('/feedback', authMiddleware, feedbackController.submitFeedback);
router.get('/feedback', authMiddleware, feedbackController.getFeedbackList);
router.get('/feedback/stats', authMiddleware, feedbackController.getFeedbackStats);
router.get('/feedback/:id', authMiddleware, feedbackController.getFeedbackDetail);
router.delete('/feedback/:id', authMiddleware, feedbackController.deleteFeedback);

// ========== 常去地点相关路由（需要token） ==========
router.post('/frequent-locations/visit', authMiddleware, frequentLocationController.recordVisit);
router.get('/frequent-locations', authMiddleware, frequentLocationController.getFrequentLocations);
router.get('/frequent-locations/recommended', authMiddleware, frequentLocationController.getRecommendedLocations);
router.get('/frequent-locations/stats', authMiddleware, frequentLocationController.getVisitStats);
router.get('/frequent-locations/:id', authMiddleware, frequentLocationController.getLocationDetail);
router.put('/frequent-locations/:id', authMiddleware, frequentLocationController.updateLocation);
router.delete('/frequent-locations/:id', authMiddleware, frequentLocationController.deleteLocation);

// ========== 协同同步相关路由 ==========
router.get('/sync/overview', collaborationController.getOverview);
router.get('/sync/contacts', collaborationController.getContacts);
router.post('/sync/contacts/tag', collaborationController.updateContactTag);
router.get('/sync/messages', collaborationController.getMessageThreads);
router.post('/sync/messages/read', collaborationController.markMessageRead);
router.get('/sync/music/library', collaborationController.getMusicLibrary);
router.get('/sync/continuation/list', collaborationController.getContinuationList);
router.post('/sync/continuation/resume', collaborationController.resumeContinuation);
router.post('/sync/music/state', collaborationController.updateMusicState);
router.get('/sync/music/state', collaborationController.getMusicState);
router.post('/sync/log', collaborationController.addLog);

// ========== 多媒体资源相关路由 ==========
router.get('/media/resources', mediaController.getMediaResources);

export default router;
