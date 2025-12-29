-- Thông tin các SP --
-- Phân hệ khách hàng
-- 1	sp_DatLichHen : Đặt lịch hẹn khám bệnh (KB) hoặc tiêm vaccine (TV).
-- 2.1	sp_App_ChonGoiTiem : Khách tự chọn đăng ký gói tiêm mới khi đặt lịch.
-- 2.2	sp_App_ChonVaccineLe : Chọn tiêm lẻ hoặc sử dụng mũi tiêm có sẵn trong gói.
-- 2.3	sp_App_XoaGoiTiem : Hủy/Xóa gói tiêm đã chọn trong lịch hẹn.
-- 2.4	sp_App_XoaVaccineLe : Hủy/Xóa vaccine lẻ đã chọn trong lịch hẹn.
-- 3    sp_XemLichBacSi : Khách hàng xem lịch bác sĩ tại một chi nhánh.
-- 6	sp_HuyLichHen : Khách chủ động hủy lịch hẹn đã đặt (khi chưa check-in).
-- 10	sp_DanhGiaDichVu : Gửi đánh giá sau khi hoàn tất dịch vụ tại cửa hàng.
-- 11	sp_DanhGiaSanPham : Gửi đánh giá cho từng sản phẩm/mặt hàng đã mua.

-- Phân hệ Tiếp tân / Bán hàng
-- 4 sp_TaoPhieuTrucTiep : Tạo phiếu dịch vụ cho khách vãng lai tại cửa hàng.
-- 5 sp_CheckInKhachHang : Tiếp nhận khách đã đặt lịch, gán bác sĩ phụ trách.
-- 9 sp_XuatHoaDonTrucTiep : Tính toán tổng tiền, áp dụng ưu đãi và xuất hóa đơn.

-- Phân hệ Bác sĩ thú y
-- 8 sp_HoanTatDichVu : Xác nhận hoàn tất chuyên môn để chuyển sang thanh toán.

-- Phân hệ Quản lý / Hệ thống (Admin)
-- 7 sp_TuDongHuyLichHen : Hệ thống tự động hủy các phiếu quá giờ hẹn 120 phút.

USE HAPPYPET
GO

