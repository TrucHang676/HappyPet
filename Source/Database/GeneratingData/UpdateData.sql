USE HAPPYPET
GO

-- =============================================
-- Năm 2023
-- =============================================
-- Set khuyến mãi, điểm quy đổi = 0
CREATE OR ALTER PROC sp_CapNhatHoaDon2023
AS
BEGIN
    -- Cập nhật Hóa Đơn Trực Tuyến
    UPDATE HDTT
    SET KhuyenMai = 0, 
        DiemQuyDoi = 0
    FROM HD_TRUC_TUYEN HDTT
    JOIN PHIEU_DICH_VU PDV ON HDTT.MaPhieu = PDV.MaPhieu
    WHERE YEAR(PDV.TG_ThucHienDV) = 2023;

    -- Cập nhật Hóa Đơn Trực Tiếp
    UPDATE HDTTiep
    SET KhuyenMai = 0, 
        DiemQuyDoi = 0
    FROM HD_TRUC_TIEP HDTTiep
    JOIN PHIEU_DICH_VU PDV ON HDTTiep.MaPhieu = PDV.MaPhieu
    WHERE YEAR(PDV.TG_ThucHienDV) = 2023;
END;
GO
-- Thực thi
sp_CapNhatHoaDon2023
GO
-- Tính tổng thành tiền
CREATE OR ALTER PROC sp_TinhTongThanhTien
AS
BEGIN
-------------------------------------------------------
    -- 1. XỬ LÝ HÓA ĐƠN TRỰC TIẾP (HD_TRUC_TIEP)
    -------------------------------------------------------
    
    -- Trường hợp 1: Mua Hàng (MH) -> Tổng tiền từ CT_MUA_HANG
    UPDATE HD
    SET TongThanhTien = T.TongTienHang
    FROM HD_TRUC_TIEP HD
    JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
    JOIN (
        SELECT MaPhieu, SUM(ThanhTien) AS TongTienHang 
        FROM CT_MUA_HANG 
        GROUP BY MaPhieu
    ) T ON HD.MaPhieu = T.MaPhieu
    WHERE P.LoaiPhieu = 'MH';

    -- Trường hợp 2: Khám Bệnh (KB) -> Tổng tiền từ CT_DON_THUOC + 150,000
    UPDATE HD
    SET TongThanhTien = ISNULL(T.TongTienThuoc, 0) + 150000
    FROM HD_TRUC_TIEP HD
    JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
    LEFT JOIN (
        SELECT MaPhieu, SUM(ThanhTien) AS TongTienThuoc 
        FROM CT_DON_THUOC 
        GROUP BY MaPhieu
    ) T ON HD.MaPhieu = T.MaPhieu
    WHERE P.LoaiPhieu = 'KB';

    -- Trường hợp 3: Tiêm Vaccine (TV) -> Xử lý điều kiện Nhắc Lại
    -- Logic: Cộng tổng tiền vaccine + (200,000 NẾU có ít nhất 1 dòng NhacLai = 0)
    UPDATE HD
    SET TongThanhTien = ISNULL(T.TongTienVC, 0) + 
                        CASE 
                            WHEN T.SoMuiCoBan >= 1 THEN 200000 
                            ELSE 0 
                        END
    FROM HD_TRUC_TIEP HD
    JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
    LEFT JOIN (
        SELECT 
            MaPhieu, 
            SUM(ThanhTien) AS TongTienVC,
            -- Đếm số dòng có NhacLai = 0
            COUNT(CASE WHEN NhacLai = 0 THEN 1 END) AS SoMuiCoBan
        FROM CT_TIEM_VC 
        GROUP BY MaPhieu
    ) T ON HD.MaPhieu = T.MaPhieu
    WHERE P.LoaiPhieu = 'TV';

    -------------------------------------------------------
    -- 2. XỬ LÝ HÓA ĐƠN TRỰC TUYẾN (HD_TRUC_TUYEN)
    -------------------------------------------------------
    
    -- Chỉ có Mua Hàng (MH) -> Tổng tiền từ CT_MUA_HANG
    UPDATE HD
    SET TongThanhTien = T.TongTienHang
    FROM HD_TRUC_TUYEN HD
    JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
    JOIN (
        SELECT MaPhieu, SUM(ThanhTien) AS TongTienHang 
        FROM CT_MUA_HANG 
        GROUP BY MaPhieu
    ) T ON HD.MaPhieu = T.MaPhieu
    WHERE P.LoaiPhieu = 'MH';

END;
GO
-- Thực thi
EXEC sp_TinhTongThanhTien
GO
-- Tính tổng thành tiền sc
CREATE OR ALTER PROC sp_TinhTongThanhTienSC
    @Nam INT
