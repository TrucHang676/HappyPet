/*
===============================================
Phân hệ: KHÁCH HÀNG
===============================================

MỤC ĐÍCH:
- Quản lý thông tin khách hàng (đăng ký, đăng nhập, cập nhật thông tin)
- Quản lý pet (thêm, cập nhật, xem, xóa)
- Đặt lịch hẹn cho dịch vụ
- Mua sắm online (khởi tạo đơn, hoàn tất, hủy)
- Đánh giá dịch vụ & sản phẩm
- Xem lịch sử hoạt động

CHỨC NĂNG CHI TIẾT:
1. Tài khoản: Đăng ký, Đăng nhập, Đổi mật khẩu
2. Thông tin cá nhân: Cập nhật, Xem chi tiết
3. Quản lý Pet: Thêm, Cập nhật, Xem danh sách, Xóa
4. Đặt lịch: Đặt lịch hẹn, Hủy lịch, Xem danh sách lịch
5. Mua hàng Online: Khởi tạo đơn, Hoàn tất, Hủy đơn
6. Chọn vaccine: Chọn gói tiêm, Chọn vaccine lẻ, Xem vaccine
7. Đánh giá: Đánh giá dịch vụ, Đánh giá sản phẩm
8. Tích lũy điểm: Xem điểm, Sử dụng điểm
9. Lịch sử: Xem lịch sử kham, tiêm, mua sắm

TỔNG SỐ SP: 28

===============================================
DANH SÁCH STORED PROCEDURES:
===============================================
*/

-- 1. TÀI KHOẢN & XÁC THỰC
-- sp_DangKyTaiKhoanKH          : Đăng ký tài khoản khách hàng mới
-- sp_DangNhap                   : Đăng nhập hệ thống
-- sp_DoiMatKhau                 : Đổi mật khẩu

-- 2. THÔNG TIN KHÁCH HÀNG
-- sp_XemThongTinCaNhan           : Xem thông tin cá nhân
-- sp_CapNhatThongTinKH           : Cập nhật thông tin khách hàng

-- 3. QUẢN LÝ PET
-- sp_ThemThuCung                 : Thêm pet mới
-- sp_CapNhatThuCung              : Cập nhật thông tin pet
-- sp_XemDanhSachThuCung          : Xem danh sách pet của khách hàng
-- sp_XoaThuCung                  : Xóa pet

-- 4. ĐẶT LỊCH HẸN
-- sp_DatLichHen                  : Đặt lịch hẹn dịch vụ
-- sp_HuyLichHen                  : Hủy lịch hẹn
-- sp_LayDanhSachDatLich          : Xem danh sách lịch đã đặt
-- sp_XemLichBacSi                : Xem lịch bác sĩ

-- 5. MUA HÀNG ONLINE
-- sp_KhoiTaoDonHangOnline        : Khởi tạo đơn hàng online
-- sp_HoanTatDonHangOnline        : Hoàn tất (thanh toán) đơn hàng
-- sp_HuyDonOnline                : Hủy đơn hàng online

-- 6. CHỌN VACCINE
-- sp_App_ChonGoiTiem             : Chọn gói tiêm
-- sp_App_ChonVaccineLe           : Chọn vaccine lẻ
-- sp_App_GetMasterVaccineData    : Lấy dữ liệu vaccine master
-- sp_App_GetSelectedVaccines     : Lấy vaccine đã chọn
-- sp_App_XoaGoiTiem              : Xóa gói tiêm
-- sp_App_XoaVaccineLe            : Xóa vaccine lẻ
-- sp_KiemTraGoiDangTiem          : Kiểm tra gói tiêm hiện tại

-- 7. ĐÁNH GIÁ
-- sp_DanhGiaDichVu               : Đánh giá dịch vụ
-- sp_DanhGiaSanPham              : Đánh giá sản phẩm

-- 8. TÍCH LŨY ĐIỂM
-- sp_TruDiemDaSuDung             : Sử dụng (trừ) điểm tích lũy