-- Dat Lich hen
CREATE OR ALTER PROC sp_DatLichHen
    @MaKH NCHAR(10),
    @MaTC NCHAR(10), 
    @MaCN NCHAR(10),
    @LoaiPhieu VARCHAR(2), 
    @NgayHen DATE,
    @GioHen TIME,            
    @TrieuChung NVARCHAR(200) = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;
    
    -- =============================================
    -- 1. VALIDATION CƠ BẢN (GIỮ NGUYÊN)
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

    DECLARE @ThoiGianHen DATETIME = CAST(@NgayHen AS DATETIME) + CAST(@GioHen AS DATETIME);
    IF @ThoiGianHen < GETDATE()
    BEGIN
        RAISERROR(N'Lỗi: Thời gian hẹn không hợp lệ (Phải lớn hơn hiện tại)!', 16, 1);
        RETURN;
    END

    -- 2. CHECK GIỜ MỞ CỬA
    DECLARE @GioMoCua TIME, @GioDongCua TIME;
    SELECT @GioMoCua = Giomocua, @GioDongCua = Giodongcua 
    FROM CHI_NHANH WHERE MaCN = @MaCN;

    IF @GioHen < @GioMoCua OR @GioHen > @GioDongCua
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh không làm việc vào giờ này!', 16, 1);
        RETURN;
    END

    -- 3. CHECK DỊCH VỤ
    IF @LoaiPhieu = 'KB' AND NOT EXISTS (SELECT 1 FROM DV_CN WHERE MaCN = @MaCN AND MaLoaiDV = 'DV01') -- Sửa cứng mã DV01 cho gọn
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Khám bệnh!', 16, 1);
        RETURN;
    END
    IF @LoaiPhieu = 'TV' AND NOT EXISTS (SELECT 1 FROM DV_CN WHERE MaCN = @MaCN AND MaLoaiDV = 'DV02')
    BEGIN
        RAISERROR(N'Lỗi: Chi nhánh này không cung cấp dịch vụ Tiêm vaccine!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 4. KIỂM TRA QUÁ TẢI (Dùng bảng PHAN_CONG_CN)
    -- =============================================
    DECLARE @TongSoBacSi INT;
    DECLARE @SoPhieuDaDat INT;

    -- A. Đếm số bác sĩ được phân công (FIX LỖI CHÍNH TẢ Ở ĐÂY)
    SELECT @TongSoBacSi = COUNT(*)
    FROM PHAN_CONG_CN PC
    JOIN NHAN_VIEN NV ON PC.MaNV = NV.MaNV
    WHERE PC.MaCN = @MaCN
      AND @NgayHen BETWEEN PC.NgayBD AND PC.NgayKT -- Kiểm tra còn hạn phân công
      AND NV.Chucvu LIKE N'%Bác sĩ%'; -- 🔥 QUAN TRỌNG: Dùng LIKE để bắt "Bác sĩ thú y"

    -- Nếu ngày đó không có bác sĩ nào -> Báo lỗi
    IF @TongSoBacSi IS NULL OR @TongSoBacSi = 0
    BEGIN
        -- Nếu là tiêm vaccine thì có thể châm chước (nếu bà muốn), còn khám bệnh thì chặn
        RAISERROR(N'Lỗi: Ngày này chi nhánh chưa có lịch phân công bác sĩ, vui lòng liên hệ hotline!', 16, 1);
        RETURN;
    END

    -- B. Đếm số phiếu đã đặt
    SELECT @SoPhieuDaDat = COUNT(*)
    FROM PHIEU_DICH_VU
    WHERE MaCN = @MaCN
      AND TG_ThucHienDV = @ThoiGianHen
      AND TrangThai IN ('DD', 'DTH');

    -- C. So sánh (Giả sử 1 bác sĩ chỉ tiếp 1 khách cùng lúc)
    IF @SoPhieuDaDat >= @TongSoBacSi
    BEGIN
        RAISERROR(N'Lỗi: Khung giờ này đã hết suất (Full slot), vui lòng chọn giờ khác!', 16, 1);
        RETURN;
    END

    -- =============================================
    -- 5. INSERT DỮ LIỆU
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        DECLARE @MaPhieu NCHAR(10);
        DECLARE @HauTo INT;
        
        SELECT @HauTo = ISNULL(MAX(CAST(RIGHT(MaPhieu, 7) AS INT)), 0)
        FROM PHIEU_DICH_VU WITH (UPDLOCK, HOLDLOCK)
        WHERE LEFT(MaPhieu, 1) = 'P' AND ISNUMERIC(RIGHT(MaPhieu, 7)) = 1;

        SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo + 1 AS VARCHAR(7)), 7); 

        WHILE EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu)
        BEGIN
            SET @HauTo = @HauTo + 1;
            SET @MaPhieu = 'P' + RIGHT('0000000' + CAST(@HauTo AS VARCHAR(7)), 7);
        END

        INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_ThucHienDV, TG_LapPhieu, TrangThai, LoaiPhieu, MaCN, MaNV, MaKH)
        VALUES (@MaPhieu, @ThoiGianHen, GETDATE(), 'DD', @LoaiPhieu, @MaCN, NULL, @MaKH);
        
        IF @LoaiPhieu = 'KB'
        BEGIN
            INSERT INTO PHIEU_KHAM_BENH (MaPhieu, MaTC, TrieuChung, ChanDoan, NgayHenTaiKham)
            VALUES (@MaPhieu, @MaTC, ISNULL(@TrieuChung, N'Chưa rõ'), NULL, NULL);
        END
        ELSE IF @LoaiPhieu = 'TV'
        BEGIN
            INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC)
            VALUES (@MaPhieu, @MaTC);
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

-- 2. Đối với đặt lịch hẹn cho dịch vụ tiêm thì KH phải chọn thêm VC/gói VC
-- 2.1 Chọn gói tiêm mới
CREATE OR ALTER PROC sp_App_ChonGoiTiem
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

