const express = require('express');
const router = express.Router();
const userController = require('../controllers/userController');
const { verifyToken } = require('../middleware/authMiddleware');

// Xem hồ sơ
router.get('/profile', verifyToken, userController.getProfile);

// Cập nhật hồ sơ
router.put('/profile/update', verifyToken, userController.updateProfile);

// Xem lịch sử hoạt động
router.get('/history', verifyToken, userController.getActivityHistory);

module.exports = router;