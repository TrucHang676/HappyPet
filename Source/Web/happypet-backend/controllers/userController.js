const { sql } = require('../config/db');

// 1. Xem hồ sơ (Gọi SP sp_XemThongTinCaNhan)
exports.getProfile = async (req, res) => {
    try {
        const pool = await sql.connect();
        // Lấy MaKH từ Token (req.user.MaUser)
        const request = pool.request().input('MaKH', sql.NChar(10), req.user.MaUser); 
        
        const result = await request.execute('sp_XemThongTinCaNhan');
        
        // Nếu không tìm thấy user
        if (result.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy thông tin' });
        }

        res.json(result.recordset[0]);
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Lỗi server: ' + err.message });
    }
};

// 2. Cập nhật hồ sơ (Gọi SP sp_CapNhatThongTinKH)
exports.updateProfile = async (req, res) => {
    const { HoTen, NgaySinh, GioiTinh, Email, CCCD } = req.body;
    try {
        const userId = req.user.id || req.user.MaUser || req.user.MaKH;

        const pool = await sql.connect();
        const request = pool.request()
            .input('MaUser', sql.NChar(10), userId)
            .input('HoTen', sql.NVarChar(50), HoTen)
            .input('NgaySinh', sql.Date, NgaySinh)
            .input('GioiTinh', sql.NVarChar(3), GioiTinh)
            // Truong hop khong muon cap nhat email hoac cccd thi gui null
            .input('Email', sql.VarChar(50), Email || null)
            .input('CCCD', sql.Char(12), CCCD || null);
        
        await request.execute('sp_CapNhatThongTinKH');
        
        res.json({ message: 'Cập nhật thông tin thành công!' });
    } catch (err) {
        // Bắt lỗi từ SP (ví dụ trùng Email)
        res.status(500).json({ message: err.message });
    }
};

// 3. Xem lịch sử hoạt động (SP số 13) - Tương tự cho SP 8 (Mua sắm)
exports.getActivityHistory = async (req, res) => {
    try {
        const pool = await sql.connect();
        const request = pool.request().input('MaKH', sql.NChar(10), req.user.MaUser);
        const result = await request.execute('sp_XemLichSuHoatDong');
        res.json(result.recordset);
    } catch (err) { res.status(500).json({ message: err.message }); }
};

