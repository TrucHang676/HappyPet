-- ============================================
-- SP TẠO PHIẾU VÃNG LAI VỚI THÔNG TIN ĐẦY ĐỦ
-- ============================================
USE HAPPYPET
GO

CREATE OR ALTER PROC sp_TaoPhieuVangLai_Full
    @SDT NVARCHAR(15),
    @HoTen NVARCHAR(50),
    @GioiTinhUser NVARCHAR(3) = N'Nam',
    @DiaChi NVARCHAR(100),
    @TenTC NVARCHAR(50),
    @Loai NVARCHAR(30),
    @Giong NVARCHAR(30) = N'Chưa rõ',
    @GioiTinh NVARCHAR(3) = N'Đực',
    @NgSinh DATE = NULL,
    @TinhTrangSucKhoe NVARCHAR(50) = N'Bình thường',
    @MaCN NCHAR(10),
    @MaNV NCHAR(10),
    @LoaiPhieu VARCHAR(2),
    @TrieuChung NVARCHAR(200) = ''
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    DECLARE @MaKH NCHAR(10);
    DECLARE @MaTC NCHAR(10);
    DECLARE @MaPhieu NCHAR(10);
    
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. KIỂM TRA & TẠO KHÁCH HÀNG (nếu chưa có)
        SELECT @MaKH = MaKH 
        FROM KHACH_HANG 
        WHERE SDT = @SDT;
        
        IF @MaKH IS NULL
        BEGIN
            -- Tạo mã KH mới
            DECLARE @MaxKH INT;
            SELECT @MaxKH = ISNULL(MAX(CAST(SUBSTRING(MaKH, 3, 8) AS INT)), 0) 
            FROM KHACH_HANG;
            
            SET @MaKH = 'KH' + RIGHT('00000000' + CAST(@MaxKH + 1 AS VARCHAR(8)), 8);
            
            -- Tạo USER với giới tính từ form
            INSERT INTO [USER] (MaUser, HoTen, GioiTinh, LoaiUser)
            VALUES (@MaKH, @HoTen, @GioiTinhUser, 'KH');
            
            -- Tạo KHACH_HANG
            INSERT INTO KHACH_HANG (MaKH, SDT, TongDiemTichLuy)
            VALUES (@MaKH, @SDT, 0);
        END
        ELSE
        BEGIN
            -- Update tên nếu thiếu
            UPDATE [USER]
            SET HoTen = ISNULL(NULLIF(HoTen, ''), @HoTen)
            WHERE MaUser = @MaKH;
        END
        
        -- 2. TẠO THÚ CƯNG MỚI
        DECLARE @MaxTC INT;
        SELECT @MaxTC = ISNULL(MAX(CAST(SUBSTRING(MaTC, 3, 8) AS INT)), 0) 
        FROM THU_CUNG;
        
        SET @MaTC = 'TC' + RIGHT('00000000' + CAST(@MaxTC + 1 AS VARCHAR(8)), 8);
        
        -- Set default cho NgSinh nếu NULL (bắt buộc NOT NULL)
        IF @NgSinh IS NULL
            SET @NgSinh = DATEADD(YEAR, -1, GETDATE()); -- Default: 1 năm tuổi
        
        INSERT INTO THU_CUNG (MaTC, Ten, Loai, Giong, NgSinh, GioiTinh, TinhTrangSucKhoe, MaKH)
        VALUES (@MaTC, @TenTC, @Loai, @Giong, @NgSinh, @GioiTinh, @TinhTrangSucKhoe, @MaKH);
        
        -- 3. TẠO PHIẾU DỊCH VỤ
        DECLARE @MaxPhieu INT;
        SELECT @MaxPhieu = ISNULL(MAX(CAST(SUBSTRING(MaPhieu, 2, 9) AS INT)), 0) 
        FROM PHIEU_DICH_VU;
        
        SET @MaPhieu = 'P' + RIGHT('000000000' + CAST(@MaxPhieu + 1 AS VARCHAR(9)), 9);
        
        INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_LapPhieu, TG_ThucHienDV, MaKH, MaCN, MaNV, LoaiPhieu, TrangThai)
        VALUES (@MaPhieu, GETDATE(), GETDATE(), @MaKH, @MaCN, NULL, @LoaiPhieu, 'DD');
        
        -- 4. TẠO PHIẾU CON (Khám bệnh hoặc Tiêm vaccine)
        IF @LoaiPhieu = 'KB'
        BEGIN
            INSERT INTO PHIEU_KHAM_BENH (MaPhieu, MaTC, TrieuChung, ChanDoan, NgayHenTaiKham)
            VALUES (@MaPhieu, @MaTC, @TrieuChung, NULL, NULL);
        END
        ELSE IF @LoaiPhieu = 'TV'
        BEGIN
            INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC)
            VALUES (@MaPhieu, @MaTC);
        END
        
        COMMIT TRANSACTION;
        
        -- Trả về thông tin
        SELECT 
            @MaPhieu AS MaPhieuMoi,
            @MaKH AS MaKH,
            @MaTC AS MaTC,
            @HoTen AS TenKhachHang,
            @TenTC AS TenThuCung;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã tạo SP sp_TaoPhieuVangLai_Full'
GO
