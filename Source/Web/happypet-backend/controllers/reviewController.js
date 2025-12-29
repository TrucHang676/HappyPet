const { sql, connectDB } = require('../config/db');

// 1. Đánh giá Dịch vụ (Lịch hẹn, Spa...)
exports.reviewService = async (req, res) => {
    try {
        const { MaPhieu, DiemChatLuong, DiemThaiDo, DiemTongThe, BinhLuan } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('DiemChatLuong', sql.Decimal(4, 2), DiemChatLuong)
            .input('DiemThaiDoNV', sql.Decimal(4, 2), DiemThaiDo)
            .input('DiemTongThe', sql.Decimal(4, 2), DiemTongThe)
            .input('BinhLuan', sql.NVarChar(200), BinhLuan)
            .execute('sp_DanhGiaDichVu');

        res.json({ success: true, message: 'Cảm ơn bạn đã đánh giá dịch vụ!' });
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
};

// 2. Đánh giá Sản phẩm (Từng món trong đơn hàng)
exports.reviewProduct = async (req, res) => {
    try {
        const { MaPhieu, MaMatHang, DiemChatLuong, BinhLuan } = req.body;
        const pool = await connectDB();

        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaMatHang', sql.NChar(10), MaMatHang)
            .input('DiemChatLuong', sql.Decimal(4, 2), DiemChatLuong)
            .input('BinhLuan', sql.NVarChar(200), BinhLuan)
            .execute('sp_DanhGiaSanPham');

        res.json({ success: true, message: 'Đánh giá sản phẩm thành công!' });
    } catch (err) {
        res.status(400).json({ message: err.message });
    }
};