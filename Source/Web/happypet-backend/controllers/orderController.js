const { sql, connectDB } = require('../config/db'); // Thêm connectDB vào đây
const orderService = require('../services/orderService');

exports.getOrderHistory = async (req, res) => {
    try {
        const maKH = req.user?.MaUser || req.user?.Id || req.user?.MaKH || req.user?.sub;
        if (!maKH) return res.status(401).json({ message: 'Vui lòng đăng nhập lại.' });

        const pool = await connectDB();

        // 1. TỰ ĐỘNG CẬP NHẬT TRẠNG THÁI (DD -> DTH) NẾU QUÁ 2 TIẾNG - KHÔNG UPDATE TG_ThucHienDV
        await pool.request().input('MaKH_Update', sql.VarChar, String(maKH)).query(`
            UPDATE PHIEU_DICH_VU 
            SET TrangThai = 'DTH'
            FROM PHIEU_DICH_VU P JOIN HD_TRUC_TUYEN H ON P.MaPhieu = H.MaPhieu
            WHERE P.TrangThai = 'DD' AND P.MaKH = @MaKH_Update AND DATEDIFF(HOUR, P.TG_LapPhieu, GETDATE()) >= 2
              AND H.DiaChiGiaoHang NOT LIKE N'%Nội thành%'
        `);
        
  // 2. LẤY DANH SÁCH LỊCH SỬ (FULL ĐƠN HÀNG + DỊCH VỤ)
    const result = await pool.request()
        .input('MaKH', sql.VarChar, String(maKH))
        .query(`
            SELECT 
                P.MaPhieu, 
                CONVERT(VARCHAR(23), P.TG_LapPhieu, 121) AS TG_LapPhieu,
                CONVERT(VARCHAR(23), P.TG_ThucHienDV, 121) AS TG_ThucHienDV, 
                P.TrangThai, P.LoaiPhieu,
                CN.TenCN AS ChiNhanh,
                
                -- 🔥 LẤY TÊN THÚ CƯNG (Ưu tiên lấy MaTC từ phiếu khám hoặc phiếu tiêm)
                TC.Ten AS TenPet, 

                -- LẤY TỔNG TIỀN
                COALESCE(H.TongThanhTienSC, HTT.TongThanhTien, 0) as TongThanhTienSC, 
                ISNULL(H.PhiGiaoHang, 0) as PhiGiaoHang,

                -- CHI TIẾT SẢN PHẨM
                CT.MaMatHang, MH.TenMatHang, CT.SoLuong, MH.DonGia, CT.ThanhTien,
                
                -- ĐÁNH GIÁ SẢN PHẨM
                CASE WHEN DG_SP.MaPhieu IS NOT NULL THEN 1 ELSE 0 END AS DaDanhGiaSP,
                CAST(ROUND(DG_SP.DiemChatLuong, 0) AS INT) AS SaoSP,          
                DG_SP.BinhLuan AS BinhLuanSP,

                -- ĐÁNH GIÁ DỊCH VỤ
                CASE WHEN DG_DV.MaPhieu IS NOT NULL THEN 1 ELSE 0 END AS DaDanhGiaDV,
                CAST(ROUND(DG_DV.DiemTongThe, 0) AS INT) AS SaoDV,          
                DG_DV.BinhLuan AS BinhLuanDV,

                -- THÔNG TIN Y TẾ
                PKB.TrieuChung, PKB.ChanDoan, PKB.NgayHenTaiKham,
                
                -- DANH SÁCH VACCINE
                (SELECT STRING_AGG(MH_V.TenMatHang + N' (' + CAST(CTV.LieuLuong AS NVARCHAR) + 'ml)', ', ') 
                FROM CT_TIEM_VC CTV 
                JOIN VACCINE V ON CTV.MaVaccine = V.MaVaccine
                JOIN MAT_HANG MH_V ON V.MaVaccine = MH_V.MaMatHang
                WHERE CTV.MaPhieu = P.MaPhieu) AS DanhSachVaccine

            FROM PHIEU_DICH_VU P
            LEFT JOIN CHI_NHANH CN ON P.MaCN = CN.MaCN
            LEFT JOIN HD_TRUC_TUYEN H ON P.MaPhieu = H.MaPhieu
            LEFT JOIN HD_TRUC_TIEP HTT ON P.MaPhieu = HTT.MaPhieu 
            LEFT JOIN CT_MUA_HANG CT ON P.MaPhieu = CT.MaPhieu
            LEFT JOIN MAT_HANG MH ON CT.MaMatHang = MH.MaMatHang
            LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
            LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu

            -- 🔥 JOIN THÊM BẢNG THÚ CƯNG Ở ĐÂY 🔥
            LEFT JOIN THU_CUNG TC ON (TC.MaTC = PKB.MaTC OR TC.MaTC = PTV.MaTC)

            LEFT JOIN DANH_GIA_SP DG_SP ON P.MaPhieu = DG_SP.MaPhieu AND CT.MaMatHang = DG_SP.MaMatHang
            LEFT JOIN DANH_GIA_DV DG_DV ON P.MaPhieu = DG_DV.MaPhieu

            WHERE LTRIM(RTRIM(P.MaKH)) = LTRIM(RTRIM(@MaKH)) 
            AND (
                (P.LoaiPhieu = 'MH' AND H.DiaChiGiaoHang NOT LIKE N'%Nội thành%' AND H.DiaChiGiaoHang IS NOT NULL)
                OR 
                (P.LoaiPhieu <> 'MH')
            )
            ORDER BY P.TG_LapPhieu DESC
        `);

        res.json(result.recordset);
    } catch (error) {
        console.error("❌ Lỗi SQL HISTORY:", error);
        res.status(500).json({ message: error.message });
    }
};

