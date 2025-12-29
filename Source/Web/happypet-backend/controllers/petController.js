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
        
        // Lấy dữ liệu từ Frontend gửi lên
        const { Ten, Loai, Giong, NgSinh, GioiTinh } = req.body; 

        console.log(`User ${userId} đang sửa thú cưng ${petId}`);

        const pool = await sql.connect();
        const request = pool.request();

        // Map tham số (Phải khớp với SP sp_CapNhatThuCung)
        request.input('MaKH', sql.NChar(10), userId);
        request.input('MaTC', sql.VarChar(20), petId);
        
        request.input('Ten', sql.NVarChar(50), Ten);
        request.input('Loai', sql.NVarChar(20), Loai);
        request.input('Giong', sql.NVarChar(50), Giong);
        // Lưu ý: Nếu NgSinh rỗng, truyền null để tránh lỗi SQL
        request.input('NgSinh', sql.Date, NgSinh || null); 
        request.input('GioiTinh', sql.NVarChar(10), GioiTinh);
        request.input('TinhTrangSucKhoe', sql.NVarChar(100), TinhTrangSucKhoe);
        // Gọi SP
        await request.execute('sp_CapNhatThuCung');

        res.json({ message: 'Cập nhật thành công!' });

    } catch (error) {
        console.error("Lỗi khi sửa:", error);
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