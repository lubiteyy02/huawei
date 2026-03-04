"use strict";
var __createBinding = (this && this.__createBinding) || (Object.create ? (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    var desc = Object.getOwnPropertyDescriptor(m, k);
    if (!desc || ("get" in desc ? !m.__esModule : desc.writable || desc.configurable)) {
      desc = { enumerable: true, get: function() { return m[k]; } };
    }
    Object.defineProperty(o, k2, desc);
}) : (function(o, m, k, k2) {
    if (k2 === undefined) k2 = k;
    o[k2] = m[k];
}));
var __setModuleDefault = (this && this.__setModuleDefault) || (Object.create ? (function(o, v) {
    Object.defineProperty(o, "default", { enumerable: true, value: v });
}) : function(o, v) {
    o["default"] = v;
});
var __importStar = (this && this.__importStar) || (function () {
    var ownKeys = function(o) {
        ownKeys = Object.getOwnPropertyNames || function (o) {
            var ar = [];
            for (var k in o) if (Object.prototype.hasOwnProperty.call(o, k)) ar[ar.length] = k;
            return ar;
        };
        return ownKeys(o);
    };
    return function (mod) {
        if (mod && mod.__esModule) return mod;
        var result = {};
        if (mod != null) for (var k = ownKeys(mod), i = 0; i < k.length; i++) if (k[i] !== "default") __createBinding(result, mod, k[i]);
        __setModuleDefault(result, mod);
        return result;
    };
})();
var __importDefault = (this && this.__importDefault) || function (mod) {
    return (mod && mod.__esModule) ? mod : { "default": mod };
};
Object.defineProperty(exports, "__esModule", { value: true });
const express_1 = __importDefault(require("express"));
const auth_1 = require("../middleware/auth");
const authController = __importStar(require("../controllers/authController"));
const favoriteController = __importStar(require("../controllers/favoriteController"));
const navigationController = __importStar(require("../controllers/navigationController"));
const routePlanController = __importStar(require("../controllers/routePlanController"));
const locationController = __importStar(require("../controllers/locationController"));
const feedbackController = __importStar(require("../controllers/feedbackController"));
const frequentLocationController = __importStar(require("../controllers/frequentLocationController"));
const router = express_1.default.Router();
// ========== 认证相关路由（无需token） ==========
router.post('/auth/register', authController.register);
router.post('/auth/login', authController.login);
// ========== 用户相关路由（需要token） ==========
router.get('/auth/profile', auth_1.authMiddleware, authController.getProfile);
router.put('/auth/profile', auth_1.authMiddleware, authController.updateProfile);
// ========== 收藏相关路由（需要token） ==========
router.get('/favorites', auth_1.authMiddleware, favoriteController.getFavorites);
router.post('/favorites', auth_1.authMiddleware, favoriteController.addFavorite);
router.put('/favorites/:id', auth_1.authMiddleware, favoriteController.updateFavorite);
router.delete('/favorites/:id', auth_1.authMiddleware, favoriteController.deleteFavorite);
// ========== 导航历史相关路由（需要token） ==========
router.get('/navigation/history', auth_1.authMiddleware, navigationController.getNavigationHistory);
router.post('/navigation/history', auth_1.authMiddleware, navigationController.saveNavigationHistory);
router.delete('/navigation/history/:id', auth_1.authMiddleware, navigationController.deleteNavigationHistory);
router.delete('/navigation/history', auth_1.authMiddleware, navigationController.clearNavigationHistory);
// ========== 路线方案相关路由（需要token） ==========
router.get('/routes', auth_1.authMiddleware, routePlanController.getRoutePlans);
router.get('/routes/:id', auth_1.authMiddleware, routePlanController.getRoutePlanDetail);
router.post('/routes', auth_1.authMiddleware, routePlanController.saveRoutePlan);
router.put('/routes/:id', auth_1.authMiddleware, routePlanController.updateRoutePlan);
router.post('/routes/:id/use', auth_1.authMiddleware, routePlanController.useRoutePlan);
router.delete('/routes/:id', auth_1.authMiddleware, routePlanController.deleteRoutePlan);
// ========== 位置相关路由（需要token） ==========
router.post('/location', auth_1.authMiddleware, locationController.updateLocation);
router.get('/location', auth_1.authMiddleware, locationController.getLocation);
router.get('/location/:targetUserId', auth_1.authMiddleware, locationController.getLocation);
router.post('/location/sharing/toggle', auth_1.authMiddleware, locationController.toggleLocationSharing);
router.post('/location/sharing', auth_1.authMiddleware, locationController.createLocationShare);
router.get('/location/sharing', auth_1.authMiddleware, locationController.getLocationShares);
router.delete('/location/sharing/:id', auth_1.authMiddleware, locationController.cancelLocationShare);
router.get('/location/nearby', auth_1.authMiddleware, locationController.getNearbySharedUsers);
// ========== 反馈相关路由（需要token） ==========
router.post('/feedback', auth_1.authMiddleware, feedbackController.submitFeedback);
router.get('/feedback', auth_1.authMiddleware, feedbackController.getFeedbackList);
router.get('/feedback/stats', auth_1.authMiddleware, feedbackController.getFeedbackStats);
router.get('/feedback/:id', auth_1.authMiddleware, feedbackController.getFeedbackDetail);
router.delete('/feedback/:id', auth_1.authMiddleware, feedbackController.deleteFeedback);
// ========== 常去地点相关路由（需要token） ==========
router.post('/frequent-locations/visit', auth_1.authMiddleware, frequentLocationController.recordVisit);
router.get('/frequent-locations', auth_1.authMiddleware, frequentLocationController.getFrequentLocations);
router.get('/frequent-locations/recommended', auth_1.authMiddleware, frequentLocationController.getRecommendedLocations);
router.get('/frequent-locations/stats', auth_1.authMiddleware, frequentLocationController.getVisitStats);
router.get('/frequent-locations/:id', auth_1.authMiddleware, frequentLocationController.getLocationDetail);
router.put('/frequent-locations/:id', auth_1.authMiddleware, frequentLocationController.updateLocation);
router.delete('/frequent-locations/:id', auth_1.authMiddleware, frequentLocationController.deleteLocation);
exports.default = router;
