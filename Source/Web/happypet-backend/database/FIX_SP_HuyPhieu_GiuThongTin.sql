-- Chỉ chạy 2 SP liên quan đến hủy phiếu
USE HAPPYPET
GO

-- SP 1: Khách hàng tự hủy
CREATE OR ALTER PROCEDURE sp_HuyLichHen
    @MaPhieu NCHAR(10),
    @MaKH NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION CƠ BẢN
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Phiếu hẹn không tồn tại hoặc bạn không có quyền hủy phiếu này!', 16, 1);
        RETURN;
    END

    -- Lấy thông tin phiếu
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaCN NCHAR(10);
    DECLARE @TG_ThucHienDV DATETIME; 

    SELECT 
        @TrangThai = TrangThai, 
        @MaCN = MaCN,
        @TG_ThucHienDV = TG_ThucHienDV
    FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- Kiểm tra trạng thái
    IF @TrangThai <> 'DD'
    BEGIN
        RAISERROR(N'Lỗi: Không thể hủy phiếu đang thực hiện hoặc đã hoàn thành/đã hủy!', 16, 1);
        RETURN;
    END

    IF DATEADD(HOUR, 2, GETDATE()) > @TG_ThucHienDV
    BEGIN
        RAISERROR(N'Lỗi: Đã sát giờ hẹn (dưới 2 tiếng). Bạn không thể hủy lúc này, vui lòng liên hệ hotline!', 16, 1);
        RETURN;
    END

    -- 2. XỬ LÝ LOGIC HOÀN TRẢ (TRANSACTION)
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- ❌ KHÔNG HOÀN KHO vì phiếu DD chưa lấy hàng từ kho
        -- ❌ KHÔNG XÓA CT_TIEM_VC vì cần giữ lịch sử đã đăng ký (chưa tiêm thật)
        
        -- Chỉ xóa đăng ký gói tiêm (nếu có)
        DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @MaPhieu;

        -- ✅ GIỮ LẠI PHIEU_KHAM_BENH và PHIEU_TIEM_VACCINE để lưu thông tin thú cưng
        
        -- Cập nhật trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DH' -- Đã Hủy
        WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã sửa SP sp_HuyLichHen - Giữ lại thông tin thú cưng khi hủy phiếu';
GO

-- SP 2: Hệ thống tự động hủy
CREATE OR ALTER PROCEDURE sp_TuDongHuyLichHen
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @SoLuongHuy INT = 0;

    -- 1. LẤY DANH SÁCH CÁC PHIẾU CẦN HỦY
    DECLARE @ListOverdue TABLE (
        MaPhieu NCHAR(10), 
        MaKH NCHAR(10), 
        MaCN NCHAR(10)
    );

    INSERT INTO @ListOverdue (MaPhieu, MaKH, MaCN)
    SELECT MaPhieu, MaKH, MaCN
    FROM PHIEU_DICH_VU
    WHERE TrangThai = 'DD' 
      AND TG_ThucHienDV < DATEADD(MINUTE, -120, GETDATE());

    -- Nếu không có phiếu nào thì thoát nhanh
    IF NOT EXISTS (SELECT 1 FROM @ListOverdue)
    BEGIN
        SELECT 0 AS SoPhieuDaHuyTuDong;
        RETURN;
    END

    -- 2. DUYỆT QUA TỪNG PHIẾU ĐỂ XỬ LÝ
    DECLARE @Cur_MaPhieu NCHAR(10);
    DECLARE @Cur_MaKH NCHAR(10);
    DECLARE @Cur_MaCN NCHAR(10);

    DECLARE cur_AutoHuy CURSOR FOR 
    SELECT MaPhieu, MaKH, MaCN FROM @ListOverdue;

    OPEN cur_AutoHuy;
    FETCH NEXT FROM cur_AutoHuy INTO @Cur_MaPhieu, @Cur_MaKH, @Cur_MaCN;

    WHILE @@FETCH_STATUS = 0
    BEGIN
        BEGIN TRANSACTION;
        BEGIN TRY
            
            -- ❌ KHÔNG HOÀN KHO vì phiếu DD chưa lấy hàng từ kho
            -- ❌ KHÔNG XÓA CT_TIEM_VC vì cần giữ lịch sử đã đăng ký (chưa tiêm thật)
            
            -- Chỉ xóa đăng ký gói tiêm (nếu có)
            DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @Cur_MaPhieu;

            -- ✅ GIỮ LẠI PHIEU_KHAM_BENH và PHIEU_TIEM_VACCINE để lưu thông tin thú cưng
            
            UPDATE PHIEU_DICH_VU
            SET TrangThai = 'DH'
            WHERE MaPhieu = @Cur_MaPhieu;

            SET @SoLuongHuy = @SoLuongHuy + 1;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            PRINT N'Lỗi khi hủy tự động phiếu ' + @Cur_MaPhieu + ': ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM cur_AutoHuy INTO @Cur_MaPhieu, @Cur_MaKH, @Cur_MaCN;
    END

    CLOSE cur_AutoHuy;
    DEALLOCATE cur_AutoHuy;

    SELECT @SoLuongHuy AS SoPhieuDaHuyTuDong;
END;
GO

PRINT N'✅ Đã sửa SP sp_TuDongHuyLichHen - Giữ lại thông tin thú cưng khi hệ thống tự hủy';
