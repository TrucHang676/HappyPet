
// // happypet-backend/index.js
// const express = require('express');
// const cors = require('cors');
// const bodyParser = require('body-parser');
// require('dotenv').config();

// // Import file kết nối database
// const { connectDB } = require('./config/db');

// // --- 1. IMPORT CÁC FILE ROUTE ---
// const authRoutes = require('./routes/authRoutes');
// const petRoutes = require('./routes/petRoutes');
// const userRoutes = require('./routes/userRoutes');
// const bookingRoutes = require('./routes/bookingRoutes');
// const orderRoutes = require('./routes/orderRoutes');
// const cartRoutes = require('./routes/cartRoutes');
// const branchRoutes = require('./routes/branchRoutes');

// // --- IMPORT CONTROLLER ---
// const productController = require('./controllers/productController');
// const cartController = require('./controllers/cartController');
// // 🔥 MỚI THÊM: Import controller xử lý đánh giá
// const reviewController = require('./controllers/reviewController');

// // --- IMPORT MIDDLEWARE ---
// // 🔥 MỚI THÊM: Import xác thực token để chặn người lạ đánh giá
// const { verifyToken } = require('./middleware/authMiddleware');

// const app = express();

// // Middleware (Cấu hình)
// app.use(cors());
// app.use(bodyParser.json());

// // Kết nối SQL Server
// connectDB();

// // --- BẪY LOG (Để xem lệnh gọi lên server) ---
// app.use((req, res, next) => {
//     console.log(`➡️ Server ĐÃ NHẬN lệnh: ${req.method} ${req.url}`);
//     next();
// });

// // --- 2. KÍCH HOẠT CÁC ĐƯỜNG DẪN API ---

// // Auth & User & Pet
// app.use('/api/auth', authRoutes);
// app.use('/api/pets', petRoutes);
// app.use('/api/users', userRoutes);

// // Orders & Booking
// app.use('/api/orders', orderRoutes);
// app.use('/api/booking', bookingRoutes);

// // 🔥 MỚI THÊM: REVIEW API (Đánh giá)
// // (Dùng app.post trực tiếp vì import controller vào đây luôn)
// app.post('/api/reviews/service', verifyToken, reviewController.reviewService);
// app.post('/api/reviews/product', verifyToken, reviewController.reviewProduct);

// // Products & Cart & Branch
// app.get('/api/orders/products', productController.getAllProducts);
// app.use('/api/branches', branchRoutes);
// app.use('/api/cart', cartRoutes);

// // Route mặc định để test server sống hay chết
// app.get('/', (req, res) => {
//     res.send('HappyPet Backend is running!');
// });

// // Chạy Server
// const PORT = process.env.PORT || 5000;
// app.listen(PORT, () => {
//     console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
// });

// happypet-backend/index.js
const express = require('express');
const cors = require('cors');
const bodyParser = require('body-parser');
require('dotenv').config();

// Import file kết nối database
const { connectDB } = require('./config/db');

// --- 1. IMPORT CÁC FILE ROUTE ---
const authRoutes = require('./routes/authRoutes');
const petRoutes = require('./routes/petRoutes');
const userRoutes = require('./routes/userRoutes');
const bookingRoutes = require('./routes/bookingRoutes');
const orderRoutes = require('./routes/orderRoutes');
const cartRoutes = require('./routes/cartRoutes');
const branchRoutes = require('./routes/branchRoutes');

// 🔥🔥🔥 BÀ THIẾU 2 DÒNG NÀY NÈ TRỜI ƠI!!! 👇👇👇
const employeeRoutes = require('./routes/employeeRoutes');
const doctorRoutes = require('./routes/doctorRoutes');

// --- IMPORT CONTROLLER ---
const productController = require('./controllers/productController');
const cartController = require('./controllers/cartController');
const reviewController = require('./controllers/reviewController');

// --- IMPORT MIDDLEWARE ---
const { verifyToken } = require('./middleware/authMiddleware');

const app = express();

// Middleware (Cấu hình)
app.use(cors());
app.use(bodyParser.json());

// Kết nối SQL Server
connectDB();

// --- BẪY LOG (Để xem lệnh gọi lên server) ---
app.use((req, res, next) => {
    console.log(`➡️ Server ĐÃ NHẬN lệnh: ${req.method} ${req.url}`);
    next();
});

// --- 2. KÍCH HOẠT CÁC ĐƯỜNG DẪN API ---

// Auth & User & Pet
app.use('/api/auth', authRoutes);
app.use('/api/pets', verifyToken, petRoutes); // Nên có verifyToken nha
app.use('/api/users', verifyToken, userRoutes); // Nên có verifyToken nha

// Orders & Booking
app.use('/api/orders', verifyToken, orderRoutes);

// 🔥 QUAN TRỌNG: Route public (không cần token) PHẢI ĐẶT TRƯỚC
// Route GET /branches để xem danh sách chi nhánh (ai cũng xem được)
const bookingController = require('./controllers/bookingController');
app.get('/api/booking/branches', bookingController.getBranches);
app.get('/api/booking/doctors', bookingController.getDoctorSchedule); // Public - xem lịch bác sĩ

// Các route còn lại của booking CẦN TOKEN
app.use('/api/booking', verifyToken, bookingRoutes);

// 🔥🔥🔥 VÀ THIẾU KÍCH HOẠT Ở ĐÂY NỮA!!! 👇👇👇
// (Không có dòng này thì Server không biết đường dẫn /api/employee là gì cả)
app.use('/api/employee', verifyToken, employeeRoutes);
app.use('/api/doctor', verifyToken, doctorRoutes);


// REVIEW API
app.post('/api/reviews/service', verifyToken, reviewController.reviewService);
app.post('/api/reviews/product', verifyToken, reviewController.reviewProduct);

// Products & Cart & Branch
app.get('/api/products', productController.getAllProducts);
app.use('/api/branches', branchRoutes);
app.use('/api/cart', verifyToken, cartRoutes);

// Route mặc định
app.get('/', (req, res) => {
    res.send('HappyPet Backend is running!');
});

// Chạy Server
const PORT = process.env.PORT || 5000;
app.listen(PORT, () => {
    console.log(`🚀 Server đang chạy tại http://localhost:${PORT}`);
    
    // 🔥 TỰ ĐỘNG HỦY LỊCH HẸN QUÁ 120 PHÚT - CHẠY MỖI 10 PHÚT
    console.log('⏰ Bật tự động hủy lịch hẹn (mỗi 10 phút)');
    setInterval(async () => {
        try {
            const { sql } = require('./config/db');
            const pool = await sql.connect();
            const result = await pool.request().execute('sp_TuDongHuyLichHen');
            const soPhieuHuy = result.recordset[0]?.SoPhieuDaHuyTuDong || 0;
            if (soPhieuHuy > 0) {
                console.log(`✅ [${new Date().toLocaleString('vi-VN')}] Tự động hủy ${soPhieuHuy} lịch hẹn quá hạn`);
            }
        } catch (error) {
            console.error('❌ Lỗi tự động hủy lịch hẹn:', error.message);
        }
    }, 10 * 60 * 1000); // 10 phút = 600,000ms
});