USE [HAPPYPET]
GO
/****** Object:  StoredProcedure [dbo].[sp_App_ChonGoiTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2. Đối với đặt lịch hẹn cho dịch vụ tiêm thì KH phải chọn thêm VC/gói VC
-- 2.1 Chọn gói tiêm mới
CREATE   PROC [dbo].[sp_App_ChonGoiTiem]
    @MaPhieu NCHAR(10),
    @MaKH NCHAR(10), -- Bắt buộc check chủ sở hữu
    @MaVaccine NCHAR(10),
    @MaGoi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    -- Check phiếu tồn tại, đúng chủ, trạng thái 'DD' (Chưa check-in)
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND MaKH = @MaKH AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu hẹn không hợp lệ hoặc không thuộc về bạn!', 16, 1);
        RETURN;
    END

    -- Check tồn kho (Phải còn ít nhất 1 liều để giữ chỗ)
    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    IF ISNULL(@TonKho, 0) < 1
    BEGIN
        RAISERROR(N'Lỗi: Vaccine này hiện đã hết hàng tại chi nhánh đã chọn!', 16, 1);
        RETURN;
    END

    -- 2. TÍNH TOÁN GIÁ GÓI
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

    -- Công thức: Đơn giá * Số mũi * (1 - Giảm giá)
    SET @ThanhTienGoi = @DonGiaVC * ISNULL(@SoMuiTuongUng, 1) * (1.0 - ISNULL(@GiamGia, 0));
    IF @ThanhTienGoi < 0 SET @ThanhTienGoi = 0;

    -- Tính ngày hết hạn (Dự kiến từ ngày đặt)
    SET @NgayHetHan = DATEADD(MONTH, ISNULL(@ThoiHan, 0), GETDATE());

    -- 3. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ kho (Giữ 1 liều cho mũi tiêm đầu tiên)
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B2: Insert vào Bảng Đăng Ký Gói
        -- Lưu giá gói vào đây để record
        INSERT INTO DANG_KI_GOI_TIEM (MaPhieu, MaVaccine, MaGoi, NgayHetHan, HieuLuc, ThanhTien)
        VALUES (@MaPhieu, @MaVaccine, @MaGoi, @NgayHetHan, 1, @ThanhTienGoi);

        -- B3: Insert vào Chi Tiết Tiêm (Mũi 1)
        -- Lưu giá trọn gói vào đây để tiện tính tổng tiền sau này
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, NhacLai, LieuLuong, ThanhTien)
        VALUES (@MaVaccine, @MaPhieu, 0, N'1 mũi', @ThanhTienGoi);

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_App_ChonVaccineLe]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.2 Tiêm lẻ hoặc tiêm nhắc lại
CREATE   PROC [dbo].[sp_App_ChonVaccineLe]
    @MaPhieu NCHAR(10),
    @MaKH NCHAR(10), 
    @MaVaccine NCHAR(10),
    @TheoGoi BIT = 0 -- 0: Mua lẻ, 1: Dùng gói có sẵn
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND MaKH = @MaKH AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu hẹn không hợp lệ hoặc không thuộc về bạn!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    IF ISNULL(@TonKho, 0) < 1
    BEGIN
        RAISERROR(N'Lỗi: Vaccine này hiện đã hết hàng tại chi nhánh đã chọn!', 16, 1);
        RETURN;
    END

    -- 2. XỬ LÝ LOGIC GIÁ & GÓI
    DECLARE @ThanhTien DECIMAL(18,2) = 0;
    
    -- Các biến xử lý gói
    DECLARE @MaPhieuDangKyGoi NCHAR(10);
    DECLARE @MaGoiDangKy NCHAR(10);
    DECLARE @SoMuiQuyDinh INT;
    DECLARE @NgayDangKyGoi DATETIME;

    IF @TheoGoi = 0 
    BEGIN
        -- TRƯỜNG HỢP 1: Mua lẻ -> Lấy đơn giá vaccine
        SELECT @ThanhTien = DonGia FROM VACCINE WHERE MaVaccine = @MaVaccine;
    END
    ELSE 
    BEGIN
        -- TRƯỜNG HỢP 2: Dùng gói -> Giá = 0, Kiểm tra hiệu lực
        
        -- A. Tìm gói khả dụng
        SELECT TOP 1 
            @MaPhieuDangKyGoi = DK.MaPhieu,
            @MaGoiDangKy = DK.MaGoi,
            @SoMuiQuyDinh = G.SoMuiTuongUng,
            @NgayDangKyGoi = P_DK.TG_LapPhieu
        FROM DANG_KI_GOI_TIEM DK
        JOIN PHIEU_DICH_VU P_DK ON DK.MaPhieu = P_DK.MaPhieu
        JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
        WHERE P_DK.MaKH = @MaKH 
          AND DK.MaVaccine = @MaVaccine 
          AND DK.HieuLuc = 1
          AND DK.NgayHetHan >= CAST(GETDATE() AS DATE)
        ORDER BY DK.NgayHetHan ASC;

        IF @MaPhieuDangKyGoi IS NULL
        BEGIN
            RAISERROR(N'Lỗi: Bạn không có gói tiêm khả dụng cho loại vaccine này!', 16, 1);
            RETURN;
        END

        -- B. Kiểm tra số mũi ĐÃ TIÊM (Tính cả lịch sử)
        DECLARE @SoMuiDaTiem INT;
        SELECT @SoMuiDaTiem = COUNT(*)
        FROM CT_TIEM_VC CT
        JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
        WHERE P.MaKH = @MaKH 
          AND CT.MaVaccine = @MaVaccine
          AND P.TG_LapPhieu >= @NgayDangKyGoi; 

        IF @SoMuiDaTiem >= @SoMuiQuyDinh
        BEGIN
            -- Nếu đã dùng hết suất -> Đóng gói luôn
            UPDATE DANG_KI_GOI_TIEM 
            SET HieuLuc = 0 
            WHERE MaPhieu = @MaPhieuDangKyGoi AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDangKy;
            
            RAISERROR(N'Lỗi: Gói tiêm của bạn đã sử dụng hết số mũi quy định!', 16, 1);
            RETURN;
        END

        SET @ThanhTien = 0; -- Free
    END

    -- 3. TÍNH SỐ MŨI (Nếu theo gói thì tính, nếu lẻ thì để "1 liều")
    DECLARE @LieuLuongText NVARCHAR(50);
    
    IF @TheoGoi = 1
    BEGIN
        -- Tính số mũi ĐÃ TIÊM (bao gồm lịch sử)
        DECLARE @SoMuiDaTiem_Current INT;
        SELECT @SoMuiDaTiem_Current = COUNT(*)
        FROM CT_TIEM_VC CT
        JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
        WHERE P.MaKH = (SELECT MaKH FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu)
          AND CT.MaVaccine = @MaVaccine
          AND P.TG_LapPhieu >= @NgayDangKyGoi;
        
        -- Mũi tiếp theo = số mũi đã tiêm + 1
        DECLARE @SoMuiTiepTheo INT = ISNULL(@SoMuiDaTiem_Current, 0) + 1;
        
        -- Format: "Mũi 1/3", "Mũi 2/3"...
        SET @LieuLuongText = N'Mũi ' + CAST(@SoMuiTiepTheo AS NVARCHAR(5)) + N'/' + CAST(@SoMuiQuyDinh AS NVARCHAR(5));
    END
    ELSE
    BEGIN
        -- Mua lẻ thì để text đơn giản
        SET @LieuLuongText = N'1 liều';
    END

    -- 4. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ kho giữ chỗ
        UPDATE TON_KHO SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B2: Thêm vào chi tiết (Sử dụng LieuLuong đã tính)
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, NhacLai, LieuLuong, ThanhTien)
        VALUES (@MaVaccine, @MaPhieu, @TheoGoi, @LieuLuongText, @ThanhTien);

        -- B3: Cập nhật hiệu lực gói (Nếu đây là mũi cuối cùng)
        IF @TheoGoi = 1
        BEGIN
            DECLARE @TongMuiSauKhiDat INT;
            
            SELECT @TongMuiSauKhiDat = COUNT(*)
            FROM CT_TIEM_VC CT
            JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
            WHERE P.MaKH = @MaKH 
              AND CT.MaVaccine = @MaVaccine
              AND P.TG_LapPhieu >= @NgayDangKyGoi;

            IF @TongMuiSauKhiDat >= @SoMuiQuyDinh
            BEGIN
                UPDATE DANG_KI_GOI_TIEM 
                SET HieuLuc = 0 
                WHERE MaPhieu = @MaPhieuDangKyGoi AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDangKy;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_App_GetMasterVaccineData]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_App_GetMasterVaccineData]
AS
BEGIN
    -- Bảng 1: Vaccine
    SELECT V.MaVaccine, MH.TenMatHang as TenVaccine, V.DonGia 
    FROM VACCINE V
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang;

    -- Bảng 2: Gói tiêm
    SELECT * FROM GOI_TIEM_VC;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_App_GetSelectedVaccines]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_App_GetSelectedVaccines]
    @MaPhieu NCHAR(10)
AS
BEGIN
    SELECT CT.MaVaccine, MH.TenMatHang as TenVaccine, CT.ThanhTien, CT.NhacLai,
           DK.MaGoi, G.TenGoi
    FROM CT_TIEM_VC CT
    JOIN MAT_HANG MH ON CT.MaVaccine = MH.MaMatHang
    LEFT JOIN DANG_KI_GOI_TIEM DK ON CT.MaPhieu = DK.MaPhieu AND CT.MaVaccine = DK.MaVaccine
    LEFT JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
    WHERE CT.MaPhieu = @MaPhieu;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_App_XoaGoiTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.3 Xóa gói
CREATE   PROC [dbo].[sp_App_XoaGoiTiem]
    @MaPhieu NCHAR(10),
    @MaKH NCHAR(10),
    @MaVaccine NCHAR(10),
    @MaGoi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND MaKH = @MaKH AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu hẹn không hợp lệ!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine AND MaGoi = @MaGoi)
    BEGIN
        RAISERROR(N'Lỗi: Bạn chưa chọn gói tiêm này!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- 2. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Xóa thông tin Đăng Ký Gói
        DELETE FROM DANG_KI_GOI_TIEM 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine AND MaGoi = @MaGoi;

        -- B2: Xóa mũi tiêm đầu tiên đi kèm
        DELETE FROM CT_TIEM_VC 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine;

        -- B3: Hoàn kho (Trả lại 1 liều đã giữ chỗ)
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon + 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_App_XoaVaccineLe]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2.4 Xóa VC
CREATE   PROC [dbo].[sp_App_XoaVaccineLe]
    @MaPhieu NCHAR(10),
    @MaKH NCHAR(10),
    @MaVaccine NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND MaKH = @MaKH AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu hẹn không hợp lệ!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine)
    BEGIN
        RAISERROR(N'Lỗi: Bạn chưa chọn vaccine này!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- 2. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Xóa chi tiết tiêm
        DELETE FROM CT_TIEM_VC 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine;

        -- B2: Hoàn kho
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon + 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B3: [LOGIC HỒI PHỤC GÓI]
        -- Kiểm tra xem nếu vừa xóa mũi nhắc lại thì có cần mở lại gói không
        DECLARE @MaPhieuDK NCHAR(10);
        DECLARE @MaGoiDK NCHAR(10);
        DECLARE @SoMuiQuyDinh INT;
        DECLARE @NgayDangKy DATETIME;

        SELECT TOP 1 
            @MaPhieuDK = DK.MaPhieu,
            @MaGoiDK = DK.MaGoi,
            @SoMuiQuyDinh = G.SoMuiTuongUng,
            @NgayDangKy = P_DK.TG_LapPhieu
        FROM DANG_KI_GOI_TIEM DK
        JOIN PHIEU_DICH_VU P_DK ON DK.MaPhieu = P_DK.MaPhieu
        JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
        WHERE P_DK.MaKH = @MaKH 
          AND DK.MaVaccine = @MaVaccine 
          AND DK.NgayHetHan >= CAST(GETDATE() AS DATE)
        ORDER BY DK.NgayHetHan ASC;

        IF @MaPhieuDK IS NOT NULL
        BEGIN
            -- Đếm lại số mũi (sau khi xóa)
            DECLARE @SoMuiHienTai INT;
            SELECT @SoMuiHienTai = COUNT(*)
            FROM CT_TIEM_VC CT
            JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
            WHERE P.MaKH = @MaKH 
              AND CT.MaVaccine = @MaVaccine
              AND P.TG_LapPhieu >= @NgayDangKy;

            -- Nếu số mũi hiện tại < Quy định -> Mở lại hiệu lực gói
            IF @SoMuiHienTai < @SoMuiQuyDinh
            BEGIN
                UPDATE DANG_KI_GOI_TIEM
                SET HieuLuc = 1
                WHERE MaPhieu = @MaPhieuDK AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDK AND HieuLuc = 0;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_KetThucKham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Bác sĩ kết thúc khám 
CREATE   PROC [dbo].[sp_BacSi_KetThucKham]
    @MaPhieu NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    -- Chỉ được kết thúc khi phiếu đang ở trạng thái 'DTH' (Đang thực hiện)
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu này chưa được check-in hoặc đã kết thúc rồi!', 16, 1);
        RETURN;
    END

    -- 2. TÍNH TỔNG TIỀN TỪ ĐƠN THUỐC
    DECLARE @TongTienThuoc DECIMAL(18,2);
    
    SELECT @TongTienThuoc = ISNULL(SUM(ThanhTien), 0)
    FROM CT_DON_THUOC
    WHERE MaPhieu = @MaPhieu;

    -- 3. UPDATE TRẠNG THÁI (HD_TRUC_TIEP đã được tạo lúc check-in)
    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. Update trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DHT',         -- Đánh dấu là Đã Hoàn Thành (về mặt chuyên môn)
            TG_ThucHienDV = GETDATE()  --  GHI ĐÈ = thời gian hoàn thành khám
        WHERE MaPhieu = @MaPhieu;
        
        -- B. Update tổng tiền vào hóa đơn (đã tồn tại từ lúc check-in)
        UPDATE HD_TRUC_TIEP
        SET TongThanhTien = @TongTienThuoc,
            TongThanhTienSC = @TongTienThuoc  -- Tổng sau chiết khấu = tổng tiền (chưa có khuyến mãi)
        WHERE MaPhieu = @MaPhieu;
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_KetThucTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 9. Bác sĩ kết thúc tiêm vc
CREATE   PROC [dbo].[sp_BacSi_KetThucTiem]
    @MaPhieu NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validation
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu chưa check-in hoặc đã kết thúc rồi!', 16, 1);
        RETURN;
    END

    -- Check xem có phải phiếu Tiêm Vaccine (TV) không
    IF NOT EXISTS (SELECT 1 FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @MaPhieu)
    BEGIN
        RAISERROR(N'Lỗi: Đây không phải là phiếu tiêm vaccine!', 16, 1);
        RETURN;
    END

    --  TÍNH TỔNG TIỀN TỪ VACCINE
    DECLARE @TongTienVaccine DECIMAL(18,2);
    
    SELECT @TongTienVaccine = ISNULL(SUM(ThanhTien), 0)
    FROM CT_TIEM_VC
    WHERE MaPhieu = @MaPhieu;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. Update trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DHT',         -- Đã hoàn tất (Chờ thanh toán)
            TG_ThucHienDV = GETDATE()  --  GHI ĐÈ = thời gian hoàn thành tiêm
        WHERE MaPhieu = @MaPhieu;
        
        --  KHÔNG CẬP NHẬT HÓA ĐƠN NỮA!
        -- Hóa đơn sẽ được TẠO MỚI khi nhân viên xuất hóa đơn
        
        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_LayDanhSachChoKham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO



CREATE   PROC [dbo].[sp_BacSi_LayDanhSachChoKham]
    @MaCN NCHAR(10),
    @MaBacSi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RTRIM(P.MaPhieu) AS MaPhieu,
        P.TG_LapPhieu AS ThoiGian, -- Tên cột cho Bác sĩ
        RTRIM(P.MaNV) AS MaNV,
        U.HoTen AS ChuNuoi,        -- Tên cột cho Bác sĩ
        TC.Ten AS TenThuCung,
        TC.Loai AS LoaiThuCung,
        CASE RTRIM(P.LoaiPhieu)
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            ELSE N'Dịch vụ'
        END AS DichVu,             -- Tên cột cho Bác sĩ
        RTRIM(ISNULL(P.TrangThai, '')) AS TrangThai
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    WHERE P.MaCN = @MaCN 
      AND RTRIM(P.MaNV) = RTRIM(@MaBacSi) -- Chỉ lấy đúng ca của ổng
      AND P.TrangThai IN ('DD', 'DTH')    -- Chỉ hiện ca chờ hoặc đang khám
    ORDER BY P.TG_LapPhieu ASC
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_ThemGoiTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. Bác sĩ ghi nhận gói tiêm đối với khách tiêm không đặt lịch trước
CREATE   PROC [dbo].[sp_BacSi_ThemGoiTiem]
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10),
    @MaGoi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không tồn tại hoặc chưa check-in (Phải là DTH)!', 16, 1);
        RETURN;
    END

    -- Check tồn kho
    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    IF ISNULL(@TonKho, 0) < 1
    BEGIN
        RAISERROR(N'Lỗi: Vaccine này đã hết hàng trong kho!', 16, 1);
        RETURN;
    END

    -- 2. TÍNH TOÁN GIÁ & THỜI HẠN
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

    -- Công thức: Đơn giá * Số mũi * (1 - Giảm giá)
    SET @ThanhTienGoi = @DonGiaVC * ISNULL(@SoMuiTuongUng, 1) * (1.0 - ISNULL(@GiamGia, 0));
    IF @ThanhTienGoi < 0 SET @ThanhTienGoi = 0;

    -- Tính ngày hết hạn
    SET @NgayHetHan = DATEADD(MONTH, ISNULL(@ThoiHan, 0), GETDATE());

    -- 3. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ kho (Trừ 1 liều cho mũi tiêm đầu tiên này)
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B2: Insert vào Bảng Đăng Ký Gói
        INSERT INTO DANG_KI_GOI_TIEM (MaPhieu, MaVaccine, MaGoi, NgayHetHan, HieuLuc, ThanhTien)
        VALUES (@MaPhieu, @MaVaccine, @MaGoi, @NgayHetHan, 1, @ThanhTienGoi);

        -- B3: Insert vào Chi Tiết Tiêm (Mũi 1)
        --  MŨI 1 TRẢ TIỀN GÓI, từ mũi 2 trở đi mới miễn phí
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
/****** Object:  StoredProcedure [dbo].[sp_BacSi_ThemVaccineLe]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 7. Bác sĩ ghi nhận VC đối với khách tiêm không đặt lịch
CREATE   PROC [dbo].[sp_BacSi_ThemVaccineLe]
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10),
    @LieuLuong NVARCHAR(70) = N'1 liều',
    @NhacLai BIT = 0,
    @TheoGoi BIT = 0
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION CƠ BẢN
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không ở trạng thái Đang thực hiện!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    DECLARE @MaKH NCHAR(10);
    SELECT @MaCN = MaCN, @MaKH = MaKH 
    FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    
    -- Check kho
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    IF ISNULL(@TonKho, 0) < 1
    BEGIN
        RAISERROR(N'Lỗi: Vaccine đã hết hàng!', 16, 1);
        RETURN;
    END

    -- 2. XỬ LÝ LOGIC GIÁ TIỀN & KIỂM TRA GÓI
    DECLARE @ThanhTien DECIMAL(18,2) = 0;
    
    -- Các biến để xử lý gói
    DECLARE @MaPhieuDangKyGoi NCHAR(10);
    DECLARE @MaGoiDangKy NCHAR(10);
    DECLARE @SoMuiQuyDinh INT;
    DECLARE @NgayDangKyGoi DATETIME;

    IF @TheoGoi = 0 
    BEGIN
        -- TRƯỜNG HỢP 1: Tiêm lẻ -> Lấy đơn giá vaccine
        SELECT @ThanhTien = DonGia FROM VACCINE WHERE MaVaccine = @MaVaccine;
    END
    ELSE 
    BEGIN
        -- TRƯỜNG HỢP 2: Tiêm nhắc lại theo gói -> Giá = 0
        
        -- A. Tìm gói tiêm KHẢ DỤNG
        SELECT TOP 1 
            @MaPhieuDangKyGoi = DK.MaPhieu,
            @MaGoiDangKy = DK.MaGoi,
            @SoMuiQuyDinh = G.SoMuiTuongUng,
            @NgayDangKyGoi = P_DK.TG_LapPhieu
        FROM DANG_KI_GOI_TIEM DK
        JOIN PHIEU_DICH_VU P_DK ON DK.MaPhieu = P_DK.MaPhieu
        JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
        WHERE P_DK.MaKH = @MaKH 
          AND DK.MaVaccine = @MaVaccine 
          AND DK.HieuLuc = 1
          AND DK.NgayHetHan >= CAST(GETDATE() AS DATE) 
        ORDER BY DK.NgayHetHan ASC;

        IF @MaPhieuDangKyGoi IS NULL
        BEGIN
            RAISERROR(N'Lỗi: Khách hàng không có gói tiêm khả dụng cho loại vaccine này!', 16, 1);
            RETURN;
        END

        -- B. Kiểm tra số mũi ĐÃ TIÊM
        DECLARE @SoMuiDaTiem INT;
        SELECT @SoMuiDaTiem = COUNT(*)
        FROM CT_TIEM_VC CT
        JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
        WHERE P.MaKH = @MaKH 
          AND CT.MaVaccine = @MaVaccine
          AND P.TG_LapPhieu >= @NgayDangKyGoi; 

        IF @SoMuiDaTiem >= @SoMuiQuyDinh
        BEGIN
            UPDATE DANG_KI_GOI_TIEM 
            SET HieuLuc = 0 
            WHERE MaPhieu = @MaPhieuDangKyGoi AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDangKy;
            
            RAISERROR(N'Lỗi: Gói tiêm đã sử dụng hết số mũi quy định!', 16, 1);
            RETURN;
        END

        -- Tiêm nhắc lại thì Free
        SET @ThanhTien = 0;
    END

    -- 3. THỰC THI INSERT
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ kho
        UPDATE TON_KHO SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B2: Thêm chi tiết tiêm
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, NhacLai, LieuLuong, ThanhTien)
        VALUES (@MaVaccine, @MaPhieu, @NhacLai, @LieuLuong, @ThanhTien);

        -- B3: Cập nhật hiệu lực gói (Nếu mũi này là mũi cuối cùng)
        IF @TheoGoi = 1
        BEGIN
            DECLARE @TongMuiSauKhiTiem INT;
            
            SELECT @TongMuiSauKhiTiem = COUNT(*)
            FROM CT_TIEM_VC CT
            JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
            WHERE P.MaKH = @MaKH 
              AND CT.MaVaccine = @MaVaccine
              AND P.TG_LapPhieu >= @NgayDangKyGoi;

            IF @TongMuiSauKhiTiem >= @SoMuiQuyDinh
            BEGIN
                UPDATE DANG_KI_GOI_TIEM 
                SET HieuLuc = 0 
                WHERE MaPhieu = @MaPhieuDangKyGoi AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDangKy;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_XoaGoiTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 6. Bác sĩ xóa gói tiêm
CREATE   PROC [dbo].[sp_BacSi_XoaGoiTiem]
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10),
    @MaGoi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không hợp lệ để xóa (Phải là DTH)!', 16, 1);
        RETURN;
    END

    -- Kiểm tra gói có tồn tại trong phiếu này không
    IF NOT EXISTS (SELECT 1 FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine AND MaGoi = @MaGoi)
    BEGIN
        RAISERROR(N'Lỗi: Không tìm thấy thông tin đăng ký gói tiêm này trong phiếu!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    SELECT @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- 2. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Xóa thông tin Đăng Ký Gói
        DELETE FROM DANG_KI_GOI_TIEM 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine AND MaGoi = @MaGoi;

        -- B2: Xóa mũi tiêm đầu tiên đi kèm trong bảng Chi Tiết
        -- (Lưu ý: Lúc thêm gói mình đã insert 1 dòng vào đây, giờ phải xóa đi)
        DELETE FROM CT_TIEM_VC 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine;

        -- B3: Hoàn kho (Cộng lại 1 liều đã trừ lúc đăng ký)
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon + 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_BacSi_XoaVaccineLe]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 8. Bác sĩ xóa VC
CREATE   PROC [dbo].[sp_BacSi_XoaVaccineLe]
    @MaPhieu NCHAR(10),
    @MaVaccine NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không hợp lệ!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine)
    BEGIN
        RAISERROR(N'Lỗi: Không tìm thấy vaccine này trong phiếu!', 16, 1);
        RETURN;
    END

    DECLARE @MaCN NCHAR(10);
    DECLARE @MaKH NCHAR(10);
    SELECT @MaCN = MaCN, @MaKH = MaKH FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- 2. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Xóa chi tiết tiêm
        DELETE FROM CT_TIEM_VC 
        WHERE MaPhieu = @MaPhieu AND MaVaccine = @MaVaccine;

        -- B2: Hoàn kho
        UPDATE TON_KHO 
        SET SoLuongTon = SoLuongTon + 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B3: [LOGIC HỒI PHỤC GÓI]
        -- Nếu mũi tiêm vừa xóa thuộc về một gói nào đó, và gói đó đang bị HieuLuc=0 (do hết số lần)
        -- Thì cần phải mở lại HieuLuc=1 cho gói đó (vì giờ số lần đã giảm xuống dưới mức quy định rồi)
        
        DECLARE @MaPhieuDK NCHAR(10);
        DECLARE @MaGoiDK NCHAR(10);
        DECLARE @SoMuiQuyDinh INT;
        DECLARE @NgayDangKy DATETIME;

        -- Tìm gói tiêm gần nhất của khách hàng cho loại vaccine này (đang còn hạn)
        SELECT TOP 1 
            @MaPhieuDK = DK.MaPhieu,
            @MaGoiDK = DK.MaGoi,
            @SoMuiQuyDinh = G.SoMuiTuongUng,
            @NgayDangKy = P_DK.TG_LapPhieu
        FROM DANG_KI_GOI_TIEM DK
        JOIN PHIEU_DICH_VU P_DK ON DK.MaPhieu = P_DK.MaPhieu
        JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
        WHERE P_DK.MaKH = @MaKH 
          AND DK.MaVaccine = @MaVaccine 
          AND DK.NgayHetHan >= CAST(GETDATE() AS DATE) -- Gói chưa hết hạn
        ORDER BY DK.NgayHetHan ASC;

        IF @MaPhieuDK IS NOT NULL
        BEGIN
            -- Đếm lại số mũi đã tiêm (sau khi đã xóa mũi hiện tại)
            DECLARE @SoMuiHienTai INT;
            SELECT @SoMuiHienTai = COUNT(*)
            FROM CT_TIEM_VC CT
            JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
            WHERE P.MaKH = @MaKH 
              AND CT.MaVaccine = @MaVaccine
              AND P.TG_LapPhieu >= @NgayDangKy;

            -- Nếu số mũi hiện tại < Quy định -> Mở lại hiệu lực gói
            IF @SoMuiHienTai < @SoMuiQuyDinh
            BEGIN
                UPDATE DANG_KI_GOI_TIEM
                SET HieuLuc = 1
                WHERE MaPhieu = @MaPhieuDK AND MaVaccine = @MaVaccine AND MaGoi = @MaGoiDK AND HieuLuc = 0;
            END
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CanhBaoHetHang]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 9. Thống kê sản phẩm sắp hết hàng
CREATE   PROC [dbo].[sp_CanhBaoHetHang]
    @MaCN NCHAR(10),
    @NguongCanhBao INT = 10 
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        K.MaMatHang,
        MH.TenMatHang,
        MH.LoaiMH, -- Loại mặt hàng: T (Thuốc), VC (Vaccine), SPK (Sản phẩm khác)
        K.SoLuongTon
    FROM TON_KHO K
    JOIN MAT_HANG MH ON K.MaMatHang = MH.MaMatHang
    WHERE K.MaCN = @MaCN 
      AND K.SoLuongTon <= @NguongCanhBao
    ORDER BY K.SoLuongTon ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatDiemTichLuy]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Update lại điểm tích lũy
CREATE   PROC [dbo].[sp_CapNhatDiemTichLuy]
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
/****** Object:  StoredProcedure [dbo].[sp_CapNhatHoaDon2023]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Năm 2023
-- =============================================
-- Set khuyến mãi, điểm quy đổi = 0
CREATE   PROC [dbo].[sp_CapNhatHoaDon2023]
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
/****** Object:  StoredProcedure [dbo].[sp_CapNhatKetQuaKham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Bác sĩ điền thông tin chẩn đoán và ngày hẹn tái khám vào phiếu.
CREATE   PROC [dbo].[sp_CapNhatKetQuaKham]
    @MaPhieu NCHAR(10),
    @ChanDoan NVARCHAR(200),
    @NgayHenTaiKham DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION
    -- Check trạng thái DTH
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không tồn tại hoặc trạng thái không hợp lệ (Phải đang thực hiện)!', 16, 1);
        RETURN;
    END

    -- Check xem phiếu này có phải là phiếu khám bệnh không (Hay là phiếu tiêm vaccine/mua hàng)
    IF NOT EXISTS (SELECT 1 FROM PHIEU_KHAM_BENH WHERE MaPhieu = @MaPhieu)
    BEGIN
        RAISERROR(N'Lỗi: Đây không phải là phiếu khám bệnh, không thể cập nhật chẩn đoán!', 16, 1);
        RETURN;
    END

     -- Kiểm tra Ngày hẹn tái khám phải lớn hơn ngày hiện tại
    IF @NgayHenTaiKham <= CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR(N'Lỗi: Ngày hẹn tái khám phải lớn hơn ngày hiện tại!', 16, 1);
        RETURN;
    END
        
    -- 2. UPDATE
    BEGIN TRY
        UPDATE PHIEU_KHAM_BENH
        SET ChanDoan = @ChanDoan,
            NgayHenTaiKham = @NgayHenTaiKham
        WHERE MaPhieu = @MaPhieu;
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatNhanVien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 8. Cáº­p nháº­t thÃ´ng tin nhÃ¢n viÃªn
CREATE   PROC [dbo].[sp_CapNhatNhanVien]
    @MaNV NCHAR(10),
    @HoTen NVARCHAR(50) = NULL,
    @NgaySinh DATE = NULL,
    @GioiTinh NVARCHAR(3) = NULL,
    @ChucVu NVARCHAR(50) = NULL,
    @LuongCoBan DECIMAL(12,2) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNV)
    BEGIN
        RAISERROR(N'NhÃ¢n viÃªn khÃ´ng tá»“n táº¡i!', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Update báº£ng USER
        UPDATE [USER]
        SET HoTen = ISNULL(@HoTen, HoTen),
            NgaySinh = ISNULL(@NgaySinh, NgaySinh),
            GioiTinh = ISNULL(@GioiTinh, GioiTinh)
        WHERE MaUser = @MaNV;

        -- Update báº£ng NHAN_VIEN
        UPDATE NHAN_VIEN
        SET ChucVu = ISNULL(@ChucVu, ChucVu),
            LuongCoBan = ISNULL(@LuongCoBan, LuongCoBan)
        WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
        PRINT N'Cáº­p nháº­t thÃ nh cÃ´ng!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatThongTinKH]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Cập nhật thông tin khách hàng
CREATE   PROC [dbo].[sp_CapNhatThongTinKH]
    @MaUser NCHAR(10),
    @HoTen NVARCHAR(50),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(3),
    @Email VARCHAR(50) = NULL, -- Thêm = NULL để không bắt buộc
    @CCCD CHAR(12) = NULL      -- Thêm = NULL
AS
BEGIN
    SET NOCOUNT ON;

    -- Để tránh lỗi khi validate và lưu vào DB cho sạch
    IF @Email = '' SET @Email = NULL;
    IF @CCCD = '' SET @CCCD = NULL;

    -- 1. VALIDATION
    -- Check User có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM [USER] WHERE MaUser = @MaUser)
    BEGIN
        RAISERROR(N'Lỗi: Người dùng không tồn tại!', 16, 1);
        RETURN;
    END

    -- Check định dạng Email (CHỈ CHECK NẾU CÓ NHẬP)
    IF @Email IS NOT NULL AND @Email NOT LIKE '%_@__%.__%'
    BEGIN
        RAISERROR(N'Lỗi: Định dạng Email không hợp lệ!', 16, 1);
        RETURN;
    END

    -- Check trùng Email (CHỈ CHECK NẾU CÓ NHẬP)
    IF @Email IS NOT NULL AND EXISTS (SELECT 1 FROM KHACH_HANG WHERE Email = @Email AND MaKH <> @MaUser)
    BEGIN
        RAISERROR(N'Lỗi: Email này đã được sử dụng bởi tài khoản khác!', 16, 1);
        RETURN;
    END

    -- Check CCCD (CHỈ CHECK NẾU CÓ NHẬP)
    IF @CCCD IS NOT NULL
    BEGIN
        IF LEN(@CCCD) <> 12 OR LEFT(@CCCD, 1) <> '0' OR @CCCD LIKE '%[^0-9]%'
        BEGIN
            RAISERROR(N'Lỗi: CCCD phải có 12 số, bắt đầu bằng số 0 và không có ký tự chữ!', 16, 1);
            RETURN;
        END
    END

    -- Check ngày sinh
    IF @NgaySinh >= GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Ngày sinh không hợp lệ!', 16, 1);
        RETURN;
    END

    -- 2. THỰC HIỆN UPDATE
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Update bảng USER
        UPDATE [USER]
        SET HoTen = @HoTen,
            NgaySinh = @NgaySinh,
            GioiTinh = @GioiTinh
        WHERE MaUser = @MaUser;

        -- Update bảng KHACH_HANG
        -- Nếu @Email là NULL thì trong DB sẽ được cập nhật thành NULL (xóa email cũ)
        UPDATE KHACH_HANG
        SET Email = @Email,
            CCCD = @CCCD
        WHERE MaKH = @MaUser;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatThuCung]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 6. Cập nhật thông tin thú cưng
CREATE   PROC [dbo].[sp_CapNhatThuCung]
    @MaKH NCHAR(10),       -- Để check xem có đúng chủ không
    @MaTC VARCHAR(20),     -- Mã thú (VARCHAR 20 cho khớp với DB)
    @TenTC NVARCHAR(50),
    @Loai NVARCHAR(20),    -- Thêm Loài (form có sửa loài)
    @Giong NVARCHAR(50),
    @NgaySinh DATE,       
    @GioiTinh NVARCHAR(10),   
    @TinhTrangSucKhoe NVARCHAR(100) 
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Check xem thú cưng có tồn tại và ĐÚNG CHỦ không
    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC AND RTRIM(MaKH) = RTRIM(@MaKH))
    BEGIN
        RAISERROR(N'Lỗi: Không tìm thấy thú cưng hoặc bạn không phải chủ sở hữu!', 16, 1);
        RETURN;
    END

    -- 2. Check ngày sinh
    IF @NgaySinh >= GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Ngày sinh phải nhỏ hơn ngày hiện tại!', 16, 1);
        RETURN;
    END

    -- 3. Update
    BEGIN TRY
        UPDATE THU_CUNG
        SET Ten = @TenTC,
            Loai = @Loai,         -- Update luôn loại cho đầy đủ
            Giong = @Giong,
            NgSinh = @NgaySinh,      
            GioiTinh = @GioiTinh,   
            TinhTrangSucKhoe = @TinhTrangSucKhoe
        WHERE MaTC = @MaTC AND RTRIM(MaKH) = RTRIM(@MaKH);
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatTongChiTieu]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Update tổng chi tiêu năm 2023
CREATE   PROC [dbo].[sp_CapNhatTongChiTieu]
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
/****** Object:  StoredProcedure [dbo].[sp_CapNhatTrangThaiDonHang]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 6. Nhân viên cập nhật trạng thái của PDV cho KH biết đơn hàng đã vận chuyển (DTH, DHT)
CREATE   PROC [dbo].[sp_CapNhatTrangThaiDonHang]
    @MaPhieu NCHAR(10),
    @MaNV NCHAR(10),       
    @TrangThaiMoi VARCHAR(3) -- 'DTH' (Đang giao) hoặc 'DHT' (Giao xong/Hoàn tất)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. KIỂM TRA INPUT
    IF @TrangThaiMoi NOT IN ('DTH', 'DHT')
    BEGIN
        RAISERROR(N'Trạng thái không hợp lệ! Chỉ chấp nhận: DTH (Đang thực hiện), DHT (Đã hoàn tất).', 16, 1);
        RETURN;
    END

    -- 2. LẤY THÔNG TIN CŨ
    DECLARE @TrangThaiCu VARCHAR(3);
    DECLARE @MaKH NCHAR(10);
    
    SELECT @TrangThaiCu = TrangThai, @MaKH = MaKH 
    FROM PHIEU_DICH_VU 
    WHERE MaPhieu = @MaPhieu;

    -- Kiểm tra tồn tại
    IF @TrangThaiCu IS NULL
    BEGIN
        RAISERROR(N'Đơn hàng không tồn tại.', 16, 1);
        RETURN;
    END

    -- Kiểm tra hủy
    IF @TrangThaiCu = 'DH'
    BEGIN
        RAISERROR(N'Đơn hàng này đã bị hủy, không thể cập nhật trạng thái.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 3. CẬP NHẬT TRẠNG THÁI & NV
        UPDATE PHIEU_DICH_VU
        SET TrangThai = @TrangThaiMoi,
            MaNV = @MaNV 
        WHERE MaPhieu = @MaPhieu;

        -- 4. LOGIC CỘNG ĐIỂM TÍCH LŨY (Chỉ chạy khi Hoàn tất đơn - DHT)
        -- Điều kiện: Trạng thái mới là DHT VÀ Trạng thái cũ CHƯA PHẢI là DHT (để tránh cộng điểm 2 lần nếu lỡ chạy lại SP)
        IF @TrangThaiMoi = 'DHT' AND @TrangThaiCu <> 'DHT'
        BEGIN
            DECLARE @TongTienThanhToan DECIMAL(18,2);
            DECLARE @DiemCong INT;

            -- Lấy tổng tiền thực trả (SC) từ hóa đơn
            SELECT @TongTienThanhToan = ISNULL(TongThanhTienSC, 0)
            FROM HD_TRUC_TUYEN
            WHERE MaPhieu = @MaPhieu;

            -- Tính điểm: 50.000 VNĐ = 1 điểm (Lấy phần nguyên)
            SET @DiemCong = CAST(@TongTienThanhToan / 50000 AS INT);

            IF @DiemCong > 0
            BEGIN
                UPDATE KHACH_HANG
                SET TongDiemTichLuy = TongDiemTichLuy + @DiemCong
                WHERE MaKH = @MaKH;
                
                PRINT N'Đã cộng ' + CAST(@DiemCong AS NVARCHAR(20)) + N' điểm tích lũy cho khách hàng.';
            END
        END

        COMMIT TRANSACTION;
        PRINT N'Cập nhật trạng thái đơn hàng thành công: ' + @TrangThaiMoi;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatXepHangHoiVien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 12. Update xếp hạng hội viên cho khách hàng

CREATE   PROC [dbo].[sp_CapNhatXepHangHoiVien]
    @Nam INT -- Năm cần xếp hạng (Ví dụ: 2025)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =========================================================
    -- 0. LOGIC BẢO VỆ: CHỈ CHO PHÉP CHẠY VÀO NGÀY CUỐI NĂM
    -- =========================================================
    DECLARE @NgayHienTai DATE = GETDATE();
    
    -- Kiểm tra ngày 31/12
    IF DAY(@NgayHienTai) <> 31 OR MONTH(@NgayHienTai) <> 12
    BEGIN
        RAISERROR(N'Lỗi: Quy trình xếp hạng chỉ được phép chạy vào ngày 31/12 hàng năm để chốt sổ!', 16, 1);
        RETURN;
    END

    IF YEAR(@NgayHienTai) <> @Nam
    BEGIN
        RAISERROR(N'Lỗi: Năm xếp hạng phải trùng với năm hiện tại!', 16, 1);
        RETURN;
    END

    -- =========================================================
    -- 1. BẢNG TẠM TÍNH TỔNG CHI TIÊU
    -- =========================================================
    DECLARE @BangChiTieu TABLE (
        MaKH NCHAR(10), 
        TongTien DECIMAL(18,2)
    );

    INSERT INTO @BangChiTieu (MaKH, TongTien)
    SELECT 
        KH.MaKH,
        ISNULL(SUM(DonHang.ThanhTien), 0) AS TongTien
    FROM KHACH_HANG KH
    LEFT JOIN (
        -- Doanh thu offline
        SELECT P.MaKH, HD.TongThanhTienSC AS ThanhTien
        FROM PHIEU_DICH_VU P
        JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
        WHERE YEAR(P.TG_ThucHienDV) = @Nam AND P.TrangThai = 'DHT'
        
        UNION ALL
        
        -- Doanh thu online
        SELECT P.MaKH, HDO.TongThanhTienSC AS ThanhTien
        FROM PHIEU_DICH_VU P
        JOIN HD_TRUC_TUYEN HDO ON P.MaPhieu = HDO.MaPhieu
        WHERE YEAR(P.TG_ThucHienDV) = @Nam AND P.TrangThai = 'DHT'
    ) AS DonHang ON KH.MaKH = DonHang.MaKH
    GROUP BY KH.MaKH;

    -- =========================================================
    -- 2. TÍNH TOÁN HẠNG MỚI
    -- =========================================================
    DECLARE @BangXepHangMoi TABLE (
        MaKH NCHAR(10),
        MaHangMoi VARCHAR(10),
        TongTienNamNay DECIMAL(18,2)
    );

    INSERT INTO @BangXepHangMoi (MaKH, MaHangMoi, TongTienNamNay)
    SELECT 
        CT.MaKH,
        CASE 
            -- LOGIC 1: C03 (VIP)
            -- Lên thẳng nếu chi >= 12tr HOẶC Giữ hạng nếu cũ là C03 và chi >= 8tr
            WHEN CT.TongTien >= 12000000 THEN 'C03'
            WHEN XH_Cu.MaHang = 'C03' AND CT.TongTien >= 8000000 THEN 'C03'

            -- LOGIC 2: C02 (Thân thiết)
            -- Lên hạng nếu chi >= 5tr HOẶC Giữ hạng nếu cũ là C02 và chi >= 3tr
            WHEN CT.TongTien >= 5000000 THEN 'C02'
            WHEN XH_Cu.MaHang = 'C02' AND CT.TongTien >= 3000000 THEN 'C02'

            -- LOGIC 3: C01 (Cơ bản)
            ELSE 'C01'
        END AS MaHangMoi,
        CT.TongTien
    FROM @BangChiTieu CT
    LEFT JOIN XEP_HANG_NAM XH_Cu 
        ON CT.MaKH = XH_Cu.MaKH AND XH_Cu.Nam = (@Nam - 1); -- Vẫn lấy lịch sử năm ngoái để so sánh

    -- =========================================================
    -- 3. CẬP NHẬT VÀO DATABASE
    -- =========================================================
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Xóa dữ liệu CỦA NĂM NAY (nếu lỡ đã chạy trước đó) để tính lại
        -- Dữ liệu các năm cũ (@Nam - 1, @Nam - 2...) VẪN GIỮ NGUYÊN
        DELETE FROM XEP_HANG_NAM WHERE Nam = @Nam;

        -- Insert dữ liệu mới
        INSERT INTO XEP_HANG_NAM (MaKH, MaHang, Nam, TongChiTieu, NgayCapNhat)
        SELECT 
            MaKH, 
            MaHangMoi, 
            @Nam, 
            TongTienNamNay, 
            GETDATE()
        FROM @BangXepHangMoi;

        COMMIT TRANSACTION;
        
        PRINT N'Cập nhật xếp hạng thành công cho năm ' + CAST(@Nam AS NVARCHAR(4));
        
        -- In kết quả kiểm tra
        SELECT MaHang, COUNT(*) AS SoLuongKhach
        FROM XEP_HANG_NAM 
        WHERE Nam = @Nam
        GROUP BY MaHang
        ORDER BY MaHang;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_CapNhatXepHangNam]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Update xếp hạng năm 2023
CREATE   PROC [dbo].[sp_CapNhatXepHangNam]
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
/****** Object:  StoredProcedure [dbo].[sp_CheckInKhachHang]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. Nhân viên check in khi khách (đã đặt lịch trước) tới cửa hàng, gán bác sĩ phụ trách
CREATE   PROC [dbo].[sp_CheckInKhachHang]
    @MaPhieu NCHAR(10),
    @MaNV_PhuTrach NCHAR(10) -- Bác sĩ hoặc NV thực hiện dịch vụ
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- 1. VALIDATION (Kiểm tra dữ liệu đầu vào)
    -- =============================================
    
    -- 1.1 Kiểm tra Phiếu tồn tại và đúng trạng thái
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @LoaiPhieu VARCHAR(2);
    DECLARE @MaCN_Phieu NCHAR(10);

    SELECT 
        @TrangThai = TrangThai,
        @LoaiPhieu = LoaiPhieu,
        @MaCN_Phieu = MaCN
    FROM PHIEU_DICH_VU 
    WHERE MaPhieu = @MaPhieu;

    IF @TrangThai IS NULL OR @TrangThai <> 'DD'
    BEGIN
        RAISERROR(N'Lỗi: Phiếu không tồn tại hoặc trạng thái không hợp lệ (Phải là Đã đặt)!', 16, 1);
        RETURN;
    END

    -- 1.2 Kiểm tra Nhân viên có thuộc Chi nhánh của phiếu không
    DECLARE @ChucVuNV NVARCHAR(50);
    DECLARE @MaCN_NV NCHAR(10);

    SELECT 
        @ChucVuNV = Chucvu,
        @MaCN_NV = MaCN
    FROM NHAN_VIEN 
    WHERE MaNV = @MaNV_PhuTrach;

    IF @MaCN_NV IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Mã nhân viên không tồn tại!', 16, 1);
        RETURN;
    END

    IF @MaCN_NV <> @MaCN_Phieu
    BEGIN
        RAISERROR(N'Lỗi: Nhân viên phụ trách không thuộc chi nhánh của phiếu dịch vụ này!', 16, 1);
        RETURN;
    END

    -- 1.3 KIỂM TRA CHUYÊN MÔN NHÂN VIÊN
    -- Nếu là Khám bệnh (KB) hoặc Tiêm vaccine (TV) -> Phải là "Bác sĩ thú y"
    IF @LoaiPhieu IN ('KB', 'TV') AND @ChucVuNV <> N'Bác sĩ thú y'
    BEGIN
        RAISERROR(N'Lỗi: Phiếu Khám bệnh/Tiêm vaccine phải do Bác sĩ thú y phụ trách!', 16, 1);
        RETURN;
    END

    -- Nếu là Mua hàng (MH) -> Phải là "Nhân viên bán hàng"
    IF @LoaiPhieu = 'MH' AND @ChucVuNV <> N'Nhân viên bán hàng'
    BEGIN
        RAISERROR(N'Lỗi: Phiếu Mua hàng phải do Nhân viên bán hàng phụ trách!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 2. UPDATE & INSERT INVOICE (Thực thi)
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        -- 2.1 Cập nhật trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DTH',             -- Chuyển sang Đang thực hiện
            MaNV = @MaNV_PhuTrach,         -- Gán nhân viên phụ trách
            TG_ThucHienDV = GETDATE()      --  GHI ĐÈ = thời gian check-in thực tế
        WHERE MaPhieu = @MaPhieu;

        -- 2.2 Tạo Hóa Đơn Trực Tiếp
        IF NOT EXISTS (SELECT 1 FROM HD_TRUC_TIEP WHERE MaPhieu = @MaPhieu)
        BEGIN
            INSERT INTO HD_TRUC_TIEP (
                MaPhieu, 
                TongThanhTien, 
                KhuyenMai, 
                DiemQuyDoi, 
                TongThanhTienSC, 
                PhuongThucTT, 
                MaNV
            )
            VALUES (
                @MaPhieu, 
                0, -- Tiền ban đầu = 0
                0, 
                0, 
                0, 
                N'Tiền mặt', -- Mặc định
                @MaNV_PhuTrach
            );
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DangKyTaiKhoanKH]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Đăng ký tài khoản cho khách hàng
-- Thêm phần liên kết với hồ sơ cũ
CREATE   PROC [dbo].[sp_DangKyTaiKhoanKH]
    @TenDangNhap VARCHAR(30),
    @MatKhau VARCHAR(70),
    @HoTen NVARCHAR(50),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(3),
    @SDT VARCHAR(10),
    @Email VARCHAR(50) = NULL,
    @CCCD CHAR(12) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Xử lý NULL cho chuỗi rỗng
    IF @Email = '' SET @Email = NULL;
    IF @CCCD = '' SET @CCCD = NULL;

    -- 1. VALIDATION (Kiểm tra dữ liệu đầu vào)
    
    -- Check định dạng SĐT
    IF LEN(@SDT) <> 10 OR LEFT(@SDT, 1) <> '0' OR @SDT LIKE '%[^0-9]%'
    BEGIN
        RAISERROR(N'Lỗi: Số điện thoại không đúng định dạng!', 16, 1);
        RETURN;
    END

    -- Check định dạng CCCD
    IF @CCCD IS NOT NULL
    BEGIN
        IF LEN(@CCCD) <> 12 OR LEFT(@CCCD, 1) <> '0' OR @CCCD LIKE '%[^0-9]%'
        BEGIN
            RAISERROR(N'Lỗi: CCCD phải có 12 số, bắt đầu bằng số 0 và không có ký tự chữ!', 16, 1);
            RETURN;
        END
    END

    -- Check trùng Tên đăng nhập (Bắt buộc duy nhất)
    IF EXISTS (SELECT 1 FROM TAI_KHOAN WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        RAISERROR(N'Lỗi: Tên đăng nhập đã tồn tại!', 16, 1);
        RETURN;
    END

    -- Check trùng Email (Trừ trường hợp chính khách hàng đó đang cập nhật)
    IF @Email IS NOT NULL AND EXISTS (
        SELECT 1 FROM KHACH_HANG 
        WHERE Email = @Email AND SDT <> @SDT -- Khác SĐT nghĩa là của người khác
    )
    BEGIN
        RAISERROR(N'Lỗi: Email này đã được người khác sử dụng!', 16, 1);
        RETURN;
    END

    -- 2. XỬ LÝ LOGIC CRM (KHỚP HỒ SƠ)

    DECLARE @MaUserExisting NCHAR(10) = NULL;

    -- Kiểm tra xem SĐT này đã có trong bảng KHACH_HANG chưa?
    SELECT @MaUserExisting = MaKH FROM KHACH_HANG WHERE SDT = @SDT;

    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- TRƯỜNG HỢP 1: KHÁCH ĐÃ TỪNG ĐẾN QUÁN (SĐT ĐÃ CÓ)
        IF @MaUserExisting IS NOT NULL
        BEGIN
            -- Kiểm tra xem khách này đã có tài khoản online chưa?
            IF EXISTS (SELECT 1 FROM TAI_KHOAN WHERE MaUser = @MaUserExisting)
            BEGIN
                -- Nếu có rồi thì báo lỗi
                RAISERROR(N'Lỗi: Số điện thoại này đã được đăng ký tài khoản rồi!', 16, 1);
                ROLLBACK TRANSACTION;
                RETURN;
            END

            -- Nếu chưa có tài khoản online -> THỰC HIỆN CẬP NHẬT (KHỚP HỒ SƠ)
            
            -- A. Cập nhật bảng [USER] (Cập nhật họ tên, ngày sinh mới nhất khách nhập)
            UPDATE [USER]
            SET HoTen = @HoTen,
                NgaySinh = @NgaySinh,
                GioiTinh = @GioiTinh
            WHERE MaUser = @MaUserExisting;

            -- B. Cập nhật bảng KHACH_HANG (Email, CCCD nếu có)
            UPDATE KHACH_HANG
            SET Email = ISNULL(@Email, Email), -- Nếu khách nhập email mới thì lấy, ko thì giữ cũ
                CCCD = ISNULL(@CCCD, CCCD)
            WHERE MaKH = @MaUserExisting;

            -- C. Tạo tài khoản đăng nhập (INSERT vào TAI_KHOAN)
            INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, MaUser)
            VALUES (@TenDangNhap, @MatKhau, @MaUserExisting);

            -- Thông báo
            COMMIT TRANSACTION;
            SELECT @MaUserExisting as MaUserMoi, N'Đăng ký thành công! Đã đồng bộ với hồ sơ cũ tại cửa hàng.' as ThongBao;
        END

        -- TRƯỜNG HỢP 2: KHÁCH MỚI TINH (SĐT CHƯA CÓ)
        ELSE
        BEGIN
            -- --- TỰ ĐỘNG SINH MÃ USER
            DECLARE @MaUserNew NCHAR(10);
            DECLARE @MaxID INT;

            SELECT @MaxID = MAX(CAST(RIGHT(MaUser, 6) AS INT)) FROM [USER];
            IF @MaxID IS NULL SET @MaxID = 0;
            
            SET @MaxID = @MaxID + 1;
            SET @MaUserNew = 'U' + RIGHT('000000' + CAST(@MaxID AS VARCHAR(6)), 6);

            -- Vòng lặp check trùng mã (An toàn)
            WHILE EXISTS (SELECT 1 FROM [USER] WHERE MaUser = @MaUserNew)
            BEGIN
                SET @MaxID = @MaxID + 1;
                SET @MaUserNew = 'U' + RIGHT('000000' + CAST(@MaxID AS VARCHAR(6)), 6);
            END

            -- A. Insert bảng [USER]
            INSERT INTO [USER] (MaUser, HoTen, NgaySinh, GioiTinh, LoaiUser)
            VALUES (@MaUserNew, @HoTen, @NgaySinh, @GioiTinh, 'KH');

            -- B. Insert bảng TAI_KHOAN
            INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, MaUser)
            VALUES (@TenDangNhap, @MatKhau, @MaUserNew);

            -- C. Insert bảng KHACH_HANG
            INSERT INTO KHACH_HANG (MaKH, SDT, Email, CCCD, TongDiemTichLuy)
            VALUES (@MaUserNew, @SDT, @Email, @CCCD, 0);

            COMMIT TRANSACTION;
            SELECT @MaUserNew as MaUserMoi, N'Đăng ký mới thành công!' as ThongBao;
        END

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = N'Lỗi hệ thống: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DangNhap]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_DangNhap]
    @TenDangNhap VARCHAR(30)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        TK.TenDangNhap,
        TK.MatKhau, -- Lấy mật khẩu hash về để Node.js so sánh
        U.MaUser,
        U.HoTen,
        U.LoaiUser,
        NV.ChucVu,
        NV.MaCN
    FROM TAI_KHOAN TK
    JOIN [USER] U ON TK.MaUser = U.MaUser
    LEFT JOIN NHAN_VIEN NV ON U.MaUser = NV.MaNV
    WHERE TK.TenDangNhap = @TenDangNhap;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGiaDichVu]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 10. Khách hàng đánh giá dịch vụ
CREATE   PROC [dbo].[sp_DanhGiaDichVu]
    @MaPhieu NCHAR(10),
    @DiemChatLuong DECIMAL(4,2), -- Thang 5
    @DiemThaiDoNV DECIMAL(4,2),
    @DiemTongThe DECIMAL(4,2),
    @BinhLuan NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Check phiếu
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaKH_Phieu NCHAR(10);
    
    SELECT @TrangThai = TrangThai, @MaKH_Phieu = MaKH 
    FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    -- Chỉ cho đánh giá khi đã hoàn tất (DHT) hoặc (HT)
    IF @TrangThai NOT IN ('DHT') 
    BEGIN
        RAISERROR(N'Lỗi: Chỉ được đánh giá khi dịch vụ đã hoàn tất.', 16, 1);
        RETURN;
    END

    -- Check đã đánh giá chưa (Tránh spam)
    IF EXISTS (SELECT 1 FROM DANH_GIA_DV WHERE MaPhieu = @MaPhieu)
    BEGIN
        RAISERROR(N'Lỗi: Bạn đã đánh giá phiếu này rồi.', 16, 1);
        RETURN;
    END

    -- 2. Insert
    INSERT INTO DANH_GIA_DV (MaPhieu, DiemChatLuong, DiemThaiDoNV, DiemTongThe, BinhLuan, NgayDang)
    VALUES (@MaPhieu, @DiemChatLuong, @DiemThaiDoNV, @DiemTongThe, @BinhLuan, GETDATE());

    PRINT N'Cảm ơn bạn đã đánh giá dịch vụ!';
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DanhGiaSanPham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 11. Khách hàng đánh giá sản phẩm
CREATE   PROC [dbo].[sp_DanhGiaSanPham]
    @MaPhieu NCHAR(10),
    @MaMatHang NCHAR(10),
    @DiemChatLuong DECIMAL(4,2),
    @BinhLuan NVARCHAR(200)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. Check xem khách có mua sản phẩm này trong phiếu này không
    IF NOT EXISTS (SELECT 1 FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang)
    BEGIN
        RAISERROR(N'Lỗi: Sản phẩm này không có trong đơn hàng của bạn.', 16, 1);
        RETURN;
    END

    -- 2. Check trạng thái đơn hàng (Phải là đã giao/hoàn tất)
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai IN ('DHT', 'HT'))
    BEGIN
        RAISERROR(N'Lỗi: Đơn hàng chưa hoàn tất, chưa thể đánh giá.', 16, 1);
        RETURN;
    END

    -- 3. Check đã đánh giá chưa
    IF EXISTS (SELECT 1 FROM DANH_GIA_SP WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang)
    BEGIN
        RAISERROR(N'Lỗi: Bạn đã đánh giá sản phẩm này trong đơn hàng này rồi.', 16, 1);
        RETURN;
    END

    -- 4. Insert
    INSERT INTO DANH_GIA_SP (MaPhieu, MaMatHang, DiemChatLuong, BinhLuan, NgayDang)
    VALUES (@MaPhieu, @MaMatHang, @DiemChatLuong, @BinhLuan, GETDATE());

    PRINT N'Đánh giá sản phẩm thành công!';
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DatLichHen]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_DatLichHen]
    @MaKH NCHAR(10),
    @MaTC NCHAR(10), 
    @MaCN NCHAR(10),
    @LoaiPhieu VARCHAR(2), 
    @NgayHen DATE,
    @GioHen VARCHAR(5),            
    @TrieuChung NVARCHAR(200) = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- =============================================
    -- 1. VALIDATION CƠ BẢN
    -- =============================================
    IF @LoaiPhieu NOT IN ('KB', 'TV')
    BEGIN
        RAISERROR(N'Lỗi: Loại phiếu không hợp lệ (Chỉ nhận KB hoặc TV)', 16, 1);
        RETURN;
    END

    IF @MaTC IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Vui lòng chọn thú cưng cần khám hoặc tiêm phòng!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC AND MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Thú cưng không tồn tại hoặc không thuộc về khách hàng này!', 16, 1);
        RETURN;
    END

    -- Chuyển đổi @GioHen từ string 'HH:MM' sang DATETIME
    DECLARE @ThoiGianHen DATETIME;
    BEGIN TRY
        -- ✅ FIX: Ghép string trước khi CAST
        SET @ThoiGianHen = CAST(CONVERT(VARCHAR(10), @NgayHen, 120) + ' ' + @GioHen AS DATETIME);
    END TRY
    BEGIN CATCH
        RAISERROR(N'Lỗi: Định dạng giờ hẹn không hợp lệ (Cần HH:MM)', 16, 1);
        RETURN;
    END CATCH

    IF @ThoiGianHen < GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Thời gian hẹn không hợp lệ (Phải lớn hơn hiện tại)!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 2. CHECK GIỜ MỞ CỬA
    -- =============================================
    DECLARE @GioMoCua TIME, @GioDongCua TIME;
    SELECT @GioMoCua = Giomocua, @GioDongCua = Giodongcua 
    FROM CHI_NHANH WHERE MaCN = @MaCN;

    IF @GioMoCua IS NULL OR @GioDongCua IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh không tồn tại!', 16, 1);
        RETURN;
    END

    DECLARE @GioHenTime TIME = CAST(@GioHen AS TIME);
    IF @GioHenTime < @GioMoCua OR @GioHenTime > @GioDongCua
    BEGIN
        DECLARE @ErrMsg1 NVARCHAR(200);
        SET @ErrMsg1 = N'Lỗi: Chi nhánh chỉ làm việc từ ' + 
                       CONVERT(VARCHAR(5), @GioMoCua, 108) + N' đến ' + 
                       CONVERT(VARCHAR(5), @GioDongCua, 108);
        RAISERROR(@ErrMsg1, 16, 1);
        RETURN;
    END

    -- =============================================
    -- 3. CHECK DỊCH VỤ CHI NHÁNH HỖ TRỢ
    -- =============================================
    IF @LoaiPhieu = 'KB' AND NOT EXISTS (
        SELECT 1 FROM DV_CN 
        WHERE MaCN = @MaCN 
        AND MaLoaiDV IN (SELECT MaLoaiDV FROM LOAI_DICH_VU WHERE TenLoaiDV LIKE N'%khám%')
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Khám bệnh!', 16, 1);
        RETURN;
    END

    IF @LoaiPhieu = 'TV' AND NOT EXISTS (
        SELECT 1 FROM DV_CN 
        WHERE MaCN = @MaCN 
        AND MaLoaiDV IN (SELECT MaLoaiDV FROM LOAI_DICH_VU WHERE TenLoaiDV LIKE N'%tiêm%' OR TenLoaiDV LIKE N'%vaccine%')
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Tiêm vaccine!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 4.  SỬA LOGIC KIỂM TRA QUÁ TẢI (FIX CHÍNH)
    -- =============================================
    DECLARE @TongSoBacSi INT;
    DECLARE @SoPhieuDaDat INT;

    -- A. Đếm số bác sĩ ĐANG HOẠT ĐỘNG tại chi nhánh
    SELECT @TongSoBacSi = COUNT(*)
    FROM NHAN_VIEN NV
    WHERE NV.MaCN = @MaCN
      AND (NV.Chucvu = N'Bác sĩ' OR NV.Chucvu = N'Bác sĩ thú y' OR NV.Chucvu = N'BS');

    -- Nếu chi nhánh không có bác sĩ -> Chặn
    IF @TongSoBacSi IS NULL OR @TongSoBacSi = 0
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này chưa có bác sĩ, vui lòng liên hệ hotline!', 16, 1);
        RETURN;
    END

    -- B. 🔥 ĐẾM SỐ PHIẾU THEO KHUNG GIỜ (60 phút)
    -- Logic: Trong cùng 1 giờ (VD: 09:00-09:59), chỉ cho đặt tối đa = số bác sĩ
    DECLARE @GioHenStart DATETIME = @ThoiGianHen;
    DECLARE @GioHenEnd DATETIME = DATEADD(HOUR, 1, @GioHenStart);

    SELECT @SoPhieuDaDat = COUNT(*)
    FROM PHIEU_DICH_VU
    WHERE MaCN = @MaCN
      AND CAST(TG_ThucHienDV AS DATE) = @NgayHen -- Cùng ngày
      AND DATEPART(HOUR, TG_ThucHienDV) = DATEPART(HOUR, @ThoiGianHen) -- Cùng giờ
      AND TrangThai IN ('DD', 'DTH'); -- Đã đặt hoặc đang thực hiện

    -- C. So sánh (1 bác sĩ = 1 slot/giờ)
    IF @SoPhieuDaDat >= @TongSoBacSi
    BEGIN
        DECLARE @ErrMsg2 NVARCHAR(300);
        SET @ErrMsg2 = N'Lỗi: Khung giờ ' + @GioHen + N' đã hết suất (' + 
                      CAST(@SoPhieuDaDat AS NVARCHAR) + '/' + 
                      CAST(@TongSoBacSi AS NVARCHAR) + N' slot). Vui lòng chọn giờ khác!';
        RAISERROR(@ErrMsg2, 16, 1);
        RETURN;
    END

    -- =============================================
    -- 5. INSERT DỮ LIỆU
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Tạo mã phiếu tự động
        DECLARE @MaPhieu NCHAR(10);
        DECLARE @HauTo INT;
        
        SELECT @HauTo = ISNULL(MAX(CAST(RIGHT(MaPhieu, 7) AS INT)), 0)
        FROM PHIEU_DICH_VU WITH (UPDLOCK, HOLDLOCK)
        WHERE LEFT(MaPhieu, 1) = 'P' AND ISNUMERIC(RIGHT(MaPhieu, 7)) = 1;

        SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo + 1 AS VARCHAR(7)), 7); 

        -- Đảm bảo unique
        WHILE EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu)
        BEGIN
            SET @HauTo = @HauTo + 1;
            SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo AS VARCHAR(7)), 7);
        END

        -- Insert vào PHIEU_DICH_VU
        INSERT INTO PHIEU_DICH_VU (
            MaPhieu, 
            TG_ThucHienDV, 
            TG_LapPhieu, 
            TrangThai, 
            LoaiPhieu, 
            MaCN, 
            MaNV, 
            MaKH
        )
        VALUES (
            @MaPhieu, 
            @ThoiGianHen, 
            GETDATE(), 
            'DD', -- Đã đặt
            @LoaiPhieu, 
            @MaCN, 
            NULL, -- Chưa assign bác sĩ
            @MaKH
        );
        
        -- Nếu là Khám bệnh và có triệu chứng -> Insert PHIEU_KHAM_BENH
        IF @LoaiPhieu = 'KB'
        BEGIN
            INSERT INTO PHIEU_KHAM_BENH (MaPhieu, MaTC, TrieuChung, ChanDoan, NgayHenTaiKham)
            VALUES (@MaPhieu, @MaTC, @TrieuChung, NULL, NULL);
        END
        
        -- Nếu là Tiêm vaccine -> Insert PHIEU_TIEM_VACCINE
        IF @LoaiPhieu = 'TV'
        BEGIN
            INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC)
            VALUES (@MaPhieu, @MaTC);
        END

        COMMIT TRANSACTION;
        
        -- Trả về thông tin phiếu vừa tạo
        SELECT @MaPhieu AS MaPhieuMoi;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @ErrMsg3 NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrMsg3, 16, 1);
    END CATCH
END
GO
/****** Object:  StoredProcedure [dbo].[sp_DieuDongNhanSu]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Điều động nhân sự
CREATE   PROC [dbo].[sp_DieuDongNhanSu]
    @MaNV NCHAR(10),
    @MaCN_Moi NCHAR(10),
    @NgayBD DATE,           -- Ngày bắt đầu ở chi nhánh mới
    @NgayKT DATE,           -- Ngày kết thúc dự kiến ở chi nhánh mới
    @GhiChu NVARCHAR(100) = NULL
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- 1. VALIDATION
    -- =============================================
    
    -- Kiểm tra ngày hợp lệ (Theo constraint của bảng: KT > BD)
    IF @NgayKT <= @NgayBD
    BEGIN
        RAISERROR(N'Lỗi: Ngày kết thúc phải lớn hơn ngày bắt đầu!', 16, 1);
        RETURN;
    END

    -- Kiểm tra nhân viên
    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaNV)
    BEGIN
        RAISERROR(N'Lỗi: Nhân viên không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra chi nhánh đích
    IF NOT EXISTS (SELECT 1 FROM CHI_NHANH WHERE MaCN = @MaCN_Moi)
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh chuyển đến không tồn tại!', 16, 1);
        RETURN;
    END

    -- Lấy chi nhánh hiện tại
    DECLARE @MaCN_Cu NCHAR(10);
    SELECT @MaCN_Cu = MaCN FROM NHAN_VIEN WHERE MaNV = @MaNV;

    -- Kiểm tra xem có chuyển trùng chi nhánh không
    IF @MaCN_Cu = @MaCN_Moi
    BEGIN
        RAISERROR(N'Lỗi: Nhân viên đang làm việc tại chi nhánh này rồi!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 2. THỰC THI (TRANSACTION)
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- BƯỚC A: Đóng hồ sơ công tác tại chi nhánh cũ
        -- Logic: Tìm đợt phân công đang "mở" (hoặc có hạn kết thúc sau ngày bắt đầu mới)
        -- Cập nhật NgayKT cũ = (Ngày bắt đầu mới - 1 ngày)
        
        UPDATE PHAN_CONG_CN
        SET NgayKT = DATEADD(DAY, -1, @NgayBD)
        WHERE MaNV = @MaNV 
          AND MaCN = @MaCN_Cu 
          AND NgayKT >= @NgayBD; 

        -- BƯỚC B: Tạo hồ sơ phân công mới tại chi nhánh mới theo input
        INSERT INTO PHAN_CONG_CN (MaCN, MaNV, NgayBD, NgayKT, Ghichu)
        VALUES (
            @MaCN_Moi, 
            @MaNV, 
            @NgayBD, 
            @NgayKT, 
            ISNULL(@GhiChu, N'Điều động theo quyết định')
        );

        -- BƯỚC C: Cập nhật Chi nhánh chính thức trong bảng NHAN_VIEN
        UPDATE NHAN_VIEN
        SET MaCN = @MaCN_Moi
        WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
        PRINT N'Đã điều chuyển nhân viên thành công và lưu lịch sử phân công.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DoanhThuChiNhanhTheoDot]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 9. Doanh thu chi nhÃ¡nh theo ngÃ y/thÃ¡ng/quÃ½/nÄƒm
CREATE   PROC [dbo].[sp_DoanhThuChiNhanhTheoDot]
    @MaCN NCHAR(10),
    @LoaiThongKe VARCHAR(10), -- 'NGAY', 'THANG', 'QUY', 'NAM'
    @Nam INT,
    @Thang INT = NULL,
    @Quy INT = NULL,
    @Ngay INT = NULL
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @TuNgay DATE, @DenNgay DATE;

    -- XÃ¡c Ä‘á»‹nh khoáº£ng thá»i gian
    IF @LoaiThongKe = 'NGAY'
    BEGIN
        SET @TuNgay = DATEFROMPARTS(@Nam, @Thang, @Ngay);
        SET @DenNgay = DATEADD(DAY, 1, @TuNgay);
    END
    ELSE IF @LoaiThongKe = 'THANG'
    BEGIN
        SET @TuNgay = DATEFROMPARTS(@Nam, @Thang, 1);
        SET @DenNgay = DATEADD(MONTH, 1, @TuNgay);
    END
    ELSE IF @LoaiThongKe = 'QUY'
    BEGIN
        SET @TuNgay = DATEFROMPARTS(@Nam, (@Quy - 1) * 3 + 1, 1);
        SET @DenNgay = DATEADD(QUARTER, 1, @TuNgay);
    END
    ELSE IF @LoaiThongKe = 'NAM'
    BEGIN
        SET @TuNgay = DATEFROMPARTS(@Nam, 1, 1);
        SET @DenNgay = DATEADD(YEAR, 1, @TuNgay);
    END

    -- TÃ­nh doanh thu
    SELECT 
        @MaCN AS MaChiNhanh,
        CN.TenCN,
        SUM(CASE WHEN HD.MaPhieu IS NOT NULL THEN HD.TongThanhTienSC ELSE 0 END) AS DoanhThuTrucTiep,
        SUM(CASE WHEN HDO.MaPhieu IS NOT NULL THEN HDO.TongThanhTienSC ELSE 0 END) AS DoanhThuOnline,
        SUM(COALESCE(HD.TongThanhTienSC, HDO.TongThanhTienSC, 0)) AS TongDoanhThu
    FROM CHI_NHANH CN
    LEFT JOIN PHIEU_DICH_VU P ON CN.MaCN = P.MaCN 
        AND P.TG_ThucHienDV >= @TuNgay 
        AND P.TG_ThucHienDV < @DenNgay
        AND P.TrangThai = 'DHT'
    LEFT JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    LEFT JOIN HD_TRUC_TUYEN HDO ON P.MaPhieu = HDO.MaPhieu
    WHERE CN.MaCN = @MaCN
    GROUP BY CN.MaCN, CN.TenCN;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_DoiMatKhau]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Đổi mật khẩu
CREATE   PROC [dbo].[sp_DoiMatKhau]
    @TenDangNhap VARCHAR(30),
    @MatKhauMoi VARCHAR(70)
AS
BEGIN
    SET NOCOUNT ON;
    
    BEGIN TRY
        UPDATE TAI_KHOAN
        SET MatKhau = @MatKhauMoi
        WHERE TenDangNhap = @TenDangNhap;
    END TRY
    BEGIN CATCH
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_GetServicesByBranch]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE PROCEDURE [dbo].[sp_GetServicesByBranch]
    @BranchID INT
AS
BEGIN
    -- Giả sử bà có bảng trung gian 'ChiNhanh_DichVu' hoặc logic tương tự
    -- Nếu không có bảng trung gian thì sửa lại theo database của bà
    SELECT dv.MaDichVu, dv.TenDichVu, dv.GiaTien
    FROM DichVu dv
    JOIN ChiNhanh_DichVu cndv ON dv.MaDichVu = cndv.MaDichVu
    WHERE cndv.MaChiNhanh = @BranchID
END
GO
/****** Object:  StoredProcedure [dbo].[sp_HoanTatDichVu]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 8. Nhân viên xác nhận phiếu đã hoàn tất sau khi khách hàng thực hiện xong
CREATE   PROC [dbo].[sp_HoanTatDichVu]
    @MaPhieu NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION
    -- Chỉ được hoàn tất khi phiếu đang ở trạng thái 'DTH' (Đang thực hiện)
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DTH')
    BEGIN
        RAISERROR(N'Lỗi: Phiếu chưa được Check-in hoặc đã hoàn tất trước đó!', 16, 1);
        RETURN;
    END

    -- 2. UPDATE
    BEGIN TRY
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DHT' -- Đã hoàn thành
        WHERE MaPhieu = @MaPhieu;

        -- PRINT N'Xác nhận hoàn tất dịch vụ.';
    END TRY
    BEGIN CATCH
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_HoanTatDonHangOnline]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Khách hàng hoàn tất đơn hàng online
CREATE   PROC [dbo].[sp_HoanTatDonHangOnline]
    @MaPhieu NCHAR(10),
    @DiemMuonDung INT = 0 -- Khách nhập số điểm (số nguyên) muốn xài
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION CƠ BẢN
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Lỗi: Đơn hàng không hợp lệ hoặc đã hoàn tất!', 16, 1);
        RETURN;
    END

    IF @DiemMuonDung < 0
    BEGIN
        RAISERROR(N'Lỗi: Số điểm sử dụng không được âm!', 16, 1);
        RETURN;
    END

    -- 2. LẤY THÔNG TIN ĐƠN HÀNG
    DECLARE @MaKH NCHAR(10);
    DECLARE @TongTienHang DECIMAL(18,2) = 0;
    DECLARE @PhiGiaoHang DECIMAL(18,2) = 0;
    
    SELECT @MaKH = MaKH FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;
    SELECT @PhiGiaoHang = ISNULL(PhiGiaoHang, 0) FROM HD_TRUC_TUYEN WHERE MaPhieu = @MaPhieu;
    SELECT @TongTienHang = ISNULL(SUM(ThanhTien), 0) FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu;

    -- ---------------------------------------------------------
    -- A. TÍNH TIỀN GIẢM TỪ HẠNG THÀNH VIÊN
    -- ---------------------------------------------------------
    DECLARE @MucGiamGia INT = 0; -- Ví dụ: 5, 7, 10...
    DECLARE @TienGiamTuHangTV DECIMAL(18,2) = 0;

    -- Lấy % giảm giá từ hạng năm ngoái
    SELECT @MucGiamGia = HTV.KhuyenMaiUuTien 
    FROM XEP_HANG_NAM XHN
    JOIN HANG_TV HTV ON XHN.MaHang = HTV.MaHang
    WHERE XHN.MaKH = @MaKH 
      AND XHN.Nam = (YEAR(GETDATE()) - 1);

    SET @MucGiamGia = ISNULL(@MucGiamGia, 0);

    -- Công thức 1: Tiền giảm hạng = Tổng tiền hàng * % / 100
    SET @TienGiamTuHangTV = @TongTienHang * (CAST(@MucGiamGia AS FLOAT) / 100.0);

    -- ---------------------------------------------------------
    -- B. TÍNH TIỀN GIẢM TỪ ĐIỂM TÍCH LŨY
    -- ---------------------------------------------------------
    DECLARE @DiemHienCo INT;
    SELECT @DiemHienCo = ISNULL(TongDiemTichLuy, 0) FROM KHACH_HANG WHERE MaKH = @MaKH;

    -- Check điểm tồn
    IF @DiemMuonDung > @DiemHienCo
    BEGIN
        RAISERROR(N'Lỗi: Bạn không đủ điểm tích lũy (Hiện có: %d)!', 16, 1, @DiemHienCo);
        RETURN;
    END

    -- Công thức 2: Tiền giảm điểm = Số điểm * 1000
    DECLARE @TienGiamTuDiem DECIMAL(18,2);
    SET @TienGiamTuDiem = @DiemMuonDung * 1000.0;

    -- ---------------------------------------------------------
    -- C. TỔNG HỢP VÀO CỘT KHUYẾN MÃI
    -- ---------------------------------------------------------
    DECLARE @TongTienKhuyenMai DECIMAL(18,2);
    -- KhuyenMai = (Tiền giảm Hạng) + (Tiền giảm Điểm)
    SET @TongTienKhuyenMai = @TienGiamTuHangTV + @TienGiamTuDiem;

    -- Check an toàn: Tổng giảm giá không được vượt quá (Tiền hàng + Ship)
    DECLARE @TongCanThanhToan DECIMAL(18,2) = @TongTienHang + @PhiGiaoHang;
    
    IF @TongTienKhuyenMai > @TongCanThanhToan
    BEGIN
        RAISERROR(N'Lỗi: Tổng giá trị giảm giá vượt quá số tiền cần thanh toán!', 16, 1);
        RETURN;
    END

    -- Tính số tiền khách thực sự phải trả
    DECLARE @TongThanhTienSC DECIMAL(18,2);
    SET @TongThanhTienSC = @TongCanThanhToan - @TongTienKhuyenMai;

    -- 3. CẬP NHẬT DATABASE (TRANSACTION)
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Cập nhật Hóa Đơn
        UPDATE HD_TRUC_TUYEN
        SET TongThanhTien = @TongTienHang,       -- Gốc
            KhuyenMai = @TongTienKhuyenMai,      -- Tổng tiền giảm (Hạng + Điểm)
            DiemQuyDoi = @DiemMuonDung,          -- Số điểm đã xài (Integer)
            TongThanhTienSC = @TongThanhTienSC   -- Khách phải trả
        WHERE MaPhieu = @MaPhieu;

        -- B2: TRỪ ĐIỂM (Nếu có dùng)
        IF @DiemMuonDung > 0
        BEGIN
            UPDATE KHACH_HANG
            SET TongDiemTichLuy = TongDiemTichLuy - @DiemMuonDung
            WHERE MaKH = @MaKH;
        END

        COMMIT TRANSACTION;

        -- 4. TRẢ VỀ KẾT QUẢ CHO APP
        SELECT 
            @MaPhieu AS MaDonHang,
            FORMAT(@TongTienHang, 'N0', 'vi-VN') AS TienHang,
            FORMAT(@PhiGiaoHang, 'N0', 'vi-VN') AS PhiShip,
            FORMAT(@TongTienKhuyenMai, 'N0', 'vi-VN') AS TongTienGiamGia, -- App hiển thị dòng này là "Tổng Khuyến Mãi"
            FORMAT(@TongThanhTienSC, 'N0', 'vi-VN') AS TongThanhToan;

    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_HuyDonOnline]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. Hủy đơn hàng online (Được hủy trong vòng 2 tiếng sau khi đặt)
CREATE   PROC [dbo].[sp_HuyDonOnline]
    @MaPhieu NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    DECLARE @TrangThaiHienTai VARCHAR(3);
    DECLARE @TG_LapPhieu DATETIME;
    DECLARE @MaCN NCHAR(10);
    DECLARE @MaKH NCHAR(10);

    SELECT 
        @TrangThaiHienTai = TrangThai, 
        @TG_LapPhieu = TG_LapPhieu,
        @MaCN = MaCN,
        @MaKH = MaKH
    FROM PHIEU_DICH_VU 
    WHERE MaPhieu = @MaPhieu;

    IF @TrangThaiHienTai IS NULL
    BEGIN
        RAISERROR(N'Đơn hàng không tồn tại!', 16, 1);
        RETURN;
    END

    IF @TrangThaiHienTai <> 'DD'
    BEGIN
        RAISERROR(N'Không thể hủy đơn hàng này!', 16, 1);
        RETURN;
    END

    IF DATEDIFF(MINUTE, @TG_LapPhieu, GETDATE()) > 120
    BEGIN
        RAISERROR(N'Đã quá thời gian quy định hủy đơn.', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. HOÀN TRẢ KHO
        UPDATE k
        SET k.SoLuongTon = k.SoLuongTon + c.SoLuong
        FROM TON_KHO k
        INNER JOIN CT_MUA_HANG c ON k.MaMatHang = c.MaMatHang
        WHERE c.MaPhieu = @MaPhieu AND k.MaCN = @MaCN;

        -- 2. XỬ LÝ ĐIỂM TÍCH LŨY (ROLLBACK ĐIỂM)
        DECLARE @DiemDaDung INT = 0;
        DECLARE @TongTienSC DECIMAL(18,2) = 0;
        
        -- Lấy số điểm đã dùng và số tiền đã trả để tính điểm cần thu hồi
        SELECT @DiemDaDung = ISNULL(DiemQuyDoi, 0), 
               @TongTienSC = ISNULL(TongThanhTienSC, 0)
        FROM HD_TRUC_TUYEN 
        WHERE MaPhieu = @MaPhieu;

        -- a. Trả lại điểm đã dùng cho khách
        IF @DiemDaDung > 0
        BEGIN
            UPDATE KHACH_HANG 
            SET TongDiemTichLuy = TongDiemTichLuy + @DiemDaDung 
            WHERE MaKH = @MaKH;
        END

        -- 3. UPDATE TRẠNG THÁI
        UPDATE PHIEU_DICH_VU SET TrangThai = 'DH' WHERE MaPhieu = @MaPhieu;
        UPDATE HD_TRUC_TUYEN SET TrangThaiHD = 'DH' WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;
        PRINT N'Đã hủy đơn, hoàn kho và hoàn điểm thành công.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_HuyLichHen]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP 1: Khách hàng tự hủy
CREATE   PROCEDURE [dbo].[sp_HuyLichHen]
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
        
        --  KHÔNG HOÀN KHO vì phiếu DD chưa lấy hàng từ kho
        --  KHÔNG XÓA CT_TIEM_VC vì cần giữ lịch sử đã đăng ký (chưa tiêm thật)
        
        -- Chỉ xóa đăng ký gói tiêm (nếu có)
        DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @MaPhieu;

        --  GIỮ LẠI PHIEU_KHAM_BENH và PHIEU_TIEM_VACCINE để lưu thông tin thú cưng
        
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
/****** Object:  StoredProcedure [dbo].[sp_KhoiTaoDonHangOnline]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 1. Khách mua hàng online
CREATE   PROC [dbo].[sp_KhoiTaoDonHangOnline]
    @MaKhachHang VARCHAR(10),
    @MaChiNhanh VARCHAR(10),
    @DiaChiGiaoHang NVARCHAR(200),
    @HinhThucThanhToan NVARCHAR(20),
    @NgayMuonNhan DATETIMEOFFSET
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Validate: require at least 24 hours (use seconds + small tolerance to avoid rounding issues)
        DECLARE @SecondsDiff INT = DATEDIFF(SECOND, SYSUTCDATETIME(), SWITCHOFFSET(@NgayMuonNhan, '+00:00'));
        IF @SecondsDiff < (24 * 60 * 60 - 30)  -- allow 30s tolerance
        BEGIN
            RAISERROR(N'Lỗi: Ngày nhận hàng phải cách hiện tại ít nhất 24 giờ.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- Tính số ngày theo ngày calendar để quyết định phí
        DECLARE @SoNgayCho INT;
        SET @SoNgayCho = DATEDIFF(DAY, CAST(SYSUTCDATETIME() AT TIME ZONE 'UTC' AS DATE), CAST(SWITCHOFFSET(@NgayMuonNhan, '+00:00') AS DATE));

        IF @SoNgayCho < 1
        BEGIN
             RAISERROR(N'Lỗi: Ngày nhận hàng phải sau ngày đặt ít nhất 1 ngày.', 16, 1);
             ROLLBACK TRANSACTION;
             RETURN;
        END

        DECLARE @PhiGiaoHang DECIMAL(18,2);
        IF @SoNgayCho = 1 SET @PhiGiaoHang = 35000;
        ELSE IF @SoNgayCho = 2 SET @PhiGiaoHang = 25000;
        ELSE SET @PhiGiaoHang = 15000;

        -- KIỂM TRA ĐỊA LÝ
        DECLARE @DiaChiChiNhanh NVARCHAR(200) = '';
        SELECT @DiaChiChiNhanh = ISNULL(DiaChi, N'') FROM CHI_NHANH WHERE MaCN = @MaChiNhanh;

        DECLARE @KhuVucChiNhanh NVARCHAR(50) = N'';
        IF @DiaChiChiNhanh COLLATE Latin1_General_CI_AI LIKE N'%Hồ Chí Minh%' COLLATE Latin1_General_CI_AI SET @KhuVucChiNhanh = N'Hồ Chí Minh';
        ELSE IF @DiaChiChiNhanh COLLATE Latin1_General_CI_AI LIKE N'%Cần Thơ%' COLLATE Latin1_General_CI_AI SET @KhuVucChiNhanh = N'Cần Thơ';
        ELSE IF @DiaChiChiNhanh COLLATE Latin1_General_CI_AI LIKE N'%Hà Nội%' COLLATE Latin1_General_CI_AI SET @KhuVucChiNhanh = N'Hà Nội';
        ELSE IF @DiaChiChiNhanh COLLATE Latin1_General_CI_AI LIKE N'%Đà Nẵng%' COLLATE Latin1_General_CI_AI SET @KhuVucChiNhanh = N'Đà Nẵng';
        ELSE IF @DiaChiChiNhanh COLLATE Latin1_General_CI_AI LIKE N'%Bình Dương%' COLLATE Latin1_General_CI_AI SET @KhuVucChiNhanh = N'Bình Dương';

        IF @KhuVucChiNhanh = N'' OR (@DiaChiGiaoHang COLLATE Latin1_General_CI_AI NOT LIKE N'%' + @KhuVucChiNhanh + N'%' COLLATE Latin1_General_CI_AI)
        BEGIN
            RAISERROR(N'Lỗi: Chi nhánh chỉ giao nội thành cùng khu vực.', 16, 1);
            ROLLBACK TRANSACTION;
            RETURN;
        END

        -- SINH MÃ PHIẾU
        DECLARE @MaxMaPhieu VARCHAR(10);
        DECLARE @NextID INT;
        DECLARE @MaPhieuMoi NCHAR(10);

        SELECT @MaxMaPhieu = MAX(MaPhieu) FROM PHIEU_DICH_VU WHERE MaPhieu LIKE 'P%';

        IF @MaxMaPhieu IS NULL
            SET @NextID = 1;
        ELSE
            SET @NextID = CAST(SUBSTRING(@MaxMaPhieu, 2, 7) AS INT) + 1;

        SET @MaPhieuMoi = 'P' + RIGHT('0000000' + CAST(@NextID AS VARCHAR(7)), 7);

        -- INSERT - TG_ThucHienDV sẽ là ngày + giờ khách chọn
        INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_ThucHienDV, TG_LapPhieu, TrangThai, LoaiPhieu, MaCN, MaNV, MaKH)
        VALUES (@MaPhieuMoi, @NgayMuonNhan, GETDATE(), 'DD', 'MH', @MaChiNhanh, NULL, @MaKhachHang);

        INSERT INTO HD_TRUC_TUYEN (MaPhieu, TongThanhTien, KhuyenMai, DiemQuyDoi, TongThanhTienSC, PhuongThucTT, DiaChiGiaoHang, PhiGiaoHang, TrangThaiHD)
        VALUES (@MaPhieuMoi, 0, 0, 0, 0, @HinhThucThanhToan, @DiaChiGiaoHang, @PhiGiaoHang, 'DTT');

        INSERT INTO PHIEU_MUA_HANG (MaPhieu) VALUES (@MaPhieuMoi);

        COMMIT TRANSACTION;

        SELECT @MaPhieuMoi AS MaPhieu, @PhiGiaoHang AS PhiVanChuyen;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_KiemTraGoiDangTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_KiemTraGoiDangTiem]
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tìm gói vaccine đang tiêm (có trong DANG_KI_GOI_TIEM, chưa tiêm đủ)
    SELECT TOP 1
        DK.MaGoi,
        DK.MaVaccine,
        MH.TenMatHang AS TenVaccine,
        GOI.TenGoi,
        GOI.SoMuiTuongUng AS TongSoMui,
        DK.NgayHetHan,
        --  Đếm số mũi đã tiêm của gói này (CHỈ PHIẾU ĐÃ HOÀN TẤT)
        -- Lý do: Phải đếm đúng số mũi thực tế đã tiêm, không tính phiếu bị hủy
        ISNULL((
            SELECT COUNT(*) 
            FROM CT_TIEM_VC CT
            INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
            INNER JOIN PHIEU_DICH_VU PDV2 ON CT.MaPhieu = PDV2.MaPhieu
            WHERE PTV.MaTC = @MaTC
              AND CT.MaVaccine = DK.MaVaccine
              AND PDV2.TrangThai = 'DHT' -- CHỈ TÍNH PHIẾU ĐÃ HOÀN TẤT
              AND PDV2.TG_LapPhieu >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
        ), 0) AS SoMuiDaTiem,
        -- Số mũi còn lại
        GOI.SoMuiTuongUng - ISNULL((
            SELECT COUNT(*) 
            FROM CT_TIEM_VC CT
            INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
            INNER JOIN PHIEU_DICH_VU PDV2 ON CT.MaPhieu = PDV2.MaPhieu
            WHERE PTV.MaTC = @MaTC
              AND CT.MaVaccine = DK.MaVaccine
              AND PDV2.TrangThai = 'DHT' -- CHỈ TÍNH PHIẾU ĐÃ HOÀN TẤT
              AND PDV2.TG_LapPhieu >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
        ), 0) AS SoMuiConLai
    FROM DANG_KI_GOI_TIEM DK
    INNER JOIN GOI_TIEM_VC GOI ON DK.MaGoi = GOI.MaGoi
    INNER JOIN PHIEU_TIEM_VACCINE PTV ON DK.MaPhieu = PTV.MaPhieu
    INNER JOIN MAT_HANG MH ON DK.MaVaccine = MH.MaMatHang
    INNER JOIN PHIEU_DICH_VU PDV ON DK.MaPhieu = PDV.MaPhieu
    WHERE PTV.MaTC = @MaTC
      AND DK.HieuLuc = 1
      --  BỎ điều kiện PDV.TrangThai = 'DHT' để tìm gói dù phiếu đăng ký đã hoàn tất hay chưa
      -- Vì khách có thể đến lần 2 (phiếu mới chưa hoàn tất) nhưng gói vẫn còn hiệu lực
      AND (DK.NgayHetHan IS NULL OR DK.NgayHetHan > GETDATE())
      -- CHỈ LẤY GÓI CHƯA TIÊM ĐỦ SỐ MŨI QUY ĐỊNH
      AND GOI.SoMuiTuongUng > ISNULL((
          SELECT COUNT(*) 
          FROM CT_TIEM_VC CT
          INNER JOIN PHIEU_TIEM_VACCINE PTV2 ON CT.MaPhieu = PTV2.MaPhieu
          INNER JOIN PHIEU_DICH_VU PDV3 ON CT.MaPhieu = PDV3.MaPhieu
          WHERE PTV2.MaTC = @MaTC
            AND CT.MaVaccine = DK.MaVaccine
            AND PDV3.TrangThai = 'DHT' -- CHỈ TÍNH PHIẾU ĐÃ HOÀN TẤT
            AND PDV3.TG_LapPhieu >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
      ), 0)
    --  LẤY GÓI CŨ NHẤT (đăng ký đầu tiên) để đếm đủ số mũi từ đầu
    ORDER BY DK.MaPhieu ASC;
    
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_LayDanhSachBacSi_TrangThai]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_LayDanhSachBacSi_TrangThai]
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        NV.MaNV,
        U.HoTen AS TenNV, --  Đổi tên cho đúng với frontend
        
        -- Đếm xem ổng đang ôm bao nhiêu ca 'DTH' (Đang thực hiện)
        (SELECT COUNT(*) 
         FROM PHIEU_DICH_VU P 
         WHERE P.MaNV = NV.MaNV AND P.TrangThai = 'DTH') AS SoCaDangKham,
         
        --  Đánh dấu trạng thái: "Rảnh" hoặc "Bận"
        CASE 
            WHEN (SELECT COUNT(*) FROM PHIEU_DICH_VU P WHERE P.MaNV = NV.MaNV AND P.TrangThai = 'DTH') > 0 
            THEN N'Bận'
            ELSE N'Rảnh'
        END AS TrangThai

    FROM NHAN_VIEN NV
    JOIN [USER] U ON NV.MaNV = U.MaUser -- JOIN để lấy thông tin cá nhân
    
    WHERE NV.MaCN = @MaCN 
      AND NV.ChucVu IN (N'Bác sĩ thú y', N'Bác sĩ') -- Chỉ lấy bác sĩ
      -- AND U.TrangThai = 1 -- (Nếu bảng USER có cột TrangThai để check khóa nick thì bà mở dòng này ra)
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_LayDanhSachDatLich]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_LayDanhSachDatLich]
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
        ISNULL(HTT.TongThanhTien, HDTT.TongThanhTienSC) AS TongThanhTien, --  LẤY TỪ HD_TRUC_TUYEN HOẶC HD_TRUC_TIEP
        HTT.MaPhieu AS MaHD,  -- Để biết có HD_TRUC_TUYEN không
        HDTT.PhuongThucTT AS PhuongThucTT, --  LẤY PHƯƠNG THỨC THANH TOÁN ĐỂ BIẾT ĐÃ XUẤT HÓA ĐƠN CHƯA
        RTRIM(HDTT.MaNV) AS MaNV_XuatHD, --  MÃ NHÂN VIÊN XUẤT HÓA ĐƠN (từ HD_TRUC_TIEP)
        RTRIM(P.MaNV) AS MaNV_BacSi, --  MÃ BÁC SĨ (từ PHIEU_DICH_VU) - đổi tên để phân biệt
        U_BacSi.HoTen AS TenBacSi --  LẤY TÊN BÁC SĨ ĐÃ GÁN
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN [USER] U_BacSi ON P.MaNV = U_BacSi.MaUser --  JOIN ĐỂ LẤY TÊN BÁC SĨ
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HDTT ON P.MaPhieu = HDTT.MaPhieu --  JOIN ĐỂ LẤY PHƯƠNG THỨC TT
    WHERE P.MaCN = @MaCN 
      AND (@TrangThai IS NULL OR RTRIM(P.TrangThai) = @TrangThai)
      AND (
          --  LOGIC MỚI: Hiện đơn nếu thỏa 1 trong 2:
          -- 1. Ngày ĐẶT nằm trong khoảng (đơn mới đặt cần xử lý)
          -- 2. Ngày MUỐN NHẬN nằm trong khoảng (đơn đến hạn giao)
          CAST(P.TG_LapPhieu AS DATE) BETWEEN @TuNgay AND @DenNgay
          OR
          CAST(P.TG_ThucHienDV AS DATE) BETWEEN @TuNgay AND @DenNgay
      ) 
      AND (
          -- Cho phép các role nhân viên xem hết
          (RTRIM(@Role_Xem) IN (N'Nhân viên Tiếp tân', N'Nhân viên bán hàng', N'Quản lý chi nhánh', N'Admin'))
          OR 
          -- Bác sĩ chỉ thấy đúng ca của mình (bao gồm 'Bác sĩ thú y')
          (RTRIM(P.MaNV) = RTRIM(@MaNV_Xem))
      )
    ORDER BY P.TG_ThucHienDV ASC
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_LayDanhSachDatLich_HomNay]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Nhân viên tiếp tân + bán hàng

CREATE   PROC [dbo].[sp_LayDanhSachDatLich_HomNay]
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        P.MaPhieu,
        P.TG_LapPhieu, -- Giờ khách đặt
        U.HoTen AS TenKhachHang,
        TC.Ten AS TenThuCung,
        
        CASE P.LoaiPhieu 
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm chủng'
            ELSE N'Mua hàng'
        END AS LoaiDichVu,
        P.TrangThai

    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    
    -- Xử lý lấy thông tin thú cưng (Giống cái SP bác sĩ lúc nãy)
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC

    WHERE P.MaCN = @MaCN 
      AND P.TrangThai = 'DD' -- Chỉ lấy phiếu Đã đặt
      AND CAST(P.TG_LapPhieu AS DATE) = CAST(GETDATE() AS DATE) -- Chỉ lấy lịch hôm nay
    ORDER BY P.TG_LapPhieu ASC
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_LayDanhSachNhanVien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 6. Quáº£n lÃ½ nhÃ¢n viÃªn chi nhÃ¡nh - Xem danh sÃ¡ch
CREATE   PROC [dbo].[sp_LayDanhSachNhanVien]
    @MaCN NCHAR(10) = NULL,
    @ChucVu NVARCHAR(50) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        NV.MaNV,
        U.HoTen,
        U.NgaySinh,
        U.GioiTinh,
        NV.ChucVu,
        NV.NgayVaoLam,
        NV.LuongCoBan,
        CN.TenCN AS ChiNhanh,
        CN.MaCN
    FROM NHAN_VIEN NV
    JOIN [USER] U ON NV.MaNV = U.MaUser
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    WHERE 
        (@MaCN IS NULL OR NV.MaCN = @MaCN)
        AND (@ChucVu IS NULL OR NV.ChucVu = @ChucVu)
    ORDER BY NV.NgayVaoLam DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_NhapHangVaoKho]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 13. Nhập hàng vào kho
CREATE   PROC [dbo].[sp_NhapHangVaoKho]
    @MaCN NCHAR(10),
    @MaMatHang NCHAR(10),
    @SoLuongNhap INT
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Validation
    IF @SoLuongNhap <= 0
    BEGIN
        RAISERROR(N'Số lượng nhập phải lớn hơn 0', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM CHI_NHANH WHERE MaCN = @MaCN)
    BEGIN
        RAISERROR(N'Chi nhánh không tồn tại', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM MAT_HANG WHERE MaMatHang = @MaMatHang)
    BEGIN
        RAISERROR(N'Mặt hàng không tồn tại', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        IF EXISTS (SELECT 1 FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaMatHang)
        BEGIN
            -- Update cộng dồn
            UPDATE TON_KHO
            SET SoLuongTon = SoLuongTon + @SoLuongNhap
            WHERE MaCN = @MaCN AND MaMatHang = @MaMatHang;
        END
        ELSE
        BEGIN
            -- Insert mới
            INSERT INTO TON_KHO (MaCN, MaMatHang, SoLuongTon)
            VALUES (@MaCN, @MaMatHang, @SoLuongNhap);
        END

        COMMIT TRANSACTION;
        PRINT N'Nhập kho thành công.';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TaoPhieuTrucTiep]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 4. Nhân viên tạo phiếu DV cho khách trực tiếp tại cửa hàng
CREATE   PROC [dbo].[sp_TaoPhieuTrucTiep]
    @MaKH NCHAR(10),
    @MaTC NCHAR(10) = NULL,
    @MaCN NCHAR(10),
    @MaNV NCHAR(10), 
    @LoaiPhieu VARCHAR(2), 
    @TrieuChung NVARCHAR(200) = NULL,
    @MaVaccine NCHAR(10) = NULL,  -- Vaccine lẻ (nếu có)
    @MaGoi NCHAR(10) = NULL        -- Gói tiêm (nếu có)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- 1. VALIDATION
    -- =============================================
    
    -- Check bắt buộc nhập thú cưng với loại phiếu KB/TV
    IF (@LoaiPhieu IN ('KB', 'TV') AND @MaTC IS NULL)
    BEGIN
        RAISERROR(N'Lỗi: Vui lòng chọn thú cưng để tạo phiếu khám hoặc tiêm!', 16, 1);
        RETURN;
    END

    -- KIỂM TRA QUYỀN SỞ HỮU THÚ CƯNG
    -- Chỉ kiểm tra nếu có mã thú cưng được truyền vào
    IF @MaTC IS NOT NULL
    BEGIN
        IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC AND MaKH = @MaKH)
        BEGIN
            RAISERROR(N'Lỗi: Thú cưng này không tồn tại hoặc không thuộc về khách hàng đang chọn!', 16, 1);
            RETURN;
        END
    END
    
    -- Validate vaccine nếu là phiếu tiêm vaccine
    IF @LoaiPhieu = 'TV'
    BEGIN
        -- Nếu chọn vaccine lẻ, kiểm tra tồn kho
        IF @MaVaccine IS NOT NULL
        BEGIN
            DECLARE @TonKho INT;
            SELECT @TonKho = SoLuongTon 
            FROM TON_KHO 
            WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;
            
            IF ISNULL(@TonKho, 0) < 1
            BEGIN
                RAISERROR(N'Lỗi: Vaccine đã hết hàng hoặc không tồn tại!', 16, 1);
                RETURN;
            END
        END
        
        -- Nếu chọn gói tiêm, kiểm tra gói tồn tại
        IF @MaGoi IS NOT NULL
        BEGIN
            IF NOT EXISTS (SELECT 1 FROM GOI_TIEM_VC WHERE MaGoi = @MaGoi)
            BEGIN
                RAISERROR(N'Lỗi: Gói tiêm không tồn tại!', 16, 1);
                RETURN;
            END
        END
    END

    -- Check giờ mở cửa
    IF NOT EXISTS (
        SELECT 1 FROM CHI_NHANH 
        WHERE MaCN = @MaCN 
        AND CAST(GETDATE() AS TIME) BETWEEN Giomocua AND Giodongcua
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh hiện đang đóng cửa!', 16, 1);
        RETURN;
    END

    -- Check Dịch vụ có tại chi nhánh không
    -- Giả định DV01: Khám bệnh, DV02: Tiêm, DV03: Mua hàng
    IF @LoaiPhieu = 'KB' AND NOT EXISTS (
        SELECT 1 
        FROM DV_CN 
        WHERE MaCN = @MaCN AND MaLoaiDV = (SELECT MaLoaiDV FROM LOAI_DICH_VU WHERE MaLoaiDV='DV01')
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Khám bệnh!', 16, 1);
        RETURN;
    END

    IF @LoaiPhieu = 'TV' AND NOT EXISTS (
        SELECT 1 
        FROM DV_CN 
        WHERE MaCN = @MaCN AND MaLoaiDV = (SELECT MaLoaiDV FROM LOAI_DICH_VU WHERE MaLoaiDV ='DV02')
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Tiêm vaccine!', 16, 1);
        RETURN;
    END

    IF @LoaiPhieu = 'MH' AND NOT EXISTS (
        SELECT 1 
        FROM DV_CN 
        WHERE MaCN = @MaCN AND MaLoaiDV = (SELECT MaLoaiDV FROM LOAI_DICH_VU WHERE MaLoaiDV ='DV03')
    )
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Bán hàng!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 2. THỰC THI (TRANSACTION)
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        -- Tạo Mã Phiếu
        DECLARE @MaPhieu NCHAR(10);
        DECLARE @HauTo INT;
        
        -- Locking để tránh trùng mã khi đông khách
        SELECT @HauTo = ISNULL(MAX(CAST(RIGHT(MaPhieu, 7) AS INT)), 0)
        FROM PHIEU_DICH_VU WITH (UPDLOCK, HOLDLOCK)
        WHERE LEFT(MaPhieu, 1) = 'P' AND ISNUMERIC(RIGHT(MaPhieu, 7)) = 1;

        SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo + 1 AS VARCHAR(7)), 7);

        -- Vòng lặp check trùng
        WHILE EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu)
        BEGIN
            SET @HauTo = @HauTo + 1;
            SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo AS VARCHAR(7)), 7);
        END

        -- Insert Bảng Cha
        -- Với khách vãng lai, TG_ThucHienDV là thời điểm hiện tại
        INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_ThucHienDV, TG_LapPhieu, TrangThai, LoaiPhieu, MaCN, MaNV, MaKH)
        VALUES (@MaPhieu, GETDATE(), GETDATE(), 'DD', @LoaiPhieu, @MaCN, @MaNV, @MaKH);
        
        -- Insert Bảng Con
        IF @LoaiPhieu = 'KB'
        BEGIN
             INSERT INTO PHIEU_KHAM_BENH (MaPhieu, MaTC, TrieuChung) 
             VALUES (@MaPhieu, @MaTC, ISNULL(@TrieuChung, N'Khám trực tiếp'));
        END
        ELSE IF @LoaiPhieu = 'TV'
        BEGIN
             INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC) 
             VALUES (@MaPhieu, @MaTC);
        END
        ELSE IF @LoaiPhieu = 'MH'
        BEGIN
             INSERT INTO PHIEU_MUA_HANG (MaPhieu) VALUES (@MaPhieu);
        END

        COMMIT TRANSACTION;
        SELECT @MaPhieu AS MaPhieuMoi;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TaoPhieuVangLai_Full]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_TaoPhieuVangLai_Full]
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
/****** Object:  StoredProcedure [dbo].[sp_ThemMatHang]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 14. Thêm 1 mặt hàng mới
CREATE   PROC [dbo].[sp_ThemMatHang]
    @TenMatHang NVARCHAR(80),
    @HangSX NVARCHAR(50),
    @NgaySanXuat DATE,
    @NgayHetHan DATE,
    @DonGia DECIMAL(18,2),
    @LoaiMH VARCHAR(3), -- 'T', 'VC', 'SPK' (Dùng để phân loại insert vào bảng con)
    
    -- Các tham số riêng (Nullable)
    @TacDungPhu NVARCHAR(200) = NULL,   -- Cho Thuốc
    @DangBaoChe NVARCHAR(70) = NULL,    -- Cho Thuốc
    @LoaiThuoc NVARCHAR(20) = NULL,     -- Cho Thuốc
    @ChongChiDinh NVARCHAR(200) = NULL, -- Cho Vaccine
    @LoaiSP NVARCHAR(70) = NULL         -- Cho SP Khác (Bắt buộc nếu là SPK)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- 1. VALIDATION ĐẦU VÀO
    -- =============================================
    
    -- Kiểm tra loại mặt hàng hợp lệ
    IF @LoaiMH NOT IN ('T', 'VC', 'SPK')
    BEGIN
        RAISERROR(N'Lỗi: Loại mặt hàng không hợp lệ (Chỉ nhận T, VC, SPK)!', 16, 1);
        RETURN;
    END

    -- Kiểm tra riêng cho Sản Phẩm Khác (SPK)
    IF @LoaiMH = 'SPK'
    BEGIN
        IF @LoaiSP IS NULL
        BEGIN
            RAISERROR(N'Lỗi: Vui lòng chọn Loại sản phẩm (Đồ chơi, Phụ kiện...)!', 16, 1);
            RETURN;
        END

        IF @LoaiSP NOT IN (N'Đồ chơi', N'Phụ kiện', N'Thức ăn', N'Quần áo')
        BEGIN
            RAISERROR(N'Lỗi: Loại sản phẩm không hợp lệ! Chỉ chấp nhận: Đồ chơi, Phụ kiện, Thức ăn, Quần áo.', 16, 1);
            RETURN;
        END
    END

    -- =============================================
    -- 2. SINH MÃ TỰ ĐỘNG (Format: MHxxxxxx)
    -- =============================================
    DECLARE @MaMatHang NCHAR(10);
    DECLARE @MaxID INT;
    
    -- Lấy số lớn nhất hiện tại của TẤT CẢ các mặt hàng có mã bắt đầu bằng MH
    SELECT @MaxID = MAX(CAST(RIGHT(MaMatHang, 6) AS INT)) 
    FROM MAT_HANG 
    WHERE MaMatHang LIKE 'MH%';

    IF @MaxID IS NULL SET @MaxID = 0;
    
    -- Tạo mã mới (Ví dụ: MH000001, MH000002...)
    SET @MaMatHang = 'MH' + RIGHT('000000' + CAST(@MaxID + 1 AS VARCHAR(6)), 6);

    -- Kiểm tra trùng lặp (Double check)
    WHILE EXISTS (SELECT 1 FROM MAT_HANG WHERE MaMatHang = @MaMatHang)
    BEGIN
        SET @MaxID = @MaxID + 1;
        SET @MaMatHang = 'MH' + RIGHT('000000' + CAST(@MaxID AS VARCHAR(6)), 6);
    END

    -- =============================================
    -- 3. INSERT DỮ LIỆU
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Insert vào bảng cha MAT_HANG
        INSERT INTO MAT_HANG (MaMatHang, TenMatHang, HangSX, NgaySanXuat, NgayHetHan, DonGia, LoaiMH)
        VALUES (@MaMatHang, @TenMatHang, @HangSX, @NgaySanXuat, @NgayHetHan, @DonGia, @LoaiMH);

        -- B2: Insert vào bảng con tương ứng dựa trên LoaiMH
        IF @LoaiMH = 'T'
        BEGIN
            INSERT INTO THUOC (MaThuoc, TacDungPhu, DangBaoChe, LoaiThuoc, DonGia)
            VALUES (@MaMatHang, @TacDungPhu, @DangBaoChe, ISNULL(@LoaiThuoc, N'Không cần kê đơn'), @DonGia);
        END
        ELSE IF @LoaiMH = 'VC'
        BEGIN
            INSERT INTO VACCINE (MaVaccine, ChongChiDinh, DonGia)
            VALUES (@MaMatHang, @ChongChiDinh, @DonGia);
        END
        ELSE IF @LoaiMH = 'SPK'
        BEGIN
            INSERT INTO SAN_PHAM_KHAC (MaSP, LoaiSP)
            VALUES (@MaMatHang, @LoaiSP);
        END

        COMMIT TRANSACTION;
        
        -- Trả về mã hàng mới
        SELECT @MaMatHang AS MaMatHangMoi;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThemNhanVien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 7. ThÃªm nhÃ¢n viÃªn má»›i
CREATE   PROC [dbo].[sp_ThemNhanVien]
    @HoTen NVARCHAR(50),
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(3),
    @ChucVu NVARCHAR(50),
    @NgayVaoLam DATE,
    @LuongCoBan DECIMAL(12,2),
    @MaCN NCHAR(10),
    @TenDangNhap VARCHAR(30),
    @MatKhau VARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- Validation
    IF EXISTS (SELECT 1 FROM TAI_KHOAN WHERE TenDangNhap = @TenDangNhap)
    BEGIN
        RAISERROR(N'TÃªn Ä‘Äƒng nháº­p Ä‘Ã£ tá»“n táº¡i!', 16, 1);
        RETURN;
    END

    IF @NgaySinh >= GETDATE()
    BEGIN
        RAISERROR(N'NgÃ y sinh khÃ´ng há»£p lá»‡!', 16, 1);
        RETURN;
    END

    IF @LuongCoBan <= 0
    BEGIN
        RAISERROR(N'LÆ°Æ¡ng cÆ¡ báº£n pháº£i lá»›n hÆ¡n 0!', 16, 1);
        RETURN;
    END

    -- Sinh mÃ£ nhÃ¢n viÃªn tá»± Ä‘á»™ng
    DECLARE @MaNV NCHAR(10);
    DECLARE @MaxID INT;
    
    SELECT @MaxID = MAX(CAST(RIGHT(MaUser, 6) AS INT)) 
    FROM [USER] 
    WHERE MaUser LIKE 'NV%';

    IF @MaxID IS NULL SET @MaxID = 0;
    SET @MaNV = 'NV' + RIGHT('000000' + CAST(@MaxID + 1 AS VARCHAR(6)), 6);

    WHILE EXISTS (SELECT 1 FROM [USER] WHERE MaUser = @MaNV)
    BEGIN
        SET @MaxID = @MaxID + 1;
        SET @MaNV = 'NV' + RIGHT('000000' + CAST(@MaxID AS VARCHAR(6)), 6);
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Insert vÃ o báº£ng USER
        INSERT INTO [USER] (MaUser, HoTen, NgaySinh, GioiTinh, LoaiUser)
        VALUES (@MaNV, @HoTen, @NgaySinh, @GioiTinh, 'NV');

        -- Insert vÃ o báº£ng NHAN_VIEN
        INSERT INTO NHAN_VIEN (MaNV, NgayVaoLam, LuongCoBan, ChucVu, MaCN)
        VALUES (@MaNV, @NgayVaoLam, @LuongCoBan, @ChucVu, @MaCN);

        -- Insert vÃ o báº£ng TAI_KHOAN
        INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, MaUser)
        VALUES (@TenDangNhap, @MatKhau, @MaNV);

        -- Táº¡o há»“ sÆ¡ phÃ¢n cÃ´ng
        INSERT INTO PHAN_CONG_CN (MaCN, MaNV, NgayBD, NgayKT, Ghichu)
        VALUES (@MaCN, @MaNV, @NgayVaoLam, '9999-12-31', N'PhÃ¢n cÃ´ng ban Ä‘áº§u');

        COMMIT TRANSACTION;
        
        SELECT @MaNV AS MaNVMoi;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThemSanPhamVaoDon]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- 2. Thêm sản phẩm vào đơn hàng (Cho NV và KH)
CREATE   PROC [dbo].[sp_ThemSanPhamVaoDon]
    @MaPhieu NCHAR(10),
    @MaMatHang NCHAR(10),
    @SoLuong INT
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; 

    -- [FIX] Kiểm tra trạng thái đơn hàng trước
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaCN NCHAR(10);
    SELECT @TrangThai = TrangThai, @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    IF @TrangThai <> 'DD'
    BEGIN
        RAISERROR(N'Chỉ được thêm sửa xóa khi đơn hàng đang chờ duyệt (DD)!', 16, 1);
        RETURN;
    END

    -- Check kho
    DECLARE @TonKho INT;
    SELECT @TonKho = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaMatHang;

    IF ISNULL(@TonKho, 0) < @SoLuong
    BEGIN
        RAISERROR(N'Hết hàng trong kho!', 16, 1);
        RETURN;
    END

    DECLARE @DonGia DECIMAL(18,2);
    SELECT @DonGia = DonGia FROM MAT_HANG WHERE MaMatHang = @MaMatHang;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Trừ kho
        UPDATE TON_KHO SET SoLuongTon = SoLuongTon - @SoLuong 
        WHERE MaCN = @MaCN AND MaMatHang = @MaMatHang;

        -- Thêm/Update chi tiết
        IF EXISTS (SELECT 1 FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang)
        BEGIN
            UPDATE CT_MUA_HANG 
            SET SoLuong = SoLuong + @SoLuong, 
                ThanhTien = (SoLuong + @SoLuong) * @DonGia
            WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang;
        END
        ELSE
        BEGIN
            INSERT INTO CT_MUA_HANG (MaPhieu, MaMatHang, SoLuong, ThanhTien)
            VALUES (@MaPhieu, @MaMatHang, @SoLuong, @SoLuong * @DonGia);
        END

        -- Cập nhật tổng tiền
        DECLARE @TongTienHang DECIMAL(18, 2);
        DECLARE @PhiShip DECIMAL(18, 2);

        SELECT @TongTienHang = SUM(ThanhTien) FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu;
        SELECT @PhiShip = PhiGiaoHang FROM HD_TRUC_TUYEN WHERE MaPhieu = @MaPhieu;

        UPDATE HD_TRUC_TUYEN
        SET TongThanhTien = @TongTienHang,
            TongThanhTienSC = @TongTienHang + ISNULL(@PhiShip, 0)
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
/****** Object:  StoredProcedure [dbo].[sp_ThemThuCung]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. Thêm thú cưng (FIX LOGIC SINH MÃ)
CREATE   PROC [dbo].[sp_ThemThuCung]
    @MaKH NCHAR(10),
    @TenTC NVARCHAR(50),
    @Loai NVARCHAR(30),        
    @Giong NVARCHAR(30),      
    @NgaySinh DATE,
    @GioiTinh NVARCHAR(3),
    @TinhTrangSucKhoe NVARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. VALIDATION
    IF NOT EXISTS (SELECT 1 FROM KHACH_HANG WHERE MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Mã khách hàng không tồn tại!', 16, 1);
        RETURN;
    END

    IF @NgaySinh >= GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Ngày sinh thú cưng phải nhỏ hơn ngày hiện tại!', 16, 1);
        RETURN;
    END

    -- 2. TỰ ĐỘNG SINH MÃ (FIX ĐÂY NÈ!)
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @MaTC NCHAR(10);
        DECLARE @MaxNum INT;

        --  FIX: Xử lý đúng với cả TC046784 và TC000001
        SELECT @MaxNum = MAX(
            TRY_CAST(
                -- Bỏ hết chữ "TC" hoặc "TC_", chỉ lấy số
                REPLACE(REPLACE(LTRIM(RTRIM(MaTC)), 'TC_', ''), 'TC', '') 
            AS INT)
        )
        FROM THU_CUNG WITH (UPDLOCK, HOLDLOCK);

        SET @MaxNum = ISNULL(@MaxNum, 0) + 1;

        -- Tạo mã mới (Format: TC + 6 chữ số)
        SET @MaTC = 'TC' + RIGHT('000000' + CAST(@MaxNum AS VARCHAR(6)), 6);

        -- Double check trùng (an toàn 100%)
        WHILE EXISTS (SELECT 1 FROM THU_CUNG WHERE LTRIM(RTRIM(MaTC)) = LTRIM(RTRIM(@MaTC)))
        BEGIN
            SET @MaxNum = @MaxNum + 1;
            SET @MaTC = 'TC' + RIGHT('000000' + CAST(@MaxNum AS VARCHAR(6)), 6);
        END

        -- 3. INSERT (Giữ nguyên tên cột Ten, NgSinh)
        INSERT INTO THU_CUNG (MaTC, Ten, Loai, Giong, NgSinh, GioiTinh, TinhTrangSucKhoe, MaKH)
        VALUES (@MaTC, @TenTC, @Loai, @Giong, @NgaySinh, @GioiTinh, @TinhTrangSucKhoe, @MaKH);
        
        COMMIT TRANSACTION;

        -- Trả về mã mới
        SELECT @MaTC AS NewMaTC;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = N'Lỗi thêm thú cưng: ' + ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_ThemThuocVaoDon]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2. Bác sĩ kê đơn thuốc
CREATE   PROC [dbo].[sp_ThemThuocVaoDon]
    @MaPhieu NCHAR(10),
    @MaThuoc NCHAR(10),
    @SoLuong INT,
    @LieuLuong NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON; -- [BẮT BUỘC] Để rollback nếu lỗi update kho

    -- 1. VALIDATION
    IF @SoLuong <= 0
    BEGIN
        RAISERROR(N'Lỗi: Số lượng thuốc phải lớn hơn 0!', 16, 1);
        RETURN;
    END

    -- [FIX] Phải Check trạng thái phiếu là DTH mới cho thêm thuốc
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaCN NCHAR(10);
    
    SELECT @TrangThai = TrangThai, @MaCN = MaCN 
    FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    IF @MaCN IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Phiếu dịch vụ không tồn tại!', 16, 1);
        RETURN;
    END

    IF @TrangThai <> 'DTH'
    BEGIN
        RAISERROR(N'Lỗi: Chỉ được kê thuốc khi phiếu đang trong quá trình khám (DTH)!', 16, 1);
        RETURN;
    END

    -- Kiểm tra ngày hết hạn thuốc nếu có
    DECLARE @NgayHetHan DATE;
    SELECT @NgayHetHan = NgayHetHan FROM MAT_HANG WHERE MaMatHang = @MaThuoc;

    IF @NgayHetHan < CAST(GETDATE() AS DATE)
    BEGIN
        RAISERROR(N'Lỗi: Thuốc đã hết hạn sử dụng!', 16, 1);
        RETURN;
    END
        
    -- Kiểm tra Tồn kho
    DECLARE @TonKhoHienTai INT;
    SELECT @TonKhoHienTai = SoLuongTon FROM TON_KHO WHERE MaCN = @MaCN AND MaMatHang = @MaThuoc;

    IF ISNULL(@TonKhoHienTai, 0) < @SoLuong
    BEGIN
        RAISERROR(N'Lỗi: Kho không đủ thuốc (Tồn: %d)!', 16, 1, @TonKhoHienTai);
        RETURN;
    END

    -- Lấy Đơn giá
    DECLARE @DonGia DECIMAL(18,2);
    SELECT @DonGia = DonGia FROM THUOC WHERE MaThuoc = @MaThuoc;

    -- 2. THỰC HIỆN
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ Kho
        UPDATE TON_KHO
        SET SoLuongTon = SoLuongTon - @SoLuong
        WHERE MaCN = @MaCN AND MaMatHang = @MaThuoc;

        -- B2: Thêm/Update chi tiết đơn thuốc
        IF EXISTS (SELECT 1 FROM CT_DON_THUOC WHERE MaPhieu = @MaPhieu AND MaThuoc = @MaThuoc)
        BEGIN
            UPDATE CT_DON_THUOC
            SET SoLuong = SoLuong + @SoLuong,
                ThanhTien = (SoLuong + @SoLuong) * @DonGia,
                LieuLuong = @LieuLuong
            WHERE MaPhieu = @MaPhieu AND MaThuoc = @MaThuoc;
        END
        ELSE
        BEGIN
            INSERT INTO CT_DON_THUOC (MaThuoc, MaPhieu, LieuLuong, SoLuong, ThanhTien)
            VALUES (@MaThuoc, @MaPhieu, @LieuLuong, @SoLuong, @SoLuong * @DonGia);
        END

        COMMIT TRANSACTION;
        
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThemVaccineVaoGoiDangTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_ThemVaccineVaoGoiDangTiem]
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
/****** Object:  StoredProcedure [dbo].[sp_ThongKeDoanhThuChiNhanh]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 6. Thống kê doanh thu tất cả chi nhánh
CREATE   PROC [dbo].[sp_ThongKeDoanhThuChiNhanh]
    @Thang INT,
    @Nam INT
AS
BEGIN
    SET NOCOUNT ON;

    -- Doanh thu Offline (Lấy từ bảng HD_TRUC_TIEP)
    SELECT 
        CN.TenCN,
        ISNULL(SUM(HD.TongThanhTienSC), 0) AS DoanhThuOffline,
        -- Doanh thu Online (Lấy từ bảng HD_TRUC_TUYEN, tính cho chi nhánh xử lý đơn)
        ISNULL((
            SELECT SUM(HDO.TongThanhTienSC)
            FROM HD_TRUC_TUYEN HDO
            JOIN PHIEU_DICH_VU P2 ON HDO.MaPhieu = P2.MaPhieu
            WHERE P2.MaCN = CN.MaCN 
              AND MONTH(P2.TG_ThucHienDV) = @Thang 
              AND YEAR(P2.TG_ThucHienDV) = @Nam
              AND P2.TrangThai = 'DHT'
        ), 0) AS DoanhThuOnline,
        -- Cột tổng cộng để tính sau
        0 AS TongCong 
    INTO #TempDoanhThu
    FROM CHI_NHANH CN
    LEFT JOIN PHIEU_DICH_VU P ON CN.MaCN = P.MaCN 
        AND MONTH(P.TG_ThucHienDV) = @Thang 
        AND YEAR(P.TG_ThucHienDV) = @Nam
        AND P.TrangThai = 'DHT'
    LEFT JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    GROUP BY CN.MaCN, CN.TenCN;

    -- Cộng dồn doanh thu
    UPDATE #TempDoanhThu SET TongCong = DoanhThuOffline + DoanhThuOnline;

    SELECT * FROM #TempDoanhThu ORDER BY TongCong DESC;
    DROP TABLE #TempDoanhThu;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeDoanhThuSanPham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 5. Thống kê doanh thu bán sản phẩm
CREATE   PROC [dbo].[sp_ThongKeDoanhThuSanPham]
    @TuNgay DATE,
    @DenNgay DATE,
    @MaCN NCHAR(10) = NULL -- NULL = tất cả chi nhánh (Director), có giá trị = chi nhánh cụ thể (Branch Manager)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MH.MaMatHang,
        M.TenMatHang,
        SUM(MH.SoLuong) AS TongSoLuongBan,
        SUM(MH.ThanhTien) AS TongDoanhThu
    FROM CT_MUA_HANG MH
    JOIN PHIEU_DICH_VU P ON MH.MaPhieu = P.MaPhieu
    JOIN MAT_HANG M ON MH.MaMatHang = M.MaMatHang
    WHERE P.TG_ThucHienDV BETWEEN @TuNgay AND @DenNgay
      AND P.TrangThai = 'DHT'
      AND (@MaCN IS NULL OR P.MaCN = @MaCN)
    GROUP BY MH.MaMatHang, M.TenMatHang
    ORDER BY TongDoanhThu DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeHoiVien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 11. Thống kê tình hình hội viên
CREATE   PROC [dbo].[sp_ThongKeHoiVien]
    @Nam INT,
    @MaCN NCHAR(10) = NULL -- NULL = tất cả chi nhánh (Director), có giá trị = khách hàng của chi nhánh đó
AS
BEGIN
    SET NOCOUNT ON;

    -- Nếu @MaCN NULL: Đếm tất cả khách hàng
    -- Nếu @MaCN có giá trị: Chỉ đếm khách hàng đã từng đến chi nhánh đó
    IF @MaCN IS NULL
    BEGIN
        -- Director: Đếm tất cả khách hàng
        SELECT 
            H.TenHang,
            H.KhuyenMaiUuTien AS PhanTramGiamGia,
            COUNT(XH.MaKH) AS SoLuongKhach
        FROM HANG_TV H
        LEFT JOIN XEP_HANG_NAM XH ON H.MaHang = XH.MaHang AND XH.Nam = @Nam
        GROUP BY H.MaHang, H.TenHang, H.KhuyenMaiUuTien
        ORDER BY H.KhuyenMaiUuTien ASC;
    END
    ELSE
    BEGIN
        -- Branch Manager: Chỉ đếm khách đã đến chi nhánh
        SELECT 
            H.TenHang,
            H.KhuyenMaiUuTien AS PhanTramGiamGia,
            COUNT(DISTINCT XH.MaKH) AS SoLuongKhach
        FROM HANG_TV H
        LEFT JOIN XEP_HANG_NAM XH ON H.MaHang = XH.MaHang AND XH.Nam = @Nam
        LEFT JOIN PHIEU_DICH_VU P ON XH.MaKH = P.MaKH AND P.MaCN = @MaCN AND P.TrangThai = 'DHT'
        WHERE XH.MaKH IS NULL OR P.MaPhieu IS NOT NULL
        GROUP BY H.MaHang, H.TenHang, H.KhuyenMaiUuTien
        ORDER BY H.KhuyenMaiUuTien ASC;
    END
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeKhachHangLauChuaQuayLai]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 5. Thá»‘ng kÃª khÃ¡ch hÃ ng lÃ¢u chÆ°a quay láº¡i
CREATE   PROC [dbo].[sp_ThongKeKhachHangLauChuaQuayLai]
    @MaCN NCHAR(10),
    @SoNgay INT = 180  -- Máº·c Ä‘á»‹nh 6 thÃ¡ng
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        KH.MaKH,
        U.HoTen,
        KH.SDT,
        KH.Email,
        MAX(P.TG_ThucHienDV) AS LanCuoiDenGiao,
        DATEDIFF(DAY, MAX(P.TG_ThucHienDV), GETDATE()) AS SoNgayChuaDen,
        COUNT(P.MaPhieu) AS TongSoLanDung
    FROM KHACH_HANG KH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    JOIN PHIEU_DICH_VU P ON KH.MaKH = P.MaKH
    WHERE 
        P.MaCN = @MaCN
        AND P.TrangThai IN ('DHT', 'HT')
    GROUP BY KH.MaKH, U.HoTen, KH.SDT, KH.Email
    HAVING DATEDIFF(DAY, MAX(P.TG_ThucHienDV), GETDATE()) >= @SoNgay
    ORDER BY SoNgayChuaDen DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeNhanVienGioi]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 7. Thống kê các nhân viên có điểm đánh giá >= x
CREATE   PROC [dbo].[sp_ThongKeNhanVienGioi]
    @DiemSan DECIMAL(4,2),
    @MaCN NCHAR(10) = NULL -- NULL = tất cả chi nhánh (Director)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        NV.MaNV,
        U.HoTen,
        CN.TenCN,
        AVG(DG.DiemThaiDoNV) AS DiemTrungBinh,
        COUNT(DG.MaPhieu) AS SoLuotDanhGia
    FROM NHAN_VIEN NV
    JOIN [USER] U ON NV.MaNV = U.MaUser
    JOIN PHIEU_DICH_VU P ON NV.MaNV = P.MaNV
    JOIN DANH_GIA_DV DG ON P.MaPhieu = DG.MaPhieu
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    WHERE (@MaCN IS NULL OR NV.MaCN = @MaCN)
    GROUP BY NV.MaNV, U.HoTen, CN.TenCN
    HAVING AVG(DG.DiemThaiDoNV) >= @DiemSan
    ORDER BY DiemTrungBinh DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKePetDuocTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 2. Danh sÃ¡ch thÃº cÆ°ng Ä‘Æ°á»£c tiÃªm phÃ²ng trong ká»³
CREATE   PROC [dbo].[sp_ThongKePetDuocTiem]
    @MaCN NCHAR(10) = NULL,
    @TuNgay DATE,
    @DenNgay DATE
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        TC.MaTC,
        TC.Ten AS TenThuCung,
        TC.Loai,
        TC.Giong,
        U.HoTen AS ChuNuoi,
        KH.SDT,
        COUNT(DISTINCT P.MaPhieu) AS SoLanTiem,
        STRING_AGG(MH.TenMatHang, ', ') AS DanhSachVaccine
    FROM THU_CUNG TC
    JOIN KHACH_HANG KH ON TC.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    JOIN PHIEU_TIEM_VACCINE PTV ON TC.MaTC = PTV.MaTC
    JOIN PHIEU_DICH_VU P ON PTV.MaPhieu = P.MaPhieu
    JOIN CT_TIEM_VC CTV ON P.MaPhieu = CTV.MaPhieu
    JOIN VACCINE V ON CTV.MaVaccine = V.MaVaccine
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang
    WHERE 
        P.TG_ThucHienDV BETWEEN @TuNgay AND @DenNgay
        AND P.TrangThai = 'DHT'
        AND (@MaCN IS NULL OR P.MaCN = @MaCN)
    GROUP BY TC.MaTC, TC.Ten, TC.Loai, TC.Giong, U.HoTen, KH.SDT
    ORDER BY SoLanTiem DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKePetTheoLoai]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 4. Thá»‘ng kÃª sá»‘ lÆ°á»£ng thÃº cÆ°ng theo loáº¡i, giá»‘ng
CREATE   PROC [dbo].[sp_ThongKePetTheoLoai]
    @MaCN NCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        TC.Loai,
        TC.Giong,
        COUNT(*) AS SoLuong,
        COUNT(DISTINCT TC.MaKH) AS SoChuNuoi
    FROM THU_CUNG TC
    WHERE @MaCN IS NULL OR TC.MaKH IN (
        SELECT DISTINCT P.MaKH 
        FROM PHIEU_DICH_VU P 
        WHERE P.MaCN = @MaCN
    )
    GROUP BY TC.Loai, TC.Giong
    ORDER BY SoLuong DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeSanPhamTot]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 8. Thống kê các sản phẩm có điểm đánh giá >=x
CREATE   PROC [dbo].[sp_ThongKeSanPhamTot]
    @DiemSan DECIMAL(4,2)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MH.MaMatHang,
        MH.TenMatHang,
        AVG(DG.DiemChatLuong) AS DiemTrungBinh,
        COUNT(DG.MaPhieu) AS SoLuotDanhGia
    FROM MAT_HANG MH
    JOIN DANH_GIA_SP DG ON MH.MaMatHang = DG.MaMatHang
    GROUP BY MH.MaMatHang, MH.TenMatHang
    HAVING AVG(DG.DiemChatLuong) >= @DiemSan
    ORDER BY DiemTrungBinh DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_ThongKeVaccineNhieuNhat]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- 3. Thá»‘ng kÃª vaccine Ä‘Æ°á»£c Ä‘áº·t nhiá»u nháº¥t
CREATE   PROC [dbo].[sp_ThongKeVaccineNhieuNhat]
    @MaCN NCHAR(10) = NULL,
    @TuNgay DATE,
    @DenNgay DATE,
    @Top INT = 10
AS
BEGIN
    SET NOCOUNT ON;

    SELECT TOP (@Top)
        V.MaVaccine,
        MH.TenMatHang AS TenVaccine,
        COUNT(*) AS SoLuotTiem,
        SUM(CTV.ThanhTien) AS TongDoanhThu
    FROM CT_TIEM_VC CTV
    JOIN VACCINE V ON CTV.MaVaccine = V.MaVaccine
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang
    JOIN PHIEU_DICH_VU P ON CTV.MaPhieu = P.MaPhieu
    WHERE 
        P.TG_ThucHienDV BETWEEN @TuNgay AND @DenNgay
        AND P.TrangThai = 'DHT'
        AND (@MaCN IS NULL OR P.MaCN = @MaCN)
    GROUP BY V.MaVaccine, MH.TenMatHang
    ORDER BY SoLuotTiem DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TimKiemKhachHangTheoSDT]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROCEDURE [dbo].[sp_TimKiemKhachHangTheoSDT]
    @SDT VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaKH NCHAR(10);
    
    -- Tìm mã khách hàng theo SĐT từ bảng KHACH_HANG
    SELECT @MaKH = MaKH 
    FROM KHACH_HANG 
    WHERE SDT = @SDT;
    
    -- Nếu không tìm thấy khách hàng
    IF @MaKH IS NULL
    BEGIN
        -- Trả về recordset rỗng với cấu trúc cột chính xác
        SELECT CAST(NULL AS NCHAR(10)) AS MaKH, CAST(NULL AS NVARCHAR(50)) AS HoTen, CAST(NULL AS VARCHAR(10)) AS SDT, CAST(NULL AS VARCHAR(50)) AS Email;
        SELECT CAST(NULL AS NCHAR(10)) AS MaTC, CAST(NULL AS NVARCHAR(50)) AS Ten, CAST(NULL AS NVARCHAR(30)) AS Loai, CAST(NULL AS NVARCHAR(3)) AS GioiTinh, CAST(NULL AS DATE) AS NgSinh;
        SELECT CAST(NULL AS NCHAR(10)) AS MaPhieu, CAST(NULL AS DATETIME) AS NgayKham, CAST(NULL AS NVARCHAR(20)) AS LoaiDV, CAST(NULL AS NVARCHAR(50)) AS BacSi, CAST(NULL AS NVARCHAR(200)) AS ChanDoan;
        RETURN;
    END
    
    -- 1. Thông tin khách hàng (Lấy HoTen từ bảng [USER])
    SELECT 
        kh.MaKH, 
        u.HoTen, 
        kh.SDT, 
        kh.Email,
        kh.TongDiemTichLuy
    FROM KHACH_HANG kh
    JOIN [USER] u ON kh.MaKH = u.MaUser
    WHERE kh.MaKH = @MaKH;
    
    -- 2. Danh sách thú cưng của khách
    -- Sửa tên cột: NgSinh (thay vì NgaySinh), bỏ cột CanNang (không có trong schema)
    SELECT 
        MaTC, 
        Ten, 
        Loai, 
        Giong,
        GioiTinh, 
        NgSinh, 
        TinhTrangSucKhoe
    FROM THU_CUNG
    WHERE MaKH = @MaKH;
    
    -- 3. Lịch sử khám/tiêm/mua hàng (10 lần gần nhất)
    -- Kết nối qua PHIEU_DICH_VU, PHIEU_KHAM_BENH và NHAN_VIEN (thông qua bảng USER để lấy tên)
    SELECT TOP 10
        p.MaPhieu,
        p.TG_LapPhieu AS NgayKham,
        CASE p.LoaiPhieu
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            WHEN 'MH' THEN N'Mua hàng'
            ELSE p.LoaiPhieu
        END AS LoaiDV,
        u_nv.HoTen AS BacSi,
        ISNULL(pkb.ChanDoan, N'N/A') AS ChanDoan,
        p.TrangThai
    FROM PHIEU_DICH_VU p
    LEFT JOIN PHIEU_KHAM_BENH pkb ON p.MaPhieu = pkb.MaPhieu
    LEFT JOIN [USER] u_nv ON p.MaNV = u_nv.MaUser -- Lấy tên nhân viên lập phiếu từ bảng USER
    WHERE p.MaKH = @MaKH
    ORDER BY p.TG_LapPhieu DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TinhKhuyenMai]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- =============================================
-- Năm 2024
-- =============================================
-- Tính tổng thành tiền
-- Tính khuyến mãi dựa vào xếp hạng năm (2023, nếu có) + tiền quy đổi từ điểm
CREATE   PROC [dbo].[sp_TinhKhuyenMai]
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
/****** Object:  StoredProcedure [dbo].[sp_TinhTongThanhTien]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Tính tổng thành tiền
CREATE   PROC [dbo].[sp_TinhTongThanhTien]
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
/****** Object:  StoredProcedure [dbo].[sp_TinhTongThanhTienSC]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Tính tổng thành tiền sc
CREATE   PROC [dbo].[sp_TinhTongThanhTienSC]
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
/****** Object:  StoredProcedure [dbo].[sp_TopDichVuDoanhThu]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 10. Dịch vụ mang lại doanh thu cao nhất trong 6 tháng vừa qua
CREATE   PROC [dbo].[sp_TopDichVuDoanhThu]
    @MaCN NCHAR(10) = NULL -- NULL = tất cả chi nhánh (Director)
AS
BEGIN
    SET NOCOUNT ON;

    DECLARE @NgayBatDau DATE = DATEADD(MONTH, -6, GETDATE());

    SELECT TOP 1
        CASE 
            WHEN P.LoaiPhieu = 'KB' THEN N'Khám bệnh'
            WHEN P.LoaiPhieu = 'TV' THEN N'Tiêm Vaccine'
            WHEN P.LoaiPhieu = 'MH' THEN N'Bán hàng'
        END AS LoaiDichVu,
        SUM(HD.TongThanhTienSC) AS TongDoanhThu
    FROM PHIEU_DICH_VU P
    JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    WHERE P.TG_ThucHienDV >= @NgayBatDau
      AND P.TrangThai = 'DHT'
      AND (@MaCN IS NULL OR P.MaCN = @MaCN)
    GROUP BY P.LoaiPhieu
    ORDER BY TongDoanhThu DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuLichBacSi]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_TraCuuLichBacSi]
    @MaCN NCHAR(10) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        ND.HoTen AS TenBacSi,  -- Lấy tên từ bảng NGUOI_DUNG (hoặc bảng chứa tên user của bà)
        -- Nếu bảng tên là KHACH_HANG hay USER thì bà sửa chữ NGUOI_DUNG lại nha
        
        CN.TenCN,
        CN.DiaChi,
        
        -- Giờ làm việc của bác sĩ = Giờ mở cửa chi nhánh
        LEFT(CAST(CN.Giomocua AS VARCHAR), 5) AS GioBatDau,
        LEFT(CAST(CN.Giodongcua AS VARCHAR), 5) AS GioKetThuc,
        
        N'Hàng ngày' AS LichLamViec -- Vì gắn cứng với chi nhánh nên làm việc hàng ngày
    FROM NHAN_VIEN NV
    -- Join để lấy tên (Giả sử bảng chứa tên là NGUOI_DUNG và MaNV khớp MaUser)
    JOIN [USER] ND ON NV.MaNV = ND.MaUser 
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    WHERE 
        NV.Chucvu LIKE N'%Bác sĩ%' -- Lọc lấy bác sĩ
        AND (@MaCN IS NULL OR NV.MaCN = @MaCN)
    ORDER BY CN.TenCN;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuSanPham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 12. Tra cứu danh sách sản phẩm
CREATE   PROC [dbo].[sp_TraCuuSanPham]
    @TuKhoa NVARCHAR(80) = NULL, -- Tìm theo tên
    @LoaiMH VARCHAR(3) = NULL    -- Lọc theo loại: T (Thuốc), VC (Vaccine), SPK (Khác)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MH.MaMatHang,
        MH.TenMatHang,
        MH.HangSX,
        MH.LoaiMH,
        FORMAT(MH.DonGia, 'N0', 'vi-VN') + ' VNĐ' AS DonGia,
        
        -- Tính tổng tồn kho của tất cả chi nhánh để báo "Còn hàng" hay "Hết hàng"
        CASE 
            WHEN SUM(TK.SoLuongTon) > 0 THEN N'Còn hàng'
            ELSE N'Hết hàng'
        END AS TinhTrang
    FROM MAT_HANG MH
    LEFT JOIN TON_KHO TK ON MH.MaMatHang = TK.MaMatHang
    WHERE 
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + '%')
        AND
        (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)
    GROUP BY MH.MaMatHang, MH.TenMatHang, MH.HangSX, MH.LoaiMH, MH.DonGia
    ORDER BY MH.TenMatHang ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuSanPham_Online]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_TraCuuSanPham_Online]
    @TuKhoa NVARCHAR(80) = NULL,
    @LoaiMH VARCHAR(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MH.MaMatHang,
        MH.TenMatHang,
        MH.HangSX,
        MH.LoaiMH,
        MH.DonGia,

        --  ĐÃ CHÈN THÊM TÍNH ĐIỂM Ở ĐÂY 
        ISNULL((SELECT AVG(CAST(DiemChatLuong AS FLOAT)) 
                FROM DANH_GIA_SP 
                WHERE MaMatHang = MH.MaMatHang), 0) AS DiemTrungBinh,

        (SELECT COUNT(*) 
         FROM DANH_GIA_SP 
         WHERE MaMatHang = MH.MaMatHang) AS SoLuongDanhGia,
        --  KẾT THÚC ĐOẠN CHÈN 

        CASE 
            WHEN SUM(TK.SoLuongTon) > 0 THEN N'Còn hàng'
            ELSE N'Hết hàng'
        END AS TinhTrang
    FROM MAT_HANG MH
    LEFT JOIN TON_KHO TK 
        ON MH.MaMatHang = TK.MaMatHang

    --  Join bảng THUOC (con của MAT_HANG)
    LEFT JOIN THUOC T
        ON T.MaThuoc = MH.MaMatHang   

    WHERE 
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%')
        AND (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)

        --  1) Vaccine không bán lẻ online
        AND MH.LoaiMH <> 'VC'

        --  2) Thuốc chỉ bán "Không cần kê đơn"
        AND (
            MH.LoaiMH <> 'T'
            OR (MH.LoaiMH = 'T' AND ISNULL(T.LoaiThuoc, N'') = N'Không cần kê đơn')
        )

    GROUP BY MH.MaMatHang, MH.TenMatHang, MH.HangSX, MH.LoaiMH, MH.DonGia
    ORDER BY MH.TenMatHang ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuSanPham_TheoChiNhanh]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Thay đổi
CREATE   PROC [dbo].[sp_TraCuuSanPham_TheoChiNhanh]
  @MaCN VARCHAR(10),
  @TuKhoa NVARCHAR(80) = NULL,
  @LoaiMH VARCHAR(3) = NULL
AS
BEGIN
  SET NOCOUNT ON;

  SELECT 
    MH.MaMatHang,
    MH.TenMatHang,
    MH.HangSX,
    MH.LoaiMH,
    MH.DonGia,                -- để FE format
    ISNULL(TK.SoLuongTon, 0) AS SoLuongTon,
    CASE 
      WHEN ISNULL(TK.SoLuongTon, 0) > 0 THEN N'Còn hàng'
      ELSE N'Hết hàng'
    END AS TinhTrang
  FROM MAT_HANG MH
  LEFT JOIN TON_KHO TK 
    ON TK.MaMatHang = MH.MaMatHang AND TK.MaCN = @MaCN
  WHERE 
    (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%')
    AND (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)
  ORDER BY MH.TenMatHang ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuSanPham_TheoChiNhanh_Online]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_TraCuuSanPham_TheoChiNhanh_Online]
    @MaCN VARCHAR(10),
    @TuKhoa NVARCHAR(80) = NULL,
    @LoaiMH VARCHAR(3) = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT
        MH.MaMatHang,
        MH.TenMatHang,
        MH.HangSX,
        MH.LoaiMH,
        MH.DonGia,

        --  ĐÃ CHÈN THÊM ĐOẠN TÍNH ĐIỂM Ở ĐÂY 
        ISNULL((SELECT AVG(CAST(DiemChatLuong AS FLOAT)) 
                FROM DANH_GIA_SP 
                WHERE MaMatHang = MH.MaMatHang), 0) AS DiemTrungBinh,

        (SELECT COUNT(*) 
         FROM DANH_GIA_SP 
         WHERE MaMatHang = MH.MaMatHang) AS SoLuongDanhGia,
        --  KẾT THÚC ĐOẠN CHÈN 

        ISNULL(TK.SoLuongTon, 0) AS SoLuongTon,
        CASE 
            WHEN ISNULL(TK.SoLuongTon, 0) > 0 THEN N'Còn hàng'
            ELSE N'Hết hàng'
        END AS TinhTrang
    FROM MAT_HANG MH

    --  tồn kho đúng CHI NHÁNH
    LEFT JOIN TON_KHO TK
        ON TK.MaMatHang = MH.MaMatHang
       AND TK.MaCN = @MaCN

    --  bảng THUOC (con)
    LEFT JOIN THUOC T
        ON T.MaThuoc = MH.MaMatHang   -- nếu khác thì đổi thành T.MaMatHang = MH.MaMatHang

    WHERE
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%')
        AND (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)

        --  1) Vaccine không bán lẻ online
        AND MH.LoaiMH <> 'VC'

        --  2) Thuốc: chỉ OTC
        AND (
            MH.LoaiMH <> 'T'
            OR (MH.LoaiMH = 'T' AND ISNULL(T.LoaiThuoc, N'') = N'Không cần kê đơn')
        )

    ORDER BY MH.TenMatHang ASC;
END;

GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuThuoc]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 2. Bác sĩ tra cứu thuốc
CREATE   PROC [dbo].[sp_TraCuuThuoc]
    @TuKhoa NVARCHAR(100), -- Tìm theo tên thuốc hoặc tác dụng phụ
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        T.MaThuoc,
        MH.TenMatHang,
        T.DangBaoChe,
        T.DonGia,
        T.TacDungPhu,
        ISNULL(K.SoLuongTon, 0) AS SoLuongTonKho
    FROM THUOC T
    JOIN MAT_HANG MH ON T.MaThuoc = MH.MaMatHang
    LEFT JOIN TON_KHO K ON T.MaThuoc = K.MaMatHang AND K.MaCN = @MaCN
    WHERE MH.TenMatHang LIKE N'%' + @TuKhoa + N'%' 
       OR T.TacDungPhu LIKE N'%' + @TuKhoa + N'%'
    ORDER BY MH.TenMatHang;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TraCuuVaccine]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER OFF
GO

-- =============================================
-- FILE NÃ€Y Bá»” SUNG CÃC SP CHÆ¯A DÃ™NG
-- =============================================

-- 1. Tra cá»©u vaccine theo tÃªn, loáº¡i, ngÃ y sáº£n xuáº¥t
CREATE   PROC [dbo].[sp_TraCuuVaccine]
    @TuKhoa NVARCHAR(100) = NULL,
    @MaCN NCHAR(10) = NULL,
    @TuNgaySX DATE = NULL,
    @DenNgaySX DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        V.MaVaccine,
        MH.TenMatHang AS TenVaccine,
        V.ChongChiDinh,
        V.DonGia,
        MH.HangSX,
        MH.NgaySanXuat,
        MH.NgayHetHan,
        CASE WHEN @MaCN IS NOT NULL 
            THEN ISNULL(K.SoLuongTon, 0) 
            ELSE NULL 
        END AS SoLuongTonKho
    FROM VACCINE V
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang
    LEFT JOIN TON_KHO K ON V.MaVaccine = K.MaMatHang AND (@MaCN IS NULL OR K.MaCN = @MaCN)
    WHERE 
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%' OR V.ChongChiDinh LIKE N'%' + @TuKhoa + N'%')
        AND (@TuNgaySX IS NULL OR MH.NgaySanXuat >= @TuNgaySX)
        AND (@DenNgaySX IS NULL OR MH.NgaySanXuat <= @DenNgaySX)
    ORDER BY MH.TenMatHang;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_TruDiemDaSuDung]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
-- Trừ đi các điểm đã sử dụng
CREATE   PROC [dbo].[sp_TruDiemDaSuDung]
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
/****** Object:  StoredProcedure [dbo].[sp_TuDongHuyLichHen]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- SP 2: Hệ thống tự động hủy
CREATE   PROCEDURE [dbo].[sp_TuDongHuyLichHen]
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
/****** Object:  StoredProcedure [dbo].[sp_XemDanhSachChiNhanh]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO
CREATE   PROC [dbo].[sp_XemDanhSachChiNhanh]
    @TuKhoa NVARCHAR(100) = NULL -- Nhập tên/địa chỉ để tìm. Nếu để NULL thì hiện tất cả.
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        CN.MaCN,
        CN.TenCN,
        CN.DiaChi,
        CN.SDT,
        
        -- Format giờ
        LEFT(CAST(CN.Giomocua AS VARCHAR), 5) AS GioMoCua,
        LEFT(CAST(CN.Giodongcua AS VARCHAR), 5) AS GioDongCua,

        -- [LOGIC REAL-TIME] Trạng thái mở cửa
        CASE 
            WHEN CAST(GETDATE() AS TIME) BETWEEN CN.Giomocua AND CN.Giodongcua 
            THEN N'Đang mở cửa'
            ELSE N'Đã đóng cửa'
        END AS TrangThaiHoatDong,

        -- [MỚI] Gom nhóm các dịch vụ thành 1 chuỗi (VD: Khám bệnh, Tiêm vaccine)
        ISNULL((
            SELECT STRING_AGG(LDV.TenLoaiDV, N', ') WITHIN GROUP (ORDER BY LDV.TenLoaiDV)
            FROM DV_CN D
            JOIN LOAI_DICH_VU LDV ON D.MaLoaiDV = LDV.MaLoaiDV
            WHERE D.MaCN = CN.MaCN
        ), N'Đang cập nhật') AS DichVuHoTro

    FROM CHI_NHANH CN
    WHERE 
        (@TuKhoa IS NULL OR 
         CN.TenCN LIKE N'%' + @TuKhoa + '%' OR 
         CN.DiaChi LIKE N'%' + @TuKhoa + '%')
    ORDER BY CN.TenCN ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemDanhSachThuCung]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- 11. Khách hàng xem danh sách thú cưng
CREATE   PROC [dbo].[sp_XemDanhSachThuCung]
    @MaKH NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        MaTC,
        Ten, --Bỏ as TenThuCung cho web dễ nhận diện
        Loai,      
        Giong,     
        NgSinh,
        GioiTinh,
        TinhTrangSucKhoe,
        -- Tính tuổi cho khách dễ nhìn
        DATEDIFF(MONTH, NgSinh, GETDATE()) / 12 AS TuoiNam,
        DATEDIFF(MONTH, NgSinh, GETDATE()) % 12 AS TuoiThang
    FROM THU_CUNG
    WHERE MaKH = @MaKH
    ORDER BY Ten ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichBacSi]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Khách hàng xem lịch bác sĩ
CREATE   PROC [dbo].[sp_XemLichBacSi]
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION: Kiểm tra chi nhánh có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM CHI_NHANH WHERE MaCN = @MaCN)
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2. TRUY VẤN
    SELECT 
        NV.MaNV AS MaBacSi,
        U.HoTen AS TenBacSi,
        NV.Chucvu,
        CN.TenCN AS ChiNhanh,
        
        -- Format giờ cho đẹp (HH:mm) thay vì hiện dây (HH:mm:ss)
        LEFT(CAST(CN.Giomocua AS VARCHAR), 5) AS GioBatDau,
        LEFT(CAST(CN.Giodongcua AS VARCHAR), 5) AS GioKetThuc,

        -- Hiển thị trạng thái hiện tại (Real-time) để tiện cho lễ tân/khách hàng
        CASE 
            WHEN CAST(GETDATE() AS TIME) BETWEEN CN.Giomocua AND CN.Giodongcua 
            THEN N'Đang trong ca trực'
            ELSE N'Đã tan ca'
        END AS TrangThaiHienTai

    FROM NHAN_VIEN NV
    JOIN [USER] U ON NV.MaNV = U.MaUser
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    WHERE NV.MaCN = @MaCN
      AND NV.Chucvu = N'Bác sĩ thú y' -- Chỉ lấy Bác sĩ
    ORDER BY U.HoTen ASC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuHoatDong]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- Sửa SP xem lịch sử để đảm bảo trả đầy đủ thông tin cho cả phiếu đã hủy
CREATE   PROC [dbo].[sp_XemLichSuHoatDong]
    @MaKH NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.MaPhieu,
        P.LoaiPhieu,
        P.MaCN,
        CN.TenCN AS ChiNhanh,
        P.TrangThai,
        P.TG_ThucHienDV AS NgayMua,
        
        --  Lấy tên thú cưng (luôn hiện dù đã hủy)
        COALESCE(TC.Ten, N'Không rõ') AS TenThuCung,
        COALESCE(TC.Ten, N'Không rõ') AS TenPet,
        
        --  Lấy triệu chứng từ phiếu khám bệnh (luôn hiện dù đã hủy)
        COALESCE(PKB.TrieuChung, N'') AS TrieuChung,
        
        -- Các thông tin khác
        PKB.ChanDoan,
        PKB.NgayHenTaiKham, --  Thêm ngày hẹn tái khám
        
        -- Vaccine (lấy từ MAT_HANG vì VACCINE không có TenVaccine)
        CASE 
            WHEN P.LoaiPhieu = 'TV' THEN (
                SELECT STRING_AGG(MH.TenMatHang, ', ')
                FROM CT_TIEM_VC CT
                JOIN VACCINE VC ON CT.MaVaccine = VC.MaVaccine
                JOIN MAT_HANG MH ON VC.MaVaccine = MH.MaMatHang
                WHERE CT.MaPhieu = P.MaPhieu
            )
            ELSE NULL
        END AS DanhSachVaccine,
        
        -- Hóa đơn
        HD.TongThanhTienSC,
        HD.MaPhieu AS MaHoaDon,
        
        -- Đánh giá dịch vụ
        CASE WHEN DG_DV.MaPhieu IS NOT NULL THEN 1 ELSE 0 END AS DaDanhGiaDV,
        DG_DV.DiemTongThe AS SaoDV,
        DG_DV.BinhLuan AS BinhLuanDV
        
    FROM PHIEU_DICH_VU P
    LEFT JOIN CHI_NHANH CN ON P.MaCN = CN.MaCN
    
    --  LEFT JOIN để luôn lấy được thông tin dù phiếu đã hủy
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON RTRIM(COALESCE(PKB.MaTC, PTV.MaTC)) = RTRIM(TC.MaTC)
    
    LEFT JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    LEFT JOIN DANH_GIA_DV DG_DV ON P.MaPhieu = DG_DV.MaPhieu
    
    WHERE P.MaKH = @MaKH
    ORDER BY P.TG_ThucHienDV DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuKham]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

--Gồm 14 sp nha    

-- 1. Bác sĩ xem lịch sử khám của thú cưng
CREATE   PROC [dbo].[sp_XemLichSuKham]
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.MaPhieu,
        P.TG_ThucHienDV AS NgayKham,
        U.HoTen AS BacSiPhuTrach, -- Lấy tên từ bảng USER
        KB.TrieuChung,
        KB.ChanDoan,
        KB.NgayHenTaiKham
    FROM PHIEU_DICH_VU P
    JOIN PHIEU_KHAM_BENH KB ON P.MaPhieu = KB.MaPhieu
    LEFT JOIN NHAN_VIEN NV ON P.MaNV = NV.MaNV
    LEFT JOIN [USER] U ON NV.MaNV = U.MaUser -- Join bảng USER để lấy HoTen
    WHERE KB.MaTC = @MaTC 
      AND P.TrangThai = 'DHT' -- Chỉ xem các phiếu đã hoàn tất
    ORDER BY P.TG_ThucHienDV DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuKhamBenh]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 9. Khách hàng xem lịch sử khám bệnh của một thú cưng
CREATE   PROC [dbo].[sp_XemLichSuKhamBenh]
    @MaKH NCHAR(10),
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION & SECURITY CHECK
    -- Kiểm tra thú cưng có tồn tại không
    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC)
    BEGIN
        RAISERROR(N'Lỗi: Mã thú cưng không tồn tại!', 16, 1);
        RETURN;
    END

    -- Kiểm tra quyền sở hữu: Thú cưng này có thuộc về Khách hàng này không?
    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC AND MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Bạn không có quyền xem lịch sử của thú cưng này!', 16, 1);
        RETURN;
    END

    -- 2. TRUY VẤN
    SELECT 
        PDV.TG_ThucHienDV AS NgayKham,
        PKB.TrieuChung,
        PKB.ChanDoan,
        PKB.NgayHenTaiKham,
        U_BS.HoTen AS BacSiKham,
        CN.TenCN AS NoiKham
    FROM PHIEU_KHAM_BENH PKB
    JOIN PHIEU_DICH_VU PDV ON PKB.MaPhieu = PDV.MaPhieu
    LEFT JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
    LEFT JOIN [USER] U_BS ON NV.MaNV = U_BS.MaUser
    JOIN CHI_NHANH CN ON PDV.MaCN = CN.MaCN
    WHERE PKB.MaTC = @MaTC
    ORDER BY PDV.TG_ThucHienDV DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuMuaSam]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE   PROC [dbo].[sp_XemLichSuMuaSam]
    @MaKH VARCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.MaPhieu,
        P.TG_LapPhieu AS NgayMua,
        P.TrangThai,
        ISNULL(CN.TenCN, N'Online') AS ChiNhanh,
        
        -- ✅ FIX 1: Phí Ship (Nếu null thì mặc định 0)
        ISNULL(HD.PhiGiaoHang, 0) AS PhiGiaoHang,

        -- ✅ FIX 2: Tự động tính tổng tiền (CƠ CHẾ DỰ PHÒNG)
        -- Logic: Nếu bảng Hóa Đơn (HD) có tiền thì lấy. 
        -- Nếu HD bị lỗi/null/0 -> Tự động tính tổng từ bảng chi tiết (CT_MUA_HANG)
        CASE 
            WHEN ISNULL(HD.TongThanhTienSC, 0) > 0 THEN HD.TongThanhTienSC
            ELSE (SELECT SUM(ThanhTien) FROM CT_MUA_HANG WHERE MaPhieu = P.MaPhieu)
        END AS TongThanhTienSC, 
        
        -- Thông tin sản phẩm
        MH.TenMatHang,
        CT.SoLuong,
        MH.DonGia,
        CT.ThanhTien

    FROM PHIEU_DICH_VU P
    LEFT JOIN CHI_NHANH CN ON P.MaCN = CN.MaCN
    
    -- ✅ FIX 3: Cắt khoảng trắng 2 đầu (RTRIM/LTRIM) để JOIN dính chặt 100%
    LEFT JOIN HD_TRUC_TUYEN HD ON LTRIM(RTRIM(P.MaPhieu)) = LTRIM(RTRIM(HD.MaPhieu))
    
    JOIN CT_MUA_HANG CT ON P.MaPhieu = CT.MaPhieu
    JOIN MAT_HANG MH ON CT.MaMatHang = MH.MaMatHang

    WHERE P.MaKH = @MaKH 
      AND P.LoaiPhieu = 'MH'
    ORDER BY P.TG_LapPhieu DESC;
END
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuTiem]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Bác sĩ xem lịch sử tiêm của thú cưng
CREATE   PROC [dbo].[sp_XemLichSuTiem]
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        P.TG_ThucHienDV AS NgayTiem,
        MH.TenMatHang AS TenVaccine, -- Tên Vaccine nằm ở bảng MAT_HANG
        CT.LieuLuong,
        CASE WHEN CT.NhacLai = 1 THEN N'Tiêm nhắc lại' ELSE N'Tiêm lần đầu' END AS LoaiTiem,
        U.HoTen AS BacSiThucHien -- Lấy tên BS từ bảng USER
    FROM PHIEU_DICH_VU P
    JOIN PHIEU_TIEM_VACCINE PT ON P.MaPhieu = PT.MaPhieu
    JOIN CT_TIEM_VC CT ON P.MaPhieu = CT.MaPhieu
    JOIN VACCINE V ON CT.MaVaccine = V.MaVaccine
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang -- Join để lấy tên Vaccine
    LEFT JOIN NHAN_VIEN NV ON P.MaNV = NV.MaNV
    LEFT JOIN [USER] U ON NV.MaNV = U.MaUser -- Join để lấy tên BS
    WHERE PT.MaTC = @MaTC 
      AND P.TrangThai = 'DHT'
    ORDER BY P.TG_ThucHienDV DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemLichSuTiemPhong]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 10. Khách hàng xem lịch sử tiêm phòng của một thú cưng
CREATE   PROC [dbo].[sp_XemLichSuTiemPhong]
    @MaKH NCHAR(10),
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION & SECURITY CHECK
    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC)
    BEGIN
        RAISERROR(N'Lỗi: Mã thú cưng không tồn tại!', 16, 1);
        RETURN;
    END

    IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = @MaTC AND MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Bạn không có quyền xem lịch sử của thú cưng này!', 16, 1);
        RETURN;
    END

    -- 2. TRUY VẤN
    SELECT 
        PDV.TG_ThucHienDV AS NgayTiem,
        MH.TenMatHang AS TenVaccine,
        CTV.LieuLuong,
        CASE 
            WHEN CTV.NhacLai = 1 THEN N'Có' 
            ELSE N'Không' 
        END AS CanNhacLai,
        U_BS.HoTen AS NguoiTiem,
        CN.TenCN AS NoiTiem
    FROM PHIEU_TIEM_VACCINE PTV
    JOIN PHIEU_DICH_VU PDV ON PTV.MaPhieu = PDV.MaPhieu
    JOIN CT_TIEM_VC CTV ON PTV.MaPhieu = CTV.MaPhieu
    JOIN VACCINE V ON CTV.MaVaccine = V.MaVaccine
    JOIN MAT_HANG MH ON V.MaVaccine = MH.MaMatHang
    LEFT JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
    LEFT JOIN [USER] U_BS ON NV.MaNV = U_BS.MaUser
    JOIN CHI_NHANH CN ON PDV.MaCN = CN.MaCN
    WHERE PTV.MaTC = @MaTC
    ORDER BY PDV.TG_ThucHienDV DESC;
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XemThongTinCaNhan]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO


-- 7. Khách hàng xem thông tin cá nhân
CREATE OR ALTER PROC sp_XemThongTinCaNhan
    @MaKH NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    -- 1. VALIDATION: Kiểm tra khách hàng có tồn tại ko
    IF NOT EXISTS (SELECT 1 FROM KHACH_HANG WHERE MaKH = @MaKH)
    BEGIN
        RAISERROR(N'Lỗi: Mã khách hàng không tồn tại!', 16, 1);
        RETURN;
    END

    -- 2. TRUY VẤN THÔNG TIN
    SELECT 
        -- Thông tin cơ bản
        U.MaUser AS MaKhachHang,
        U.HoTen,
        TK.TenDangNhap,
        U.NgaySinh,
        U.GioiTinh,
        KH.SDT,
        KH.Email,
        KH.CCCD,
        
        -- Thông tin điểm tích lũy hiện tại
        ISNULL(KH.TongDiemTichLuy, 0) AS DiemTichLuy,

        --  FIX: Lấy hạng từ năm GẦN NHẤT (không nhất thiết phải năm ngoái)
        -- Vì có thể chưa chốt năm ngoái, hoặc data test có năm khác
        ISNULL(HTV.TenHang, N'Thành viên mới') AS HangThanhVien,
        ISNULL(HTV.MaHang, 'C01') AS MaHang,
        ISNULL(HTV.KhuyenMaiUuTien, 0) AS GiamGiaThanhVien,  --  THÊM % giảm giá
        
        -- Hiển thị mức chi tiêu đã chốt
        ISNULL(XHN.TongChiTieu, 0) AS TongChiTieuNamNgoai

    FROM KHACH_HANG KH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    JOIN TAI_KHOAN TK ON KH.MaKH = TK.MaUser
    
    --  LEFT JOIN với subquery lấy XẾP HẠNG NĂM GẦN NHẤT
    LEFT JOIN (
        SELECT TOP 1 MaKH, MaHang, TongChiTieu, Nam
        FROM XEP_HANG_NAM
        WHERE MaKH = @MaKH
        ORDER BY Nam DESC  -- Lấy năm mới nhất
    ) XHN ON KH.MaKH = XHN.MaKH
    
    -- LEFT JOIN bảng tên hạng để lấy tên hiển thị
    LEFT JOIN HANG_TV HTV ON XHN.MaHang = HTV.MaHang

    WHERE KH.MaKH = @MaKH;
END;
GO

/****** Object:  StoredProcedure [dbo].[sp_XoaSanPhamKhoiDon]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Xóa sản phẩm (Cho NV và KH)
CREATE   PROC [dbo].[sp_XoaSanPhamKhoiDon]
    @MaPhieu NCHAR(10),
    @MaMatHang NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- [FIX] Check trạng thái
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaCN NCHAR(10);
    SELECT @TrangThai = TrangThai, @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    IF @TrangThai <> 'DD'
    BEGIN
        RAISERROR(N'Không thể xóa món khi đơn hàng đã xử lý!', 16, 1);
        RETURN;
    END

    DECLARE @SoLuongDaMua INT;
    SELECT @SoLuongDaMua = SoLuong FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang;

    IF @SoLuongDaMua IS NULL RETURN; 

    BEGIN TRANSACTION;
    BEGIN TRY
        -- 1. Xóa chi tiết
        DELETE FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu AND MaMatHang = @MaMatHang;
        
        -- 2. Hoàn lại kho
        UPDATE TON_KHO SET SoLuongTon = SoLuongTon + @SoLuongDaMua 
        WHERE MaCN = @MaCN AND MaMatHang = @MaMatHang;

        -- 3. [FIX] CẬP NHẬT LẠI TỔNG TIỀN (QUAN TRỌNG)
        DECLARE @TongTienHang DECIMAL(18, 2) = 0;
        DECLARE @PhiShip DECIMAL(18, 2);

        -- Tính lại tổng (Nếu xóa hết sạch thì SUM trả về NULL nên phải ISNULL = 0)
        SELECT @TongTienHang = ISNULL(SUM(ThanhTien), 0) FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu;
        SELECT @PhiShip = PhiGiaoHang FROM HD_TRUC_TUYEN WHERE MaPhieu = @MaPhieu;

        UPDATE HD_TRUC_TUYEN
        SET TongThanhTien = @TongTienHang,
            TongThanhTienSC = @TongTienHang + ISNULL(@PhiShip, 0)
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
/****** Object:  StoredProcedure [dbo].[sp_XoaThuCung]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 15. Khách hàng xóa thú cưng (chưa có lịch sử tiêm/khám)
CREATE   PROCEDURE [dbo].[sp_XoaThuCung]
    @MaKH NCHAR(10),
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. KIỂM TRA QUYỀN SỞ HỮU & TỒN TẠI
    DECLARE @ChuSoHuu NCHAR(10);
    SELECT @ChuSoHuu = MaKH FROM THU_CUNG WHERE MaTC = @MaTC;

    IF @ChuSoHuu IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Thú cưng không tồn tại!', 16, 1);
        RETURN;
    END

    IF @ChuSoHuu <> @MaKH
    BEGIN
        RAISERROR(N'Lỗi: Bạn không có quyền xóa thú cưng của người khác!', 16, 1);
        RETURN;
    END

    -- 2. KIỂM TRA RÀNG BUỘC DỮ LIỆU (Có lịch sử khám/tiêm chưa?)
    -- Check bảng PHIEU_KHAM_BENH
    IF EXISTS (SELECT 1 FROM PHIEU_KHAM_BENH WHERE MaTC = @MaTC)
    BEGIN
        RAISERROR(N'Lỗi: Không thể xóa thú cưng đã có hồ sơ khám bệnh (Dữ liệu cần lưu trữ lịch sử).', 16, 1);
        RETURN;
    END

    -- Check bảng PHIEU_TIEM_VACCINE
    IF EXISTS (SELECT 1 FROM PHIEU_TIEM_VACCINE WHERE MaTC = @MaTC)
    BEGIN
        RAISERROR(N'Lỗi: Không thể xóa thú cưng đã có hồ sơ tiêm vaccine.', 16, 1);
        RETURN;
    END

    -- 3. THỰC HIỆN XÓA
    BEGIN TRANSACTION;
    BEGIN TRY
        DELETE FROM THU_CUNG WHERE MaTC = @MaTC;
        
        COMMIT TRANSACTION;
        PRINT N'Đã xóa thú cưng thành công.';
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XoaThuocKhoiDon]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

-- 3. Xóa thuốc khỏi đơn
CREATE   PROC [dbo].[sp_XoaThuocKhoiDon]
    @MaPhieu NCHAR(10),
    @MaThuoc NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- [FIX] Check trạng thái
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaCN NCHAR(10);
    SELECT @TrangThai = TrangThai, @MaCN = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    IF @TrangThai <> 'DTH'
    BEGIN
        RAISERROR(N'Lỗi: Không thể xóa thuốc khi phiếu đã kết thúc hoặc chưa bắt đầu!', 16, 1);
        RETURN;
    END

    -- Lấy số lượng đã kê
    DECLARE @SoLuongDaKe INT;
    SELECT @SoLuongDaKe = SoLuong FROM CT_DON_THUOC WHERE MaPhieu = @MaPhieu AND MaThuoc = @MaThuoc;

    IF @SoLuongDaKe IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Thuốc này không có trong đơn!', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Xóa khỏi đơn
        DELETE FROM CT_DON_THUOC WHERE MaPhieu = @MaPhieu AND MaThuoc = @MaThuoc;

        -- B2: Hoàn kho
        UPDATE TON_KHO
        SET SoLuongTon = SoLuongTon + @SoLuongDaKe
        WHERE MaCN = @MaCN AND MaMatHang = @MaThuoc;

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO
/****** Object:  StoredProcedure [dbo].[sp_XuatHoaDonTrucTiep]    Script Date: 1/8/2026 10:29:59 PM ******/
SET ANSI_NULLS ON
GO
SET QUOTED_IDENTIFIER ON
GO

