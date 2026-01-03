-- ============================================
-- SP THÊM VACCINE VÀO GÓI ĐANG TIÊM (MŨI TIẾP THEO)
-- Tự động tính số mũi đã tiêm, set NhacLai, tính giá
-- ============================================
USE HAPPYPET
GO

CREATE OR ALTER PROC sp_ThemVaccineVaoGoiDangTiem
    @MaPhieu NCHAR(10),
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Tìm gói đang tiêm
        DECLARE @MaGoi NCHAR(10);
        DECLARE @MaVaccine NCHAR(10);
        DECLARE @TongSoMui INT;
        DECLARE @SoMuiDaTiem INT;
        
        SELECT TOP 1
            @MaGoi = DK.MaGoi,
            @MaVaccine = DK.MaVaccine,
            @TongSoMui = GOI.SoMuiTuongUng,
            @SoMuiDaTiem = (
                SELECT COUNT(*) 
                FROM CT_TIEM_VC CT
                INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
                INNER JOIN DANG_KI_GOI_TIEM DK2 ON CT.MaPhieu = DK2.MaPhieu 
                    AND CT.MaVaccine = DK2.MaVaccine
                    AND DK2.MaGoi = DK.MaGoi
                WHERE PTV.MaTC = @MaTC
            )
        FROM DANG_KI_GOI_TIEM DK
        INNER JOIN GOI_TIEM_VC GOI ON DK.MaGoi = GOI.MaGoi
        INNER JOIN PHIEU_TIEM_VACCINE PTV ON DK.MaPhieu = PTV.MaPhieu
        WHERE PTV.MaTC = @MaTC
          AND DK.HieuLuc = 1
          AND (DK.NgayHetHan IS NULL OR DK.NgayHetHan > GETDATE())
        ORDER BY DK.MaPhieu DESC;
        
        IF @MaGoi IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy gói đang tiêm!', 16, 1);
            RETURN;
        END
        
        -- 2. Check đã tiêm đủ chưa
        IF @SoMuiDaTiem >= @TongSoMui
        BEGIN
            RAISERROR(N'Gói này đã tiêm đủ số mũi!', 16, 1);
            RETURN;
        END
        
        -- 3. Tính giá: Mũi 1 = giá gói giảm, mũi 2+ = 0đ
        DECLARE @GiaGoc MONEY;
        DECLARE @GiamGia MONEY;
        DECLARE @ThanhTien MONEY;
        
        SELECT @GiaGoc = DonGia FROM MAT_HANG WHERE MaMatHang = @MaVaccine;
        SELECT @GiamGia = GiamGia FROM GOI_TIEM_VC WHERE MaGoi = @MaGoi;
        
        IF @SoMuiDaTiem = 0
            SET @ThanhTien = @GiaGoc - @GiamGia; -- Mũi đầu tiên
        ELSE
            SET @ThanhTien = 0; -- Mũi 2, 3, ... = miễn phí
        
        -- 4. Thêm vaccine vào CT_TIEM_VC với NhacLai = 1
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, LieuLuong, ThanhTien, NhacLai)
        VALUES (@MaVaccine, @MaPhieu, N'Mũi ' + CAST(@SoMuiDaTiem + 1 AS NVARCHAR(10)), @ThanhTien, 1);
        
        -- 5. KHÔNG CẦN INSERT vào DANG_KI_GOI_TIEM vì đã có rồi từ lúc mua gói
        -- Chỉ cần link qua CT_TIEM_VC là đủ để đếm số mũi
        
        COMMIT TRANSACTION;
        
        -- Trả về thông tin
        SELECT 
            @MaVaccine AS MaVaccine,
            @MaGoi AS MaGoi,
            @SoMuiDaTiem + 1 AS SoMuiHienTai,
            @TongSoMui AS TongSoMui,
            @ThanhTien AS ThanhTien,
            N'Đã thêm mũi ' + CAST(@SoMuiDaTiem + 1 AS NVARCHAR(10)) AS Message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã tạo SP sp_ThemVaccineVaoGoiDangTiem'
GO
