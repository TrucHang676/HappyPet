
// happypet-backend/routes/cartRoutes.js
const express = require('express');
const router = express.Router();
const cartController = require('../controllers/cartController');

// 👇 1. IMPORT ĐÚNG TÊN LÀ verifyToken
const { verifyToken } = require('../middleware/authMiddleware'); 

// 👇 2. GẮN verifyToken VÀO GIỮA
router.post('/add', verifyToken, cartController.addToCart);

// Mấy cái dưới này nếu cần bảo mật thì gắn luôn:
router.get('/', verifyToken, cartController.getCart);
router.post('/remove', verifyToken, cartController.removeFromCart);

module.exports = router;