AS
BEGIN
    -- 1. Cập nhật Hóa Đơn Trực Tiếp
    -- Công thức: TongThanhTienSC = TongThanhTien - KhuyenMai
    UPDATE HDTTiep
    SET TongThanhTienSC = HDTTiep.TongThanhTien - ISNULL(HDTTiep.KhuyenMai, 0)
    FROM HD_TRUC_TIEP HDTTiep
    JOIN PHIEU_DICH_VU PDV ON HDTTiep.MaPhieu = PDV.MaPhieu
    WHERE YEAR(PDV.TG_ThucHienDV) = @Nam;

    -- 2. Cập nhật Hóa Đơn Trực Tuyến
    -- Công thức: TongThanhTienSC = TongThanhTien - KhuyenMai + PhiGiaoHang
    UPDATE HDTT
    SET TongThanhTienSC = HDTT.TongThanhTien - ISNULL(HDTT.KhuyenMai, 0) + HDTT.PhiGiaoHang
    FROM HD_TRUC_TUYEN HDTT
    JOIN PHIEU_DICH_VU PDV ON HDTT.MaPhieu = PDV.MaPhieu
    WHERE YEAR(PDV.TG_ThucHienDV) = @Nam;
END;
GO
-- Thực thi
EXEC sp_TinhTongThanhTienSC 2023
GO
-- Update lại điểm tích lũy
CREATE OR ALTER PROC sp_CapNhatDiemTichLuy
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. TÍNH TIỀN TỪ CÁC HÓA ĐƠN TRONG NĂM
    WITH ChiTieuKhachHang AS (
        SELECT P.MaKH, SUM(ISNULL(HD.TongThanhTienSC, 0)) AS TongTien
        FROM HD_TRUC_TIEP HD
        JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
        WHERE YEAR(P.TG_ThucHienDV) = @Nam
        GROUP BY P.MaKH
        
        UNION ALL
        
        SELECT P.MaKH, SUM(ISNULL(HD.TongThanhTienSC, 0)) AS TongTien
        FROM HD_TRUC_TUYEN HD
        JOIN PHIEU_DICH_VU P ON HD.MaPhieu = P.MaPhieu
        WHERE YEAR(P.TG_ThucHienDV) = @Nam
        GROUP BY P.MaKH
    ),
    TongHopChiTieu AS (
        SELECT MaKH, SUM(TongTien) AS TongTienNam
        FROM ChiTieuKhachHang
        GROUP BY MaKH
    )

    -- 2. CẬP NHẬT CỘNG DỒN VÀO BẢNG KHACH_HANG
    UPDATE KH
    SET TongDiemTichLuy = 
        CASE 
            -- Nếu khách hàng KHÔNG có tài khoản -> Vẫn giữ logic là 0 (hoặc giữ nguyên điểm cũ tùy bạn, ở đây mình để 0 theo code cũ)
            WHEN TK.MaUser IS NULL THEN 0 
            
            -- Nếu CÓ tài khoản -> Lấy Điểm Cũ + Điểm Mới
            ELSE 
                -- [ĐIỂM CŨ]: Lấy từ bảng Khách Hàng (nếu chưa có thì là 0)
                ISNULL(KH.TongDiemTichLuy, 0) 
                + 
                -- [ĐIỂM MỚI]: Tính từ tiền năm nay chia 50.000
                CAST((ISNULL(T.TongTienNam, 0) / 50000) AS INT)
        END
    FROM KHACH_HANG KH
    -- Join bảng tài khoản
    LEFT JOIN TAI_KHOAN TK ON KH.MaKH = TK.MaUser
    -- Join bảng tính tiền
    LEFT JOIN TongHopChiTieu T ON KH.MaKH = T.MaKH;
END;
GO
-- Thực thi
EXEC sp_CapNhatDiemTichLuy 2023
GO
-- Update tổng chi tiêu năm 2023
CREATE OR ALTER PROC sp_CapNhatTongChiTieu
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. TÍNH TỔNG TIỀN TỪ CÁC HÓA ĐƠN TRONG NĂM
    WITH BangTam_ChiTieu AS (
        -- Nguồn 1: Hóa đơn trực tiếp
        SELECT PDV.MaKH, SUM(ISNULL(HD.TongThanhTienSC, 0)) AS TongTien
        FROM HD_TRUC_TIEP HD
        JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
        WHERE YEAR(PDV.TG_ThucHienDV) = @Nam
        GROUP BY PDV.MaKH
        
        UNION ALL
        
        -- Nguồn 2: Hóa đơn trực tuyến
        SELECT PDV.MaKH, SUM(ISNULL(HD.TongThanhTienSC, 0)) AS TongTien
        FROM HD_TRUC_TUYEN HD
        JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
        WHERE YEAR(PDV.TG_ThucHienDV) = @Nam AND HD.TrangThaiHD = 'DTT'
        GROUP BY PDV.MaKH
    ),
    BangTongHop AS (
        SELECT 
            BT.MaKH, 
            SUM(BT.TongTien) AS TongChiTieuThucTe
        FROM BangTam_ChiTieu BT
        -- [QUAN TRỌNG] Phải JOIN với KHACH_HANG để loại bỏ mã rác gây lỗi FK
        INNER JOIN KHACH_HANG KH ON BT.MaKH = KH.MaKH 
        GROUP BY BT.MaKH
    )

    -- 2. CẬP NHẬT VÀO BẢNG XẾP HẠNG
    MERGE XEP_HANG_NAM AS Target
    USING BangTongHop AS Source
    ON Target.MaKH = Source.MaKH AND Target.Nam = @Nam
    
    -- Nếu đã có -> Update số tiền mới tính được
    WHEN MATCHED THEN
        UPDATE SET 
            Target.TongChiTieu = Source.TongChiTieuThucTe;
