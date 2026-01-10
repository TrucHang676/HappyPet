/*
===============================================
FILE: 2_NHAN_VIEN_TU_VAN_BAC_SI.sql
Phân hệ: BÁC SĨ
===============================================

MỤC ĐÍCH:
- Quản lý khám bệnh & kết quả khám
- Tiêm vaccine & quản lý gói tiêm
- Kê đơn thuốc
- Xem danh sách khách hàng cần khám/tiêm
- Tra cứu dữ liệu vaccine & thuốc
- Đánh giá dịch vụ

CHỨC NĂNG CHI TIẾT:
1. Khám bệnh: Lấy danh sách, Kết thúc khám, Cập nhật kết quả
2. Tiêm vaccine: Lấy danh sách, Kết thúc tiêm, Thêm vaccine
3. Gói tiêm: Tạo gói, Xóa gói, Thêm vaccine vào gói
4. Vắc-xin lẻ: Chọn, Xóa
5. Tra cứu: Vaccine, Thuốc
6. Dịch vụ: Hoàn tất dịch vụ, Xem danh sách chi nhánh

TỔNG SỐ SP: 20

===============================================
DANH SÁCH STORED PROCEDURES:
===============================================
*/

-- 1. KHÁM BỆNH
-- sp_BacSi_LayDanhSachChoKham    : Lấy danh sách khách hàng cần khám
-- sp_BacSi_KetThucKham           : Kết thúc khám bệnh
-- sp_CapNhatKetQuaKham           : Cập nhật kết quả khám (chẩn đoán, kê đơn)

-- 2. TIÊM VACCINE
-- sp_BacSi_ThemGoiTiem           : Tạo gói tiêm mới
-- sp_BacSi_XoaGoiTiem            : Xóa gói tiêm
-- sp_BacSi_ThemVaccineLe         : Thêm vaccine lẻ (ngoài gói)
-- sp_BacSi_XoaVaccineLe          : Xóa vaccine lẻ
-- sp_BacSi_KetThucTiem           : Kết thúc tiêm vaccine
-- sp_ThemVaccineVaoGoiDangTiem   : Thêm vaccine vào gói đang tiêm

-- 3. DỊCH VỤ
-- sp_HoanTatDichVu               : Hoàn tất dịch vụ
-- sp_GetServicesByBranch         : Lấy danh sách dịch vụ theo chi nhánh

-- 4. LỊCH HẸN & DANH SÁCH
-- sp_LayDanhSachDatLich          : Xem danh sách lịch hẹn
-- sp_LayDanhSachDatLich_HomNay   : Xem lịch hẹn hôm nay
-- sp_LayDanhSachBacSi_TrangThai  : Xem danh sách bác sĩ theo trạng thái


-- 5. TRA CỨU DỮ LIỆU
-- sp_TraCuuVaccine                : Tra cứu thông tin vaccine
-- sp_TraCuuThuoc                  : Tra cứu thông tin thuốc
-- sp_TraCuuLichBacSi              : Tra cứu lịch bác sĩ

-- 6. LỊCH SỬ
-- sp_XemLichSuKhamBenh            : Xem lịch sử khám bệnh
-- sp_XemLichSuTiem                : Xem lịch sử tiêm vaccine
-- sp_XemLichSuTiemPhong           : Xem lịch sử tiêm phòng

USE HAPPYPET
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
        --   MŨI 1 TRẢ TIỀN GÓI, từ mũi 2 trở đi mới miễn phí
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

    --   TÍNH TỔNG TIỀN TỪ VACCINE
    DECLARE @TongTienVaccine DECIMAL(18,2);
    
    SELECT @TongTienVaccine = ISNULL(SUM(ThanhTien), 0)
    FROM CT_TIEM_VC
    WHERE MaPhieu = @MaPhieu;

    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. Update trạng thái phiếu
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DHT',         -- Đã hoàn tất (Chờ thanh toán)
            TG_ThucHienDV = GETDATE()  --   GHI ĐÈ = thời gian hoàn thành tiêm
        WHERE MaPhieu = @MaPhieu;
        
        --   KHÔNG CẬP NHẬT HÓA ĐƠN NỮA!
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
        ISNULL(HTT.TongThanhTien, HDTT.TongThanhTienSC) AS TongThanhTien, --   LẤY TỪ HD_TRUC_TUYEN HOẶC HD_TRUC_TIEP
        HTT.MaPhieu AS MaHD,  -- Để biết có HD_TRUC_TUYEN không
        HDTT.PhuongThucTT AS PhuongThucTT, --   LẤY PHƯƠNG THỨC THANH TOÁN ĐỂ BIẾT ĐÃ XUẤT HÓA ĐƠN CHƯA
        RTRIM(HDTT.MaNV) AS MaNV_XuatHD, --   MÃ NHÂN VIÊN XUẤT HÓA ĐƠN (từ HD_TRUC_TIEP)
        RTRIM(P.MaNV) AS MaNV_BacSi, --   MÃ BÁC SĨ (từ PHIEU_DICH_VU) - đổi tên để phân biệt
        U_BacSi.HoTen AS TenBacSi --   LẤY TÊN BÁC SĨ ĐÃ GÁN
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN [USER] U_BacSi ON P.MaNV = U_BacSi.MaUser --   JOIN ĐỂ LẤY TÊN BÁC SĨ
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HDTT ON P.MaPhieu = HDTT.MaPhieu --   JOIN ĐỂ LẤY PHƯƠNG THỨC TT
    WHERE P.MaCN = @MaCN 
      AND (@TrangThai IS NULL OR RTRIM(P.TrangThai) = @TrangThai)
      AND (
          --   LOGIC MỚI: Hiện đơn nếu thỏa 1 trong 2:
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

CREATE   PROC [dbo].[sp_LayDanhSachBacSi_TrangThai]
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        NV.MaNV,
        U.HoTen AS TenNV, --   Đổi tên cho đúng với frontend
        
        -- Đếm xem ổng đang ôm bao nhiêu ca 'DTH' (Đang thực hiện)
        (SELECT COUNT(*) 
         FROM PHIEU_DICH_VU P 
         WHERE P.MaNV = NV.MaNV AND P.TrangThai = 'DTH') AS SoCaDangKham,
         
        --   Đánh dấu trạng thái: "Rảnh" hoặc "Bận"
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

