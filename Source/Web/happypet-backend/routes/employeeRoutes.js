// // const express = require('express');
// // const router = express.Router();
// // const employeeController = require('../controllers/employeeController');

// // // 🔥 SỬA: Dùng 'verifyToken' cho khớp với file index.js của bạn
// // // Nếu file authMiddleware của bạn chưa có hàm 'authorize', hãy comment tạm dòng đó lại
// // const { verifyToken } = require('../middleware/authMiddleware'); 

// // // --- QUAN TRỌNG: Kiểm tra hàm authorize ---
// // // Nếu middleware của bạn chưa có hàm phân quyền (authorize), bạn có thể tạm bỏ dòng router.use(authorize...)
// // // Nhưng để chuẩn logic, mình giả sử bạn đã có hoặc sẽ dùng verifyToken để chặn login.

// // router.use(verifyToken); // Đảm bảo phải đăng nhập mới vào được

// // // 1. Lấy danh sách lịch hẹn
// // router.get('/bookings', employeeController.getBookings);

// // // 2. Check-in khách hàng
// // router.post('/check-in', employeeController.checkIn);

// // // 3. Tạo phiếu vãng lai
// // router.post('/walk-in', employeeController.createWalkInTicket);

// // module.exports = router;

// const express = require('express');
// const router = express.Router();
// const employeeController = require('../controllers/employeeController');
// const { verifyToken, authorize } = require('../middleware/authMiddleware');

// // Chỉ những ai có Chức vụ là 'Tiếp tân' hoặc 'Quản lý' mới vào được các API này
// router.use(verifyToken);
// router.use(authorize('Tiếp tân', 'Quản lý')); 

// router.get('/appointments', employeeController.getAppointments);
// router.post('/check-in', employeeController.checkIn);
// router.post('/walk-in', employeeController.createWalkInTicket);

// module.exports = router;

const express = require('express');
const router = express.Router();
const employeeController = require('../controllers/employeeController');

router.get('/appointments', employeeController.getAppointments);

// 2. Lấy danh sách bác sĩ (để hiển thị trong Popup chọn bác sĩ)
// GET: /api/employee/doctors-status
router.get('/doctors-status', employeeController.getDoctorsStatus); 

// 3. Xử lý Check-in (Cập nhật trạng thái & Gán bác sĩ)
// PUT: /api/employee/check-in
router.put('/check-in', employeeController.checkIn);

// 4. Tìm kiếm khách hàng theo SĐT (cho vãng lai)
// GET: /api/employee/search-customer?sdt=xxx
router.get('/search-customer', employeeController.searchCustomerByPhone);

// 5. Tạo phiếu vãng lai (Khách đến trực tiếp)
// POST: /api/employee/walk-in
router.post('/walk-in', employeeController.createDirectAppointment);

// 5. Xác nhận đã giao hàng (Nhân viên)
router.post('/confirm-delivery', employeeController.confirmDelivery);

// 6. Tự động hủy lịch hẹn quá hạn 120 phút
router.post('/auto-huy-hen', employeeController.autoHuyLichHen);

// 7. Lấy chi tiết sản phẩm trong đơn hàng
router.get('/order-detail/:maPhieu', employeeController.getOrderDetail);

module.exports = router;