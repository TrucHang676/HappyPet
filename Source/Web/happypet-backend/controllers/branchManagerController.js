const { sql, connectDB } = require('../config/db');

// =============================================
// QUẢN LÝ CHI NHÁNH - CHỈ XEM DỮ LIỆU CHI NHÁNH CỦA MÌNH
// =============================================

// 1. Doanh thu chi nhánh theo ngày/tháng/quý/năm
exports.getRevenueByPeriod = async (req, res) => {
    try {
        const { loaiThongKe, nam, thang, quy, ngay } = req.query;
        const MaCN = req.user.MaCN; // Lấy từ token

        // Lấy ngày hiện tại để làm mặc định
        const now = new Date();
        const namHienTai = now.getFullYear();
        const thangHienTai = now.getMonth() + 1;
        const ngayHienTai = now.getDate();
        const quyHienTai = Math.ceil(thangHienTai / 3);

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('LoaiThongKe', sql.VarChar(10), loaiThongKe || 'THANG')
            .input('Nam', sql.Int, parseInt(nam) || namHienTai)
            .input('Thang', sql.Int, thang ? parseInt(thang) : thangHienTai)
            .input('Quy', sql.Int, quy ? parseInt(quy) : quyHienTai)
            .input('Ngay', sql.Int, ngay ? parseInt(ngay) : ngayHienTai)
            .execute('sp_DoanhThuChiNhanhTheoDot');

        res.json(result.recordset[0] || {});
    } catch (error) {
        console.error('Lỗi thống kê doanh thu:', error);
        res.status(500).json({ message: error.message });
    }
};

// 2. Danh sách nhân viên chi nhánh
exports.getEmployees = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { chucVu } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('ChucVu', sql.NVarChar(50), chucVu || null)
            .execute('sp_LayDanhSachNhanVien');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi lấy danh sách nhân viên:', error);
        res.status(500).json({ message: error.message });
    }
};

// 3. Thêm nhân viên mới
exports.addEmployee = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { hoTen, ngaySinh, gioiTinh, chucVu, ngayVaoLam, luongCoBan, tenDangNhap, matKhau } = req.body;

        const pool = await connectDB();
        const result = await pool.request()
            .input('HoTen', sql.NVarChar(50), hoTen)
            .input('NgaySinh', sql.Date, ngaySinh)
            .input('GioiTinh', sql.NVarChar(3), gioiTinh)
            .input('ChucVu', sql.NVarChar(50), chucVu)
            .input('NgayVaoLam', sql.Date, ngayVaoLam)
            .input('LuongCoBan', sql.Decimal(12, 2), luongCoBan)
            .input('MaCN', sql.NChar(10), MaCN)
            .input('TenDangNhap', sql.VarChar(30), tenDangNhap)
            .input('MatKhau', sql.VarChar(50), matKhau)
            .execute('sp_ThemNhanVien');

        res.json({ success: true, data: result.recordset[0] });
    } catch (error) {
        console.error('Lỗi thêm nhân viên:', error);
        res.status(500).json({ message: error.message });
    }
};

// 4. Cập nhật thông tin nhân viên
exports.updateEmployee = async (req, res) => {
    try {
        const { maNV } = req.params;
        const { hoTen, ngaySinh, gioiTinh, chucVu, luongCoBan } = req.body;

        const pool = await connectDB();
        await pool.request()
            .input('MaNV', sql.NChar(10), maNV)
            .input('HoTen', sql.NVarChar(50), hoTen || null)
            .input('NgaySinh', sql.Date, ngaySinh || null)
            .input('GioiTinh', sql.NVarChar(3), gioiTinh || null)
            .input('ChucVu', sql.NVarChar(50), chucVu || null)
            .input('LuongCoBan', sql.Decimal(12, 2), luongCoBan || null)
            .execute('sp_CapNhatNhanVien');

        res.json({ success: true, message: 'Cập nhật thành công!' });
    } catch (error) {
        console.error('Lỗi cập nhật nhân viên:', error);
        res.status(500).json({ message: error.message });
    }
};

// 5. Tồn kho chi nhánh (sử dụng lại từ managerController)
exports.getInventoryAlert = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { nguongCanhBao } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('NguongCanhBao', sql.Int, nguongCanhBao || 10)
            .execute('sp_CanhBaoHetHang');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi kiểm tra tồn kho:', error);
        res.status(500).json({ message: error.message });
    }
};