CREATE PROCEDURE [dbo].[sp_XuatHoaDonTrucTiep]  
    @MaPhieu NCHAR(10),  
    @DiemMuonDung INT = 0,
    @PhuongThucTT NVARCHAR(50),  
    @MaNV_XuatHD NCHAR(10)
AS  
BEGIN  
    SET NOCOUNT ON;  
    SET XACT_ABORT ON;

    DECLARE @TrangThai VARCHAR(3);  
    DECLARE @MaKH NCHAR(10);  
    DECLARE @LoaiPhieu VARCHAR(2);
      
    SELECT @TrangThai = TrangThai, @MaKH = MaKH, @LoaiPhieu = LoaiPhieu  
    FROM PHIEU_DICH_VU   
    WHERE MaPhieu = @MaPhieu;  

    IF @TrangThai IS NULL  
    BEGIN  
        RAISERROR(N'Lỗi: Phiếu dịch vụ không tồn tại!', 16, 1);  
        RETURN;  
    END  

    IF @TrangThai <> 'DHT'   
    BEGIN  
        RAISERROR(N'Lỗi: Phiếu chưa được xác nhận hoàn tất!', 16, 1);  
        RETURN;  
    END  

    DECLARE @DiemHienCo INT;  
    SELECT @DiemHienCo = ISNULL(TongDiemTichLuy, 0) FROM KHACH_HANG WHERE MaKH = @MaKH;  

    IF @DiemMuonDung > @DiemHienCo  
    BEGIN  
        RAISERROR(N'Lỗi: Điểm tích lũy không đủ (Hiện có: %d)!', 16, 1, @DiemHienCo);  
        RETURN;  
    END  

    IF @DiemMuonDung < 0  
    BEGIN  
        RAISERROR(N'Lỗi: Số điểm sử dụng không được âm!', 16, 1);  
        RETURN;  
    END  

    DECLARE @TongTienHang DECIMAL(18,2) = 0;  

    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)  
    FROM CT_DON_THUOC WHERE MaPhieu = @MaPhieu;  

    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)  
    FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu;  

    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)  
    FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu;  

    DECLARE @TienDichVuCoBan DECIMAL(18,2) = 0;  

    IF @LoaiPhieu = 'KB'  
    BEGIN  
        SET @TienDichVuCoBan = 150000;  
    END  
    ELSE IF @LoaiPhieu = 'TV'  
    BEGIN  
        IF EXISTS (SELECT 1 FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu AND (NhacLai = 0 OR NhacLai IS NULL))  
        BEGIN  
            SET @TienDichVuCoBan = 200000;  
        END  
        ELSE  
        BEGIN  
            SET @TienDichVuCoBan = 0;  
        END  
    END  

    SET @TongTienHang = @TongTienHang + @TienDichVuCoBan;  

    DECLARE @PhanTramGiam INT = 0;  
    DECLARE @TienGiamHangTV DECIMAL(18,2) = 0;  

    SELECT TOP 1 @PhanTramGiam = HTV.KhuyenMaiUuTien  
    FROM XEP_HANG_NAM XHN  
    JOIN HANG_TV HTV ON XHN.MaHang = HTV.MaHang  
    WHERE XHN.MaKH = @MaKH  
    ORDER BY XHN.Nam DESC;

    SET @TienGiamHangTV = @TongTienHang * (ISNULL(@PhanTramGiam, 0) / 100.0);  

    DECLARE @TienGiamDiem DECIMAL(18,2);  
    SET @TienGiamDiem = @DiemMuonDung * 1000.0;  

    DECLARE @TongKhuyenMai DECIMAL(18,2) = @TienGiamHangTV + @TienGiamDiem;  
    DECLARE @TongThanhToan DECIMAL(18,2) = @TongTienHang - @TongKhuyenMai;  

    IF @TongThanhToan < 0 SET @TongThanhToan = 0;  

    BEGIN TRANSACTION;  
    BEGIN TRY  
          
        --  THÊM MaNV = @MaNV_XuatHD VÀO ĐÂY
        UPDATE HD_TRUC_TIEP  
        SET TongThanhTien = @TongTienHang,
            KhuyenMai = @TongKhuyenMai,  
            DiemQuyDoi = @DiemMuonDung,  
            TongThanhTienSC = @TongThanhToan,  
            PhuongThucTT = @PhuongThucTT,
            MaNV = @MaNV_XuatHD  --  DÒNG NÀY
        WHERE MaPhieu = @MaPhieu;  

        IF @DiemMuonDung > 0  
        BEGIN  
            UPDATE KHACH_HANG  
            SET TongDiemTichLuy = TongDiemTichLuy - @DiemMuonDung  
            WHERE MaKH = @MaKH;  
        END  

        DECLARE @DiemCongThem INT = 0;  
        SET @DiemCongThem = CAST(@TongThanhToan / 50000 AS INT);  

        IF @DiemCongThem > 0  
        BEGIN  
            UPDATE KHACH_HANG  
            SET TongDiemTichLuy = TongDiemTichLuy + @DiemCongThem  
            WHERE MaKH = @MaKH;  
        END  
          
        UPDATE PHIEU_DICH_VU   
        SET TG_ThucHienDV = GETDATE()
        WHERE MaPhieu = @MaPhieu;  

        COMMIT TRANSACTION;  

        SELECT   
            @MaPhieu AS MaHoaDon,  
            FORMAT(@TienDichVuCoBan, 'N0', 'vi-VN') AS TienDichVuCoBan,
            FORMAT(@TongTienHang, 'N0', 'vi-VN') AS TongTienHang,
            FORMAT(@TienGiamHangTV, 'N0', 'vi-VN') AS GiamHangTV,  
            FORMAT(@TienGiamDiem, 'N0', 'vi-VN') AS GiamDiem,  
            FORMAT(@TongThanhToan, 'N0', 'vi-VN') AS KhachCanTra,  
            @DiemCongThem AS DiemDuocCong,  
            @DiemHienCo AS DiemHienCoBanDau,
            (@DiemHienCo - @DiemMuonDung + @DiemCongThem) AS DiemConLai;
  
    END TRY  
    BEGIN CATCH  
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;  
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();  
        RAISERROR(@Err, 16, 1);  
    END CATCH  
