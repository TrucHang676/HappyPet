const express = require('express');
const router = express.Router();
const doctorController = require('../controllers/doctorController');
const { verifyToken } = require('../middleware/authMiddleware');

// ==================== DANH SÁCH & CHI TIẾT ====================
router.get('/waiting-list', verifyToken, doctorController.getWaitingList);
router.get('/exam-detail/:maPhieu', verifyToken, doctorController.getExamDetail);
router.get('/patient-info/:maPhieu', verifyToken, doctorController.getPatientInfo);
router.get('/medicines', verifyToken, doctorController.getAvailableMedicines);
router.get('/prescription/:maPhieu', verifyToken, doctorController.getCurrentPrescription);
router.get('/medical-history/:maPhieu', verifyToken, doctorController.getMedicalHistory);

// ==================== KHÁM BỆNH ====================
router.post('/update-diagnosis', verifyToken, doctorController.capNhatKetQuaKham);
router.post('/add-medicine', verifyToken, doctorController.themThuocVaoDon);
router.post('/remove-medicine', verifyToken, doctorController.xoaThuocKhoiDon);
router.post('/finish-exam', verifyToken, doctorController.ketThucKham);

// ==================== TIÊM VACCINE ====================
router.get('/vaccine-packages', verifyToken, doctorController.getVaccinePackages);
router.get('/vaccine-history/:MaTC', verifyToken, doctorController.getLichSuTiem); // 🔥 LỊCH SỬ TIÊM
router.post('/add-vaccine-package', verifyToken, doctorController.themGoiTiem);
router.post('/remove-vaccine-package', verifyToken, doctorController.xoaGoiTiem);
router.post('/add-vaccine-single', verifyToken, doctorController.themVaccineLe); // 🔥 THÊM VACCINE LẺ
router.post('/add-vaccine', verifyToken, doctorController.themVaccineLe); // Alias
router.post('/remove-vaccine', verifyToken, doctorController.xoaVaccineLe);
router.post('/complete-vaccine', verifyToken, doctorController.ketThucTiem);

// ==================== XUẤT HÓA ĐƠN ====================
router.post('/export-invoice', verifyToken, doctorController.exportInvoice); // 🔥 XUẤT HÓA ĐƠN

// ==================== HELPER ====================
router.get('/search-medicines', verifyToken, doctorController.searchMedicinesOrVaccines);

module.exports = router;