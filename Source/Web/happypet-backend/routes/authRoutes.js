const express = require('express');
const router = express.Router();
// Import Controller
const authController = require('../controllers/authController');

// Import Middleware (để bảo vệ, bắt buộc đăng nhập mới được đổi pass)
const { verifyToken } = require('../middleware/authMiddleware');

// DEBUG: in case a handler is not a function
console.log('DEBUG authController keys:', Object.keys(authController));
console.log('DEBUG typeof authController.login:', typeof authController.login);
console.log('DEBUG typeof verifyToken:', typeof verifyToken);

// 1. Đăng ký
router.post('/register', authController.register);

// 2. Đăng nhập
router.post('/login', authController.login);

// 3. Đổi mật khẩu (DÒNG NÀY BÀ ĐANG THIẾU NÈ)
router.post('/change-password', verifyToken, authController.changePassword);
router.post('/google-register', authController.completeGoogleRegister); // Thêm dòng này
router.post('/google-login', authController.googleLogin); // Thêm dòng này

// 4. Quên mật khẩu (mới)
// Frontend hiện dùng: GET /api/auth/check-account  and POST /api/auth/forgot-password
router.get('/check-account', authController.checkAccount);
router.post('/forgot-password', authController.forgotPassword);

module.exports = router;