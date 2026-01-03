const { sql, connectDB } = require('../config/db');

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

        if (!MaBacSi) {
            return res.status(400).json({ message: 'Chưa chọn bác sĩ phụ trách!' });
        }

        const pool = await sql.connect();
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaNV_PhuTrach', sql.NChar(10), MaBacSi) // SP chỉ cần 2 tham số: MaPhieu và MaNV_PhuTrach
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
            .execute('sp_TaoPhieuTrucTiep');
        
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

// 🔥 MỚI: Lấy danh sách phiếu có ngày hẹn tái khám
exports.getRecheckAppointments = async (req, res) => {
    try {
        const { MaCN } = req.user;
        const { tuNgay, denNgay } = req.query;
        
        console.log("🔔 Lấy danh sách tái khám - Chi nhánh:", MaCN);
        
        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaCN', sql.NChar(10), MaCN)
            .input('TuNgay', sql.Date, tuNgay)
            .input('DenNgay', sql.Date, denNgay)
            .query(`
                SELECT 
                    P.MaPhieu,
                    P.TG_LapPhieu,
                    P.TG_ThucHienDV,
                    U.HoTen AS TenKhachHang,
                    KH.SDT,
                    TC.Ten AS TenThuCung,
                    PKB.ChanDoan,
                    PKB.NgayHenTaiKham,
                    DATEDIFF(DAY, GETDATE(), PKB.NgayHenTaiKham) AS SoNgayConLai
                FROM PHIEU_DICH_VU P
                JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
                JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
                JOIN [USER] U ON KH.MaKH = U.MaUser
                LEFT JOIN THU_CUNG TC ON PKB.MaTC = TC.MaTC
                WHERE P.MaCN = @MaCN
                  AND P.TrangThai IN ('DHT', 'HT')
                  AND PKB.NgayHenTaiKham IS NOT NULL
                  AND PKB.NgayHenTaiKham BETWEEN @TuNgay AND @DenNgay
                ORDER BY PKB.NgayHenTaiKham ASC
            `);
            
        console.log("✅ Tìm thấy:", result.recordset.length, "lịch tái khám");
        res.json(result.recordset);
        
    } catch (error) {
        console.error('❌ Lỗi lấy danh sách tái khám:', error);
        res.status(500).json({ message: 'Lỗi lấy danh sách tái khám', error: error.message });
    }
};

// 🔥 MỚI: Xuất hóa đơn trực tiếp (Sau khi hoàn tất dịch vụ)
exports.exportInvoice = async (req, res) => {
    try {
        const { MaPhieu, DiemMuonDung = 0, PhuongThucTT = 'Tiền mặt' } = req.body;
        
        if (!MaPhieu) {
            return res.status(400).json({ message: 'Thiếu mã phiếu!' });
        }

        // 🔥 LẤY MÃ NHÂN VIÊN TIẾP TÁN TỪ TOKEN
        const MaNV_XuatHD = req.user.MaUser;

        console.log("💳 Xuất hóa đơn:", { MaPhieu, DiemMuonDung, PhuongThucTT, MaNV_XuatHD });
        
        const pool = await sql.connect();
        
        // Lấy điểm hiện có của khách hàng trước
        const ticketInfo = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .query('SELECT MaKH FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu');
        
        if (ticketInfo.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy phiếu!' });
        }
        
        const maKH = ticketInfo.recordset[0].MaKH;
        
        const customerInfo = await pool.request()
            .input('MaKH', sql.NChar(10), maKH)
            .query('SELECT ISNULL(TongDiemTichLuy, 0) AS DiemHienCo FROM KHACH_HANG WHERE MaKH = @MaKH');
        
        const diemHienCo = customerInfo.recordset[0]?.DiemHienCo || 0;
        
        const result = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('DiemMuonDung', sql.Int, DiemMuonDung)
            .input('PhuongThucTT', sql.NVarChar(50), PhuongThucTT)
            .input('MaNV_XuatHD', sql.NChar(10), MaNV_XuatHD) // 🔥 TRUYỀN MÃ NHÂN VIÊN
            .execute('sp_XuatHoaDonTrucTiep');
        
        // SP trả về thông tin hóa đơn với format đã format sẵn
        const invoiceData = result.recordset[0];
        
        console.log("✅ Xuất hóa đơn thành công:", invoiceData);
        
        res.json({
            success: true,
            message: 'Xuất hóa đơn thành công!',
            invoice: {
                ...invoiceData,
                DiemHienCoBanDau: diemHienCo
            }
        });
        
    } catch (error) {
        console.error('❌ Lỗi xuất hóa đơn:', error);
        res.status(500).json({ 
            success: false,
            message: 'Lỗi xuất hóa đơn: ' + error.message 
        });
    }
};

