/*
===============================================
FILE: 3_NHAN_VIEN_TIEP_TAN_BAN_HANG.sql
Phân hệ: NHÂN VIÊN TIẾP TÂN & BÁN HÀNG
===============================================

MỤC ĐÍCH:
- Check-in khách hàng
- Tạo phiếu dịch vụ (trực tiếp & vắng lại)
- Quản lý sản phẩm trong phiếu (thêm, xóa)
- Quản lý thuốc trong phiếu
- Xuất hóa đơn
- Tra cứu sản phẩm & lịch sử

CHỨC NĂNG CHI TIẾT:
1. Check-in: Tiếp nhận khách hàng
2. Phiếu dịch vụ: Tạo trực tiếp, Tạo vắng lại
3. Sản phẩm: Thêm vào phiếu, Xóa khỏi phiếu
4. Thuốc: Thêm vào phiếu, Xóa khỏi phiếu
5. Hóa đơn: Xuất hóa đơn
6. Tra cứu: Sản phẩm, Theo chi nhánh


TỔNG SỐ SP: 14

===============================================
DANH SÁCH STORED PROCEDURES:
===============================================
*/

-- 1. CHECK-IN & TIẾP NHẬN
-- sp_CheckInKhachHang             : Check-in khách hàng tại chi nhánh

-- 2. TẠO PHIẾU DỊCH VỤ
-- sp_TaoPhieuTrucTiep             : Tạo phiếu dịch vụ trực tiếp
-- sp_TaoPhieuVangLai_Full         : Tạo phiếu dịch vụ vắng lại

-- 3. QUẢN LÝ SẢN PHẨM TRONG PHIẾU
-- sp_ThemSanPhamVaoDon            : Thêm sản phẩm vào phiếu
-- sp_XoaSanPhamKhoiDon            : Xóa sản phẩm khỏi phiếu

-- 4. QUẢN LÝ THUỐC TRONG PHIẾU
-- sp_ThemThuocVaoDon              : Thêm thuốc vào phiếu
-- sp_XoaThuocKhoiDon              : Xóa thuốc khỏi phiếu

-- 5. XUẤT HÓA ĐƠN
-- sp_XuatHoaDonTrucTiep           : Xuất hóa đơn trực tiếp

-- 6. TRA CỨU SẢN PHẨM
-- sp_TraCuuSanPham                : Tra cứu sản phẩm (tất cả chi nhánh)
-- sp_TraCuuSanPham_TheoChiNhanh   : Tra cứu sản phẩm theo chi nhánh
-- sp_TraCuuSanPham_Online         : Tra cứu sản phẩm online
-- sp_TraCuuSanPham_TheoChiNhanh_Online : Tra cứu sản phẩm online theo chi nhánh

-- 7. QUẢN LÝ HÀNG HÓA
-- sp_ThemMatHang                  : Thêm mặt hàng mới vào kho
-- sp_CapNhatTrangThaiDonHang      : Cập nhật trạng thái đơn hàng


USE HAPPYPET
GO

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
          
        -- 🔥 THÊM MaNV = @MaNV_XuatHD VÀO ĐÂY
        UPDATE HD_TRUC_TIEP  
        SET TongThanhTien = @TongTienHang,
            KhuyenMai = @TongKhuyenMai,  
            DiemQuyDoi = @DiemMuonDung,  
            TongThanhTienSC = @TongThanhToan,  
            PhuongThucTT = @PhuongThucTT,
            MaNV = @MaNV_XuatHD  -- 🔥 DÒNG NÀY
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

        -- 🔥 ĐÃ CHÈN THÊM TÍNH ĐIỂM Ở ĐÂY 🔥
        ISNULL((SELECT AVG(CAST(DiemChatLuong AS FLOAT)) 
                FROM DANH_GIA_SP 
                WHERE MaMatHang = MH.MaMatHang), 0) AS DiemTrungBinh,

        (SELECT COUNT(*) 
         FROM DANH_GIA_SP 
         WHERE MaMatHang = MH.MaMatHang) AS SoLuongDanhGia,
        -- 🔥 KẾT THÚC ĐOẠN CHÈN 🔥

        CASE 
            WHEN SUM(TK.SoLuongTon) > 0 THEN N'Còn hàng'
            ELSE N'Hết hàng'
        END AS TinhTrang
    FROM MAT_HANG MH
    LEFT JOIN TON_KHO TK 
        ON MH.MaMatHang = TK.MaMatHang

    -- ✅ Join bảng THUOC (con của MAT_HANG)
    LEFT JOIN THUOC T
        ON T.MaThuoc = MH.MaMatHang   

    WHERE 
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%')
        AND (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)

        -- ✅ 1) Vaccine không bán lẻ online
        AND MH.LoaiMH <> 'VC'

        -- ✅ 2) Thuốc chỉ bán "Không cần kê đơn"
        AND (
            MH.LoaiMH <> 'T'
            OR (MH.LoaiMH = 'T' AND ISNULL(T.LoaiThuoc, N'') = N'Không cần kê đơn')
        )

    GROUP BY MH.MaMatHang, MH.TenMatHang, MH.HangSX, MH.LoaiMH, MH.DonGia
    ORDER BY MH.TenMatHang ASC;
END;
GO

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

        -- 🔥 ĐÃ CHÈN THÊM ĐOẠN TÍNH ĐIỂM Ở ĐÂY 🔥
        ISNULL((SELECT AVG(CAST(DiemChatLuong AS FLOAT)) 
                FROM DANH_GIA_SP 
                WHERE MaMatHang = MH.MaMatHang), 0) AS DiemTrungBinh,

        (SELECT COUNT(*) 
         FROM DANH_GIA_SP 
         WHERE MaMatHang = MH.MaMatHang) AS SoLuongDanhGia,
        -- 🔥 KẾT THÚC ĐOẠN CHÈN 🔥

        ISNULL(TK.SoLuongTon, 0) AS SoLuongTon,
        CASE 
            WHEN ISNULL(TK.SoLuongTon, 0) > 0 THEN N'Còn hàng'
            ELSE N'Hết hàng'
        END AS TinhTrang
    FROM MAT_HANG MH

    -- ✅ tồn kho đúng CHI NHÁNH
    LEFT JOIN TON_KHO TK
        ON TK.MaMatHang = MH.MaMatHang
       AND TK.MaCN = @MaCN

    -- ✅ bảng THUOC (con)
    LEFT JOIN THUOC T
        ON T.MaThuoc = MH.MaMatHang   -- nếu khác thì đổi thành T.MaMatHang = MH.MaMatHang

    WHERE
        (@TuKhoa IS NULL OR MH.TenMatHang LIKE N'%' + @TuKhoa + N'%')
        AND (@LoaiMH IS NULL OR MH.LoaiMH = @LoaiMH)

        -- ✅ 1) Vaccine không bán lẻ online
        AND MH.LoaiMH <> 'VC'

        -- ✅ 2) Thuốc: chỉ OTC
        AND (
            MH.LoaiMH <> 'T'
            OR (MH.LoaiMH = 'T' AND ISNULL(T.LoaiThuoc, N'') = N'Không cần kê đơn')
        )

    ORDER BY MH.TenMatHang ASC;
END;

GO

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