-- 9. TRA CỨU & LỊCH SỬ
-- sp_TraCuuSanPham               : Tra cứu sản phẩm
-- sp_TraCuuSanPham_Online        : Tra cứu sản phẩm online
-- sp_TimKiemKhachHangTheoSDT     : Tìm kiếm khách hàng theo số điện thoại
-- sp_CheckInKhachHang            : Check-in khách hàng tại chi nhánh
-- sp_XemLichSuKham               : Xem lịch sử khám bệnh
-- sp_XemLichSuMuaSam             : Xem lịch sử mua sắm

USE HAPPYPET
GO

-- ======== 1.1. sp_DangKyTaiKhoanKH ========
-- Chức năng: Đăng ký tài khoản khách hàng mới
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

-- ======== 1.2. sp_DangNhap ========
-- Chức năng: Đăng nhập hệ thống
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

-- ======== 1.3. sp_DoiMatKhau ========
-- Chức năng: Đổi mật khẩu
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

-- ======== 2.1. sp_XemThongTinCaNhan ========
-- Chức năng: Xem thông tin cá nhân
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

        -- 🔥 FIX: Lấy hạng từ năm GẦN NHẤT (không nhất thiết phải năm ngoái)
        -- Vì có thể chưa chốt năm ngoái, hoặc data test có năm khác
        ISNULL(HTV.TenHang, N'Thành viên mới') AS HangThanhVien,
        ISNULL(HTV.MaHang, 'C01') AS MaHang,
        ISNULL(HTV.KhuyenMaiUuTien, 0) AS GiamGiaThanhVien,  -- 🔥 THÊM % giảm giá
        
        -- Hiển thị mức chi tiêu đã chốt
        ISNULL(XHN.TongChiTieu, 0) AS TongChiTieuNamNgoai

    FROM KHACH_HANG KH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    JOIN TAI_KHOAN TK ON KH.MaKH = TK.MaUser
    
    -- 🔥 LEFT JOIN với subquery lấy XẾP HẠNG NĂM GẦN NHẤT
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

-- ======== 2.2. sp_CapNhatThongTinKH ========
-- Chức năng: Cập nhật thông tin khách hàng
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

-- ======== 3.1. sp_ThemThuCung ========
-- Chức năng: Thêm pet mới
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

        -- 🔥 FIX: Xử lý đúng với cả TC046784 và TC000001
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

-- ======== 3.2. sp_CapNhatThuCung ========
-- Chức năng: Cập nhật thông tin pet
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

-- ======== 3.3. sp_XemDanhSachThuCung ========
-- Chức năng: Xem danh sách pet của khách hàng
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

-- ======== 3.4. sp_XoaThuCung ========
-- Chức năng: Xóa pet
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

-- ======== 4.1. sp_DatLichHen ========
-- Chức năng: Đặt lịch hẹn dịch vụ
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
    -- 4. 🔥 SỬA LOGIC KIỂM TRA QUÁ TẢI (FIX CHÍNH)
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

-- ======== 4.2. sp_HuyLichHen ========
-- Chức năng: Hủy lịch hẹn
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