END;
GO
-- Thực thi
EXEC sp_CapNhatTongChiTieu 2023
GO
-- Update xếp hạng năm 2023
CREATE OR ALTER PROC sp_CapNhatXepHangNam
AS
BEGIN
    SET NOCOUNT ON;

    -- Cập nhật trực tiếp trên bảng XEP_HANG_NAM
    -- Dựa vào cột TongChiTieu của chính dòng đó để tính ra MaHang
    UPDATE XEP_HANG_NAM
    SET 
        MaHang = CASE 
                    -- === 1. LOGIC GIỮ HẠNG (Cho khách cũ) ===
                    
                    -- Khách đang hạng C03 VIP: Chỉ cần >= 8tr là giữ được hạng
                    WHEN MaHang = 'C03' AND TongChiTieu >= 8000000 THEN 'C03'
                    
                    -- Khách đang hạng C02 thân thiết:
                    -- Nếu tiêu >= 12tr -> Lên C03
                    WHEN MaHang = 'C02' AND TongChiTieu >= 12000000 THEN 'C03'
                    -- Nếu tiêu >= 3tr -> Giữ C02
                    WHEN MaHang = 'C02' AND TongChiTieu >= 3000000 THEN 'C02'
                    
                    -- === 2. LOGIC CHUẨN (Cho khách mới hoặc rớt hạng) ===
                    WHEN TongChiTieu >= 12000000 THEN 'C03'
                    WHEN TongChiTieu >= 5000000  THEN 'C02'
                    
                    -- Không đủ điều kiện nào ở trên -> Về C01
                    ELSE 'C01'
                 END;
END;
GO
-- Thực thi
EXEC sp_CapNhatXepHangNam
GO

-- =============================================
-- Năm 2024
-- =============================================
-- Tính tổng thành tiền
-- Tính khuyến mãi dựa vào xếp hạng năm (2023, nếu có) + tiền quy đổi từ điểm
CREATE OR ALTER PROC sp_TinhKhuyenMai
    @Nam INT -- Input: Năm cần tính khuyến mãi
AS
BEGIN
    SET NOCOUNT ON;

    -- =============================================
    -- 1. CẬP NHẬT CHO HÓA ĐƠN TRỰC TIẾP (HD_TRUC_TIEP)
    -- =============================================
    UPDATE HD
    SET KhuyenMai = 
        CASE 
            -- Hạng C02 (Thân thiết): * 0.95 + Điểm
            WHEN XHN.MaHang = 'C02' THEN (HD.TongThanhTien * 0.95) + (ISNULL(HD.DiemQuyDoi, 0) * 1000)
            
            -- Hạng C03 (VIP): * 0.93 + Điểm
            WHEN XHN.MaHang = 'C03' THEN (HD.TongThanhTien * 0.93) + (ISNULL(HD.DiemQuyDoi, 0) * 1000)
            
            ELSE 0 
        END
    FROM HD_TRUC_TIEP HD
    JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
    -- Join với XEP_HANG_NAM để lấy hạng của "Năm Ngoái" (Tức là @Nam - 1)
    INNER JOIN XEP_HANG_NAM XHN ON PDV.MaKH = XHN.MaKH 
                               AND XHN.Nam = (@Nam - 1)
    WHERE XHN.MaHang IN ('C02', 'C03')
      AND YEAR(PDV.TG_ThucHienDV) = @Nam; -- [QUAN TRỌNG] Chỉ update hóa đơn của năm đầu vào
    -- =============================================
    -- 2. CẬP NHẬT CHO HÓA ĐƠN TRỰC TUYẾN (HD_TRUC_TUYEN)
    -- =============================================
    UPDATE HD
    SET KhuyenMai = 
        CASE 
            WHEN XHN.MaHang = 'C02' THEN (HD.TongThanhTien * 0.95) + (ISNULL(HD.DiemQuyDoi, 0) * 1000)
            WHEN XHN.MaHang = 'C03' THEN (HD.TongThanhTien * 0.93) + (ISNULL(HD.DiemQuyDoi, 0) * 1000)
            ELSE 0
        END
    FROM HD_TRUC_TUYEN HD
    JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
    INNER JOIN XEP_HANG_NAM XHN ON PDV.MaKH = XHN.MaKH 
                               AND XHN.Nam = (@Nam - 1)
    WHERE XHN.MaHang IN ('C02', 'C03')
      AND YEAR(PDV.TG_ThucHienDV) = @Nam; -- [QUAN TRỌNG] Chỉ update hóa đơn của năm đầu vào

