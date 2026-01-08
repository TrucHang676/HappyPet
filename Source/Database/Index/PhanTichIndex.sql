USE HAPPYPET
GO

SET STATISTICS TIME ON;
SET STATISTICS IO ON;
GO

SET STATISTICS IO OFF;
SET STATISTICS TIME OFF;
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- =================================================================================
-- TV1: Tra cứu danh sách thú cưng đến hẹn tái khám
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_KHAM_BENH_NgayHen_T1
ON [dbo].[PHIEU_KHAM_BENH] ([NgayHenTaiKham])
INCLUDE ([MaTC], [ChanDoan]);
GO

CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_T1
ON [dbo].[PHIEU_DICH_VU] ([MaCN])
INCLUDE ([MaPhieu]); 
GO

DROP INDEX IX_PHIEU_KHAM_BENH_NgayHen_T1 ON dbo.PHIEU_KHAM_BENH;
DROP INDEX IX_PHIEU_DICH_VU_MaCN_T1 ON dbo.PHIEU_DICH_VU;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @TuNgay DATE = '2024-12-15';
DECLARE @DenNgay DATE = '2024-12-21';
DECLARE @MaCN nchar(10) = 'CN01';

SELECT 
    PK.MaPhieu AS N'Mã phiếu',
    TC.Ten AS N'Tên thú cưng',
    U.HoTen AS N'Tên khách hàng',       
    KH.SDT,
    PK.NgayHenTaiKham AS N'Ngày hẹn tái khám',
    PK.ChanDoan AS N'Chẩn đoán'
FROM PHIEU_KHAM_BENH PK
	JOIN THU_CUNG TC ON PK.MaTC = TC.MaTC
	JOIN KHACH_HANG KH ON TC.MaKH = KH.MaKH
	JOIN [USER] U ON KH.MaKH = U.MaUser
	JOIN PHIEU_DICH_VU PDV ON PK.MaPhieu = PDV.MaPhieu
WHERE 
    PDV.MaCN = @MaCN 
    AND PK.NgayHenTaiKham >= @TuNgay 
    AND PK.NgayHenTaiKham <= @DenNgay
ORDER BY PK.NgayHenTaiKham ASC
GO

-- Không index
DECLARE @TuNgay DATE = '2024-12-15';
DECLARE @DenNgay DATE = '2024-12-21';
DECLARE @MaCN nchar(10) = 'CN02';

SELECT 
    PK.MaPhieu AS N'Mã phiếu',
    TC.Ten AS N'Tên thú cưng',
    U.HoTen AS N'Tên khách hàng',
    KH.SDT,
    PK.NgayHenTaiKham AS N'Ngày hẹn tái khám',
    PK.ChanDoan AS N'Chẩn đoán'
FROM PHIEU_KHAM_BENH_NoIndex PK          
JOIN THU_CUNG_NoIndex TC ON PK.MaTC = TC.MaTC
JOIN KHACH_HANG_NoIndex KH ON TC.MaKH = KH.MaKH
JOIN [USER_NoIndex] U ON KH.MaKH = U.MaUser
JOIN PHIEU_DICH_VU_NoIndex PDV           
    ON PK.MaPhieu = PDV.MaPhieu
WHERE 
    PDV.MaCN = @MaCN 
    AND PK.NgayHenTaiKham >= @TuNgay 
    AND PK.NgayHenTaiKham <= @DenNgay
ORDER BY PK.NgayHenTaiKham ASC;

-- =================================================================================
-- TV2: Tra cứu sản phẩm (theo Tên/Loại) của một chi nhánh
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_MAT_HANG_LoaiMH_T2
ON [dbo].[MAT_HANG] ([LoaiMH]) 
INCLUDE ([TenMatHang], [DonGia]);

DROP INDEX IX_MAT_HANG_LoaiMH_T2 ON MAT_HANG;
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM
GO

DECLARE @MaCN NCHAR(10) = 'CN01';
DECLARE @TuKhoa NVARCHAR(80) = N'Trị'; -- Nhập tên để tìm (hoặc NULL)
DECLARE @LoaiMH VARCHAR(3) = 'T';   -- Nhập mã loại: 'T', 'VC', 'SPK' (hoặc NULL)

