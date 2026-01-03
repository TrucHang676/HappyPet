const { sql, connectDB } = require('../config/db');

// ==================== LỊCH SỬ TIÊM ====================

// Lấy lịch sử tiêm vaccine của thú cưng
exports.getLichSuTiem = async (req, res) => {
    try {
        const { MaTC } = req.params;
        
        console.log("📋 Lấy lịch sử tiêm của thú cưng:", MaTC);
        
        const pool = await connectDB();
        const result = await pool.request()
            .input('MaTC', sql.NChar(10), MaTC)
            .execute('sp_XemLichSuTiem');
            
        console.log("✅ Tìm thấy:", result.recordset.length, "lần tiêm");
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy lịch sử tiêm:', error.message);
        res.status(500).json({ success: false, message: error.message });
    }
};

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

// 10. Thêm vaccine lẻ (không theo gói)
exports.themVaccineLe = async (req, res) => {
    try {
        const { MaPhieu, MaVaccine, NhacLai } = req.body;
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaVaccine', sql.NChar(10), MaVaccine)
            .input('NhacLai', sql.Date, NhacLai || null)
            .execute('sp_BacSi_ThemVaccineLe');
            
        res.json({ 
            success: true, 
            message: 'Đã thêm vaccine lẻ',
            data: result.recordset[0]
        });
    } catch (error) {
        console.error('❌ Lỗi thêm vaccine lẻ:', error.message);
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
            
        // Convert ThoiGian (Date) to a local datetime string to avoid UTC shift when
        // serialized to JSON (frontend will parse this as local time)
        const formatted = result.recordset.map(r => {
            const row = { ...r };
            if (row.ThoiGian) {
                const raw = row.ThoiGian;
                let d = null;

                // Handle different possible types returned by mssql driver
                if (raw instanceof Date) {
                    // MSSQL driver returned a Date object. In some setups the driver's
                    // Date represents the DB datetime as UTC, which causes a timezone
                    // shift when displayed. Treat the UTC components as the original
                    // wall-clock values stored in the DB.
                    const r = raw;
                    const y = r.getUTCFullYear();
                    const mo = r.getUTCMonth();
                    const day = r.getUTCDate();
                    const hh = r.getUTCHours();
                    const mm = r.getUTCMinutes();
                    const ss = r.getUTCSeconds();
                    const ms = r.getUTCMilliseconds();

                    // Build a Date using the local constructor with those components
                    // so the epoch corresponds to that wall-clock in the server's timezone.
                    d = new Date(y, mo, day, hh, mm, ss, ms);
                } else if (typeof raw === 'number') {
                    d = new Date(raw);
                } else if (typeof raw === 'string') {
                    // If it's already ISO-like, new Date() will handle it.
                    // If it's SQL style "YYYY-MM-DD hh:mm:ss[.fff]", replace first space with 'T'.
                    const s = raw.includes('T') ? raw : raw.replace(' ', 'T');
                    d = new Date(s);
                } else {
                    d = new Date(raw);
                }

                if (isNaN(d.getTime())) {
                    // Invalid date: preserve nulls for frontend clarity
                    row.ThoiGian = null;
                    row.ThoiGianDisplay = 'Invalid Date - Invalid Date';
                } else {
                    row.ThoiGian = d.getTime();
                    try {
                        const datePart = d.toLocaleDateString('vi-VN');
                        const timePart = d.toLocaleTimeString('vi-VN', { hour: '2-digit', minute: '2-digit' });
                        row.ThoiGianDisplay = `${timePart} - ${datePart}`;
                    } catch (e) {
                        row.ThoiGianDisplay = `${d.getHours().toString().padStart(2,'0')}:${d.getMinutes().toString().padStart(2,'0')} - ${d.getDate().toString().padStart(2,'0')}/${(d.getMonth()+1).toString().padStart(2,'0')}/${d.getFullYear()}`;
                    }
                }

                // Detailed per-item log to help debug timezone parsing issues
                console.log('➡️ Time parse - waiting-list item:', JSON.stringify({ MaPhieu: row.MaPhieu, typeOfRaw: Object.prototype.toString.call(raw), raw, epoch: row.ThoiGian, ThoiGianDisplay: row.ThoiGianDisplay }));
            }
            return row;
        });

        // Log the payload we will send so we can inspect what the frontend receives
        console.log('➡️ Payload - /api/doctor/waiting-list:', JSON.stringify(formatted, null, 2));

        res.json(formatted);
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
                    U.HoTen AS TenKhachHang, KH.SDT, KH.TongDiemTichLuy,
                    TC.Ten AS TenThuCung, TC.Loai AS LoaiThuCung, TC.Giong AS GiongThuCung, 
                    TC.NgSinh, TC.TinhTrangSucKhoe,
                    PKB.ChanDoan, PKB.NgayHenTaiKham
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
        
        // Lấy thông tin gói tiêm đã đăng ký (nếu có)
        const packageResult = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    DK.MaVaccine, 
                    MH.TenMatHang AS TenVaccine,
                    DK.MaGoi, 
                    G.TenGoi, 
                    G.SoMuiTuongUng, 
                    G.ThoiHan,
                    G.GiamGia,
                    DK.NgayHetHan, 
                    DK.HieuLuc, 
                    DK.ThanhTien
                FROM DANG_KI_GOI_TIEM DK
                JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
                JOIN MAT_HANG MH ON DK.MaVaccine = MH.MaMatHang
                WHERE DK.MaPhieu = @MaPhieu
            `);
        
        res.json({
            phieu: phieuResult.recordset[0],
            danhSachThuoc: thuocResult.recordset,
            danhSachVaccine: vaccineResult.recordset,
            goiTiem: packageResult.recordset.length > 0 ? packageResult.recordset[0] : null
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
        
        // Xác định LoaiMH: 'T' = Thuốc, 'V' = Vaccine
        const loaiMH = loai === 'Vaccine' ? 'V' : 'T';
        
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN)
            .input('TuKhoa', sql.NVarChar, tuKhoa || '')
            .input('LoaiMH', sql.VarChar(1), loaiMH)
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
                    TC.MaTC,
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

// Lấy danh sách thuốc và vaccine khả dụng (cho cả khám bệnh và xem danh sách)
exports.getAvailableMedicines = async (req, res) => {
    try {
        const maCN = req.user.MaCN || 'CN001';
        const pool = await connectDB();
        
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), maCN)
            .query(`
                SELECT 
                    MH.MaMatHang,
                    MH.TenMatHang,
                    MH.DonGia,
                    TK.SoLuongTon,
                    MH.LoaiMH,
                    -- Thông tin thuốc
                    T.TacDungPhu,
                    T.LoaiThuoc,
                    T.DangBaoChe,
                    -- Thông tin vaccine
                    VC.ChongChiDinh
                FROM MAT_HANG MH
                JOIN TON_KHO TK ON MH.MaMatHang = TK.MaMatHang
                LEFT JOIN THUOC T ON MH.MaMatHang = T.MaThuoc AND MH.LoaiMH = 'T'
                LEFT JOIN VACCINE VC ON MH.MaMatHang = VC.MaVaccine AND MH.LoaiMH = 'VC'
                WHERE TK.MaCN = @MaCN 
                  AND (MH.LoaiMH = 'T' OR MH.LoaiMH = 'VC')
                  AND TK.SoLuongTon > 0
                ORDER BY 
                    CASE MH.LoaiMH 
                        WHEN 'T' THEN 1 
                        WHEN 'VC' THEN 2 
                    END,
                    MH.TenMatHang
            `);
        
        console.log('💊 Danh sách thuốc & vaccine:', result.recordset.length, 'items');
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy danh sách thuốc & vaccine:', error.message);
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
                -- Lấy lịch sử khám bệnh THẬT từ PHIEU_KHAM_BENH
                SELECT 
                    P.MaPhieu,
                    P.TG_LapPhieu,
                    P.TG_ThucHienDV,
                    P.TrangThai,
                    PKB.ChanDoan,
                    PKB.NgayHenTaiKham,
                    U.HoTen AS BacSi
                FROM PHIEU_KHAM_BENH PKB_CURRENT
                JOIN PHIEU_KHAM_BENH PKB ON PKB.MaTC = PKB_CURRENT.MaTC
                JOIN PHIEU_DICH_VU P ON PKB.MaPhieu = P.MaPhieu
                LEFT JOIN [USER] U ON P.MaNV = U.MaUser
                WHERE PKB_CURRENT.MaPhieu = @MaPhieu
                  AND PKB.MaPhieu != @MaPhieu
                  AND P.TrangThai IN ('DHT', 'HT')
                ORDER BY P.TG_ThucHienDV DESC
            `);
            
        res.json(result.recordset);
    } catch (error) {
        console.error('❌ Lỗi lấy lịch sử khám:', error.message);
        res.status(500).json({ message: error.message });
    }
};
// ==================== XUẤT HÓA ĐƠN ====================