-- 2.2 Tiêm lẻ hoặc tiêm nhắc lại
CREATE OR ALTER PROC sp_App_ChonVaccineLe
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

    -- 3. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- B1: Trừ kho giữ chỗ
        UPDATE TON_KHO SET SoLuongTon = SoLuongTon - 1 
        WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

        -- B2: Thêm vào chi tiết (Nhắc lại = 1 nếu theo gói, 0 nếu lẻ - hoặc tùy logic App truyền vào)
        INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, NhacLai, LieuLuong, ThanhTien)
        VALUES (@MaVaccine, @MaPhieu, @TheoGoi, N'Đặt qua App', @ThanhTien);

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

-- 2.3 Xóa gói
CREATE OR ALTER PROC sp_App_XoaGoiTiem
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

-- 2.4 Xóa VC
CREATE OR ALTER PROC sp_App_XoaVaccineLe
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

-- 3. Khách hàng xem lịch bác sĩ
CREATE OR ALTER PROC sp_XemLichBacSi
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

-- 4. Nhân viên tạo phiếu DV cho khách trực tiếp tại cửa hàng
CREATE OR ALTER PROC sp_TaoPhieuTrucTiep
    @MaKH NCHAR(10),
    @MaTC NCHAR(10) = NULL,
    @MaCN NCHAR(10),
    @MaNV NCHAR(10), 
    @LoaiPhieu VARCHAR(2), 
    @TrieuChung NVARCHAR(200) = NULL
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

-- 5. Nhân viên check in khi khách (đã đặt lịch trước) tới cửa hàng, gán bác sĩ phụ trách
CREATE OR ALTER PROC sp_CheckInKhachHang
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

    -- 1.4 🔥 KIỂM TRA GIỞ LÀM VIỆC
    DECLARE @GioHienTai TIME = CAST(GETDATE() AS TIME);
    DECLARE @GioMoCua TIME, @GioDongCua TIME;
    
    SELECT @GioMoCua = Giomocua, @GioDongCua = Giodongcua 
    FROM CHI_NHANH 
    WHERE MaCN = @MaCN_Phieu;

    IF @GioHienTai < @GioMoCua OR @GioHienTai > @GioDongCua
    BEGIN
        RAISERROR(N'Lỗi: Hiện tại ngoài giờ làm việc của chi nhánh!', 16, 1);
        RETURN;
    END

    -- 1.5 🔥 KIỂM TRA BÁC SĨ CÓ ĐANG BẬN KHÔNG (Nếu là KB/TV)
    IF @LoaiPhieu IN ('KB', 'TV')
    BEGIN
        DECLARE @SoPhieuDangXuLy INT;
        SELECT @SoPhieuDangXuLy = COUNT(*)
        FROM PHIEU_DICH_VU
        WHERE MaNV = @MaNV_PhuTrach 
          AND TrangThai = 'DTH' -- Đang thực hiện
          AND LoaiPhieu IN ('KB', 'TV');

        IF @SoPhieuDangXuLy > 0
        BEGIN
            RAISERROR(N'Lỗi: Bác sĩ này đang bận với phiếu khác, vui lòng chọn bác sĩ khác!', 16, 1);
            RETURN;
        END
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
            TG_ThucHienDV = GETDATE()      -- 🔥 GHI ĐÈ = thời gian check-in thực tế
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

