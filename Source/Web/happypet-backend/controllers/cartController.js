
const { sql, connectDB } = require('../config/db');

// ✅ 1. Lấy giỏ hàng (CHỈ LẤY PHIẾU MUA HÀNG - MH)
exports.getCart = async (req, res) => {
    try {
        const maKH = req.user?.MaUser || req.user?.Id || req.user?.MaKH || req.user?.userId || req.user?.sub;
        if (!maKH) return res.status(401).json({ message: 'Vui lòng đăng nhập.' });

        // Cắt khoảng trắng user ID cho chắc
        const cleanMaKH = String(maKH).trim();
        console.log("🔍 Tìm giỏ hàng (MH) cho:", cleanMaKH);

        let requestedMaPhieu = req.query?.maPhieu || req.query?.MaPhieu;
        if (requestedMaPhieu) {
            requestedMaPhieu = String(requestedMaPhieu).replace(/\+/g, '').trim();
        }

        console.log("🔍 Đang tìm giỏ hàng sạch cho mã:", requestedMaPhieu);
        
        const pool = await connectDB();

        let cart = null;
        let maPhieuFinal = null;

        // A. Nếu Frontend có gửi mã phiếu -> Check xem có phải MH và của User này k
        if (requestedMaPhieu) {
            const cartRs = await pool.request()
                .input('MaPhieu', sql.VarChar, String(requestedMaPhieu)) 
                .query(`
                    SELECT TOP 1 P.MaPhieu, P.MaCN, ISNULL(H.PhiGiaoHang, 0) as PhiGiaoHang, H.DiaChiGiaoHang, H.TongThanhTien, H.TongThanhTienSC, H.DiemQuyDoi
                    FROM PHIEU_DICH_VU P
                    LEFT JOIN HD_TRUC_TUYEN H ON P.MaPhieu = H.MaPhieu
                    WHERE LTRIM(RTRIM(P.MaPhieu)) = LTRIM(RTRIM(@MaPhieu))
                      AND P.LoaiPhieu = 'MH' -- Chỉ chấp nhận phiếu Mua Hàng
                `);
            
            if (cartRs.recordset.length > 0) {
                cart = cartRs.recordset[0];
                maPhieuFinal = cart.MaPhieu;
            }
        }
        
        // B. Tự tìm phiếu 'MH' đang 'DD' mới nhất
        if (!cart) {
            const autoCartRs = await pool.request()
                .input('MaKH', sql.VarChar, cleanMaKH)
                .query(`
                    SELECT TOP 1 P.MaPhieu, P.MaCN, ISNULL(H.PhiGiaoHang, 0) as PhiGiaoHang, H.DiaChiGiaoHang, H.TongThanhTien, H.TongThanhTienSC, H.DiemQuyDoi
                    FROM PHIEU_DICH_VU P
                    LEFT JOIN HD_TRUC_TUYEN H ON P.MaPhieu = H.MaPhieu
                    WHERE LTRIM(RTRIM(P.MaKH)) = @MaKH
                      AND P.TrangThai = 'DD' 
                      AND P.LoaiPhieu = 'MH' -- 🔥 BẮT BUỘC PHẢI LÀ MH
                      -- Chỉ lấy đơn nào có địa chỉ "Nội thành..." (tức là giỏ hàng thật)
                     AND (H.DiaChiGiaoHang LIKE N'%Nội thành%' OR H.DiaChiGiaoHang IS NULL)
                    ORDER BY P.TG_LapPhieu DESC
                `);

            if (autoCartRs.recordset.length > 0) {
                cart = autoCartRs.recordset[0];
                maPhieuFinal = cart.MaPhieu;
            }
        }

        if (!cart || !maPhieuFinal) {
            return res.json({ cart: null, items: [] });
        }

        // Lấy items
        const itemsRs = await pool.request()
            .input('MaPhieu', sql.VarChar, String(maPhieuFinal))
            .query(`
                SELECT CT.MaMatHang, MH.TenMatHang, MH.DonGia, CT.SoLuong, CT.ThanhTien
                FROM CT_MUA_HANG CT
                JOIN MAT_HANG MH ON MH.MaMatHang = CT.MaMatHang
                WHERE LTRIM(RTRIM(CT.MaPhieu)) = LTRIM(RTRIM(@MaPhieu))
            `);

        res.json({ cart, items: itemsRs.recordset });

    } catch (error) {
        console.error('❌ Error in getCart:', error);
        res.status(500).json({ message: error.message });
    }
};