// Xuất hóa đơn trực tiếp (Sau khi hoàn tất dịch vụ)
exports.exportInvoice = async (req, res) => {
    try {
        const { MaPhieu, DiemMuonDung = 0, PhuongThucTT = 'Tiền mặt' } = req.body;
        
        if (!MaPhieu) {
            return res.status(400).json({ success: false, message: 'Thiếu mã phiếu!' });
        }

        console.log("💳 Bác sĩ xuất hóa đơn:", { MaPhieu, DiemMuonDung, PhuongThucTT });
        
        const pool = await connectDB();
        
        // Lấy thông tin khách hàng và điểm hiện có
        const customerInfo = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .query(`
                SELECT P.MaKH, KH.TongDiemTichLuy AS DiemHienCo
                FROM PHIEU_DICH_VU P
                JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
                WHERE P.MaPhieu = @MaPhieu
            `);
        
        if (customerInfo.recordset.length === 0) {
            return res.status(404).json({ success: false, message: 'Không tìm thấy thông tin khách hàng!' });
        }

        const DiemHienCoBanDau = customerInfo.recordset[0].DiemHienCo || 0;
        
        // Gọi SP xuất hóa đơn
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('DiemMuonDung', sql.Int, DiemMuonDung)
            .input('PhuongThucTT', sql.NVarChar(50), PhuongThucTT)
            .execute('sp_XuatHoaDonTrucTiep');
        
        const invoice = result.recordset[0];
        
        res.json({
            success: true,
            message: 'Xuất hóa đơn thành công!',
            invoice: {
                ...invoice,
                DiemHienCoBanDau // Trả về điểm ban đầu để frontend biết
            }
        });
        
    } catch (error) {
        console.error('❌ Lỗi xuất hóa đơn:', error.message);
        res.status(500).json({ 
            success: false, 
            message: 'Lỗi xuất hóa đơn: ' + error.message 
        });
    }
};