-- 6. Hủy lịch hẹn
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
        @TG_ThucHienDV = TG_ThucHienDV -- Lấy giờ hẹn
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
-- =============================================
    -- 2. XỬ LÝ LOGIC HOÀN TRẢ (TRANSACTION)
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- ... (Đoạn xử lý Hồi sinh gói tiêm giữ nguyên y chang cũ) ...
        -- Tạo bảng tạm lưu các loại vaccine có trong phiếu hủy
        DECLARE @VaccineCanCheck TABLE (MaVaccine NCHAR(10));
        INSERT INTO @VaccineCanCheck (MaVaccine)
        SELECT MaVaccine FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu;

        -- Duyệt qua từng vaccine để check gói
        DECLARE @Cur_MaVaccine NCHAR(10);
        
        DECLARE cur_CheckGoi CURSOR FOR SELECT MaVaccine FROM @VaccineCanCheck;
        OPEN cur_CheckGoi;
        FETCH NEXT FROM cur_CheckGoi INTO @Cur_MaVaccine;

        WHILE @@FETCH_STATUS = 0
        BEGIN
            -- Tìm gói tiêm gần nhất của khách bị hết hiệu lực (HieuLuc=0) và chưa hết hạn ngày
            DECLARE @MaPhieuDK NCHAR(10), @MaGoiDK NCHAR(10), @SoMuiQuyDinh INT, @NgayDangKy DATETIME;
            
            SELECT TOP 1 
                @MaPhieuDK = DK.MaPhieu,
                @MaGoiDK = DK.MaGoi,
                @SoMuiQuyDinh = G.SoMuiTuongUng,
                @NgayDangKy = P.TG_LapPhieu
            FROM DANG_KI_GOI_TIEM DK
            JOIN PHIEU_DICH_VU P ON DK.MaPhieu = P.MaPhieu
            JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
            WHERE P.MaKH = @MaKH 
              AND DK.MaVaccine = @Cur_MaVaccine
              AND DK.HieuLuc = 0 
              AND DK.NgayHetHan >= CAST(GETDATE() AS DATE) 
            ORDER BY DK.NgayHetHan DESC; 

            IF @MaPhieuDK IS NOT NULL
            BEGIN
                DECLARE @SoMuiThucTe INT;
                SELECT @SoMuiThucTe = COUNT(*)
                FROM CT_TIEM_VC CT
                JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
                WHERE P.MaKH = @MaKH 
                  AND CT.MaVaccine = @Cur_MaVaccine
                  AND P.TG_LapPhieu >= @NgayDangKy
                  AND CT.MaPhieu <> @MaPhieu; 

                IF @SoMuiThucTe < @SoMuiQuyDinh
                BEGIN
                    UPDATE DANG_KI_GOI_TIEM
                    SET HieuLuc = 1
                    WHERE MaPhieu = @MaPhieuDK AND MaVaccine = @Cur_MaVaccine AND MaGoi = @MaGoiDK;
                END
            END
            FETCH NEXT FROM cur_CheckGoi INTO @Cur_MaVaccine;
        END
        CLOSE cur_CheckGoi;
        DEALLOCATE cur_CheckGoi;

        -- Hoàn trả kho 
        UPDATE k
        SET k.SoLuongTon = k.SoLuongTon + 1
        FROM TON_KHO k
        INNER JOIN CT_TIEM_VC c ON k.MaMatHang = c.MaVaccine
        WHERE c.MaPhieu = @MaPhieu AND k.MaCN = @MaCN;

        -- Xóa dữ liệu chi tiết
        DELETE FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu;
        DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @MaPhieu;
        DELETE FROM PHIEU_KHAM_BENH WHERE MaPhieu = @MaPhieu;
        DELETE FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @MaPhieu;

        -- Cập nhật trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DH' -- Đã Hủy
        WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;
        -- PRINT N'Hủy lịch hẹn thành công.';

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        
        IF CURSOR_STATUS('global','cur_CheckGoi') >= -1
        BEGIN
            CLOSE cur_CheckGoi;
            DEALLOCATE cur_CheckGoi;
        END

        DECLARE @ErrorMessage NVARCHAR(4000) = ERROR_MESSAGE();
        RAISERROR(@ErrorMessage, 16, 1);
    END CATCH