// 6. Tra cứu vaccine
exports.searchVaccine = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { tuKhoa, tuNgaySX, denNgaySX } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('TuKhoa', sql.NVarChar(100), tuKhoa || null)
            .input('MaCN', sql.NChar(10), MaCN)
            .input('TuNgaySX', sql.Date, tuNgaySX || null)
            .input('DenNgaySX', sql.Date, denNgaySX || null)
            .execute('sp_TraCuuVaccine');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi tra cứu vaccine:', error);
        res.status(500).json({ message: error.message });
    }
};

// 7. Thống kê thú cưng được tiêm trong kỳ
exports.getPetsVaccinated = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { tuNgay, denNgay } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('TuNgay', sql.Date, tuNgay)
            .input('DenNgay', sql.Date, denNgay)
            .execute('sp_ThongKePetDuocTiem');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê thú cưng tiêm:', error);
        res.status(500).json({ message: error.message });
    }
};

// 8. Thống kê vaccine được đặt nhiều nhất
exports.getTopVaccines = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { tuNgay, denNgay, top } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('TuNgay', sql.Date, tuNgay)
            .input('DenNgay', sql.Date, denNgay)
            .input('Top', sql.Int, parseInt(top) || 10)
            .execute('sp_ThongKeVaccineNhieuNhat');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê vaccine:', error);
        res.status(500).json({ message: error.message });
    }
};

// 9. Thống kê khách hàng lâu chưa quay lại
exports.getInactiveCustomers = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { soNgay } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('SoNgay', sql.Int, parseInt(soNgay) || 180)
            .execute('sp_ThongKeKhachHangLauChuaQuayLai');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê khách hàng:', error);
        res.status(500).json({ message: error.message });
    }
};

// 10. Nhập hàng vào kho (sử dụng lại từ managerController)
exports.importStock = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { maMatHang, soLuongNhap } = req.body;

        const pool = await connectDB();
        await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('MaMatHang', sql.NChar(10), maMatHang)
            .input('SoLuongNhap', sql.Int, soLuongNhap)
            .execute('sp_NhapHangVaoKho');

        res.json({ success: true, message: 'Nhập kho thành công!' });
    } catch (error) {
        console.error('Lỗi nhập kho:', error);
        res.status(500).json({ message: error.message });
    }
};

// 11. Thống kê doanh thu sản phẩm (của chi nhánh)
exports.getProductRevenue = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { tuNgay, denNgay } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('TuNgay', sql.Date, tuNgay)
            .input('DenNgay', sql.Date, denNgay)
            .input('MaCN', sql.NChar(10), MaCN) // Chỉ lấy của chi nhánh này
            .execute('sp_ThongKeDoanhThuSanPham');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê doanh thu sản phẩm:', error);
        res.status(500).json({ message: error.message });
    }
};

// 12. Thống kê nhân viên giỏi (của chi nhánh)
exports.getTopEmployees = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { diemSan } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('DiemSan', sql.Decimal(4, 2), parseFloat(diemSan) || 4.0)
            .input('MaCN', sql.NChar(10), MaCN)
            .execute('sp_ThongKeNhanVienGioi');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê nhân viên:', error);
        res.status(500).json({ message: error.message });
    }
};

// 13. Top dịch vụ doanh thu cao nhất (của chi nhánh)
exports.getTopService = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .execute('sp_TopDichVuDoanhThu');

        res.json(result.recordset[0] || {});
    } catch (error) {
        console.error('Lỗi thống kê dịch vụ:', error);
        res.status(500).json({ message: error.message });
    }
};

// 14. Thống kê hội viên (của chi nhánh)
exports.getMemberStats = async (req, res) => {
    try {
        const MaCN = req.user.MaCN;
        const { nam } = req.query;

        const pool = await connectDB();
        const result = await pool.request()
            .input('Nam', sql.Int, parseInt(nam) || new Date().getFullYear())
            .input('MaCN', sql.NChar(10), MaCN)
            .execute('sp_ThongKeHoiVien');

        res.json(result.recordset);
    } catch (error) {
        console.error('Lỗi thống kê hội viên:', error);
        res.status(500).json({ message: error.message });
    }
};

module.exports = exports;
