const express = require('express');
const router = express.Router();
// Import Controller
const authController = require('../controllers/authController');

// Import Middleware (để bảo vệ, bắt buộc đăng nhập mới được đổi pass)
const { verifyToken } = require('../middleware/authMiddleware');

// 1. Đăng ký
router.post('/register', authController.register);

// 2. Đăng nhập
router.post('/login', authController.login);

// 3. Đổi mật khẩu (DÒNG NÀY BÀ ĐANG THIẾU NÈ)
// Đường dẫn: POST http://localhost:5000/api/auth/change-password
router.post('/change-password', verifyToken, authController.changePassword);
router.post('/google-register', authController.completeGoogleRegister); // Thêm dòng này
router.post('/google-login', authController.googleLogin); // Thêm dòng này

module.exports = router;