// 🔥 TẠO PHIẾU VÃNG LAI VỚI THÔNG TIN ĐẦY ĐỦ
exports.createWalkInWithFullInfo = async (req, res) => {
    try {
        const { 
            SDT, HoTen, GioiTinhUser, DiaChi,  // Thông tin khách hàng
            TenTC, Loai, Giong, GioiTinh, NgSinh, TinhTrangSucKhoe,  // Thông tin thú cưng
            LoaiPhieu, TrieuChung  // Thông tin phiếu
        } = req.body;
        
        const { MaCN, MaUser } = req.user;
        const pool = await connectDB();
        
        // Gọi SP tạo phiếu vãng lai với thông tin đầy đủ
        const result = await pool.request()
            .input('SDT', sql.NVarChar(15), SDT)
            .input('HoTen', sql.NVarChar(50), HoTen)
            .input('GioiTinhUser', sql.NVarChar(3), GioiTinhUser || 'Nam')
            .input('DiaChi', sql.NVarChar(100), DiaChi || '')
            .input('TenTC', sql.NVarChar(50), TenTC)
            .input('Loai', sql.NVarChar(30), Loai)
            .input('Giong', sql.NVarChar(30), Giong || 'Chưa rõ')
            .input('GioiTinh', sql.NVarChar(3), GioiTinh || 'Đực')
            .input('NgSinh', sql.Date, NgSinh ? new Date(NgSinh) : null)
            .input('TinhTrangSucKhoe', sql.NVarChar(50), TinhTrangSucKhoe || 'Bình thường')
            .input('MaCN', sql.NChar(10), MaCN)
            .input('MaNV', sql.NChar(10), MaUser)
            .input('LoaiPhieu', sql.VarChar(2), LoaiPhieu)
            .input('TrieuChung', sql.NVarChar(200), TrieuChung || '')
            .execute('sp_TaoPhieuVangLai_Full');
            
        res.json({
            success: true,
            message: 'Đã tạo phiếu vãng lai!',
            data: result.recordset[0]
        });
    } catch (error) {
        console.error('❌ Lỗi tạo phiếu vãng lai:', error);
        res.status(500).json({
            success: false,
            message: error.message
        });
    }
};

// 🔥 ĐĂNG KÝ KHÁCH HÀNG ĐƠN GIẢN (CHO BÁN HÀNG TRỰC TIẾP)
exports.createCustomerSimple = async (req, res) => {
    try {
        const { HoTen, SDT, GioiTinh = 'Nam', DiaChi = '' } = req.body;
        
        if (!HoTen || !SDT) {
            return res.status(400).json({ message: 'Thiếu thông tin bắt buộc (Họ tên, SĐT)!' });
        }
        
        console.log("📝 Đăng ký khách hàng mới:", { HoTen, SDT, GioiTinh });
        
        const pool = await sql.connect();
        
        // Kiểm tra SĐT đã tồn tại chưa
        const checkSDT = await pool.request()
            .input('SDT', sql.VarChar(15), SDT)
            .query(`
                SELECT U.MaUser, U.HoTen 
                FROM [USER] U 
                JOIN KHACH_HANG KH ON U.MaUser = KH.MaKH
                WHERE U.SDT = @SDT
            `);
        
        if (checkSDT.recordset.length > 0) {
            return res.status(400).json({ 
                message: 'Số điện thoại này đã được đăng ký!',
                existing: checkSDT.recordset[0]
            });
        }
        
        // Tạo MaKH tự động
        const nextKH = await pool.request().query(`
            SELECT 'KH' + RIGHT('00000' + CAST(ISNULL(MAX(CAST(SUBSTRING(MaKH, 3, 5) AS INT)), 0) + 1 AS VARCHAR), 5) AS MaKH_Moi
            FROM KHACH_HANG
        `);
        
        const MaKH_Moi = nextKH.recordset[0].MaKH_Moi;
        
        // INSERT vào USER
        await pool.request()
            .input('MaUser', sql.NChar(10), MaKH_Moi)
            .input('HoTen', sql.NVarChar(50), HoTen)
            .input('SDT', sql.VarChar(15), SDT)
            .input('GioiTinh', sql.NVarChar(3), GioiTinh)
            .input('DiaChi', sql.NVarChar(100), DiaChi)
            .query(`
                INSERT INTO [USER] (MaUser, HoTen, SDT, GioiTinh, DiaChi, Role)
                VALUES (@MaUser, @HoTen, @SDT, @GioiTinh, @DiaChi, N'Khách hàng')
            `);
        
        // INSERT vào KHACH_HANG
        await pool.request()
            .input('MaKH', sql.NChar(10), MaKH_Moi)
            .query(`
                INSERT INTO KHACH_HANG (MaKH, TongDiemTichLuy, HangThanhVien)
                VALUES (@MaKH, 0, 'Đồng')
            `);
        
        console.log("✅ Đăng ký thành công:", MaKH_Moi);
        
        res.json({
            success: true,
            message: 'Đăng ký khách hàng thành công!',
            customer: {
                MaKH: MaKH_Moi,
                HoTen,
                SDT,
                GioiTinh,
                DiaChi,
                TongDiemTichLuy: 0,
                HangThanhVien: 'Đồng'
            }
        });
        
    } catch (error) {
        console.error('❌ Lỗi đăng ký khách hàng:', error);
        res.status(500).json({ 
            success: false,
            message: 'Lỗi đăng ký khách hàng: ' + error.message 
        });
    }
};

