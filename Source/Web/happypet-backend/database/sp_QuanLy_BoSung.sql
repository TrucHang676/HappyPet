USE HAPPYPET
GO

-- =============================================
-- FILE NÀY BỔ SUNG CÁC SP CHƯA DÙNG
-- =============================================

-- 1. Tra cứu vaccine theo tên, loại, ngày sản xuất
CREATE OR ALTER PROC sp_TraCuuVaccine
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

-- 2. Danh sách thú cưng được tiêm phòng trong kỳ
CREATE OR ALTER PROC sp_ThongKePetDuocTiem
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

-- 3. Thống kê vaccine được đặt nhiều nhất
CREATE OR ALTER PROC sp_ThongKeVaccineNhieuNhat
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

-- 4. Thống kê số lượng thú cưng theo loại, giống
CREATE OR ALTER PROC sp_ThongKePetTheoLoai
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

-- 5. Thống kê khách hàng lâu chưa quay lại
CREATE OR ALTER PROC sp_ThongKeKhachHangLauChuaQuayLai
    @MaCN NCHAR(10),
    @SoNgay INT = 180  -- Mặc định 6 tháng
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

-- 6. Quản lý nhân viên chi nhánh - Xem danh sách
CREATE OR ALTER PROC sp_LayDanhSachNhanVien
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

-- 7. Thêm nhân viên mới
CREATE OR ALTER PROC sp_ThemNhanVien
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
        RAISERROR(N'Tên đăng nhập đã tồn tại!', 16, 1);
        RETURN;
    END

    IF @NgaySinh >= GETDATE()
    BEGIN
        RAISERROR(N'Ngày sinh không hợp lệ!', 16, 1);
        RETURN;
    END

    IF @LuongCoBan <= 0
    BEGIN
        RAISERROR(N'Lương cơ bản phải lớn hơn 0!', 16, 1);
        RETURN;
    END

    -- Sinh mã nhân viên tự động
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
        -- Insert vào bảng USER
        INSERT INTO [USER] (MaUser, HoTen, NgaySinh, GioiTinh, LoaiUser)
        VALUES (@MaNV, @HoTen, @NgaySinh, @GioiTinh, 'NV');

        -- Insert vào bảng NHAN_VIEN
        INSERT INTO NHAN_VIEN (MaNV, NgayVaoLam, LuongCoBan, ChucVu, MaCN)
        VALUES (@MaNV, @NgayVaoLam, @LuongCoBan, @ChucVu, @MaCN);

        -- Insert vào bảng TAI_KHOAN
        INSERT INTO TAI_KHOAN (TenDangNhap, MatKhau, MaUser)
        VALUES (@TenDangNhap, @MatKhau, @MaNV);

        -- Tạo hồ sơ phân công
        INSERT INTO PHAN_CONG_CN (MaCN, MaNV, NgayBD, NgayKT, Ghichu)
        VALUES (@MaCN, @MaNV, @NgayVaoLam, '9999-12-31', N'Phân công ban đầu');

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

-- 8. Cập nhật thông tin nhân viên
CREATE OR ALTER PROC sp_CapNhatNhanVien
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
        RAISERROR(N'Nhân viên không tồn tại!', 16, 1);
        RETURN;
    END

    BEGIN TRANSACTION;
    BEGIN TRY
        -- Update bảng USER
        UPDATE [USER]
        SET HoTen = ISNULL(@HoTen, HoTen),
            NgaySinh = ISNULL(@NgaySinh, NgaySinh),
            GioiTinh = ISNULL(@GioiTinh, GioiTinh)
        WHERE MaUser = @MaNV;

        -- Update bảng NHAN_VIEN
        UPDATE NHAN_VIEN
        SET ChucVu = ISNULL(@ChucVu, ChucVu),
            LuongCoBan = ISNULL(@LuongCoBan, LuongCoBan)
        WHERE MaNV = @MaNV;

        COMMIT TRANSACTION;
        PRINT N'Cập nhật thành công!';
    END TRY
    BEGIN CATCH
        ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

-- 9. Doanh thu chi nhánh theo ngày/tháng/quý/năm
CREATE OR ALTER PROC sp_DoanhThuChiNhanhTheoDot
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

    -- Xác định khoảng thời gian
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

    -- Tính doanh thu
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

PRINT N'✅ Đã tạo xong 9 stored procedures bổ sung!';
