const express = require('express');
const router = express.Router();
const { verifyBranchManager } = require('../middleware/authMiddleware');
const branchManagerController = require('../controllers/branchManagerController');

// =============================================
// ROUTES CHO QUẢN LÝ CHI NHÁNH
// =============================================

// Thống kê doanh thu chi nhánh
router.get('/revenue', verifyBranchManager, branchManagerController.getRevenueByPeriod);

// Quản lý nhân viên
router.get('/employees', verifyBranchManager, branchManagerController.getEmployees);
router.post('/employees', verifyBranchManager, branchManagerController.addEmployee);
router.put('/employees/:maNV', verifyBranchManager, branchManagerController.updateEmployee);

// Tồn kho
router.get('/inventory/alert', verifyBranchManager, branchManagerController.getInventoryAlert);
router.post('/inventory/import', verifyBranchManager, branchManagerController.importStock);

// Tra cứu vaccine
router.get('/vaccines/search', verifyBranchManager, branchManagerController.searchVaccine);

// Thống kê
router.get('/stats/pets-vaccinated', verifyBranchManager, branchManagerController.getPetsVaccinated);
router.get('/stats/top-vaccines', verifyBranchManager, branchManagerController.getTopVaccines);
router.get('/stats/inactive-customers', verifyBranchManager, branchManagerController.getInactiveCustomers);

// Thống kê quản lý (mới thêm - có thể truyền tham số time range, điểm sàn)
router.get('/revenue/products', verifyBranchManager, branchManagerController.getProductRevenue); // ?tuNgay=&denNgay=
router.get('/employees/top-rated', verifyBranchManager, branchManagerController.getTopEmployees); // ?diemSan=4.0
router.get('/service/top-revenue', verifyBranchManager, branchManagerController.getTopService);
router.get('/members/stats', verifyBranchManager, branchManagerController.getMemberStats); // ?nam=2024

module.exports = router;
