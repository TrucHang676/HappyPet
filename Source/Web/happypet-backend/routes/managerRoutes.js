const express = require('express');
const router = express.Router();
const managerController = require('../controllers/managerController');
const { verifyToken } = require('../middleware/authMiddleware');

// Tất cả routes yêu cầu đăng nhập
router.use(verifyToken);

// Điều động nhân sự
router.post('/transfer-employee', managerController.transferEmployee);

// Thống kê
router.get('/product-revenue', managerController.getProductRevenue);
router.get('/branch-revenue', managerController.getBranchRevenue);
router.get('/top-employees', managerController.getTopEmployees);
router.get('/top-products', managerController.getTopProducts);
router.get('/low-stock-alert', managerController.getLowStockAlert);
router.get('/top-service', managerController.getTopService);
router.get('/membership-stats', managerController.getMembershipStats);

// Cập nhật xếp hạng (Admin only)
router.post('/update-membership-ranking', managerController.updateMembershipRanking);

// Quản lý kho
router.post('/import-stock', managerController.importStock);
router.post('/add-product', managerController.addProduct);

// Danh sách để chọn
router.get('/employees', managerController.getAllEmployees);
router.get('/products', managerController.getAllProducts);

module.exports = router;
