-- Phân hệ Khách hàng (Đặt hàng trực tuyến)
-- 1 sp_KhoiTaoDonHangOnline : Khởi tạo đơn hàng mới, tự động tính phí giao hàng dựa trên ngày nhận và kiểm tra vùng giao nội thành.
-- 2 sp_ThemSanPhamVaoDon : Thêm mặt hàng vào giỏ hàng, tự động trừ số lượng tồn kho và cập nhật lại tổng tiền đơn hàng.
-- 3 sp_XoaSanPhamKhoiDon : Xóa mặt hàng khỏi giỏ, hoàn lại số lượng vào kho chi nhánh và tính toán lại tổng tiền.
-- 4 sp_HoanTatDonHangOnline : Khách hàng xác nhận đặt đơn, áp dụng giảm giá theo hạng thành viên năm ngoái và trừ điểm tích lũy đã dùng.
-- 5 sp_HuyDonOnline : Cho phép khách hủy đơn trong vòng 120 phút kể từ khi đặt. Tự động hoàn kho và trả lại điểm tích lũy cho khách.

-- Phân hệ Nhân viên (Xử lý đơn hàng)
-- 6 sp_CapNhatTrangThaiDonHang : Nhân viên cập nhật đơn sang "Đang giao" hoặc "Hoàn tất". Khi hoàn tất, hệ thống tự động cộng điểm tích lũy mới (50k = 1 điểm) cho khách.


USE HAPPYPET
GO

-- 1. Khách mua hàng online
CREATE OR ALTER PROC sp_KhoiTaoDonHangOnline
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


-- 2. Thêm sản phẩm vào đơn hàng (Cho NV và KH)
CREATE OR ALTER PROC sp_ThemSanPhamVaoDon
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

-- 3. Xóa sản phẩm (Cho NV và KH)
CREATE OR ALTER PROC sp_XoaSanPhamKhoiDon
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

-- 4. Khách hàng hoàn tất đơn hàng online
CREATE OR ALTER PROC sp_HoanTatDonHangOnline
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

-- 5. Hủy đơn hàng online (Được hủy trong vòng 2 tiếng sau khi đặt)
CREATE OR ALTER PROC sp_HuyDonOnline
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

-- 6. Nhân viên cập nhật trạng thái của PDV cho KH biết đơn hàng đã vận chuyển (DTH, DHT)
CREATE OR ALTER PROC sp_CapNhatTrangThaiDonHang
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
