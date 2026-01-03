// controllers/authController.js
const { sql } = require('../config/db');
const bcrypt = require('bcryptjs');
const jwt = require('jsonwebtoken');
const { OAuth2Client } = require('google-auth-library');
const client = new OAuth2Client("811103521068-7pa920b80fub1g7gf646lsgue3v0jl8p.apps.googleusercontent.com");
// 1. ĐĂNG KÝ
exports.register = async (req, res) => {
    const { TenDangNhap, MatKhau, HoTen, NgaySinh, GioiTinh, SDT, Email, CCCD } = req.body;

    try {
        const pool = await sql.connect();
        
        // Mã hóa mật khẩu trước khi gửi vào SP
        const salt = await bcrypt.genSalt(10);
        const hashedPassword = await bcrypt.hash(MatKhau, salt);

        const request = pool.request();
        request.input('TenDangNhap', sql.VarChar(30), TenDangNhap);
        request.input('MatKhau', sql.VarChar(70), hashedPassword); // Pass đã mã hóa
        request.input('HoTen', sql.NVarChar(50), HoTen);
        request.input('NgaySinh', sql.Date, NgaySinh);
        request.input('GioiTinh', sql.NVarChar(3), GioiTinh);
        request.input('SDT', sql.VarChar(10), SDT);
        request.input('Email', sql.VarChar(50), Email);
        request.input('CCCD', sql.Char(12), CCCD);

        // Gọi SP Đăng ký
        await request.execute('sp_DangKyTaiKhoanKH');

        res.status(201).json({ message: 'Đăng ký thành công!' });

    } catch (err) {
        // Bắt lỗi RAISERROR từ SQL trả về
        if (err.message.includes('Tên đăng nhập')) return res.status(409).json({ message: 'Tên đăng nhập đã tồn tại' });
        if (err.message.includes('Số điện thoại')) return res.status(409).json({ message: 'Số điện thoại đã được sử dụng' });
        if (err.message.includes('Email')) return res.status(409).json({ message: 'Email đã được sử dụng hoặc sai định dạng' });
        
        res.status(500).json({ message: 'Lỗi hệ thống: ' + err.message });
    }
};

// 2. ĐĂNG NHẬP
// exports.login = async (req, res) => {
//     const { TenDangNhap, MatKhau } = req.body;

//     try {
//         const pool = await sql.connect();
//         // 1. Gọi SP kiểm tra đăng nhập
//         const request = pool.request().input('TenDangNhap', sql.VarChar(30), TenDangNhap);
//         const result = await request.execute('sp_DangNhap');
//         const user = result.recordset[0];

//         // 2. Kiểm tra User tồn tại
//         if (!user) {
//             return res.status(401).json({ message: 'Sai tên đăng nhập!' });
//         }

//         // 3. Kiểm tra Mật khẩu (So sánh Hash)
//         const isMatch = await bcrypt.compare(MatKhau, user.MatKhau);
//         if (!isMatch) {
//             return res.status(401).json({ message: 'Sai mật khẩu!' });
//         }

//         // 4. TẠO TOKEN XỊN (QUAN TRỌNG NHẤT LÀ ĐÂY) 
//         // Mã hóa thông tin User vào trong Token
//         const token = jwt.sign(
//             { 
//                 MaUser: user.MaUser, 
//                 Role: user.LoaiUser,
//                 MaCN: user.MaCN 
//             }, 
//             process.env.JWT_SECRET || 'toimuontoitetlamroichoioiii!!', // Khóa bí mật
//             { expiresIn: '1d' } // Token sống trong 1 ngày
//         );

//         // 5. Trả về cho Frontend
//         res.json({
//             message: 'Đăng nhập thành công',
//             token: token, // <--- ĐÂY LÀ TOKEN THẬT
//             Role: user.LoaiUser,
//             ChucVu: user.ChucVu,
//             MaCN: user.MaCN,
//             HoTen: user.HoTen,
//             TenDangNhap: user.TenDangNhap
//         });

//     } catch (err) {
//         res.status(500).json({ message: err.message });
//     }
// };