// ✅ 2. Thêm vào giỏ (CHECK KỸ LOẠI PHIẾU)
exports.addToCart = async (req, res) => {
    try {
        console.log("🔑 Dữ liệu User trong Token:", req.user);

        // 2. Lấy MaKH (Thử hết các trường hợp có thể xảy ra)
        // Lưu ý: Token của bà có thể lưu là 'MaUser', 'MaKH', 'Id', hoặc 'id' (chữ thường)
        const maKH = req.user?.MaKH || req.user?.MaUser || req.user?.Id || req.user?.id || req.user?.sub;

        // 3. 🔥 CHẶN NGAY NẾU KHÔNG CÓ MÃ
        if (!maKH || String(maKH) === 'undefined') {
            console.error("❌ LỖI: Không tìm thấy ID người dùng hợp lệ!");
            return res.status(401).json({ message: 'Lỗi xác thực: Token không chứa mã khách hàng.' });
        }
        const { maCN, diaChi, hinhThucTT, ngayNhan, maMH, soLuong, maPhieuHienTai } = req.body;

        if (!maCN) return res.status(400).json({ message: 'Vui lòng chọn chi nhánh.' });

        const pool = await connectDB();
        let maPhieu = maPhieuHienTai;

        // 🔥 [FIX QUAN TRỌNG] Kiểm tra maPhieu hiện tại có hợp lệ không?
        if (maPhieu) {
            const checkRs = await pool.request()
                .input('MP', sql.VarChar, maPhieu)
                .query("SELECT LoaiPhieu, TrangThai FROM PHIEU_DICH_VU WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP))");
            
            const info = checkRs.recordset[0];
            
            // Nếu phiếu không tồn tại, hoặc KHÁC LOẠI MH (ví dụ TV, KB), hoặc đã Chốt -> BỎ QUA, TẠO MỚI
            if (!info || info.LoaiPhieu !== 'MH' || info.TrangThai !== 'DD') {
                console.log(`⚠️ Mã ${maPhieu} không hợp lệ (Loại: ${info?.LoaiPhieu}), tạo phiếu MH mới...`);
                maPhieu = null; 
            }
        }

        // Nếu chưa có mã phiếu (hoặc mã cũ bị loại bỏ) -> Tạo mới
        if (!maPhieu) {
            // ... (Logic tạo ngày giữ nguyên) ...
            const MARGIN_MS = 30 * 1000;
            const MIN_MS = 24 * 60 * 60 * 1000;
            let ngayMuonParam = new Date(Date.now() + MIN_MS + MARGIN_MS);
            if (ngayNhan) {
                let parsed = new Date(ngayNhan);
                if (!isNaN(parsed.getTime()) && parsed > new Date()) ngayMuonParam = parsed;
            }

            const resultSP1 = await pool.request()
                 .input('MaKhachHang', sql.VarChar, String(maKH))
                 .input('MaChiNhanh', sql.VarChar, String(maCN))
                 .input('DiaChiGiaoHang', sql.NVarChar, String(diaChi || ''))
                //  .input('DiaChiGiaoHang', sql.NVarChar, '')
                 .input('HinhThucThanhToan', sql.NVarChar, hinhThucTT || 'Tiền mặt')
                 .input('NgayMuonNhan', sql.DateTimeOffset, ngayMuonParam.toISOString())
                 .execute('sp_KhoiTaoDonHangOnline');
            
            maPhieu = resultSP1.recordset?.[0]?.MaPhieu;

            // 🔥 GIỮ NGUYÊN ĐOẠN NÀY ĐỂ ÉP SHIP VỀ 0:
            // ... bên trong addToCart ...
            if (maPhieu) {
                await pool.request()
                    .input('MP', sql.VarChar, maPhieu)
                    .query("UPDATE HD_TRUC_TUYEN SET PhiGiaoHang = 0 WHERE MaPhieu = @MP");

                // 🔥 THÊM DÒNG NÀY ĐỂ CHECK:
                console.log(`✅ Đã ép phí ship về 0đ cho đơn: ${maPhieu}`);
            }
        }

        // Thêm sản phẩm
        await pool.request()
            .input('MaPhieu', sql.VarChar, maPhieu)
            .input('MaMatHang', sql.VarChar, maMH)
            .input('SoLuong', sql.Int, soLuong || 1)
            .execute('sp_ThemSanPhamVaoDon');

        res.json({ success: true, maPhieu, message: 'Đã thêm vào giỏ hàng!' });
    } catch (error) {
        console.error('Error in addToCart:', error);
        res.status(400).json({ message: error.message });
    }
};

// ✅ 3. Xóa sản phẩm
exports.removeFromCart = async (req, res) => {
    try {
        const { maPhieu, maMH } = req.body;
        const pool = await connectDB();
        await pool.request()
            .input('MaPhieu', sql.VarChar, maPhieu)
            .input('MaMatHang', sql.VarChar, maMH)
            .execute('sp_XoaSanPhamKhoiDon'); 
        res.json({ success: true });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};