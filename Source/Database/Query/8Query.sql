USE HAPPYPET
GO

-- T1: Tra cứu danh sách thú cưng đến hẹn tái khám
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


-- T2: Tra cứu sản phẩm (theo Tên/Loại) của một chi nhánh
DECLARE @MaCN NCHAR(10) = 'CN01';
DECLARE @TuKhoa NVARCHAR(80) = N'Trị'; -- Nhập tên để tìm (hoặc NULL)
DECLARE @LoaiMH VARCHAR(3) = 'T';   -- Nhập mã loại: 'T', 'VC', 'SPK'

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

-- T3: Tra cứu Phiếu dịch vụ trong ngày của một chi nhánh (Lọc theo Ngày & Mã CN)
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

-- TV4: Nhân viên update trạng thái của một Phiếu Dịch Vụ
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


-- T5: Thống kê doanh thu theo tháng của từng chi nhánh theo từng loại dịch vụ
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

-- T6: Báo cáo hàng tồn kho, cảnh báo nhập hàng của một chi nhánh
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

-- T7: Xem lịch sử khám bệnh của một thú cưng
DECLARE @MaThuCung nchar(10) = 'TC00022';

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

-- T8: Xem lịch sử tiêm phòng của một thú cưng
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