// exports.login = async (req, res) => {
//     const { TenDangNhap, MatKhau } = req.body;

//     try {
//         const pool = await sql.connect();
//         // 1. Gọi SP kiểm tra đăng nhập
//         const request = pool.request().input('TenDangNhap', sql.VarChar(30), TenDangNhap);
//         const result = await request.execute('sp_DangNhap');
//         const user = result.recordset[0];

//         // 2. Kiểm tra User tồn tại
//         if (!user) {
//             return res.status(401).json({ message: 'Sai tên đăng nhập!' });
//         }

//         // 3. Kiểm tra Mật khẩu
//         const isMatch = await bcrypt.compare(MatKhau, user.MatKhau);
//         if (!isMatch) {
//             return res.status(401).json({ message: 'Sai mật khẩu!' });
//         }

//         // 🔥 [QUAN TRỌNG] XÁC ĐỊNH ROLE CHUẨN 🔥
//         // Nếu có ChucVu (Bác sĩ thú y) thì lấy ChucVu.
//         // Nếu không (là Khách hàng) thì lấy LoaiUser (KH).
//         const roleChuan = user.ChucVu || user.LoaiUser; 

//         // 4. TẠO TOKEN
//         const token = jwt.sign(
//             { 
//                 MaUser: user.MaUser, 
//                 Role: roleChuan, // 🔥 Sửa chỗ này: Dùng roleChuan thay vì user.LoaiUser
//                 MaCN: user.MaCN 
//             }, 
//             process.env.JWT_SECRET || 'toimuontoitetlamroichoioiii!!', 
//             { expiresIn: '1d' }
//         );

//         // 5. Trả về cho Frontend
//         res.json({
//             message: 'Đăng nhập thành công',
//             token: token,
//             Role: roleChuan, // 🔥 Sửa chỗ này luôn: Trả về "Bác sĩ thú y" cho Frontend lưu
//             ChucVu: user.ChucVu,
//             MaCN: user.MaCN,
//             HoTen: user.HoTen,
//             TenDangNhap: user.TenDangNhap
//         });

//     } catch (err) {
//         res.status(500).json({ message: err.message });
//     }
// };

