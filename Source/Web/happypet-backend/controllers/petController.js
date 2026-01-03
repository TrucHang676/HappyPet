const { sql } = require('../config/db');

// --- 1. LẤY DANH SÁCH (Sửa lại dùng SP của bà) ---
exports.getMyPets = async (req, res) => {
  try {
    // Lấy ID user
    const userId = req.user.id || req.user.MaUser || req.user.MaKH;
    
    console.log("Đang gọi SP sp_XemDanhSachThuCung cho:", userId);

    const pool = await sql.connect();
    const request = pool.request();

    // Truyền tham số vào SP
    request.input('MaKH', sql.NChar(10), userId); 

    // 🔥 GỌI STORED PROCEDURE (Thay vì SELECT thường)
    const result = await request.execute('sp_XemDanhSachThuCung');

    // Trả kết quả về
    res.json(result.recordset);

  } catch (error) {
    console.error("Lỗi lấy danh sách:", error);
    res.status(500).json({ message: 'Lỗi Server', error: error.message });
  }
};

// --- 2. THÊM MỚI (Dùng SP sp_ThemThuCung) ---
exports.addPet = async (req, res) => {
    const { Ten, Loai, Giong, NgSinh, GioiTinh, TinhTrangSucKhoe } = req.body;

    try {
        const userId = req.user.id || req.user.MaUser;

        // ⚠️ SỬA LỖI: Dùng sql.connect() thay vì poolPromise (cái cũ gây lỗi)
        const pool = await sql.connect(); 
        const request = pool.request();

        // Map tham số (Phải khớp với SP sp_ThemThuCung)
        request.input('MaKH', sql.NChar(10), userId);
        request.input('TenTC', sql.NVarChar(50), Ten);
        request.input('Loai', sql.NVarChar(30), Loai);
        request.input('Giong', sql.NVarChar(30), Giong);
        request.input('NgaySinh', sql.Date, NgSinh);
        request.input('GioiTinh', sql.NVarChar(3), GioiTinh);
        request.input('TinhTrangSucKhoe', sql.NVarChar(100), TinhTrangSucKhoe);

        const result = await request.execute('sp_ThemThuCung');
        
        res.status(201).json({ 
            message: 'Thêm thú cưng thành công!', 
            newPetId: result.recordset ? result.recordset[0]?.NewMaTC : null 
        });

    } catch (err) {
        console.error("Lỗi thêm mới:", err);
        res.status(500).json({ message: 'Lỗi khi thêm thú cưng', error: err.message });
    }
};

// --- 3. CẬP NHẬT (Dùng SP sp_CapNhatThuCung) ---
exports.updatePet = async (req, res) => {
    try {
        const userId = req.user.id || req.user.MaUser; 
        const petId = req.params.id; 
        
        console.log("📥 Dữ liệu update:", req.body); 

        // Lấy dữ liệu từ Frontend (Frontend gửi tên biến là Ten, NgSinh... nên giữ nguyên đoạn này)
        const { Ten, Loai, Giong, NgSinh, GioiTinh, TinhTrangSucKhoe } = req.body; 

        // Validate cơ bản
        if (!Ten) {
            return res.status(400).json({ message: "Tên thú cưng không được để trống!" });
        }

        const pool = await sql.connect();
        const request = pool.request();

        // --- MAP THAM SỐ (SỬA KHỚP 100% VỚI SP BÀ VỪA GỬI) ---
        
        // 1. Mã Khách Hàng (NCHAR 10)
        request.input('MaKH', sql.NChar(10), userId);
        
        // 2. Mã Thú Cưng (Sửa thành VarChar 20 cho khớp SP)
        request.input('MaTC', sql.VarChar(20), petId); 
        
        // 3. Tên Thú Cưng (Trong SP là @TenTC) -> QUAN TRỌNG
        request.input('TenTC', sql.NVarChar(50), Ten); 
        
        // 4. Loại (NVARCHAR 20)
        request.input('Loai', sql.NVarChar(20), Loai);
        
        // 5. Giống (NVARCHAR 50 - SP bà để 50)
        request.input('Giong', sql.NVarChar(50), Giong);
        
        // 6. Ngày Sinh (Trong SP là @NgaySinh) -> QUAN TRỌNG
        const validNgSinh = (NgSinh && NgSinh !== '') ? NgSinh : new Date();
        request.input('NgaySinh', sql.Date, validNgSinh); 
        
        // 7. Giới Tính (NVARCHAR 10 - SP bà để 10)
        request.input('GioiTinh', sql.NVarChar(10), GioiTinh);
        
        // 8. Tình Trạng Sức Khỏe (NVARCHAR 100)
        request.input('TinhTrangSucKhoe', sql.NVarChar(100), TinhTrangSucKhoe || '');
        
        // Gọi SP
        await request.execute('sp_CapNhatThuCung');

        console.log("✅ Cập nhật thành công!");
        res.json({ message: 'Cập nhật thành công!' });

    } catch (error) {
        console.error("❌ Lỗi SQL chi tiết:", error); 
        res.status(500).json({ message: 'Lỗi cập nhật', error: error.message });
    }
};
    
