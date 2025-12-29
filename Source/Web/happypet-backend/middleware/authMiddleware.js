// middleware/authMiddleware.js
const jwt = require('jsonwebtoken');

// 1. Hàm xác thực: Kiểm tra xem User có gửi Token hợp lệ không?
const verifyToken = (req, res, next) => {
    // Lấy token từ header (thường gửi dạng: "Bearer <token>")
    const authHeader = req.header('Authorization');
    const token = authHeader && authHeader.split(' ')[1]; 

    if (!token) {
        return res.status(401).json({ message: 'Bạn chưa đăng nhập! (Không tìm thấy Token)' });
    }

    try {
        // Giải mã token
        // LƯU Ý: Cái chuỗi 'khoa_bi_mat_cua_ban' phải GIỐNG Y CHANG bên file authController.js nha
        const verified = jwt.verify(token, process.env.JWT_SECRET || 'toimuontoitetlamroichoioiii!!');
        // Lưu thông tin user đã giải mã vào biến req.user để dùng ở các bước sau
        req.user = verified; 
        
        next(); // Cho phép đi tiếp
    } catch (err) {
        res.status(400).json({ message: 'Token không hợp lệ hoặc đã hết hạn!' });
    }
};

// 2. Hàm phân quyền: Chỉ cho phép Nhân viên (NV) đi tiếp
const verifyStaff = (req, res, next) => {
    // Gọi hàm verifyToken trước để chắc chắn đã đăng nhập
    verifyToken(req, res, () => {
        // Kiểm tra Role trong token
        // (Lúc login mình đã nhét Role vào token rồi, giờ lôi ra check)
        if (req.user.Role === 'NV' || req.user.Role === 'ADMIN') {
            next(); // Là nhân viên -> Mời vào
        } else {
            res.status(403).json({ message: 'Bạn không có quyền truy cập chức năng này!' });
        }
    });
};

module.exports = { verifyToken, verifyStaff };
