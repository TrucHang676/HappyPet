const { sql } = require('../config/db');

// 1. Điều động nhân sự
exports.transferEmployee = async (req, res) => {
    try {
        const { MaNV, MaCN_Moi, NgayBD, NgayKT, GhiChu } = req.body;

        const pool = await sql.connect();
        await pool.request()
            .input('MaNV', sql.NChar(10), MaNV)
            .input('MaCN_Moi', sql.NChar(10), MaCN_Moi)
            .input('NgayBD', sql.Date, NgayBD)
            .input('NgayKT', sql.Date, NgayKT)
            .input('GhiChu', sql.NVarChar(100), GhiChu)
            .execute('sp_DieuDongNhanSu');

        res.json({ success: true, message: 'Điều động nhân sự thành công!' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 2. Thống kê doanh thu sản phẩm
exports.getProductRevenue = async (req, res) => {
    try {
        const { tuNgay, denNgay } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('TuNgay', sql.Date, tuNgay)
            .input('DenNgay', sql.Date, denNgay)
            .execute('sp_ThongKeDoanhThuSanPham');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 3. Thống kê doanh thu chi nhánh
exports.getBranchRevenue = async (req, res) => {
    try {
        const { thang, nam } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('Thang', sql.Int, parseInt(thang))
            .input('Nam', sql.Int, parseInt(nam))
            .execute('sp_ThongKeDoanhThuChiNhanh');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 4. Thống kê nhân viên có điểm đánh giá cao
exports.getTopEmployees = async (req, res) => {
    try {
        const { diemSan } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('DiemSan', sql.Decimal(4, 2), parseFloat(diemSan))
            .execute('sp_ThongKeNhanVienGioi');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 5. Thống kê sản phẩm có điểm đánh giá cao
exports.getTopProducts = async (req, res) => {
    try {
        const { diemSan } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('DiemSan', sql.Decimal(4, 2), parseFloat(diemSan))
            .execute('sp_ThongKeSanPhamTot');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 6. Cảnh báo hết hàng
exports.getLowStockAlert = async (req, res) => {
    try {
        const { maCN, nguongCanhBao } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN || req.user.MaCN)
            .input('NguongCanhBao', sql.Int, parseInt(nguongCanhBao) || 10)
            .execute('sp_CanhBaoHetHang');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 7. Top dịch vụ doanh thu cao nhất
exports.getTopService = async (req, res) => {
    try {
        const pool = await sql.connect();
        const result = await pool.request()
            .execute('sp_TopDichVuDoanhThu');

        res.json(result.recordset[0] || {});
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 8. Thống kê hội viên
exports.getMembershipStats = async (req, res) => {
    try {
        const { nam } = req.query;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('Nam', sql.Int, parseInt(nam))
            .execute('sp_ThongKeHoiVien');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 9. Cập nhật xếp hạng hội viên (Admin only, chỉ chạy ngày 31/12)
exports.updateMembershipRanking = async (req, res) => {
    try {
        const { nam } = req.body;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('Nam', sql.Int, parseInt(nam))
            .execute('sp_CapNhatXepHangHoiVien');

        res.json({ success: true, message: 'Cập nhật xếp hạng thành công!', data: result.recordset });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 10. Nhập hàng vào kho
exports.importStock = async (req, res) => {
    try {
        const { MaCN, MaMatHang, SoLuongNhap } = req.body;

        const pool = await sql.connect();
        await pool.request()
            .input('MaCN', sql.NChar(10), MaCN || req.user.MaCN)
            .input('MaMatHang', sql.NChar(10), MaMatHang)
            .input('SoLuongNhap', sql.Int, parseInt(SoLuongNhap))
            .execute('sp_NhapHangVaoKho');

        res.json({ success: true, message: 'Nhập hàng thành công!' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 11. Thêm mặt hàng mới
exports.addProduct = async (req, res) => {
    try {
        const {
            TenMatHang, HangSX, NgaySanXuat, NgayHetHan, DonGia, LoaiMH,
            TacDungPhu, DangBaoChe, LoaiThuoc, ChongChiDinh, LoaiSP
        } = req.body;

        const pool = await sql.connect();
        const result = await pool.request()
            .input('TenMatHang', sql.NVarChar(80), TenMatHang)
            .input('HangSX', sql.NVarChar(50), HangSX)
            .input('NgaySanXuat', sql.Date, NgaySanXuat)
            .input('NgayHetHan', sql.Date, NgayHetHan)
            .input('DonGia', sql.Decimal(18, 2), parseFloat(DonGia))
            .input('LoaiMH', sql.VarChar(3), LoaiMH)
            .input('TacDungPhu', sql.NVarChar(200), TacDungPhu || null)
            .input('DangBaoChe', sql.NVarChar(70), DangBaoChe || null)
            .input('LoaiThuoc', sql.NVarChar(20), LoaiThuoc || null)
            .input('ChongChiDinh', sql.NVarChar(200), ChongChiDinh || null)
            .input('LoaiSP', sql.NVarChar(70), LoaiSP || null)
            .execute('sp_ThemMatHang');

        res.json({ 
            success: true, 
            message: 'Thêm mặt hàng thành công!', 
            data: result.recordset[0] 
        });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 12. Lấy danh sách nhân viên (để chọn khi điều động)
exports.getAllEmployees = async (req, res) => {
    try {
        const pool = await sql.connect();
        const result = await pool.request().query(`
            SELECT 
                NV.MaNV,
                U.HoTen,
                NV.Chucvu,
                CN.TenCN,
                NV.MaCN
            FROM NHAN_VIEN NV
            JOIN [USER] U ON NV.MaNV = U.MaUser
            JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
            ORDER BY U.HoTen
        `);

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 13. Lấy danh sách mặt hàng (để chọn khi nhập kho)
exports.getAllProducts = async (req, res) => {
    try {
        const pool = await sql.connect();
        const result = await pool.request().query(`
            SELECT 
                MaMatHang,
                TenMatHang,
                LoaiMH,
                DonGia
            FROM MAT_HANG
            ORDER BY TenMatHang
        `);

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};