SELECT 
    MH.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.LoaiMH AS N'Loại mặt hàng', 
    TK.SoLuongTon AS N'SL tồn', 
    MH.DonGia AS N'Đơn giá'
FROM TON_KHO TK
	JOIN MAT_HANG MH ON TK.MaMatHang = MH.MaMatHang
WHERE TK.MaCN = @MaCN
  AND (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + '%')
  AND MH.LoaiMH = @LoaiMH
ORDER BY TK.SoLuongTon DESC
GO

-- Không index
DECLARE @MaCN NCHAR(10) = 'CN01';
DECLARE @TuKhoa NVARCHAR(80) = N'Trị'; -- Nhập tên để tìm (hoặc NULL)
DECLARE @LoaiMH VARCHAR(3) = 'T';   -- Nhập mã loại: 'T', 'VC', 'SPK' (hoặc NULL)

SELECT 
    MH.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.LoaiMH AS N'Loại mặt hàng', 
    TK.SoLuongTon AS N'SL tồn', 
    MH.DonGia AS N'Đơn giá'
FROM TON_KHO_NoIndex TK  
	JOIN MAT_HANG_NoIndex MH ON TK.MaMatHang = MH.MaMatHang
WHERE TK.MaCN = @MaCN
  AND (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + '%')
  AND MH.LoaiMH = @LoaiMH
ORDER BY TK.SoLuongTon DESC
GO

-- Tối ưu hóa + index
DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

DECLARE @MaCN NCHAR(10) = 'CN01';
DECLARE @TuKhoa NVARCHAR(80) = N'Trị'; -- Nhập tên để tìm (hoặc NULL)
DECLARE @LoaiMH VARCHAR(3) = 'T';   -- Nhập mã loại: 'T', 'VC', 'SPK' (hoặc NULL)

SELECT 
    MH.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.LoaiMH AS N'Loại mặt hàng', 
    TK.SoLuongTon AS N'SL tồn', 
    MH.DonGia AS N'Đơn giá'
FROM TON_KHO TK
	JOIN MAT_HANG MH ON TK.MaMatHang = MH.MaMatHang
WHERE TK.MaCN = @MaCN
  AND (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + '%')
  AND MH.LoaiMH = @LoaiMH
ORDER BY TK.SoLuongTon DESC
OPTION (RECOMPILE);
GO

-- Không index
DECLARE @MaCN NCHAR(10) = 'CN01';
DECLARE @TuKhoa NVARCHAR(80) = N'Trị'; -- Nhập tên để tìm (hoặc NULL)
DECLARE @LoaiMH VARCHAR(3) = 'T';   -- Nhập mã loại: 'T', 'VC', 'SPK' (hoặc NULL)

SELECT 
    MH.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.LoaiMH AS N'Loại mặt hàng', 
    TK.SoLuongTon AS N'SL tồn', 
    MH.DonGia AS N'Đơn giá'
FROM TON_KHO_NoIndex TK  
	JOIN MAT_HANG_NoIndex MH ON TK.MaMatHang = MH.MaMatHang
WHERE TK.MaCN = @MaCN
  AND (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + '%')
  AND MH.LoaiMH = @LoaiMH
ORDER BY TK.SoLuongTon DESC
GO

-- =================================================================================
-- TV3: Tra cứu Phiếu dịch vụ trong ngày của một chi nhánh (Lọc theo Ngày & Mã CN)
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_Ngay_T3
ON [dbo].[PHIEU_DICH_VU] ([MaCN], [TG_ThucHienDV])
INCLUDE ([TrangThai], [LoaiPhieu], [MaNV], [MaKH]);
GO

DROP INDEX IX_PHIEU_DICH_VU_MaCN_Ngay_T3 ON PHIEU_DICH_VU;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @NgayTraCuu DATE = '2024-12-15';
DECLARE @MaCN NCHAR(10) = 'CN01';

SELECT 
    PDV.MaPhieu AS N'Mã phiếu', 
    PDV.TG_ThucHienDV AS N'Thời gian hẹn', 
    U_KH.HoTen AS N'Tên khách hàng', 
    PDV.TrangThai AS N'Trạng thái',
    PDV.LoaiPhieu AS N'Loại phiếu',
	U_NV.HoTen AS N'Nhân viên phụ trách'
