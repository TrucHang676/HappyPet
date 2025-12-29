const { sql, connectDB } = require('../config/db');

// ==================== KHÁM BỆNH ====================

// 1. Cập nhật kết quả khám (Chẩn đoán + ngày hẹn tái khám)
exports.capNhatKetQuaKham = async (req, res) => {
    try {
        const { MaPhieu, ChanDoan, NgayHenTaiKham } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('ChanDoan', sql.NVarChar(200), ChanDoan)
            .input('NgayHenTaiKham', sql.Date, NgayHenTaiKham || null)
            .execute('sp_CapNhatKetQuaKham');
            
        res.json({ success: true, message: 'Đã cập nhật chẩn đoán' });
    } catch (error) {
        console.error('❌ Lỗi cập nhật chẩn đoán:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 2. Thêm thuốc vào đơn
exports.themThuocVaoDon = async (req, res) => {
    try {
        const { MaPhieu, MaThuoc, SoLuong, LieuLuong } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaThuoc', sql.NChar(10), MaThuoc)
            .input('SoLuong', sql.Int, SoLuong)
            .input('LieuLuong', sql.NVarChar(50), LieuLuong || '')
            .execute('sp_ThemThuocVaoDon');
            
        res.json({ success: true, message: 'Đã thêm thuốc vào đơn' });
    } catch (error) {
        console.error('❌ Lỗi thêm thuốc:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 3. Xóa thuốc khỏi đơn
exports.xoaThuocKhoiDon = async (req, res) => {
    try {
        const { MaPhieu, MaThuoc } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaThuoc', sql.NChar(10), MaThuoc)
            .execute('sp_XoaThuocKhoiDon');
            
        res.json({ success: true, message: 'Đã xóa thuốc khỏi đơn' });
    } catch (error) {
        console.error('❌ Lỗi xóa thuốc:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 4. Kết thúc khám bệnh
exports.ketThucKham = async (req, res) => {
    try {
        const { MaPhieu } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .execute('sp_BacSi_KetThucKham');
            
        res.json({ success: true, message: 'Đã hoàn tất khám bệnh' });
    } catch (error) {
        console.error('❌ Lỗi kết thúc khám:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==================== TIÊM VACCINE ====================

// 5. Thêm gói tiêm (Khách vãng lai không đặt trước)
exports.themGoiTiem = async (req, res) => {
    try {
        const { MaPhieu, MaVaccine, MaGoi } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaVaccine', sql.NChar(10), MaVaccine)
            .input('MaGoi', sql.NChar(10), MaGoi)
            .execute('sp_BacSi_ThemGoiTiem');
            
        res.json({ success: true, message: 'Đã thêm gói tiêm' });
    } catch (error) {
        console.error('❌ Lỗi thêm gói tiêm:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 6. Xóa gói tiêm
exports.xoaGoiTiem = async (req, res) => {
    try {
        const { MaPhieu, MaVaccine, MaGoi } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaVaccine', sql.NChar(10), MaVaccine)
            .input('MaGoi', sql.NChar(10), MaGoi)
            .execute('sp_BacSi_XoaGoiTiem');
            
        res.json({ success: true, message: 'Đã xóa gói tiêm' });
    } catch (error) {
        console.error('❌ Lỗi xóa gói tiêm:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 7. Thêm vaccine lẻ hoặc mũi nhắc lại
exports.themVaccineLe = async (req, res) => {
    try {
        const { MaPhieu, MaVaccine, LieuLuong, NhacLai, TheoGoi } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaVaccine', sql.NChar(10), MaVaccine)
            .input('LieuLuong', sql.NVarChar(70), LieuLuong || '1 liều')
            .input('NhacLai', sql.Bit, NhacLai || 0)
            .input('TheoGoi', sql.Bit, TheoGoi || 0)
            .execute('sp_BacSi_ThemVaccineLe');
            
        res.json({ success: true, message: 'Đã thêm vaccine' });
    } catch (error) {
        console.error('❌ Lỗi thêm vaccine:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 8. Xóa vaccine lẻ
exports.xoaVaccineLe = async (req, res) => {
    try {
        const { MaPhieu, MaVaccine } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaVaccine', sql.NChar(10), MaVaccine)
            .execute('sp_BacSi_XoaVaccineLe');
            
        res.json({ success: true, message: 'Đã xóa vaccine' });
    } catch (error) {
        console.error('❌ Lỗi xóa vaccine:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// 9. Kết thúc tiêm vaccine
exports.ketThucTiem = async (req, res) => {
    try {
        const { MaPhieu } = req.body;
        const pool = await connectDB();
        
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .execute('sp_BacSi_KetThucTiem');
            
        res.json({ success: true, message: 'Đã hoàn tất tiêm vaccine' });
    } catch (error) {
        console.error('❌ Lỗi kết thúc tiêm:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

// ==================== HELPER - Lấy danh sách chờ khám ====================
exports.getWaitingList = async (req, res) => {
    try {
        const maCN = req.user.MaCN || 'CN001';
        const maBacSi = req.user.MaUser;

        const pool = await connectDB();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN)
            .input('MaBacSi', sql.NChar(10), maBacSi)
            .execute('sp_BacSi_LayDanhSachChoKham');
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy danh sách chờ:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// ==================== HELPER - Lấy chi tiết phiếu ====================
exports.getExamDetail = async (req, res) => {
    try {
        const { maPhieu } = req.params;
        const pool = await connectDB();
        
        // Lấy thông tin phiếu dịch vụ
        const phieuResult = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    P.MaPhieu, P.TG_LapPhieu, P.TG_ThucHienDV, P.TrangThai, P.MaCN,
                    U.HoTen AS TenKhachHang, KH.SDT, U.DiemTichLuy,
                    TC.TenTC AS TenThuCung, TC.Loai AS LoaiThuCung, TC.Giong AS GiongThuCung, 
                    TC.NgSinh, TC.TinhTrangSucKhoe,
                    PKB.ChanDoan, PKB.NgayHenTaiKham,
                    PTV.MaGoi AS MaGoiVaccine
                FROM PHIEU_DICH_VU P
                JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
                JOIN [USER] U ON KH.MaKH = U.MaUser
                LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
                LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
                LEFT JOIN THU_CUNG TC ON COALESCE(PKB.MaTC, PTV.MaTC) = TC.MaTC
                WHERE P.MaPhieu = @MaPhieu
            `);
            
        // Lấy đơn thuốc (nếu là phiếu khám)
        const thuocResult = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT CT.MaThuoc, MH.TenMatHang, CT.SoLuong, CT.LieuLuong, CT.ThanhTien
                FROM CT_DON_THUOC CT
                JOIN MAT_HANG MH ON CT.MaThuoc = MH.MaMatHang
                WHERE CT.MaPhieu = @MaPhieu
            `);
            
        // Lấy danh sách vaccine (nếu là phiếu tiêm)
        const vaccineResult = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT CT.MaVaccine, MH.TenMatHang, CT.LieuLuong, CT.NhacLai, CT.ThanhTien
                FROM CT_TIEM_VC CT
                JOIN MAT_HANG MH ON CT.MaVaccine = MH.MaMatHang
                WHERE CT.MaPhieu = @MaPhieu
            `);
        
        res.json({
            phieu: phieuResult.recordset[0],
            danhSachThuoc: thuocResult.recordset,
            danhSachVaccine: vaccineResult.recordset
        });
    } catch (error) {
        console.error('❌ Lỗi lấy chi tiết phiếu:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// ==================== HELPER - Tìm thuốc/vaccine trong kho ====================
exports.searchMedicinesOrVaccines = async (req, res) => {
    try {
        const { tuKhoa, loai } = req.query; // loai: 'Thuốc' hoặc 'Vaccine'
        const maCN = req.user.MaCN || 'CN001';
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN)
            .input('TuKhoa', sql.NVarChar, tuKhoa || '')
            .input('LoaiMH', sql.NVarChar, loai || 'Thuốc')
            .query(`
                SELECT MH.MaMatHang, MH.TenMatHang, MH.DonGia, TK.SoLuongTon
                FROM MAT_HANG MH
                JOIN TON_KHO TK ON MH.MaMatHang = TK.MaMatHang
                WHERE TK.MaCN = @MaCN 
                  AND MH.LoaiMH = @LoaiMH
                  AND MH.TenMatHang LIKE '%' + @TuKhoa + '%'
                  AND TK.SoLuongTon > 0
            `);
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi tìm thuốc/vaccine:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// ==================== HELPER - Lấy danh sách gói tiêm ====================
exports.getVaccinePackages = async (req, res) => {
    try {
        const pool = await connectDB();
        const result = await pool.request()
            .query(`
                SELECT MaGoi, TenGoi, SoMuiTuongUng, GiamGia, ThoiHan
                FROM GOI_TIEM_VC
            `);
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy gói tiêm:', error.message);
        res.status(500).json({ message: error.message });
    }
};
// ==================== API MỚI CHO EXAM DETAIL ====================

// Lấy thông tin bệnh nhân từ phiếu
exports.getPatientInfo = async (req, res) => {
    try {
        const { maPhieu } = req.params;
        console.log('🔍 Getting patient info for:', maPhieu);
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    TC.Ten AS TenThuCung, 
                    TC.Loai AS LoaiThuCung, 
                    TC.Giong AS GiongThuCung,
                    U.HoTen AS ChuNuoi,
                    KH.SDT
                FROM PHIEU_DICH_VU P
                LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
                LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
                LEFT JOIN THU_CUNG TC ON COALESCE(PKB.MaTC, PTV.MaTC) = TC.MaTC
                JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
                JOIN [USER] U ON KH.MaKH = U.MaUser
                WHERE P.MaPhieu = @MaPhieu
            `);
        
        console.log('📦 Query result:', result.recordset);
            
        if (result.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy thông tin bệnh nhân' });
        }
        
        res.json(result.recordset[0]);
    } catch (error) {
        console.error('❌ Lỗi lấy thông tin bệnh nhân:', error);
        res.status(500).json({ message: error.message });
    }
};

// Lấy danh sách thuốc khả dụng
exports.getAvailableMedicines = async (req, res) => {
    try {
        const maCN = req.user.MaCN || 'CN001';
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN)
            .query(`
                SELECT 
                    MH.MaMatHang AS MaThuoc,
                    MH.TenMatHang AS TenThuoc,
                    MH.DonGia,
                    TK.SoLuongTon,
                    MH.LoaiMH
                FROM MAT_HANG MH
                JOIN TON_KHO TK ON MH.MaMatHang = TK.MaMatHang
                WHERE TK.MaCN = @MaCN 
                  AND MH.LoaiMH = 'T'
                  AND TK.SoLuongTon > 0
                ORDER BY MH.TenMatHang
            `);
        
        console.log('💊 Danh sách thuốc:', result.recordset.length, 'items');
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy danh sách thuốc:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// Lấy đơn thuốc hiện tại của phiếu
exports.getCurrentPrescription = async (req, res) => {
    try {
        const { maPhieu } = req.params;
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    CT.MaThuoc,
                    MH.TenMatHang AS TenThuoc,
                    CT.SoLuong,
                    CT.LieuLuong,
                    CT.ThanhTien
                FROM CT_DON_THUOC CT
                JOIN MAT_HANG MH ON CT.MaThuoc = MH.MaMatHang
                WHERE CT.MaPhieu = @MaPhieu
            `);
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy đơn thuốc:', error.message);
        res.status(500).json({ message: error.message });
    }
};

// Lấy lịch sử khám bệnh của thú cưng
exports.getMedicalHistory = async (req, res) => {
    try {
        const { maPhieu } = req.params;
        const pool = await connectDB();
        
        // Lấy MaTC từ phiếu hiện tại
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    P.MaPhieu,
                    P.TG_LapPhieu,
                    P.TG_ThucHienDV,
                    P.TrangThai,
                    PKB.ChanDoan,
                    PKB.NgayHenTaiKham,
                    U.HoTen AS BacSi
                FROM PHIEU_DICH_VU P
                LEFT JOIN PHIEU_KHAM_BENH PKB_CURRENT ON P.MaPhieu = PKB_CURRENT.MaPhieu
                LEFT JOIN PHIEU_TIEM_VACCINE PTV_CURRENT ON P.MaPhieu = PTV_CURRENT.MaPhieu
                JOIN PHIEU_KHAM_BENH PKB ON PKB.MaTC = COALESCE(PKB_CURRENT.MaTC, PTV_CURRENT.MaTC)
                JOIN PHIEU_DICH_VU P2 ON PKB.MaPhieu = P2.MaPhieu
                LEFT JOIN [USER] U ON P2.MaNV = U.MaUser
                WHERE P.MaPhieu = @MaPhieu
                  AND PKB.MaPhieu != @MaPhieu
                  AND P2.TrangThai IN ('DHT', 'HT')
                ORDER BY P2.TG_ThucHienDV DESC
            `);
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy lịch sử khám:', error.message);
        res.status(500).json({ message: error.message });
    }
};