exports.checkout = async (req, res) => {
    try {
        const { MaPhieu, DiemDung, NgayNhanHang, DiaChi } = req.body;

        if (!MaPhieu) return res.status(400).json({ message: 'Thiếu mã phiếu!' });

        const pool = await connectDB();

        // 1. TÍNH PHÍ SHIP (Ví dụ: HCM 15k, còn lại 35k)
        let phiShipMoi = 35000; // Mặc định là giao gấp
        
        if (NgayNhanHang) {
            const homNay = new Date();
            const ngayNhan = new Date(NgayNhanHang);
            
            // Tính khoảng cách ngày (đổi ra mili-giây rồi chia cho số mili-giây trong 1 ngày)
            const diffTime = ngayNhan - homNay;
            const soNgay = Math.ceil(diffTime / (1000 * 60 * 60 * 24));

            if (soNgay > 2) {
                phiShipMoi = 15000; // Tiết kiệm
            } else if (soNgay === 2) {
                phiShipMoi = 25000; // Giao nhanh
            } else {
                phiShipMoi = 35000; // Giao gấp (ngày mai hoặc trong ngày)
            }
        }

        // 2. CẬP NHẬT ĐỊA CHỈ, SHIP, VÀ TG_ThucHienDV (Ngày muốn nhận)
        await pool.request()
            .input('MP', sql.VarChar, MaPhieu)
            .input('DC', sql.NVarChar, DiaChi || 'Tại cửa hàng')
            .input('Ship', sql.Int, phiShipMoi)
            .input('NgayNhan', sql.DateTime, NgayNhanHang ? `${NgayNhanHang} 11:00:00` : null)
            .query(`
                UPDATE HD_TRUC_TUYEN 
                SET DiaChiGiaoHang = @DC, 
                    PhiGiaoHang = @Ship
                WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP));
                
                -- Cập nhật TG_ThucHienDV nếu có ngày muốn nhận
                UPDATE PHIEU_DICH_VU
                SET TG_ThucHienDV = @NgayNhan
                WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP)) AND @NgayNhan IS NOT NULL;
            `);

        // 3. GỌI SP "ONLINE" ĐỂ CHỐT ĐƠN, TRỪ ĐIỂM, TÍNH TỔNG TIỀN
        await pool.request()
            .input('MaPhieu', sql.NChar(10), MaPhieu) // SP yêu cầu NCHAR(10)
            .input('DiemMuonDung', sql.Int, DiemDung || 0) // Tên tham số trong SP là @DiemMuonDung
            .execute('sp_HoanTatDonHangOnline'); //  TÊN ĐÚNG LÀ ĐÂY

        res.json({ success: true, message: 'Đặt hàng thành công!' });

    } catch (error) {
        console.error("❌ Lỗi Checkout:", error);
        // Nếu lỗi do SP trả về (ví dụ: Không đủ điểm) thì hiện thông báo đó lên
        res.status(500).json({ message: error.message });
    }
};

exports.cancelOrder = async (req, res) => {
    try {
        const { maPhieu } = req.body;
        const pool = await connectDB();
        await pool.request()
            .input('MaPhieu', sql.NChar(10), maPhieu)
            .execute('sp_HuyDonOnline');
        res.json({ message: 'Hủy đơn thành công!' });
    } catch (error) {
        res.status(400).json({ message: error.message });
    }
};

// API: KHÁCH HÀNG NHẬN HÀNG HOÀN TẤT
exports.completeOrder = async (req, res) => {
    try {
        const { MaPhieu } = req.body;
        const MaKH = req.user?.MaUser || req.user?.Id;

        if (!MaKH) return res.status(401).json({ message: 'Vui lòng đăng nhập lại.' });
        if (!MaPhieu) return res.status(400).json({ message: 'Thiếu mã phiếu!' });

        const pool = await connectDB();

        // UPDATE TrangThai = 'HT' - KHÔNG UPDATE TG_ThucHienDV vì đó là ngày muốn nhận
        const result = await pool.request()
            .input('MP', sql.NChar(10), MaPhieu)
            .input('MaKH', sql.VarChar(20), String(MaKH))
            .query(`
                UPDATE PHIEU_DICH_VU
                SET TrangThai = 'HT'
                WHERE LTRIM(RTRIM(MaPhieu)) = LTRIM(RTRIM(@MP))
                  AND LTRIM(RTRIM(MaKH)) = LTRIM(RTRIM(@MaKH))
                  AND TrangThai = 'DTH'
            `);

        if (result.rowsAffected[0] === 0) {
            return res.status(400).json({ message: 'Không thể hoàn tất đơn hàng này (đã hoàn tất hoặc chưa giao).' });
        }

        res.json({ success: true, message: 'Đã xác nhận nhận hàng thành công!' });

    } catch (error) {
        console.error("❌ Lỗi hoàn tất đơn:", error);
        res.status(500).json({ message: error.message });
    }
};