FROM PHIEU_DICH_VU PDV
	LEFT JOIN [USER] U_KH ON PDV.MaKH = U_KH.MaUser 
	LEFT JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
	LEFT JOIN [USER] U_NV ON NV.MaNV = U_NV.MaUser 
WHERE PDV.MaCN = @MaCN 
	AND CAST(PDV.TG_ThucHienDV AS DATE) = @NgayTraCuu
GO

-- Không index
DECLARE @NgayTraCuu DATE = '2024-12-15';
DECLARE @MaCN NCHAR(10) = 'CN01';

SELECT 
    PDV.MaPhieu AS N'Mã phiếu', 
    PDV.TG_ThucHienDV AS N'Thời gian hẹn', 
    U_KH.HoTen AS N'Tên khách hàng', 
    PDV.TrangThai AS N'Trạng thái',
    PDV.LoaiPhieu AS N'Loại phiếu',
	U_NV.HoTen AS N'Nhân viên phụ trách'
FROM PHIEU_DICH_VU_NoIndex PDV 
	LEFT JOIN [USER_NoIndex] U_KH ON PDV.MaKH = U_KH.MaUser 
	LEFT JOIN NHAN_VIEN_NoIndex NV ON PDV.MaNV = NV.MaNV
	LEFT JOIN [USER_NoIndex] U_NV ON NV.MaNV = U_NV.MaUser 
WHERE PDV.MaCN = @MaCN 
	AND CAST(PDV.TG_ThucHienDV AS DATE) = @NgayTraCuu
GO

-- =================================================================================
-- TV4: Nhân viên update trạng thái của một Phiếu Dịch Vụ
-- =================================================================================
DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

DECLARE @MaPhieuCanSua NCHAR(10) = 'P0109999';
DECLARE @TrangThaiMoi VARCHAR(3) = 'DTH';      

UPDATE PHIEU_DICH_VU
SET 
    TrangThai = @TrangThaiMoi,
    TG_ThucHienDV = CASE 
                        WHEN @TrangThaiMoi = 'DTH' THEN GETDATE() 
                        ELSE TG_ThucHienDV 
                    END
WHERE MaPhieu = @MaPhieuCanSua
GO

update PHIEU_DICH_VU
set TrangThai = 'DD'
where MaPhieu = 'P0110000'
go
-- =================================================================================
-- TV5: Thống kê doanh thu theo tháng của từng chi nhánh theo từng loại dịch vụ
-- =================================================================================
-- Cài đặt index
-- 1.
CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_T5
ON [dbo].[PHIEU_DICH_VU] ([MaCN])
INCLUDE ([TG_LapPhieu], [LoaiPhieu]);
GO

-- 2.
CREATE NONCLUSTERED INDEX IX_HD_TRUC_TIEP_MaPhieu_T5
ON [dbo].[HD_TRUC_TIEP] ([MaPhieu])
INCLUDE ([TongThanhTienSC]);
GO

CREATE NONCLUSTERED INDEX IX_HD_TRUC_TUYEN_MaPhieu_T5
ON [dbo].[HD_TRUC_TUYEN] ([MaPhieu])
INCLUDE ([TongThanhTienSC]);
GO

DROP INDEX IX_PHIEU_DICH_VU_MaCN_T5 ON PHIEU_DICH_VU;
DROP INDEX IX_HD_TRUC_TIEP_MaPhieu ON HD_TRUC_TIEP;
DROP INDEX IX_HD_TRUC_TUYEN_MaPhieu ON HD_TRUC_TUYEN;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @Thang INT = 12;
DECLARE @Nam INT = 2024;
DECLARE @MaCN nchar(10) = 'CN01';

SELECT 
    PDV.MaCN AS N'Mã CN',
    CASE 
        WHEN PDV.LoaiPhieu = 'KB' THEN N'Khám bệnh'
        WHEN PDV.LoaiPhieu = 'TV' THEN N'Tiêm phòng'
        WHEN PDV.LoaiPhieu = 'MH' THEN N'Mua hàng'
    END AS N'Loại dịch vụ',
    FORMAT(SUM(HD.TongTien), 'N0', 'vi-VN') + ' VNĐ' AS N'Tổng doanh thu'
