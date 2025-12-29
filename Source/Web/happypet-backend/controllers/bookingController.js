const { sql } = require('../config/db');

// 1. API TRA CỨU LỊCH BÁC SĨ (MỚI)
exports.getDoctorSchedule = async (req, res) => {
    try {
        const { MaCN } = req.query; // Có thể nhận tham số MaCN từ frontend
        const pool = await sql.connect();
        
        const request = pool.request();
        if (MaCN) request.input('MaCN', sql.NChar(10), MaCN);
        
        const result = await request.execute('sp_XemLichBacSi');
        res.json(result.recordset);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// 1. Lấy danh sách chi nhánh
// exports.getBranches = async (req, res) => {
//     try {
//         const pool = await sql.connect();
//         const result = await pool.request().query('SELECT * FROM CHI_NHANH');
//         res.json(result.recordset);
//     } catch (error) {
//         res.status(500).json({ message: error.message });
//     }
// };

// 1. LẤY DANH SÁCH CHI NHÁNH (Gọi SP: sp_XemDanhSachChiNhanh)
// 1. LẤY DANH SÁCH CHI NHÁNH (CHUẨN)
exports.getBranches = async (req, res) => {
    try {
        const pool = await sql.connect();
        
        // 🔥 QUAN TRỌNG: Gọi SP này để lấy cột 'DichVuHoTro' và giờ đã format đẹp '09:00'
        const result = await pool.request().execute('sp_XemDanhSachChiNhanh'); 
        
        console.log("DATA BACKEND GỬI VỀ:", result.recordset); // Tui thêm dòng này để bà check terminal xem nó có dữ liệu chưa
        res.json(result.recordset);
    } catch (error) {
        console.error("Lỗi lấy chi nhánh:", error);
        res.status(500).json({ message: error.message });
    }
};

// 2. TẠO LỊCH HẸN (GIỮ NGUYÊN - Chỉ update logic bắt lỗi từ SP mới)
exports.createAppointment = async (req, res) => {
    try {
        let MaKH = req.user.MaUser; 
        let { MaTC, MaCN, LoaiPhieu, NgayHen, GioHen, TrieuChung } = req.body;

        MaKH = MaKH ? MaKH.toString().trim() : '';
        
        if (!MaKH) return res.status(401).json({ message: "Lỗi Token" });

        const pool = await sql.connect();
        const request = pool.request();

        request.input('MaKH', sql.VarChar(20), MaKH);
        request.input('MaTC', sql.VarChar(20), MaTC);
        request.input('MaCN', sql.VarChar(20), MaCN);
        request.input('LoaiPhieu', sql.VarChar(10), LoaiPhieu);
        request.input('NgayHen', sql.Date, NgayHen);
        
        // Input giờ từ Frontend gửi xuống dạng "08:30" là chuẩn rồi
        request.input('GioHen', sql.VarChar(10), GioHen);
        request.input('TrieuChung', sql.NVarChar(200), TrieuChung || null);

        const result = await request.execute('sp_DatLichHen');
        
        res.status(201).json({ 
            message: 'Tạo lịch hẹn thành công!', 
            MaPhieu: result.recordset[0].MaPhieuMoi 
        });

    } catch (error) {
        console.error("❌ Lỗi đặt lịch:", error.message);
        // SP mới của bà sẽ quăng lỗi (RAISERROR). Frontend sẽ hứng cái message này để hiện lên.
        res.status(400).json({ message: error.message }); 
    }
};
// 3. Lấy dữ liệu Vaccine và Gói (Master Data)
exports.getVaccineData = async (req, res) => {
    try {
        const pool = await sql.connect();
        
        // 1. Lấy Vaccine (Bỏ cột MoTa vì DB không có)
        const vaccines = await pool.request().query(`
            SELECT V.MaVaccine, MH.TenMatHang as TenVaccine, V.DonGia 
            FROM VACCINE V
            JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang
        `);

        // 2. Lấy danh sách Gói
        const packages = await pool.request().query(`
            SELECT * FROM GOI_TIEM_VC
        `);

        res.json({
            vaccines: vaccines.recordset,
            packages: packages.recordset
        });
    } catch (error) {
        console.error("❌ Lỗi lấy data vaccine:", error.message);
        res.status(500).json({ message: "Lỗi hệ thống: " + error.message });
    }
};

// 4. Lấy danh sách đã chọn trong phiếu (Giỏ hàng)
exports.getSelectedVaccines = async (req, res) => {
    try {
        const { id } = req.params; // MaPhieu
        const pool = await sql.connect();

        const selected = await pool.request()
            .input('MaPhieu', sql.VarChar(20), id)
            .query(`
                SELECT CT.MaVaccine, MH.TenMatHang as TenVaccine, CT.ThanhTien, CT.NhacLai,
                       DK.MaGoi, G.TenGoi
                FROM CT_TIEM_VC CT
                JOIN MAT_HANG MH ON CT.MaVaccine = MH.MaMatHang 
                LEFT JOIN DANG_KI_GOI_TIEM DK ON CT.MaPhieu = DK.MaPhieu AND CT.MaVaccine = DK.MaVaccine
                LEFT JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
                WHERE CT.MaPhieu = @MaPhieu
            `);

        res.json(selected.recordset);
    } catch (error) {
        res.status(500).json({ message: error.message });
    }
};

// // ============================================================
// // CÁC HÀM XỬ LÝ THÊM/XÓA (ĐÃ FIX TOÀN BỘ THÀNH MaUser)
// // ============================================================

// 5. Thêm Vaccine Lẻ
exports.addSingleVaccine = async (req, res) => {
    try {
        // 🔥 FIX: Dùng MaUser
        const MaKH = req.user.MaUser ? req.user.MaUser.trim() : ''; 
        const { MaPhieu, MaVaccine, TheoGoi } = req.body;

        console.log(`➕ Thêm Vaccine Lẻ: User=${MaKH}, Phieu=${MaPhieu}, Vaccine=${MaVaccine}`);

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.VarChar(20), MaPhieu)
            .input('MaKH', sql.VarChar(20), MaKH) // Gửi đúng MaUser xuống
            .input('MaVaccine', sql.VarChar(20), MaVaccine)
            .input('TheoGoi', sql.Bit, TheoGoi || 0)
            .execute('sp_App_ChonVaccineLe');

        res.json({ message: 'Đã thêm vaccine thành công!' });
    } catch (error) {
        console.error("❌ Lỗi thêm vaccine:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// 6. Thêm Gói Vaccine
exports.addPackageVaccine = async (req, res) => {
    try {
        // 🔥 FIX: Dùng MaUser
        const MaKH = req.user.MaUser ? req.user.MaUser.trim() : ''; 
        const { MaPhieu, MaVaccine, MaGoi } = req.body;

        console.log(`📦 Thêm Gói: User=${MaKH}, Gói=${MaGoi} cho Vaccine=${MaVaccine}`);

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.VarChar(20), MaPhieu)
            .input('MaKH', sql.VarChar(20), MaKH)
            .input('MaVaccine', sql.VarChar(20), MaVaccine)
            .input('MaGoi', sql.VarChar(20), MaGoi)
            .execute('sp_App_ChonGoiTiem');

        res.json({ message: 'Đã đăng ký gói thành công!' });
    } catch (error) {
        console.error("❌ Lỗi thêm gói:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// 7. Xóa Vaccine Lẻ
exports.removeSingleVaccine = async (req, res) => {
    try {
        // 🔥 FIX: Dùng MaUser
        const MaKH = req.user.MaUser ? req.user.MaUser.trim() : '';
        const { MaPhieu, MaVaccine } = req.body;

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.VarChar(20), MaPhieu)
            .input('MaKH', sql.VarChar(20), MaKH)
            .input('MaVaccine', sql.VarChar(20), MaVaccine)
            .execute('sp_App_XoaVaccineLe');

        res.json({ message: 'Đã xóa vaccine!' });
    } catch (error) {
        console.error("❌ Lỗi xóa vaccine:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// 8. Xóa Gói Vaccine
exports.removePackageVaccine = async (req, res) => {
    try {
        // 🔥 FIX: Dùng MaUser
        const MaKH = req.user.MaUser ? req.user.MaUser.trim() : '';
        const { MaPhieu, MaVaccine, MaGoi } = req.body;

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.VarChar(20), MaPhieu)
            .input('MaKH', sql.VarChar(20), MaKH)
            .input('MaVaccine', sql.VarChar(20), MaVaccine)
            .input('MaGoi', sql.VarChar(20), MaGoi)
            .execute('sp_App_XoaGoiTiem');

        res.json({ message: 'Đã hủy gói vaccine!' });
    } catch (error) {
        console.error("❌ Lỗi xóa gói:", error.message);
        res.status(400).json({ message: error.message });
    }
};

// ============================================================
// 9. LẤY LỊCH SỬ ĐẶT (MY BOOKINGS)
// ============================================================
// server/controllers/bookingController.js

// 9. LẤY LỊCH SỬ ĐẶT (MY BOOKINGS)
exports.getMyBookings = async (req, res) => {
    try {
        const MaUser = req.user.MaUser; // Lấy từ Token
        const pool = await sql.connect();
        
        // 🔥 GỌI ĐÚNG CÁI SP BÀ VỪA GỬI NÈ
        const result = await pool.request()
            .input('MaKH', sql.NChar(10), MaUser)
            .execute('sp_XemLichSuHoatDong'); 

        res.json(result.recordset);
    } catch (err) {
        console.error("Lỗi lấy lịch sử:", err);
        res.status(500).json({ message: 'Lỗi lấy dữ liệu lịch sử' });
    }
};

// ============================================================
// 10. HỦY LỊCH HẸN
// ============================================================
exports.cancelBooking = async (req, res) => {
    const { id } = req.params; // MaPhieu gửi trên URL
    const MaUser = req.user.MaUser; 

    try {
        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.NChar(10), id)
            .input('MaKH', sql.NChar(10), MaUser)
            .execute('sp_HuyLichHen'); // Gọi SP mới sửa check 2 tiếng

        res.json({ message: 'Đã hủy lịch hẹn thành công!' });

    } catch (err) {
        console.error("Lỗi hủy hẹn:", err);
        // Lỗi 2 tiếng hay lỗi trạng thái sẽ được trả về ở đây
        res.status(400).json({ message: err.message || 'Không thể hủy lịch hẹn này.' });
    }
};