exports.login = async (req, res) => {
    const { TenDangNhap, MatKhau } = req.body;

    try {
        const pool = await sql.connect();
        
        // 1. Tìm User cơ bản trước
        const request = pool.request().input('TenDangNhap', sql.VarChar(50), TenDangNhap);
        const result = await request.execute('sp_DangNhap');
        const user = result.recordset[0];

        // 2. Kiểm tra tồn tại & Mật khẩu
        if (!user) {
            return res.status(401).json({ message: 'Sai tên đăng nhập!' });
        }

        // Xử lý mật khẩu (Giữ nguyên logic trim() nãy tui chỉ bà cho chắc)
        const dbPass = user.MatKhau ? user.MatKhau.trim() : ''; 
        let isMatch = false;
        if (dbPass.startsWith('$2a$') || dbPass.startsWith('$2b$')) {
            isMatch = await bcrypt.compare(MatKhau, dbPass);
        } else {
            isMatch = (MatKhau === dbPass);
        }

        if (!isMatch) {
            return res.status(401).json({ message: 'Sai mật khẩu!' });
        }

        // 🔥🔥🔥 ĐOẠN QUAN TRỌNG NHẤT: ÉP LẤY CHỨC VỤ 🔥🔥🔥
        // Mặc định lấy LoaiUser (NV hoặc KH)
        let finalRole = user.LoaiUser; 
        let finalMaCN = user.MaCN;

        // Nếu là NV, tui sẽ Query thêm 1 phát nữa vào bảng NHAN_VIEN để lấy chính xác ChucVu
        let chucVuCuThe = null; // 🔥 THÊM BIẾN NÀY
        if (user.LoaiUser === 'NV') {
            const staffReq = pool.request().input('MaNV', sql.VarChar(20), user.MaUser);
            const staffRes = await staffReq.query("SELECT Chucvu, MaCN FROM NHAN_VIEN WHERE MaNV = @MaNV");
            
            if (staffRes.recordset.length > 0) {
                // Đây rồi! Lấy đúng cái "Bác sĩ" hoặc "Bác sĩ thú y" ra
                finalRole = staffRes.recordset[0].Chucvu; 
                chucVuCuThe = staffRes.recordset[0].Chucvu; // 🔥 LẤY CHỨC VỤ (CỘT TÊN LÀ Chucvu)
                finalMaCN = staffRes.recordset[0].MaCN;
                console.log("✅ Đã tìm thấy chức vụ cụ thể:", finalRole, "- ChucVuCuThe:", chucVuCuThe);
            }
        }

        // 4. Tạo Token với Role chuẩn vừa tìm được
        const token = jwt.sign(
            { 
                MaUser: user.MaUser, 
                Role: finalRole, 
                MaCN: finalMaCN,
                ChucVuCuThe: chucVuCuThe // 🔥 THÊM CHỨC VỤ CỤ THỂ VÀO TOKEN
            }, 
            process.env.JWT_SECRET || 'toimuontoitetlamroichoioiii!!', 
            { expiresIn: '1d' }
        );

        // 5. Trả về cho Frontend
        res.json({
            message: 'Đăng nhập thành công',
            token: token,
            HoTen: user.HoTen,
            Role: finalRole, // Cái này để code cũ của bà bắt được nè
            ChucVuCuThe: chucVuCuThe, // 🔥 TRẢ VỀ CHỨC VỤ CỤ THỂ
            MaUser: user.MaUser,
            MaCN: finalMaCN,
            user: { // Cái này để code mới bắt được (nếu có dùng)
                MaUser: user.MaUser,
                HoTen: user.HoTen,
                role: finalRole, // 🔥 QUAN TRỌNG: Trả về "Bác sĩ" tại đây
                ChucVuCuThe: chucVuCuThe, // 🔥 THÊM VÀO USER OBJECT
                MaCN: finalMaCN,
                Avatar: user.Avatar || ''
            }
        });

    } catch (err) {
        console.error(err);
        res.status(500).json({ message: 'Lỗi server: ' + err.message });
    }
};

// 3. ĐỔI MẬT KHẨU
exports.changePassword = async (req, res) => {
    const { TenDangNhap, MatKhauCu, MatKhauMoi } = req.body;

    try {
        const pool = await sql.connect();
        
        // B1: Lấy mật khẩu hiện tại trong DB ra check trước
        const requestCheck = pool.request();
        requestCheck.input('TenDangNhap', sql.VarChar(30), TenDangNhap);
        const result = await requestCheck.execute('sp_DangNhap'); // Tận dụng SP Login để lấy pass
        const user = result.recordset[0];

        if (!user) return res.status(404).json({ message: 'Tài khoản không tồn tại' });

        // B2: So sánh mật khẩu cũ
        const isMatch = await bcrypt.compare(MatKhauCu, user.MatKhau);
        if (!isMatch) return res.status(400).json({ message: 'Mật khẩu cũ không chính xác' });

        // B3: Mã hóa mật khẩu mới và cập nhật
        const salt = await bcrypt.genSalt(10);
        const hashedNewPassword = await bcrypt.hash(MatKhauMoi, salt);

        const requestUpdate = pool.request();
        requestUpdate.input('TenDangNhap', sql.VarChar(30), TenDangNhap);
        requestUpdate.input('MatKhauMoi', sql.VarChar(70), hashedNewPassword);
        
        await requestUpdate.execute('sp_DoiMatKhau');

        res.json({ message: 'Đổi mật khẩu thành công!' });

    } catch (err) {
        res.status(500).json({ message: err.message });
    }
};

