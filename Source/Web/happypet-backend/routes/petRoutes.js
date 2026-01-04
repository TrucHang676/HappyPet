// Xem danh sách, Thêm mới, xem bệnh án
// routes/petRoutes.js
const express = require('express');
const router = express.Router();

// 1. Import Controller (Cái máy xử lý nãy bà viết)
const petController = require('../controllers/petController');

// 2. Import Middleware (Để kiểm tra đăng nhập)
const { verifyToken } = require('../middleware/authMiddleware'); 

// --- CÁC ROUTE CHÍNH THỨC ---

// API 1: Lấy danh sách thú cưng của tui (Gọi SP 11)
router.get('/my-pets', verifyToken, petController.getMyPets);

// API 2: Thêm thú cưng mới (Gọi SP 5)
router.post('/add', verifyToken, petController.addPet);

// API 5: Kiểm tra gói vaccine đang tiêm dở
router.get('/check-ongoing-vaccine/:MaTC', verifyToken, petController.checkOngoingVaccinePackage);

// API 3: Xem lịch sử khám bệnh (Gọi SP 9)
// :id là cái mã thú cưng nó sẽ thay đổi tùy con bà bấm vào
router.get('/:id/medical', verifyToken, petController.getPetMedicalHistory);

// API Sửa thú cưng (Put)
router.put('/update/:id', verifyToken, petController.updatePet);
// API Xóa thú cưng (Delete)
router.delete('/delete/:id', verifyToken, petController.deletePet);
// API: Xem lịch sử khám bệnh
router.get('/history/:id', verifyToken, petController.getPetHistory);
module.exports = router;