END;
GO


USE HAPPYPET
GO

--  SP CẬP NHẬT ĐIỂM SAU KHI GIAO HÀNG THÀNH CÔNG
-- Gọi khi nhân viên nhấn "Đã nhận hàng" (DTH → DHT)
CREATE OR ALTER PROC sp_CapNhatDiemSauKhiGiaoHang
    @MaPhieu NCHAR(10)  --  Nhận MaPhieu chứ không phải MaHD
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaKH NCHAR(10);
    DECLARE @TongTien DECIMAL(18, 2);
    DECLARE @DiemCong INT;
    DECLARE @DiemHienTai INT;
    
    -- 1. Lấy thông tin khách hàng và tổng tiền từ hóa đơn trực tuyến
    SELECT 
        @MaKH = P.MaKH,
        @TongTien = H.TongThanhTienSC  --  Sau khi trừ điểm, ship, khuyến mãi
    FROM HD_TRUC_TUYEN H
    JOIN PHIEU_DICH_VU P ON H.MaPhieu = P.MaPhieu
    WHERE LTRIM(RTRIM(H.MaPhieu)) = LTRIM(RTRIM(@MaPhieu));
    
    IF @MaKH IS NULL
    BEGIN
        RAISERROR(N'Không tìm thấy khách hàng cho hóa đơn này!', 16, 1);
        RETURN;
    END
    
    -- 2. Tính điểm được cộng (1 điểm = 50.000đ)
    SET @DiemCong = FLOOR(@TongTien / 50000);
    
    -- 3. Cộng điểm vào tài khoản khách hàng
    UPDATE KHACH_HANG
    SET TongDiemTichLuy = ISNULL(TongDiemTichLuy, 0) + @DiemCong
    WHERE MaKH = @MaKH;
    
    -- 4. Lấy điểm sau khi cộng
    SELECT @DiemHienTai = TongDiemTichLuy FROM KHACH_HANG WHERE MaKH = @MaKH;
    
    -- 5. Trả về thông báo
    SELECT 
        @MaKH AS MaKhachHang,
        @TongTien AS TongTienDonHang,
        @DiemCong AS DiemDuocCong,
        @DiemHienTai AS DiemConLai,
        N'Đã cộng ' + CAST(@DiemCong AS NVARCHAR(10)) + N' điểm cho khách hàng!' AS Message;