// 4. SỬA HÀM NÀY: googleLogin
exports.googleLogin = async (req, res) => {
    const { token } = req.body;
    try {
        const ticket = await client.verifyIdToken({
            idToken: token,
            audience: "811103521068-7pa920b80fub1g7gf646lsgue3v0jl8p.apps.googleusercontent.com", 
        });
        const payload = ticket.getPayload();
        const email = payload.email;
        const name = payload.name; // Lấy luôn tên
        
        console.log(`Google Check: ${email}`);

        const pool = await sql.connect();
        const checkUser = await pool.request()
            .input('Email', sql.VarChar(50), email)
            .query("SELECT * FROM KHACH_HANG WHERE Email = @Email");

        let user = checkUser.recordset[0];

        // 🔥 KHÁC BIỆT LÀ Ở ĐÂY:
        // Nếu chưa có user -> Trả về cờ "isNewUser: true" để Frontend biết đường chuyển trang
        if (!user) {
            return res.json({ 
                isNewUser: true, 
                email: email,
                name: name,
                photo: payload.picture // Lấy luôn avatar nếu thích
            });
        }

        // Nếu có rồi -> Đăng nhập bình thường
// --- SỬA ĐOẠN TRẢ VỀ CHO USER CŨ ---
    const appToken = jwt.sign(
        { MaUser: user.MaKH, Role: 'KH', MaCN: null },
        process.env.JWT_SECRET || 'secret',
        { expiresIn: '1d' }
    );

    res.json({
        isNewUser: false, 
        token: appToken,
        Role: 'KH',
        // 🔥 FIX: Ưu tiên lấy tên từ DB, nếu lỡ DB đặt tên cột lạ thì lấy tạm tên Google
        HoTen: user.HoTen || user.TenKH || name, 
        MaUser: user.MaKH
    });

    } catch (err) {
        console.error("Lỗi Google Auth:", err);
        res.status(500).json({ message: "Xác thực Google thất bại!" });
    }
};

// 5. THÊM HÀM MỚI: Hoàn tất đăng ký Google
exports.completeGoogleRegister = async (req, res) => {
    // Lấy HoTen từ chính cái Form bà nhập (Nhật Vy Nguyễn)
    const { Email, HoTen, SDT, DiaChi, GioiTinh, NgaySinh, CCCD } = req.body;

    try {
        const pool = await sql.connect();
        const request = pool.request();

        // Tạo mật khẩu giả (Vì Google ko cần pass, nhưng DB bắt buộc NOT NULL)
        const dummyPass = await bcrypt.hash("GOOGLE_LOGIN_NO_PASS_" + Math.random(), 10);

        // Gọi SP Đăng ký như bình thường
        // Lưu ý: Tên đăng nhập tui lấy luôn là Email cho dễ nhớ
        request.input('TenDangNhap', sql.VarChar(30), Email); 
        request.input('MatKhau', sql.VarChar(70), dummyPass);
        request.input('HoTen', sql.NVarChar(50), HoTen);
        request.input('NgaySinh', sql.Date, NgaySinh || '2000-01-01'); // Mặc định nếu lười nhập
        request.input('GioiTinh', sql.NVarChar(3), GioiTinh || 'Nam');
        request.input('SDT', sql.VarChar(10), SDT);
        request.input('Email', sql.VarChar(50), Email);
        request.input('CCCD', sql.Char(12), CCCD || '000000000000'); // Mặc định để pass qua validate

        await request.execute('sp_DangKyTaiKhoanKH');

        // Đăng ký xong -> Tự động đăng nhập luôn (Lấy lại thông tin vừa tạo)
        // Lấy lại user vừa tạo
        const newUserCheck = await pool.request()
            .input('Email', sql.VarChar(50), Email)
            .query("SELECT * FROM KHACH_HANG WHERE Email = @Email");
        
        const newUser = newUserCheck.recordset[0];

        const appToken = jwt.sign(
            { MaUser: newUser.MaKH, Role: 'KH', MaCN: null },
            process.env.JWT_SECRET || 'secret',
            { expiresIn: '1d' }
        );

        res.json({ 
            message: 'Chào mừng thành viên mới!', 
            token: appToken,
            Role: 'KH',
            // 🔥 FIX: Lấy luôn cái HoTen từ Form bà vừa nhập cho chắc ăn!
            // Khỏi sợ DB trả về cột TenKH hay HoTenKH gì hết
            HoTen: HoTen, 
            MaUser: newUser.MaKH
        });
    } catch (err) {
        console.error("Lỗi tạo user Google:", err);
        res.status(500).json({ message: "Lỗi hệ thống: " + err.message });
    }
};