// 🔥 LẤY DANH SÁCH SẢN PHẨM (CHO BÁN HÀNG TRỰC TIẾP)
exports.getProducts = async (req, res) => {
    try {
        const { MaCN } = req.user;
        const { tuKhoa, loaiMH } = req.query;
        
        console.log("🛒 Lấy danh sách sản phẩm - Chi nhánh:", MaCN);
        
        const pool = await sql.connect();
        
        let query = `
            SELECT 
                MH.MaMatHang,
                MH.TenMatHang,
                MH.DonGia,
                MH.LoaiMH,
                ISNULL(TON.SoLuongTon, 0) AS SoLuongTon
            FROM MAT_HANG MH
            LEFT JOIN TON_KHO TON ON MH.MaMatHang = TON.MaMatHang AND TON.MaCN = @MaCN
            WHERE ISNULL(TON.SoLuongTon, 0) > 0
        `;
        
        const request = pool.request()
            .input('MaCN', sql.NChar(10), MaCN);
        
        if (tuKhoa) {
            query += " AND MH.TenMatHang LIKE '%' + @TuKhoa + '%'";
            request.input('TuKhoa', sql.NVarChar(100), tuKhoa);
        }
        
        if (loaiMH) {
            query += " AND MH.LoaiMH = @LoaiMH";
            request.input('LoaiMH', sql.VarChar(10), loaiMH);
        }
        
        query += " ORDER BY MH.TenMatHang";
        
        const result = await request.query(query);
        
        console.log("✅ Tìm thấy:", result.recordset.length, "sản phẩm");
        res.json(result.recordset);
        
    } catch (error) {
        console.error('❌ Lỗi lấy danh sách sản phẩm:', error);
        res.status(500).json({ 
            success: false,
            message: 'Lỗi lấy danh sách sản phẩm: ' + error.message 
        });
    }
};