END;
GO
-- THỐNG KÊ SỐ LƯỢT KHÁM THEO THỜI GIAN
CREATE OR ALTER PROC sp_ThongKeSoLuotKham
    @MaCN NCHAR(10) = NULL,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @TuNgay IS NULL SET @TuNgay = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    IF @DenNgay IS NULL SET @DenNgay = EOMONTH(GETDATE());
    
    SELECT 
        CONVERT(DATE, P.TG_LapPhieu) AS Ngay,
        CN.TenCN AS ChiNhanh,
        COUNT(*) AS SoLuotKham,
        SUM(ISNULL(HTT.TongThanhTienSC, 0) + ISNULL(HT.TongThanhTienSC, 0)) AS DoanhThu
    FROM PHIEU_DICH_VU P
    JOIN NHAN_VIEN NV ON P.MaNV = NV.MaNV
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HT ON P.MaPhieu = HT.MaPhieu
    WHERE 
        P.LoaiPhieu = 'KB'  -- Chỉ phiếu khám bệnh
        AND P.TrangThai IN ('DHT', 'HT')
        AND CAST(P.TG_LapPhieu AS DATE) BETWEEN @TuNgay AND @DenNgay
        AND (@MaCN IS NULL OR NV.MaCN = @MaCN)
    GROUP BY CONVERT(DATE, P.TG_LapPhieu), CN.TenCN
    ORDER BY Ngay DESC, CN.TenCN;
