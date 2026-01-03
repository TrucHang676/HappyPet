// server/routes/bookingRoutes.js
const express = require('express');
const router = express.Router();
const bookingController = require('../controllers/bookingController');
const { verifyToken } = require('../middleware/authMiddleware');

// Lấy danh sách chi nhánh (Ai xem cũng được, hoặc cần login tùy bà, tui để public cho dễ)
router.get('/branches', bookingController.getBranches);

// Tạo lịch hẹn (Bắt buộc đăng nhập)
router.post('/create', verifyToken, bookingController.createAppointment);

// --- ROUTES MỚI CHO VACCINE ---
// Lấy danh sách Vaccine/Gói để hiển thị (Cần login)
router.get('/vaccine-data', verifyToken, bookingController.getVaccineData);

// Lấy những gì đã chọn trong phiếu
router.get('/selected/:id', verifyToken, bookingController.getSelectedVaccines);

// Các hành động Thêm/Xóa
router.post('/add-single', verifyToken, bookingController.addSingleVaccine);
router.post('/add-package', verifyToken, bookingController.addPackageVaccine);
router.post('/remove-single', verifyToken, bookingController.removeSingleVaccine);
router.post('/remove-package', verifyToken, bookingController.removePackageVaccine);

// Lấy thông tin phiếu (MaTC, MaKH)
router.get('/booking-info/:maPhieu', verifyToken, bookingController.getBookingInfo);

// Check gói vaccine đang tiêm dở
router.get('/check-ongoing-package/:maTC', verifyToken, bookingController.checkOngoingPackage);

// Thêm vaccine vào gói đang tiêm (mũi tiếp theo)
router.post('/add-to-ongoing-package', verifyToken, bookingController.addVaccineToOngoingPackage);

// router.get('/doctors', bookingController.getDoctorSchedule); // Moved to index.js as public route
router.get('/my-bookings', verifyToken, bookingController.getMyBookings);
router.delete('/cancel/:id', verifyToken, bookingController.cancelBooking);
module.exports = router;