// 🔥 BÁN HÀNG TRỰC TIẾP (KHÔNG CẦN THÚ CƯNG)
exports.directSale = async (req, res) => {
    try {
        const { 
            MaKH, 
            sanPham,  // Array: [{ MaMatHang, SoLuong }]
            DiemMuonDung = 0,
            PhuongThucTT = 'Tiền mặt'
        } = req.body;
        
        if (!MaKH || !sanPham || sanPham.length === 0) {
            return res.status(400).json({ message: 'Thiếu thông tin đơn hàng!' });
        }
        
        const { MaCN, MaUser } = req.user;
        
        console.log("💰 Xử lý bán hàng trực tiếp:", { MaKH, SoSP: sanPham.length, DiemMuonDung });
        
        const pool = await sql.connect();
        
        // Kiểm tra điểm tích lũy của khách
        const customerInfo = await pool.request()
            .input('MaKH', sql.NChar(10), MaKH)
            .query('SELECT ISNULL(TongDiemTichLuy, 0) AS DiemHienCo FROM KHACH_HANG WHERE MaKH = @MaKH');
        
        if (customerInfo.recordset.length === 0) {
            return res.status(404).json({ message: 'Không tìm thấy khách hàng!' });
        }
        
        const diemHienCo = customerInfo.recordset[0].DiemHienCo;
        
        if (DiemMuonDung > diemHienCo) {
            return res.status(400).json({ 
                message: `Khách chỉ có ${diemHienCo} điểm, không thể dùng ${DiemMuonDung} điểm!` 
            });
        }
        
        // Bước 1: Tạo phiếu MH (Mua hàng) bằng sp_TaoPhieuTrucTiep
        const createTicket = await pool.request()
            .input('MaKH', sql.NChar(10), MaKH)
            .input('MaTC', sql.NChar(10), null)  // NULL vì không cần thú cưng
            .input('MaCN', sql.NChar(10), MaCN)
            .input('MaNV', sql.NChar(10), MaUser)
            .input('LoaiPhieu', sql.VarChar(2), 'MH')
            .input('TrieuChung', sql.NVarChar(200), null)
            .execute('sp_TaoPhieuTrucTiep');
        
        const MaPhieu = createTicket.recordset[0].MaPhieuMoi;
        
        console.log("✅ Đã tạo phiếu:", MaPhieu);
        
        // Bước 2: Thêm các sản phẩm vào CT_MUA_HANG
        for (const sp of sanPham) {
            await pool.request()
                .input('MaPhieu', sql.NChar(10), MaPhieu)
                .input('MaMatHang', sql.NChar(10), sp.MaMatHang)
                .input('SoLuong', sql.Int, sp.SoLuong)
                .query(`
                    INSERT INTO CT_MUA_HANG (MaPhieu, MaMatHang, SoLuong)
                    VALUES (@MaPhieu, @MaMatHang, @SoLuong)
                `);
            
            console.log("  ✅ Thêm sản phẩm:", sp.MaMatHang, "x", sp.SoLuong);
        }
        
        // Bước 2.5: Đánh dấu phiếu đã hoàn tất (TrangThai = 'DHT')
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .query(`
                UPDATE PHIEU_DICH_VU
                SET TrangThai = 'DHT',
                    TG_ThucHienDV = GETDATE()
                WHERE MaPhieu = @MaPhieu
            `);
        
        console.log("  ✅ Đã đánh dấu phiếu hoàn tất");
        
        // Bước 2.6: Tạo record HD_TRUC_TIEP (để sp_XuatHoaDonTrucTiep có dữ liệu UPDATE)
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('MaNV', sql.NChar(10), MaUser)
            .query(`
                IF NOT EXISTS (SELECT 1 FROM HD_TRUC_TIEP WHERE MaPhieu = @MaPhieu)
                BEGIN
                    INSERT INTO HD_TRUC_TIEP (MaPhieu, TongThanhTien, KhuyenMai, DiemQuyDoi, TongThanhTienSC, PhuongThucTT, MaNV)
                    VALUES (@MaPhieu, 0, 0, 0, 0, N'Tiền mặt', @MaNV)
                END
            `);
        
        console.log("  ✅ Đã tạo record HD_TRUC_TIEP");
        
        // Bước 3: Xuất hóa đơn ngay (gọi sp_XuatHoaDonTrucTiep)
        const exportResult = await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu)
            .input('DiemMuonDung', sql.Int, DiemMuonDung)
            .input('PhuongThucTT', sql.NVarChar(50), PhuongThucTT)
            .input('MaNV_XuatHD', sql.NChar(10), MaUser)
            .execute('sp_XuatHoaDonTrucTiep');
        
        const invoiceData = exportResult.recordset[0];
        
        console.log("✅ Xuất hóa đơn thành công!");
        
        res.json({
            success: true,
            message: 'Bán hàng thành công!',
            invoice: {
                MaPhieu,
                ...invoiceData,
                DiemHienCoBanDau: diemHienCo
            }
        });
        
    } catch (error) {
        console.error('❌ Lỗi bán hàng trực tiếp:', error);
        res.status(500).json({ 
            success: false,
            message: 'Lỗi bán hàng: ' + error.message 
        });
    }
};