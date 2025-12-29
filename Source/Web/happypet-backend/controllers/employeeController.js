const { sql } = require('../config/db');

exports.getAppointments = async (req, res) => {
    try {
        // 1. Lấy thông tin từ token (phải đảm bảo middleware verifyToken đã chạy)
        // Dựa vào log của bà, biến này phải là req.user.MaUser
        const MaUser_HienTai = req.user.MaUser; 
        const Role_HienTai = req.user.Role;
        const MaCN_HienTai = req.user.MaCN || 'CN01'; 

        const { tuNgay, denNgay, status } = req.query;

        // Log để bà kiểm tra trong terminal xem có đúng không
        console.log("-----------------------------------------");
        console.log("👤 Đang xử lý cho User:", MaUser_HienTai);
        console.log("🛡️ Role:", Role_HienTai);
        console.log("🏢 Chi nhánh:", MaCN_HienTai);
        console.log("📅 Từ ngày:", tuNgay, "đến:", denNgay);
        console.log("📊 Trạng thái:", status);
        console.log("-----------------------------------------");

        const pool = await sql.connect();
        const request = pool.request();
        
        // 2. Gán các tham số cho Stored Procedure
        request.input('MaCN', sql.NChar(10), MaCN_HienTai);
        request.input('TuNgay', sql.Date, tuNgay);
        request.input('DenNgay', sql.Date, denNgay);
        request.input('TrangThai', sql.VarChar(5), status === 'ALL' ? null : status);

        // 🔥 SỬA LỖI TẠI ĐÂY: Truyền đúng biến đã khai báo ở trên
        
        // Sửa MaUser thành req.user.MaUser
        request.input('MaNV_Xem', sql.NChar(10), req.user.MaUser);
        request.input('Role_Xem', sql.NVarChar(50), Role_HienTai);      

        console.log("🔍 Calling SP with params:", {
            MaCN: MaCN_HienTai,
            TuNgay: tuNgay,
            DenNgay: denNgay,
            TrangThai: status === 'ALL' ? null : status,
            MaNV_Xem: req.user.MaUser,
            Role_Xem: Role_HienTai
        });

        const result = await request.execute('sp_LayDanhSachDatLich');
        
        console.log("✅ SP trả về:", result.recordset.length, "records");
        if (result.recordset.length > 0) {
            console.log("📋 Sample record:", JSON.stringify(result.recordset[0], null, 2));
        } else {
            console.log("❌ KHÔNG CÓ DỮ LIỆU! Kiểm tra:");
            console.log("   - Chi nhánh có đúng không?");
            console.log("   - Ngày có phù hợp không?");
            console.log("   - Role có quyền xem không?");
        }
        
        res.json(result.recordset);

    } catch (err) {
        // Log lỗi chi tiết để bà nhìn thấy trong terminal
        console.error("❌ Lỗi Backend:", err.message);
        console.error("❌ Chi tiết:", err);
        res.status(500).json({ message: 'Lỗi server: ' + err.message });
    }
};

