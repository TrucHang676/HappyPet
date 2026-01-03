-- ============================================
-- SCRIPT FIX: CẬP NHẬT SP VÀ DỮ LIỆU
-- ============================================
USE HAPPYPET
GO

PRINT N'🔧 BẮT ĐẦU CẬP NHẬT...'
GO

-- 1️⃣ CẬP NHẬT SP sp_LayDanhSachDatLich (Thêm field PhuongThucTT)
PRINT N'📝 Cập nhật SP sp_LayDanhSachDatLich...'
GO

CREATE OR ALTER PROC sp_LayDanhSachDatLich
    @MaCN NCHAR(10),
    @TuNgay DATE,
    @DenNgay DATE,
    @TrangThai VARCHAR(5) = NULL,
    @MaNV_Xem NCHAR(10) = NULL,   
    @Role_Xem NVARCHAR(50) = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        RTRIM(P.MaPhieu) AS MaPhieu,
        CONVERT(VARCHAR(23), P.TG_LapPhieu, 121) AS TG_LapPhieu,
        CONVERT(VARCHAR(23), P.TG_ThucHienDV, 121) AS TG_ThucHienDV,               
        RTRIM(P.MaNV) AS MaNV,
        U.HoTen AS TenKhachHang,       
        TC.Ten AS TenThuCung,
        CASE RTRIM(P.LoaiPhieu)
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            ELSE N'Dịch vụ khác'
        END AS LoaiDichVu,
        RTRIM(ISNULL(P.TrangThai, 'DD')) AS TrangThai,
        KH.SDT,
        HTT.DiaChiGiaoHang AS DiaChi,
        HTT.TongThanhTien AS TongThanhTien,
        HTT.MaPhieu AS MaHD,
        HDTT.PhuongThucTT AS PhuongThucTT, -- 🔥 FIELD MỚI
        U_BacSi.HoTen AS TenBacSi
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN [USER] U_BacSi ON P.MaNV = U_BacSi.MaUser
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HDTT ON P.MaPhieu = HDTT.MaPhieu -- 🔥 JOIN MỚI
    WHERE P.MaCN = @MaCN 
      AND (@TrangThai IS NULL OR RTRIM(P.TrangThai) = @TrangThai)
      AND CAST(P.TG_ThucHienDV AS DATE) BETWEEN @TuNgay AND @DenNgay 
      AND (
          (RTRIM(@Role_Xem) IN (N'Nhân viên Tiếp tân', N'Nhân viên bán hàng', N'Quản lý chi nhánh', N'Admin'))
          OR 
          (RTRIM(P.MaNV) = RTRIM(@MaNV_Xem))
      )
    ORDER BY P.TG_ThucHienDV ASC
END;
GO

PRINT N'✅ Đã cập nhật SP sp_LayDanhSachDatLich'
GO

-- 2️⃣ CẬP NHẬT SP sp_BacSi_ThemGoiTiem (Fix giá mũi 1 = 0đ)
PRINT N'📝 Cập nhật SP sp_BacSi_ThemGoiTiem...'
GO

-- Tìm và chạy lại file sp_Kham_Benh-Tiem_VC.sql để update toàn bộ
-- HOẶC chạy script riêng:

CREATE OR ALTER PROC sp_BacSi_ThemGoiTiem
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10),
    @MaGoi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không tồn tại hoặc chưa check-in (Phải là DTH)!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    IF ISNULL(@TonKho, 0) < 1
    BEGIN
        RAISERROR(N'Lỗi: Vaccine này đã hết hàng trong kho!', 16, 1);
        RETURN;
    END

    DECLARE @DonGiaVC DECIMAL(18,2);
    DECLARE @GiamGia DECIMAL(18,2); 
    DECLARE @SoMuiTuongUng INT;
    DECLARE @ThoiHan INT;
    DECLARE @ThanhTienGoi DECIMAL(18,2);
    DECLARE @NgayHetHan DATE;

    SELECT @DonGiaVC = DonGia FROM VACCINE WHERE MaVaccine = @MaVaccine;
    
    SELECT @GiamGia = GiamGia, 
           @SoMuiTuongUng = SoMuiTuongUng, 
           @ThoiHan = ThoiHan 
    FROM GOI_TIEM_VC WHERE MaGoi = @MaGoi;

    SET @ThanhTienGoi = @DonGiaVC * ISNULL(@SoMuiTuongUng, 1) * (1.0 - ISNULL(@GiamGia, 0));
    IF @ThanhTienGoi < 0 SET @ThanhTienGoi = 0;

    SET @NgayHetHan = DATEADD(MONTH, ISNULL(@ThoiHan, 0), GETDATE());

    BEGIN TRANSACTION;
    BEGIN TRY
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        INSERT INTO DANG_KI_GOI_TIEM (MaPhieu, MaVaccine, MaGoi, NgayHetHan, HieuLuc, ThanhTien)
        VALUES (@MaPhieu, @MaVaccine, @MaGoi, @NgayHetHan, 1, @ThanhTienGoi);

        -- 🔥 MŨI 1 TRẢ TIỀN GÓI (giá gói), từ mũi 2 trở đi mới miễn phí (0đ)
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, NhacLai, LieuLuong, ThanhTien)
        VALUES (@MaVaccine, @MaPhieu, 0, N'Mũi 1/'+CAST(@SoMuiTuongUng AS NVARCHAR(5)), @ThanhTienGoi);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã cập nhật SP sp_BacSi_ThemGoiTiem'
GO

PRINT N'✅ HOÀN TẤT CẬP NHẬT!'
PRINT N''
PRINT N'📌 LƯU Ý:'
PRINT N'   - Reload lại trang Employee Dashboard để thấy thay đổi'
PRINT N'   - Nếu vẫn thấy "Đã xuất hóa đơn" sai, check console.log xem PhuongThucTT trả về gì'
GO