FROM PHIEU_DICH_VU PDV
	JOIN (
    SELECT MaPhieu, TongThanhTienSC AS TongTien FROM HD_TRUC_TIEP
    UNION ALL
    SELECT MaPhieu, TongThanhTienSC AS TongTien FROM HD_TRUC_TUYEN
	) AS HD ON PDV.MaPhieu = HD.MaPhieu
WHERE 
    PDV.MaCN = @MaCN 
    AND MONTH(PDV.TG_LapPhieu) = @Thang 
    AND YEAR(PDV.TG_LapPhieu) = @Nam
GROUP BY 
    PDV.MaCN, PDV.LoaiPhieu
ORDER BY SUM(HD.TongTien) DESC;
GO

-- Không index
DECLARE @Thang INT = 12;
DECLARE @Nam INT = 2024;
DECLARE @MaCN nchar(10) = 'CN01';

SELECT 
    PDV.MaCN AS N'Mã CN',
    CASE 
        WHEN PDV.LoaiPhieu = 'KB' THEN N'Khám bệnh'
        WHEN PDV.LoaiPhieu = 'TV' THEN N'Tiêm phòng'
        WHEN PDV.LoaiPhieu = 'MH' THEN N'Mua hàng'
    END AS N'Loại dịch vụ',
    FORMAT(SUM(HD.TongTien), 'N0', 'vi-VN') + ' VNĐ' AS N'Tổng doanh thu'
FROM PHIEU_DICH_VU_NoIndex PDV
	JOIN (
    SELECT MaPhieu, TongThanhTienSC AS TongTien FROM HD_TRUC_TIEP_NoIndex
    UNION ALL
    SELECT MaPhieu, TongThanhTienSC AS TongTien FROM HD_TRUC_TUYEN_NoIndex
	) AS HD ON PDV.MaPhieu = HD.MaPhieu
WHERE 
    PDV.MaCN = @MaCN 
    AND MONTH(PDV.TG_LapPhieu) = @Thang 
    AND YEAR(PDV.TG_LapPhieu) = @Nam
GROUP BY 
    PDV.MaCN, PDV.LoaiPhieu
ORDER BY SUM(HD.TongTien) DESC;
GO

-- =================================================================================
-- TV6: Báo cáo hàng tồn kho, cảnh báo nhập hàng của một chi nhánh
-- =================================================================================
-- 1.
CREATE NONCLUSTERED INDEX IX_TON_KHO_MaCN_SoLuong_T6
ON [dbo].[TON_KHO] ([MaCN], [SoLuongTon] ASC)
INCLUDE ([MaMatHang]);
GO

-- 2.
CREATE NONCLUSTERED INDEX IX_MAT_HANG_MaMH_Ten_Gia_T6
ON [dbo].[MAT_HANG] ([MaMatHang])
INCLUDE ([TenMatHang], [DonGia]);
GO

DROP INDEX IX_TON_KHO_MaCN_SoLuong_T6 ON TON_KHO;
DROP INDEX IX_MAT_HANG_MaMH_Ten_Gia_T6 ON MAT_HANG;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @MaCN nchar(10) = 'CN01';
DECLARE @MucCanhBao INT = 10;

SELECT 
    TK.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.DonGia AS 'Đơn giá',
    TK.SoLuongTon AS 'SL tồn',
    CN.TenCN AS N'Tên CN'
FROM TON_KHO TK
	JOIN MAT_HANG MH ON TK.MaMatHang = MH.MaMatHang
	JOIN CHI_NHANH CN ON TK.MaCN = CN.MaCN
WHERE 
    TK.MaCN = @MaCN
    AND TK.SoLuongTon < @MucCanhBao
ORDER BY 
    TK.SoLuongTon ASC
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Không index
DECLARE @MaCN nchar(10) = 'CN01';
DECLARE @MucCanhBao INT = 10;

SELECT 
    TK.MaMatHang AS N'Mã mặt hàng', 
    MH.TenMatHang AS N'Tên mặt hàng', 
    MH.DonGia AS 'Đơn giá',
    TK.SoLuongTon AS 'SL tồn',
    CN.TenCN AS N'Tên CN'
FROM TON_KHO_NoIndex TK
	JOIN MAT_HANG_NoIndex MH ON TK.MaMatHang = MH.MaMatHang
	JOIN CHI_NHANH_NoIndex CN ON TK.MaCN = CN.MaCN