// --- 4. XEM BỆNH ÁN ---
exports.getPetMedicalHistory = async (req, res) => {
    res.json([]); 
};

// --- 5. XÓA THÚ CƯNG ---
exports.deletePet = async (req, res) => {
    try {
        const userId = req.user.id || req.user.MaUser; // Lấy ID chủ
        const petId = req.params.id; // Lấy ID thú cưng trên URL

        console.log(`User ${userId} đang muốn xóa thú cưng ${petId}`);

        const pool = await sql.connect();
        const request = pool.request();

        request.input('MaKH', sql.NChar(10), userId);
        request.input('MaTC', sql.VarChar(20), petId);

        await request.execute('sp_XoaThuCung');

        res.json({ message: 'Đã xóa bé thành công (vĩnh biệt bé)!' });

    } catch (error) {
        console.error("Lỗi xóa thú cưng:", error);
        res.status(500).json({ message: 'Lỗi khi xóa', error: error.message });
    }
};

// --- 6. XEM LỊCH SỬ KHÁM BỆNH VÀ TIÊM PHÒNG ---
exports.getPetHistory = async (req, res) => {
    try {
        const userId = req.user.id || req.user.MaUser || req.user.MaKH;
        const petId = req.params.id;

        console.log(`User ${userId} xem hồ sơ thú cưng ${petId}`);

        const pool = await sql.connect();
        
        // 1. Gọi SP Khám Bệnh
        const req1 = pool.request();
        req1.input('MaKH', sql.NChar(10), userId);
        req1.input('MaTC', sql.NChar(10), petId); // Lưu ý: SP bà để NCHAR(10)
        const resKham = await req1.execute('sp_XemLichSuKhamBenh');

        // 2. Gọi SP Tiêm Phòng
        const req2 = pool.request();
        req2.input('MaKH', sql.NChar(10), userId);
        req2.input('MaTC', sql.NChar(10), petId);
        const resTiem = await req2.execute('sp_XemLichSuTiemPhong');

        // 3. Trả về cả 2 danh sách trong 1 cục JSON
        res.json({
            khamBenh: resKham.recordset,
            tiemPhong: resTiem.recordset
        });

    } catch (error) {
        console.error("Lỗi lấy lịch sử:", error);
        res.status(500).json({ message: 'Lỗi lấy dữ liệu', error: error.message });
    }
};

// --- 5. KIỂM TRA GÓI VACCINE ĐANG TIÊM DỞ ---
exports.checkOngoingVaccinePackage = async (req, res) => {
    try {
        const { MaTC } = req.params;
        
        const pool = await sql.connect();
        const result = await pool.request()
            .input('MaTC', sql.NChar(10), MaTC)
            .execute('sp_KiemTraGoiDangTiem');
            
        // Nếu có kết quả = có gói đang tiêm
        if (result.recordset.length > 0) {
            res.json({
                hasOngoingPackage: true,
                packageInfo: result.recordset[0]
            });
        } else {
            res.json({
                hasOngoingPackage: false,
                packageInfo: null
            });
        }
    } catch (error) {
        console.error("Lỗi check gói vaccine:", error);
        res.status(500).json({ message: 'Lỗi kiểm tra gói vaccine', error: error.message });
    }
};