END;
GO

-- THỐNG KÊ DOANH THU BÁN SẢN PHẨM
CREATE OR ALTER PROC sp_ThongKeDoanhThuBanHang
    @MaCN NCHAR(10) = NULL,
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    IF @TuNgay IS NULL SET @TuNgay = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    IF @DenNgay IS NULL SET @DenNgay = EOMONTH(GETDATE());
    
    SELECT 
        MH.LoaiMH,
        CASE 
            WHEN MH.LoaiMH = 'T' THEN N'Thuốc'
            WHEN MH.LoaiMH = 'VC' THEN N'Vaccine'
            WHEN MH.LoaiMH = 'SPK' THEN N'Sản phẩm khác'
        END AS TenLoai,
        CN.TenCN AS ChiNhanh,
        COUNT(DISTINCT CT.MaPhieu) AS SoDonHang,
        SUM(CT.SoLuong) AS TongSoLuong,
        SUM(CT.ThanhTien) AS TongDoanhThu
    FROM CT_MUA_HANG CT
    JOIN MAT_HANG MH ON CT.MaMatHang = MH.MaMatHang
    JOIN PHIEU_MUA_HANG PMH ON CT.MaPhieu = PMH.MaPhieu
    JOIN PHIEU_DICH_VU PDV ON PMH.MaPhieu = PDV.MaPhieu
    JOIN NHAN_VIEN NV ON PDV.MaNV = NV.MaNV
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    WHERE 
        PDV.TrangThai IN ('DTH', 'DHT')
        AND CAST(PDV.TG_LapPhieu AS DATE) BETWEEN @TuNgay AND @DenNgay
        AND (@MaCN IS NULL OR NV.MaCN = @MaCN)
    GROUP BY MH.LoaiMH, CN.TenCN
    ORDER BY TongDoanhThu DESC;