WHERE 
    TK.MaCN = @MaCN
    AND TK.SoLuongTon < @MucCanhBao
ORDER BY 
    TK.SoLuongTon ASC
GO

-- =================================================================================
-- TV7: Xem lịch sử khám bệnh của một thú cưng
-- =================================================================================
-- Cài đặt index
-- 1.
CREATE NONCLUSTERED INDEX IX_PHIEU_KHAM_BENH_MaTC_T7
ON [dbo].[PHIEU_KHAM_BENH] ([MaTC])
INCLUDE ([TrieuChung], [ChanDoan]);
GO

-- 2.
CREATE NONCLUSTERED INDEX IX_CT_DON_THUOC_MaPhieu_T7
ON [dbo].[CT_DON_THUOC] ([MaPhieu])
INCLUDE ([MaThuoc], [SoLuong], [LieuLuong]);
GO

DROP INDEX IX_PHIEU_KHAM_BENH_MaTC_T7 ON PHIEU_KHAM_BENH;
DROP INDEX IX_CT_DON_THUOC_MaPhieu_T7 ON CT_DON_THUOC;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @MaThuCung nchar(10) = 'TC31087';

SELECT 
    PDV.TG_ThucHienDV AS N'Ngày khám',
    PK.TrieuChung AS N'Triệu chứng',
    PK.ChanDoan AS N'Chẩn đoán',
    MH.TenMatHang AS N'Tên thuốc',
    CTDT.SoLuong AS N'Số lượng',
    CTDT.LieuLuong AS N'Liều lượng',
    NV_User.HoTen AS N'Bác sĩ phụ trách'
FROM PHIEU_KHAM_BENH PK
	JOIN PHIEU_DICH_VU PDV ON PK.MaPhieu = PDV.MaPhieu
	-- Lấy thông tin Bác sĩ
	JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
	JOIN [USER] NV_User ON NV.MaNV = NV_User.MaUser
	-- Lấy chi tiết đơn thuốc (Nếu có kê thuốc)
	LEFT JOIN CT_DON_THUOC CTDT ON PK.MaPhieu = CTDT.MaPhieu
	LEFT JOIN THUOC T ON CTDT.MaThuoc = T.MaThuoc
	LEFT JOIN MAT_HANG MH ON T.MaThuoc = MH.MaMatHang
WHERE 
    PK.MaTC = @MaThuCung
ORDER BY PDV.TG_ThucHienDV DESC
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Không index
DECLARE @MaThuCung nchar(10) = 'TC31086';

SELECT 
    PDV.TG_ThucHienDV AS N'Ngày khám',
    PK.TrieuChung AS N'Triệu chứng',
    PK.ChanDoan AS N'Chẩn đoán',
    MH.TenMatHang AS N'Tên thuốc',
    CTDT.SoLuong AS N'Số lượng',
    CTDT.LieuLuong AS N'Liều lượng',
    NV_User.HoTen AS N'Bác sĩ phụ trách'
FROM PHIEU_KHAM_BENH_NoIndex PK
	JOIN PHIEU_DICH_VU_NoIndex PDV ON PK.MaPhieu = PDV.MaPhieu
	-- Lấy thông tin Bác sĩ
	JOIN NHAN_VIEN_NoIndex NV ON PDV.MaNV = NV.MaNV
	JOIN [USER_NoIndex] NV_User ON NV.MaNV = NV_User.MaUser
	-- Lấy chi tiết đơn thuốc (Nếu có kê thuốc)
	LEFT JOIN CT_DON_THUOC_NoIndex CTDT ON PK.MaPhieu = CTDT.MaPhieu
	LEFT JOIN THUOC_NoIndex T ON CTDT.MaThuoc = T.MaThuoc
	LEFT JOIN MAT_HANG_NoIndex MH ON T.MaThuoc = MH.MaMatHang
WHERE 
    PK.MaTC = @MaThuCung
ORDER BY PDV.TG_ThucHienDV DESC
GO

