/*
===============================================
FILE: 4_QUAN_LY_CHI_NHANH_GIAM_DOC.sql
Phân hệ: QUẢN LÝ CHI NHÁNH VÀ GIÁM ĐỐC
===============================================

MỤC ĐÍCH:
- Quản lý nhân sự (thêm, cập nhật, điều động)
- Quản lý kho hàng (nhập hàng)
- Thống kê doanh thu & hiệu suất
- Quản lý xếp hạng khách hàng
- Báo cáo theo dõi
- Cảnh báo hết hàng

CHỨC NĂNG CHI TIẾT:
1. Nhân sự: Thêm, Cập nhật, Điều động
2. Kho: Nhập hàng, Quản lý tồn kho
3. Doanh thu: Thống kê, Báo cáo theo dot, theo sản phẩm
4. Xếp hạng: Xếp hạng hội viên, Cập nhật xếp hạng
5. Thống kê: Nhân viên giỏi, Khách hàng lâu chưa quay lại, Pet được tiêm
6. Lịch sử: Hoạt động, Đặt lịch
7. Danh sách: Chi nhánh, Lịch bác sĩ

TỔNG SỐ SP: 24

===============================================
DANH SÁCH STORED PROCEDURES:
===============================================
*/


-- 1. QUẢN LÝ KHO
-- sp_NhapHangVaoKho               : Nhập hàng vào kho

-- 2. DOANH THU & THỐNG KÊ
-- sp_ThongKeDoanhThuChiNhanh      : Thống kê doanh thu chi nhánh
-- sp_ThongKeDoanhThuSanPham       : Thống kê doanh thu theo sản phẩm
-- sp_DoanhThuChiNhanhTheoDot      : Doanh thu chi nhánh theo đợt
-- sp_TopDichVuDoanhThu            : Top dịch vụ có doanh thu cao

-- 3. NHÂN VIÊN
-- sp_ThongKeNhanVienGioi          : Thống kê nhân viên giỏi
-- sp_LayDanhSachNhanVien          : Danh sách nhân viên

-- 4. KHÁCH HÀNG & HỘI VIÊN
-- sp_ThongKeHoiVien               : Thống kê hội viên
-- sp_ThongKeKhachHangLauChuaQuayLai : Khách hàng lâu chưa quay lại
-- sp_CapNhatXepHangHoiVien        : Cập nhật xếp hạng hội viên

-- 5. PET & VACCINE
-- sp_ThongKePetDuocTiem           : Thống kê pet được tiêm
-- sp_ThongKePetTheoLoai           : Thống kê pet theo loại

-- 6. SẢN PHẨM
-- sp_ThongKeSanPhamTot            : Thống kê sản phẩm tốt

-- 7. LỊCH & DANH SÁCH
-- sp_XemDanhSachChiNhanh          : Danh sách chi nhánh
-- sp_LayDanhSachDatLich           : Danh sách lịch đặt
-- sp_LayDanhSachDatLich_HomNay    : Lịch đặt hôm nay
             

-- 8. LỊCH SỬ & HOẠT ĐỘNG
-- sp_XemLichSuHoatDong            : Lịch sử hoạt động

-- 9. CẢNH BÁO
-- sp_CanhBaoHetHang               : Cảnh báo khi hết hàng


--10. NHAN SỰ (Giám đốc)
-- sp_ThemNhanVien                 : Thêm nhân viên mới
-- sp_CapNhatNhanVien              : Cập nhật thông tin nhân viên
-- sp_DieuDongNhanSu               : Điều động nhân viên

USE HAPPYPET
GO

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
        
        --    Lấy triệu chứng từ phiếu khám bệnh (luôn hiện dù đã hủy)
        COALESCE(PKB.TrieuChung, N'') AS TrieuChung,
        
        -- Các thông tin khác
        PKB.ChanDoan,
        PKB.NgayHenTaiKham, --    Thêm ngày hẹn tái khám
        
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
    
    --    LEFT JOIN để luôn lấy được thông tin dù phiếu đã hủy
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON RTRIM(COALESCE(PKB.MaTC, PTV.MaTC)) = RTRIM(TC.MaTC)
    
    LEFT JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    LEFT JOIN DANH_GIA_DV DG_DV ON P.MaPhieu = DG_DV.MaPhieu
    
    WHERE P.MaKH = @MaKH
    ORDER BY P.TG_ThucHienDV DESC;
END;
GO

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
