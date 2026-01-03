USE HAPPYPET
GO

--Gồm 14 sp nha    

-- 1. Bác sĩ xem lịch sử khám của thú cưng
CREATE OR ALTER PROC sp_XemLichSuKham
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

-- 2. Bác sĩ tra cứu thuốc
CREATE OR ALTER PROC sp_TraCuuThuoc
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

-- 3. Bác sĩ xem lịch sử tiêm của thú cưng
CREATE OR ALTER PROC sp_XemLichSuTiem
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

-- 4. Điều động nhân sự
CREATE OR ALTER PROC sp_DieuDongNhanSu
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

-- 5. Thống kê doanh thu bán sản phẩm
CREATE OR ALTER PROC sp_ThongKeDoanhThuSanPham
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

-- 6. Thống kê doanh thu tất cả chi nhánh
CREATE OR ALTER PROC sp_ThongKeDoanhThuChiNhanh
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

-- 7. Thống kê các nhân viên có điểm đánh giá >= x
CREATE OR ALTER PROC sp_ThongKeNhanVienGioi
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

-- 8. Thống kê các sản phẩm có điểm đánh giá >=x
CREATE OR ALTER PROC sp_ThongKeSanPhamTot
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

-- 9. Thống kê sản phẩm sắp hết hàng
CREATE OR ALTER PROC sp_CanhBaoHetHang
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

-- 10. Dịch vụ mang lại doanh thu cao nhất trong 6 tháng vừa qua
CREATE OR ALTER PROC sp_TopDichVuDoanhThu
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

-- 11. Thống kê tình hình hội viên
CREATE OR ALTER PROC sp_ThongKeHoiVien
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

-- 12. Update xếp hạng hội viên cho khách hàng

CREATE OR ALTER PROC sp_CapNhatXepHangHoiVien
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

-- 13. Nhập hàng vào kho
CREATE OR ALTER PROC sp_NhapHangVaoKho
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

-- 14. Thêm 1 mặt hàng mới
CREATE OR ALTER PROC sp_ThemMatHang
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