-- ======== 4.3. sp_LayDanhSachDatLich ========
-- Chức năng: Xem danh sách lịch đã đặt
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
        ISNULL(HTT.TongThanhTien, HDTT.TongThanhTienSC) AS TongThanhTien, -- 🔥 LẤY TỪ HD_TRUC_TUYEN HOẶC HD_TRUC_TIEP
        HTT.MaPhieu AS MaHD,  -- Để biết có HD_TRUC_TUYEN không
        HDTT.PhuongThucTT AS PhuongThucTT, -- 🔥 LẤY PHƯƠNG THỨC THANH TOÁN ĐỂ BIẾT ĐÃ XUẤT HÓA ĐƠN CHƯA
        RTRIM(HDTT.MaNV) AS MaNV_XuatHD, -- 🔥 MÃ NHÂN VIÊN XUẤT HÓA ĐƠN (từ HD_TRUC_TIEP)
        RTRIM(P.MaNV) AS MaNV_BacSi, -- 🔥 MÃ BÁC SĨ (từ PHIEU_DICH_VU) - đổi tên để phân biệt
        U_BacSi.HoTen AS TenBacSi -- 🔥 LẤY TÊN BÁC SĨ ĐÃ GÁN
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN [USER] U_BacSi ON P.MaNV = U_BacSi.MaUser -- 🔥 JOIN ĐỂ LẤY TÊN BÁC SĨ
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    LEFT JOIN HD_TRUC_TIEP HDTT ON P.MaPhieu = HDTT.MaPhieu -- 🔥 JOIN ĐỂ LẤY PHƯƠNG THỨC TT
    WHERE P.MaCN = @MaCN 
      AND (@TrangThai IS NULL OR RTRIM(P.TrangThai) = @TrangThai)
      AND (
          -- 🔥 LOGIC MỚI: Hiện đơn nếu thỏa 1 trong 2:
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

-- ======== 4.4. sp_XemLichBacSi ========
-- Chức năng: Xem lịch bác sĩ
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

-- ======== 5.1. sp_KhoiTaoDonHangOnline ========
-- Chức năng: Khởi tạo đơn hàng online
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

-- ======== 5.2. sp_HoanTatDonHangOnline ========
-- Chức năng: Hoàn tất (thanh toán) đơn hàng
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

-- ======== 5.3. sp_HuyDonOnline ========
-- Chức năng: Hủy đơn hàng online
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

-- ======== 6.1. sp_App_ChonGoiTiem ========
-- Chức năng: Chọn gói tiêm
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

-- ======== 6.2. sp_App_ChonVaccineLe ========
-- Chức năng: Chọn vaccine lẻ
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

-- ======== 6.3. sp_App_GetMasterVaccineData ========
-- Chức năng: Lấy dữ liệu vaccine master
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

-- ======== 6.4. sp_App_GetSelectedVaccines ========
-- Chức năng: Lấy vaccine đã chọn
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

-- ======== 6.5. sp_App_XoaGoiTiem ========
-- Chức năng: Xóa gói tiêm
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

-- ======== 6.6. sp_App_XoaVaccineLe ========
-- Chức năng: Xóa vaccine lẻ
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

-- ======== 6.7. sp_KiemTraGoiDangTiem ========
-- Chức năng: Kiểm tra gói tiêm hiện tại
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
        -- 🔥 Đếm số mũi đã tiêm của gói này (CHỈ PHIẾU ĐÃ HOÀN TẤT)
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
      -- 🔥 BỎ điều kiện PDV.TrangThai = 'DHT' để tìm gói dù phiếu đăng ký đã hoàn tất hay chưa
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
    -- 🔥 LẤY GÓI CŨ NHẤT (đăng ký đầu tiên) để đếm đủ số mũi từ đầu
    ORDER BY DK.MaPhieu ASC;
    
END;
GO

-- ======== 7.1. sp_DanhGiaDichVu ========
-- Chức năng: Đánh giá dịch vụ
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

-- ======== 7.2. sp_DanhGiaSanPham ========
-- Chức năng: Đánh giá sản phẩm
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

-- ======== 8.1. sp_TruDiemDaSuDung ========
-- Chức năng: Sử dụng (trừ) điểm tích lũy
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

-- ======== 9.1. sp_TraCuuSanPham ========
-- Chức năng: Tra cứu sản phẩm
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

-- ======== 9.2. sp_TraCuuSanPham_Online ========
-- Chức năng: Tra cứu sản phẩm online
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

-- ======== 9.3. sp_TimKiemKhachHangTheoSDT ========
-- Chức năng: Tìm kiếm khách hàng theo số điện thoại
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

-- ======== 9.4. sp_CheckInKhachHang ========
-- Chức năng: Check-in khách hàng tại chi nhánh
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
-- ======== 9.5. sp_XemLichSuKham ========
-- Chức năng: Xem lịch sử khám bệnh
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

-- ======== 9.6. sp_XemLichSuMuaSam ========
-- Chức năng: Xem lịch sử mua sắm
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