exports.checkIn = async (req, res) => {
    try {
        // Frontend gửi lên: Mã Phiếu + Mã Bác Sĩ (lấy từ cái dropdown chọn lúc nãy)
        const { MaPhieu, MaBacSi } = req.body; 
        const MaNV_TiepTan = req.user.MaUser; 

        if (!MaBacSi) {
            return res.status(400).json({ message: 'Chưa chọn bác sĩ phụ trách!' });
        }

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaNV_TiepTan', sql.NChar(10), MaNV_TiepTan)
            .input('MaBacSiChiDinh', sql.NChar(10), MaBacSi) // 🔥 Truyền cái này vào SP mới chịu nha
            .execute('sp_CheckInKhachHang');

        res.json({ success: true, message: 'Check-in thành công! Đã chuyển khách cho BS.' });
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 3. Tạo phiếu trực tiếp (Sử dụng sp_TaoPhieuTrucTiep bà gửi)
exports.createWalkInTicket = async (req, res) => {
    try {
        const { MaKH, MaTC, LoaiPhieu, TrieuChung } = req.body;
        const maCN = req.user.MaCN;
        const maNV = req.user.MaUser; // Nhân viên đang đăng nhập

        const pool = await connectDB();
        await pool.request()
            .input('MaKH', sql.NChar(10), MaKH)
            .input('MaTC', sql.NChar(10), MaTC) // Có thể null nếu mua hàng
            .input('MaCN', sql.NChar(10), maCN)
            .input('MaNV', sql.NChar(10), maNV)
            .input('LoaiPhieu', sql.VarChar(2), LoaiPhieu)
            .input('TrieuChung', sql.NVarChar(200), TrieuChung)
            .execute('sp_TaoPhieuTrucTiep'); //
        
        res.json({ success: true, message: 'Đã tạo phiếu thành công!' });
    } catch (err) { res.status(500).json({ message: err.message }); }
};

exports.getDoctorsStatus = async (req, res) => {
    try {
        const { MaCN } = req.user; // Lấy từ token của Tiếp tân
        
        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .execute('sp_LayDanhSachBacSi_TrangThai');

        res.json(result.recordset);
    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// Tìm kiếm khách hàng theo SĐT
exports.searchCustomerByPhone = async (req, res) => {
    try {
        const { sdt } = req.query;
        
        if (!sdt) {
            return res.status(400).json({ message: 'Vui lòng nhập số điện thoại!' });
        }

        const pool = await sql.connect();
        const result = await pool.request()
            .input('SDT', sql.VarChar(15), sdt)
            .execute('sp_TimKiemKhachHangTheoSDT');

        // SP trả về 3 recordsets: [0]=customer info, [1]=pets, [2]=history
        const customer = result.recordsets[0][0];
        const pets = result.recordsets[1];
        const history = result.recordsets[2];

        res.json({
            found: !!customer.MaKH, // true nếu tìm thấy
            customer: customer.MaKH ? customer : null,
            pets: customer.MaKH ? pets : [],
            history: customer.MaKH ? history : []
        });
    } catch (err) {
        console.error('Error searching customer:', err);
        res.status(500).json({ message: err.message });
    }
};

// controllers/employeeController.js

exports.createDirectAppointment = async (req, res) => {
    try {
        const { MaKH, MaTC, LoaiPhieu, TrieuChung } = req.body;
        const { MaCN, MaUser } = req.user; // Lấy từ token nhân viên đang đăng nhập

        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaKH', sql.NChar(10), MaKH)
            .input('MaTC', sql.NChar(10), MaTC || null)
            .input('MaCN', sql.NChar(10), MaCN)
            .input('MaNV', sql.NChar(10), MaUser)
            .input('LoaiPhieu', sql.VarChar(2), LoaiPhieu)
            .input('TrieuChung', sql.NVarChar(200), TrieuChung || null)
            .execute('sp_TaoPhieuTrucTiep');

        res.json({
            success: true,
            message: 'Tạo phiếu thành công!',
            maPhieu: result.recordset[0].MaPhieuMoi
        });
    } catch (err) {
        console.error(err);
        res.status(500).json({ message: err.message });
    }
};

// XÁC NHẬN ĐÃ GIAO HÀNG (Chỉ được nhấn đúng ngày nhận)
exports.confirmDelivery = async (req, res) => {
    try {
        const { MaPhieu } = req.body;
        const MaNV = req.user.MaUser;

        if (!MaPhieu) return res.status(400).json({ message: 'Thiếu mã phiếu!' });

        const pool = await sql.connect();

        // Check xem hôm nay có phải ngày nhận không
        const checkDate = await pool.request()
            .input('MP', sql.NChar(10), MaPhieu)
            .query(`
                SELECT TG_ThucHienDV, TrangThai 
                FROM PHIEU_DICH_VU 
                WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP))
            `);

        if (checkDate.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy phiếu!' });
        }

        const { TG_ThucHienDV, TrangThai } = checkDate.recordset[0];
        
        if (TrangThai !== 'DTH') {
            return res.status(400).json({ message: 'Phiếu không ở trạng thái đang giao!' });
        }

        // Check ngày
        const ngayNhan = new Date(TG_ThucHienDV);
        const homNay = new Date();
        ngayNhan.setHours(0, 0, 0, 0);
        homNay.setHours(0, 0, 0, 0);

        if (ngayNhan.getTime() > homNay.getTime()) {
            return res.status(400).json({ 
                message: `Chưa đến ngày giao! Ngày nhận: ${ngayNhan.toLocaleDateString('vi-VN')}` 
            });
        }

        // UPDATE trạng thái DHT - KHÔNG UPDATE TG_ThucHienDV vì đó là ngày muốn nhận
        await pool.request()
            .input('MP', sql.NChar(10), MaPhieu)
            .query(`
                UPDATE PHIEU_DICH_VU
                SET TrangThai = 'DHT'
                WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP))
            `);

        res.json({ success: true, message: 'Đã xác nhận giao hàng thành công!' });

    } catch (err) {
        console.error("❌ Lỗi xác nhận giao:", err);
        res.status(500).json({ message: err.message });
    }
};

// 🔥 API TỰ ĐỘNG HỦY LỊCH HẸN QUÁ 120 PHÚT
exports.autoHuyLichHen = async (req, res) => {
    try {
        const pool = await sql.connect();
        const result = await pool.request().execute('sp_TuDongHuyLichHen');
        
        const soPhieuHuy = result.recordset[0]?.SoPhieuDaHuyTuDong || 0;
        
        res.json({ 
            success: true, 
            message: `Đã tự động hủy ${soPhieuHuy} lịch hẹn quá hạn`,
            soPhieuHuy 
        });
    } catch (error) {
        console.error('Lỗi tự động hủy lịch hẹn:', error);
        res.status(500).json({ 
            success: false,
            message: 'Lỗi khi tự động hủy lịch hẹn', 
            error: error.message 
        });
    }
};

// Lấy chi tiết sản phẩm trong đơn hàng
exports.getOrderDetail = async (req, res) => {
    try {
        const { maPhieu } = req.params;
        
        console.log("📦 Lấy chi tiết đơn hàng:", maPhieu);
        
        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .query(`
                SELECT 
                    MH.MaMatHang,
                    MH.TenMatHang,
                    MH.DonGia AS Gia,
                    CT.SoLuong,
                    (MH.DonGia * CT.SoLuong) AS ThanhTien
                FROM CT_MUA_HANG CT
                JOIN MAT_HANG MH ON CT.MaMatHang = MH.MaMatHang
                WHERE CT.MaPhieu = @MaPhieu
            `);
            
        console.log("✅ Tìm thấy:", result.recordset.length, "sản phẩm");
        res.json(result.recordset);
        
    } catch (error) {
        console.error('❌ Lỗi lấy chi tiết đơn:', error);
        res.status(500).json({ message: 'Lỗi lấy chi tiết đơn hàng', error: error.message });
    }
};