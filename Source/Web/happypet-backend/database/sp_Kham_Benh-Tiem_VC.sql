-- Thông tin các SP trong hệ thống Happy Pet (Phân hệ Bác sĩ) --
-- Nhóm nghiệp vụ Khám bệnh
-- 1 sp_CapNhatKetQuaKham : Bác sĩ ghi nhận chẩn đoán bệnh và ngày hẹn tái khám (nếu có) vào phiếu khám.
-- 2 sp_ThemThuocVaoDon : Kê đơn thuốc cho thú cưng, tự động trừ tồn kho thuốc tại chi nhánh và tính thành tiền.
-- 3 sp_XoaThuocKhoiDon : Loại bỏ thuốc khỏi đơn thuốc (khi bác sĩ thay đổi chỉ định), đồng thời hoàn lại số lượng thuốc vào kho.
-- 4 sp_BacSi_KetThucKham : Xác nhận hoàn tất quá trình khám bệnh chuyên môn, chuyển trạng thái phiếu sang "Đã hoàn thành" (DHT).

-- Nhóm nghiệp vụ Tiêm chủng (Vaccine)
-- 5 sp_BacSi_ThemGoiTiem : Ghi nhận đăng ký gói tiêm mới cho khách hàng vãng lai (không đặt trước), tự động trừ liều đầu tiên trong kho.
-- 6 sp_BacSi_XoaGoiTiem : Hủy thông tin gói tiêm vừa đăng ký và hoàn lại số lượng vaccine vào kho chi nhánh.
-- 7 sp_BacSi_ThemVaccineLe : Ghi nhận tiêm vaccine lẻ hoặc tiêm nhắc lại theo gói sẵn có (nếu theo gói thì thành tiền sẽ bằng 0).
-- 8 sp_BacSi_XoaVaccineLe : Xóa mũi tiêm lẻ khỏi phiếu, hoàn kho vaccine và tự động "mở lại" hiệu lực gói tiêm nếu đó là mũi tiêm nhắc lại vừa bị xóa.
-- 9 sp_BacSi_KetThucTiem : Xác nhận hoàn tất quy trình tiêm chủng, chuyển trạng thái phiếu sang "Đã hoàn thành" (DHT).

USE HAPPYPET
GO

-- 1. Bác sĩ điền thông tin chẩn đoán và ngày hẹn tái khám vào phiếu.
CREATE OR ALTER PROC sp_CapNhatKetQuaKham
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

-- 2. Bác sĩ kê đơn thuốc
CREATE OR ALTER PROC sp_ThemThuocVaoDon
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

-- 3. Xóa thuốc khỏi đơn
CREATE OR ALTER PROC sp_XoaThuocKhoiDon
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

-- 4. Bác sĩ kết thúc khám 
CREATE OR ALTER PROC sp_BacSi_KetThucKham
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
            TG_ThucHienDV = GETDATE()  -- 🔥 GHI ĐÈ = thời gian hoàn thành khám
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

-- 5. Bác sĩ ghi nhận gói tiêm đối với khách tiêm không đặt lịch trước
CREATE OR ALTER PROC sp_BacSi_ThemGoiTiem
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
        -- 🔥 MŨI 1 TRẢ TIỀN GÓI, từ mũi 2 trở đi mới miễn phí
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

-- 6. Bác sĩ xóa gói tiêm
CREATE OR ALTER PROC sp_BacSi_XoaGoiTiem
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

-- 7. Bác sĩ ghi nhận VC đối với khách tiêm không đặt lịch
CREATE OR ALTER PROC sp_BacSi_ThemVaccineLe
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

-- 8. Bác sĩ xóa VC
CREATE OR ALTER PROC sp_BacSi_XoaVaccineLe
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

-- 9. Bác sĩ kết thúc tiêm vc
CREATE OR ALTER PROC sp_BacSi_KetThucTiem
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

    -- 🔥 TÍNH TỔNG TIỀN TỪ VACCINE
    DECLARE @TongTienVaccine DECIMAL(18,2);
    
    SELECT @TongTienVaccine = ISNULL(SUM(ThanhTien), 0)
    FROM CT_TIEM_VC
    WHERE MaPhieu = @MaPhieu;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. Update trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DHT',         -- Đã hoàn tất (Chờ thanh toán)
            TG_ThucHienDV = GETDATE()  -- 🔥 GHI ĐÈ = thời gian hoàn thành tiêm
        WHERE MaPhieu = @MaPhieu;
        
        -- 🔥 KHÔNG CẬP NHẬT HÓA ĐƠN NỮA!
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