END;
GO
-- Thực thi
EXEC sp_TinhKhuyenMai 2024
GO
-- Tính tổng thành tiền sc
EXEC sp_TinhTongThanhTienSC 2024
GO
-- Update lại điểm tích lũy
EXEC sp_CapNhatDiemTichLuy 2024
GO
-- Update tổng chi tiêu năm 2024
EXEC sp_CapNhatTongChiTieu 2024
GO
-- Update xếp hạng năm 2024
EXEC sp_CapNhatXepHangNam
GO

-- =============================================
-- Năm 2025
-- =============================================
-- Tính tổng thành tiền
-- Tính khuyến mãi dựa vào xếp hạng năm (2024, nếu có) + tiền quy đổi từ điểm
EXEC sp_TinhKhuyenMai 2025
GO
-- Tính tổng thành tiền sc
EXEC sp_TinhTongThanhTienSC 2025
GO
-- Update lại điểm tích lũy
EXEC sp_CapNhatDiemTichLuy 2025
GO
-- Trừ đi các điểm đã sử dụng
CREATE OR ALTER PROC sp_TruDiemDaSuDung
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. TÍNH TỔNG ĐIỂM ĐÃ SỬ DỤNG (DiemQuyDoi) CỦA TỪNG KHÁCH
    WITH DiemDaSuDung AS (
        -- Lấy điểm dùng trong Hóa đơn trực tiếp
        SELECT PDV.MaKH, SUM(ISNULL(HD.DiemQuyDoi, 0)) AS DiemDaDung
        FROM HD_TRUC_TIEP HD
        JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
        WHERE HD.DiemQuyDoi > 0 -- Chỉ lấy những hóa đơn có dùng điểm
        GROUP BY PDV.MaKH
        
        UNION ALL
        
        -- Lấy điểm dùng trong Hóa đơn trực tuyến
        SELECT PDV.MaKH, SUM(ISNULL(HD.DiemQuyDoi, 0)) AS DiemDaDung
        FROM HD_TRUC_TUYEN HD
        JOIN PHIEU_DICH_VU PDV ON HD.MaPhieu = PDV.MaPhieu
        WHERE HD.DiemQuyDoi > 0
        GROUP BY PDV.MaKH
    ),
    TongHopDiemDung AS (
        SELECT MaKH, SUM(DiemDaDung) AS TongDiemBiTru
        FROM DiemDaSuDung
        GROUP BY MaKH
    )

    -- 2. CẬP NHẬT TRỪ ĐIỂM VÀO BẢNG KHACH_HANG
    UPDATE KH
    SET 
        -- Logic: Điểm Mới = Điểm Hiện Tại - Tổng Điểm Đã Xài
        -- (Dùng ISNULL để tránh lỗi nếu dữ liệu null)
        KH.TongDiemTichLuy = ISNULL(KH.TongDiemTichLuy, 0) - Source.TongDiemBiTru
    FROM KHACH_HANG KH
    -- [QUAN TRỌNG] Chỉ update những người có TAI_KHOAN
    INNER JOIN TAI_KHOAN TK ON KH.MaKH = TK.MaUser
    -- Join với bảng tổng hợp điểm dùng để lấy số liệu trừ
    INNER JOIN TongHopDiemDung Source ON KH.MaKH = Source.MaKH;
    
END;
GO
-- Thực thi
EXEC sp_TruDiemDaSuDung
GO
-------------------------------------------------------------------
UPDATE XEP_HANG_NAM SET TongChiTieu = 0 WHERE TongChiTieu IS NULL
GO

UPDATE HD_TRUC_TUYEN SET KhuyenMai = 0 WHERE KhuyenMai IS NULL
GO

UPDATE HD_TRUC_TUYEN SET DiemQuyDoi = 0 WHERE KhuyenMai = 0
GO

UPDATE HD_TRUC_TIEP SET DiemQuyDoi = 0 WHERE KhuyenMai = 0
GO