-- ============================================
-- SP THÊM VACCINE LẺ (KHÔNG THEO GÓI)
-- Dùng khi khách muốn tiêm vaccine lẻ, tính tiền đầy đủ
-- ============================================
USE HAPPYPET
GO

CREATE OR ALTER PROC sp_BacSi_ThemVaccineLe
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Lấy MaTC từ phiếu
        DECLARE @MaTC NCHAR(10);
        SELECT @MaTC = MaTC FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @MaPhieu;
        
        IF @MaTC IS NULL
        BEGIN
            RAISERROR(N'Phiếu chưa có thú cưng!', 16, 1);
            RETURN;
        END
        
        -- 2. Check xem vaccine này có thuộc gói đang dở không?
        DECLARE @MaGoi NCHAR(10);
        DECLARE @SoMuiDaTiem INT;
        DECLARE @TongSoMui INT;
        
        SELECT TOP 1 
            @MaGoi = DK.MaGoi,
            @SoMuiDaTiem = (
                SELECT COUNT(*) 
                FROM CT_TIEM_VC CT
                INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
                INNER JOIN DANG_KI_GOI_TIEM DK2 ON CT.MaPhieu = DK2.MaPhieu 
                    AND CT.MaVaccine = DK2.MaVaccine
                    AND DK2.MaGoi = DK.MaGoi
                WHERE PTV.MaTC = @MaTC
            ),
            @TongSoMui = GOI.SoMuiTuongUng
        FROM DANG_KI_GOI_TIEM DK
        INNER JOIN GOI_TIEM_VC GOI ON DK.MaGoi = GOI.MaGoi
        INNER JOIN PHIEU_TIEM_VACCINE PTV ON DK.MaPhieu = PTV.MaPhieu
        WHERE PTV.MaTC = @MaTC
          AND DK.MaVaccine = @MaVaccine
          AND DK.HieuLuc = 1
          AND (DK.NgayHetHan IS NULL OR DK.NgayHetHan > GETDATE())
          AND GOI.SoMuiTuongUng > (
              SELECT COUNT(*) 
              FROM CT_TIEM_VC CT
              INNER JOIN DANG_KI_GOI_TIEM DK2 ON CT.MaPhieu = DK2.MaPhieu 
                  AND CT.MaVaccine = DK2.MaVaccine
                  AND DK2.MaGoi = DK.MaGoi
              INNER JOIN PHIEU_TIEM_VACCINE PTV2 ON CT.MaPhieu = PTV2.MaPhieu
              WHERE PTV2.MaTC = @MaTC
          )
        ORDER BY DK.MaPhieu DESC;
        
        -- 3. Tính giá và NhacLai
        DECLARE @Gia MONEY;
        DECLARE @GiamGia MONEY;
        DECLARE @ThanhTien MONEY;
        DECLARE @NhacLai BIT;
        DECLARE @LieuLuong NVARCHAR(70);
        
        SELECT @Gia = DonGia FROM MAT_HANG WHERE MaMatHang = @MaVaccine;
        
        IF @Gia IS NULL
        BEGIN
            RAISERROR(N'Không tìm thấy vaccine!', 16, 1);
            RETURN;
        END
        
        IF @MaGoi IS NOT NULL
        BEGIN
            -- CÓ GÓI DỞ → Tiêm tiếp gói
            SET @NhacLai = 1;
            SET @LieuLuong = N'Mũi ' + CAST(@SoMuiDaTiem + 1 AS NVARCHAR(10));
            
            SELECT @GiamGia = GiamGia FROM GOI_TIEM_VC WHERE MaGoi = @MaGoi;
            
            IF @SoMuiDaTiem = 0
                SET @ThanhTien = @Gia - @GiamGia; -- Mũi đầu
            ELSE
                SET @ThanhTien = 0; -- Mũi 2+ miễn phí
                
            -- Thêm vào CT_TIEM_VC
            INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, LieuLuong, ThanhTien, NhacLai)
            VALUES (@MaVaccine, @MaPhieu, @LieuLuong, @ThanhTien, 1);
            
            -- Thêm vào DANG_KI_GOI_TIEM để link với gói
            INSERT INTO DANG_KI_GOI_TIEM (MaPhieu, MaVaccine, MaGoi, NgayHetHan, HieuLuc, ThanhTien)
            SELECT @MaPhieu, @MaVaccine, @MaGoi, NgayHetHan, 1, @ThanhTien
            FROM DANG_KI_GOI_TIEM
            WHERE MaGoi = @MaGoi AND MaVaccine = @MaVaccine AND HieuLuc = 1
            GROUP BY NgayHetHan;
        END
        ELSE
        BEGIN
            -- KHÔNG CÓ GÓI → Vaccine lẻ
            SET @NhacLai = 0;
            SET @ThanhTien = @Gia;
            SET @LieuLuong = N'1 mũi';
            
            INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, LieuLuong, ThanhTien, NhacLai)
            VALUES (@MaVaccine, @MaPhieu, @LieuLuong, @ThanhTien, 0);
        END
        
        COMMIT TRANSACTION;
        
        SELECT 
            @MaVaccine AS MaVaccine,
            @ThanhTien AS ThanhTien,
            @NhacLai AS NhacLai,
            @MaGoi AS MaGoi,
            CASE WHEN @MaGoi IS NOT NULL THEN N'Đã thêm vào gói' ELSE N'Đã thêm vaccine lẻ' END AS Message;
            
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã tạo SP sp_BacSi_ThemVaccineLe'
GO