END;
GO
-- 7. Phiếu tự động hủy khi quá giờ hẹn 120ph mà phiếu chưa được check in
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
        -- Bắt đầu Transaction cho từng phiếu riêng biệt
        -- Để nếu phiếu A lỗi thì phiếu B vẫn được xử lý tiếp
        BEGIN TRANSACTION;
        BEGIN TRY
            
            -- =========================================================
            -- A. LOGIC HỒI SINH GÓI TIÊM (Nếu phiếu này dùng gói và làm gói hết hạn)
            -- =========================================================
            -- Lấy danh sách vaccine trong phiếu này
            DECLARE @VaccineInTicket TABLE (MaVaccine NCHAR(10));
            DELETE FROM @VaccineInTicket; -- Clear bảng tạm
            INSERT INTO @VaccineInTicket (MaVaccine)
            SELECT MaVaccine FROM CT_TIEM_VC WHERE MaPhieu = @Cur_MaPhieu;

            -- Duyệt từng vaccine trong phiếu để check gói của khách
            DECLARE @Cur_MaVaccine NCHAR(10);
            
            DECLARE cur_CheckGoi CURSOR FOR SELECT MaVaccine FROM @VaccineInTicket;
            OPEN cur_CheckGoi;
            FETCH NEXT FROM cur_CheckGoi INTO @Cur_MaVaccine;

            WHILE @@FETCH_STATUS = 0
            BEGIN
                -- Tìm gói tiêm của khách đang bị HieuLuc=0 và còn hạn
                DECLARE @MaPhieuDK NCHAR(10), @MaGoiDK NCHAR(10), @SoMuiQuyDinh INT, @NgayDangKy DATETIME;
                
                SELECT TOP 1 
                    @MaPhieuDK = DK.MaPhieu,
                    @MaGoiDK = DK.MaGoi,
                    @SoMuiQuyDinh = G.SoMuiTuongUng,
                    @NgayDangKy = P.TG_LapPhieu
                FROM DANG_KI_GOI_TIEM DK
                JOIN PHIEU_DICH_VU P ON DK.MaPhieu = P.MaPhieu
                JOIN GOI_TIEM_VC G ON DK.MaGoi = G.MaGoi
                WHERE P.MaKH = @Cur_MaKH 
                  AND DK.MaVaccine = @Cur_MaVaccine
                  AND DK.HieuLuc = 0 -- Gói đã bị đóng
                  AND DK.NgayHetHan >= CAST(GETDATE() AS DATE)
                ORDER BY DK.NgayHetHan DESC;

                IF @MaPhieuDK IS NOT NULL
                BEGIN
                    -- Đếm số mũi thực tế (TRỪ ĐI phiếu đang hủy)
                    DECLARE @SoMuiThucTe INT;
                    SELECT @SoMuiThucTe = COUNT(*)
                    FROM CT_TIEM_VC CT
                    JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
                    WHERE P.MaKH = @Cur_MaKH 
                      AND CT.MaVaccine = @Cur_MaVaccine
                      AND P.TG_LapPhieu >= @NgayDangKy
                      AND CT.MaPhieu <> @Cur_MaPhieu; -- Không tính phiếu này

                    -- Nếu số mũi thực tế < Quy định -> Mở lại gói
                    IF @SoMuiThucTe < @SoMuiQuyDinh
                    BEGIN
                        UPDATE DANG_KI_GOI_TIEM
                        SET HieuLuc = 1
                        WHERE MaPhieu = @MaPhieuDK AND MaVaccine = @Cur_MaVaccine AND MaGoi = @MaGoiDK;
                    END
                END

                FETCH NEXT FROM cur_CheckGoi INTO @Cur_MaVaccine;
            END
            CLOSE cur_CheckGoi;
            DEALLOCATE cur_CheckGoi;

            -- =========================================================
            -- B. LOGIC HOÀN KHO
            -- =========================================================
            UPDATE k
            SET k.SoLuongTon = k.SoLuongTon + 1
            FROM TON_KHO k
            INNER JOIN CT_TIEM_VC c ON k.MaMatHang = c.MaVaccine
            WHERE c.MaPhieu = @Cur_MaPhieu AND k.MaCN = @Cur_MaCN;

            -- =========================================================
            -- C. DỌN DẸP DỮ LIỆU & CẬP NHẬT TRẠNG THÁI
            -- =========================================================
            DELETE FROM CT_TIEM_VC WHERE MaPhieu = @Cur_MaPhieu;
            DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @Cur_MaPhieu;
            DELETE FROM PHIEU_KHAM_BENH WHERE MaPhieu = @Cur_MaPhieu;
            DELETE FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @Cur_MaPhieu;

            UPDATE PHIEU_DICH_VU
            SET TrangThai = 'DH'
            WHERE MaPhieu = @Cur_MaPhieu;

            SET @SoLuongHuy = @SoLuongHuy + 1;

            COMMIT TRANSACTION;
        END TRY
        BEGIN CATCH
            -- Nếu lỗi ở phiếu này thì rollback phiếu này, nhưng vẫn chạy tiếp phiếu sau
            IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
            
            -- Dọn dẹp cursor con nếu bị lỗi giữa chừng
            IF CURSOR_STATUS('local', 'cur_CheckGoi') >= -1
            BEGIN
                CLOSE cur_CheckGoi;
                DEALLOCATE cur_CheckGoi;
            END

            -- Ghi log lỗi nếu cần (Ở đây in ra để debug)
            PRINT N'Lỗi khi hủy tự động phiếu ' + @Cur_MaPhieu + ': ' + ERROR_MESSAGE();
        END CATCH

        FETCH NEXT FROM cur_AutoHuy INTO @Cur_MaPhieu, @Cur_MaKH, @Cur_MaCN;
    END

    CLOSE cur_AutoHuy;
    DEALLOCATE cur_AutoHuy;

    -- Trả về kết quả tổng
    SELECT @SoLuongHuy AS SoPhieuDaHuyTuDong;