END;
GO

-- THỐNG KÊ DOANH THU PHÒNG KHÁM THEO BÁC SĨ
CREATE OR ALTER PROC sp_ThongKeDoanhThuBacSi
    @MaCN NCHAR(10) = NULL,  -- Nếu NULL = tất cả chi nhánh (cho Giám đốc)
    @TuNgay DATE = NULL,
    @DenNgay DATE = NULL
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Mặc định: tháng hiện tại
    IF @TuNgay IS NULL SET @TuNgay = DATEFROMPARTS(YEAR(GETDATE()), MONTH(GETDATE()), 1);
    IF @DenNgay IS NULL SET @DenNgay = EOMONTH(GETDATE());
    
    SELECT 
        NV.MaNV,
        U.HoTen AS TenBacSi,
        CN.TenCN AS ChiNhanh,
        COUNT(DISTINCT P.MaPhieu) AS SoLuotKham,
        SUM(ISNULL(HTT.TongThanhTienSC, 0) + ISNULL(HT.TongThanhTienSC, 0)) AS TongDoanhThu
    FROM PHIEU_DICH_VU P
    JOIN NHAN_VIEN NV ON P.MaNV = NV.MaNV
    JOIN [USER] U ON NV.MaNV = U.MaUser
    JOIN CHI_NHANH CN ON NV.MaCN = CN.MaCN
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HT ON P.MaPhieu = HT.MaPhieu
    WHERE 
        P.LoaiPhieu IN ('KB', 'TV')  -- Khám bệnh + tiêm vaccine
        AND P.TrangThai IN ('DHT', 'HT')  -- Đã hoàn tất
        AND CAST(P.TG_LapPhieu AS DATE) BETWEEN @TuNgay AND @DenNgay
        AND (@MaCN IS NULL OR NV.MaCN = @MaCN)
    GROUP BY NV.MaNV, U.HoTen, CN.TenCN
    ORDER BY TongDoanhThu DESC;
END;
GO