-- =================================================================================
-- TV8: Xem lịch sử tiêm phòng của một thú cưng
-- =================================================================================
-- Cài đặt index
-- 1.
CREATE NONCLUSTERED INDEX IX_CT_TIEM_VC_MaPhieu_T8
ON [dbo].[CT_TIEM_VC] ([MaPhieu])
INCLUDE ([NhacLai], [LieuLuong]);
GO
-- 2.
CREATE NONCLUSTERED INDEX IX_PHIEU_TIEM_VACCINE_MaTC_T8
ON [dbo].[PHIEU_TIEM_VACCINE] ([MaTC]);
GO
-- 3.
CREATE NONCLUSTERED INDEX IX_PHIEU_TIEM_VACCINE_MaPhieu_T8
ON [dbo].[PHIEU_TIEM_VACCINE] ([MaPhieu]);
GO

DROP INDEX IX_PHIEU_TIEM_VACCINE_MaTC_T8 ON PHIEU_TIEM_VACCINE;
DROP INDEX IX_CT_TIEM_VC_MaPhieu_T8 ON CT_TIEM_VC;
DROP INDEX IX_PHIEU_TIEM_VACCINE_MaPhieu_T8 ON PHIEU_TIEM_VACCINE;

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Có index
DECLARE @MaThuCung nchar(10) = 'TC34091';

SELECT 
    PDV.TG_ThucHienDV AS N'Ngày tiêm',
    MH.TenMatHang AS N'Tên vaccine',
    CTTV.LieuLuong AS N'Liều lượng',
    CASE CTTV.NhacLai 
        WHEN 1 THEN N'Tiêm nhắc lại (Gói)' 
        ELSE N'Tiêm lẻ / Mới' 
    END AS N'Loại mũi tiêm',
    NV_User.HoTen AS N'Bác sĩ phụ trách'
FROM PHIEU_TIEM_VACCINE PTV
	JOIN PHIEU_DICH_VU PDV ON PTV.MaPhieu = PDV.MaPhieu
	-- Lấy thông tin bác sĩ tiêm
	JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
	JOIN [USER] NV_User ON NV.MaNV = NV_User.MaUser
	-- Lấy chi tiết mũi tiêm
	JOIN CT_TIEM_VC CTTV ON PTV.MaPhieu = CTTV.MaPhieu
	JOIN VACCINE VC ON CTTV.MaVaccine = VC.MaVaccine
	JOIN MAT_HANG MH ON VC.MaVaccine = MH.MaMatHang
WHERE 
    PTV.MaTC = @MaThuCung
ORDER BY PDV.TG_ThucHienDV DESC
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM

-- Không index
DECLARE @MaThuCung nchar(10) = 'TC34091';

SELECT 
    PDV.TG_ThucHienDV AS N'Ngày tiêm',
    MH.TenMatHang AS N'Tên vaccine',
    CTTV.LieuLuong AS N'Liều lượng',
    CASE CTTV.NhacLai 
        WHEN 1 THEN N'Tiêm nhắc lại (Gói)' 
        ELSE N'Tiêm lẻ / Mới' 
    END AS N'Loại mũi tiêm',
    NV_User.HoTen AS N'Bác sĩ phụ trách'
FROM PHIEU_TIEM_VACCINE_NoIndex PTV
	JOIN PHIEU_DICH_VU_NoIndex PDV ON PTV.MaPhieu = PDV.MaPhieu
	-- Lấy thông tin bác sĩ tiêm
	JOIN NHAN_VIEN_NoIndex NV ON PDV.MaNV = NV.MaNV
	JOIN [USER_NoIndex] NV_User ON NV.MaNV = NV_User.MaUser
	-- Lấy chi tiết mũi tiêm
	JOIN CT_TIEM_VC_NoIndex CTTV ON PTV.MaPhieu = CTTV.MaPhieu
	JOIN VACCINE_NoIndex VC ON CTTV.MaVaccine = VC.MaVaccine
	JOIN MAT_HANG_NoIndex MH ON VC.MaVaccine = MH.MaMatHang
WHERE 
    PTV.MaTC = @MaThuCung
ORDER BY PDV.TG_ThucHienDV DESC
GO

SELECT 
    t.name AS [Tên Bảng],
    i.name AS [Tên Index],
    i.type_desc AS [Loại Index],
    CASE 
        WHEN i.is_primary_key = 1 THEN 'Khoa Chinh (PK)'
        WHEN i.is_unique = 1 THEN 'Duy Nhat (Unique)'
        ELSE 'Thuong'
    END AS [Ghi Chu]
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL -- Loại bỏ các bảng chưa có index (Heap)
ORDER BY t.name, i.name;