END;
GO

-- 8. Nhân viên xác nhận phiếu đã hoàn tất sau khi khách hàng thực hiện xong
CREATE OR ALTER PROC sp_HoanTatDichVu
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

-- 9. Nhân viên xuất hóa đơn trực tiếp
CREATE OR ALTER PROCEDURE sp_XuatHoaDonTrucTiep
    @MaPhieu NCHAR(10),
    @DiemMuonDung INT = 0,        -- Số điểm khách muốn dùng để giảm giá
    @PhuongThucTT NVARCHAR(50)
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- =============================================
    -- 1. VALIDATION
    -- =============================================
    
    DECLARE @TrangThai VARCHAR(3);
    DECLARE @MaKH NCHAR(10);
    DECLARE @LoaiPhieu VARCHAR(2); -- Cần lấy loại phiếu để tính tiền dịch vụ
    
    SELECT @TrangThai = TrangThai, @MaKH = MaKH, @LoaiPhieu = LoaiPhieu
    FROM PHIEU_DICH_VU 
    WHERE MaPhieu = @MaPhieu;

    IF @TrangThai IS NULL
    BEGIN
        RAISERROR(N'Lỗi: Phiếu dịch vụ không tồn tại!', 16, 1);
        RETURN;
    END

    -- Chỉ cho xuất hóa đơn khi đã hoàn tất chuyên môn (DHT)
    IF @TrangThai <> 'DHT' 
    BEGIN
        RAISERROR(N'Lỗi: Phiếu chưa được xác nhận hoàn tất!', 16, 1);
        RETURN;
    END

    -- Kiểm tra điểm tích lũy
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

    -- =============================================
    -- 2. TÍNH TOÁN TIỀN (CALCULATION)
    -- =============================================
    
    DECLARE @TongTienHang DECIMAL(18,2) = 0;

    -- A. Cộng tiền vật tư (Thuốc + Vaccine + Hàng hóa)
    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)
    FROM CT_DON_THUOC WHERE MaPhieu = @MaPhieu;

    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)
    FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu;

    SELECT @TongTienHang = @TongTienHang + ISNULL(SUM(ThanhTien), 0)
    FROM CT_MUA_HANG WHERE MaPhieu = @MaPhieu;

    -- B. TÍNH TIỀN DỊCH VỤ CƠ BẢN
    DECLARE @TienDichVuCoBan DECIMAL(18,2) = 0;

    IF @LoaiPhieu = 'KB'
    BEGIN
        -- Khám bệnh: Phí cố định 150k
        SET @TienDichVuCoBan = 150000;
    END
    ELSE IF @LoaiPhieu = 'TV'
    BEGIN
        -- Tiêm vaccine: Check xem có mũi tiêm thường (NhacLai=0) nào không
        -- Mua gói tiêm mũi 1 thì NhacLai cũng = 0 -> Vẫn tính tiền dịch vụ -> Đúng logic.
        IF EXISTS (SELECT 1 FROM CT_TIEM_VC WHERE MaPhieu = @MaPhieu AND (NhacLai = 0 OR NhacLai IS NULL))
        BEGIN
            -- Có ít nhất 1 mũi tiêm thường/tiêm mới -> Phí 200k
            SET @TienDichVuCoBan = 200000;
        END
        ELSE
        BEGIN
            -- Chỉ toàn là mũi nhắc lại (NhacLai = 1) -> Miễn phí dịch vụ
            SET @TienDichVuCoBan = 0;
        END
    END
    -- Nếu là 'MH' (Mua hàng) thì @TienDichVuCoBan là 0.

    -- C. Cộng tiền dịch vụ vào Tổng tiền hàng
    SET @TongTienHang = @TongTienHang + @TienDichVuCoBan;

    -- D. Tính giảm giá Hạng Thành Viên
    DECLARE @PhanTramGiam INT = 0;
    DECLARE @TienGiamHangTV DECIMAL(18,2) = 0;

    SELECT @PhanTramGiam = HTV.KhuyenMaiUuTien
    FROM XEP_HANG_NAM XHN
    JOIN HANG_TV HTV ON XHN.MaHang = HTV.MaHang
    WHERE XHN.MaKH = @MaKH AND XHN.Nam = YEAR(GETDATE()) - 1;

    SET @TienGiamHangTV = @TongTienHang * (ISNULL(@PhanTramGiam, 0) / 100.0);

    -- E. Tính giảm giá Điểm tích lũy (1 điểm = 1000 VNĐ)
    DECLARE @TienGiamDiem DECIMAL(18,2);
    SET @TienGiamDiem = @DiemMuonDung * 1000.0;

    -- F. Tổng kết
    DECLARE @TongKhuyenMai DECIMAL(18,2) = @TienGiamHangTV + @TienGiamDiem;
    DECLARE @TongThanhToan DECIMAL(18,2) = @TongTienHang - @TongKhuyenMai;

    IF @TongThanhToan < 0 SET @TongThanhToan = 0;

    -- =============================================
    -- 3. THỰC THI (UPDATE & CỘNG ĐIỂM)
    -- =============================================
    BEGIN TRANSACTION;
    BEGIN TRY
        
        -- B1: Cập nhật bảng HD_TRUC_TIEP
        UPDATE HD_TRUC_TIEP
        SET TongThanhTien = @TongTienHang,   -- Đã bao gồm tiền thuốc + vaccine + tiền dịch vụ
            KhuyenMai = @TongKhuyenMai,
            DiemQuyDoi = @DiemMuonDung,
            TongThanhTienSC = @TongThanhToan,
            PhuongThucTT = @PhuongThucTT
        WHERE MaPhieu = @MaPhieu;

        -- B2: Trừ điểm tích lũy đã dùng
        IF @DiemMuonDung > 0
        BEGIN
            UPDATE KHACH_HANG
            SET TongDiemTichLuy = TongDiemTichLuy - @DiemMuonDung
            WHERE MaKH = @MaKH;
        END

        -- B3: CỘNG ĐIỂM TÍCH LŨY MỚI (50.000 VNĐ = 1 điểm)
        DECLARE @DiemCongThem INT = 0;
        SET @DiemCongThem = CAST(@TongThanhToan / 50000 AS INT);

        IF @DiemCongThem > 0
        BEGIN
            UPDATE KHACH_HANG
            SET TongDiemTichLuy = TongDiemTichLuy + @DiemCongThem
            WHERE MaKH = @MaKH;
        END
        
        -- B4: Update trạng thái phiếu thành Hoàn Tất (HT)
        UPDATE PHIEU_DICH_VU 
        SET TrangThai = 'DHT',
            TG_ThucHienDV = GETDATE()      -- 🔥 GHI ĐÈ = thời gian thanh toán
        WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;

        -- B5: Trả về kết quả hiển thị (bao gồm chi tiết tiền dịch vụ để rõ ràng)
        SELECT 
            @MaPhieu AS MaHoaDon,
            FORMAT(@TienDichVuCoBan, 'N0', 'vi-VN') AS TienDichVuCoBan, -- Hiển thị thêm dòng này cho rõ
            FORMAT(@TongTienHang, 'N0', 'vi-VN') AS TongTienHang, -- Tổng (đã gồm DV)
            FORMAT(@TienGiamHangTV, 'N0', 'vi-VN') AS GiamHangTV,
            FORMAT(@TienGiamDiem, 'N0', 'vi-VN') AS GiamDiem,
            FORMAT(@TongThanhToan, 'N0', 'vi-VN') AS KhachCanTra,
            @DiemCongThem AS DiemDuocCong;

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- 10. Khách hàng đánh giá dịch vụ
CREATE OR ALTER PROC sp_DanhGiaDichVu
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

-- 11. Khách hàng đánh giá sản phẩm
CREATE OR ALTER PROC sp_DanhGiaSanPham
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