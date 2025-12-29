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
router.post('/them-goi-tiem', verifyToken, doctorController.themGoiTiem);
router.delete('/xoa-goi-tiem', verifyToken, doctorController.xoaGoiTiem);
router.post('/them-vaccine-le', verifyToken, doctorController.themVaccineLe);
router.delete('/xoa-vaccine-le', verifyToken, doctorController.xoaVaccineLe);
router.post('/ket-thuc-tiem', verifyToken, doctorController.ketThucTiem);

// ==================== HELPER ====================
router.get('/search-medicines', verifyToken, doctorController.searchMedicinesOrVaccines);
router.get('/vaccine-packages', verifyToken, doctorController.getVaccinePackages);

module.exports = router;