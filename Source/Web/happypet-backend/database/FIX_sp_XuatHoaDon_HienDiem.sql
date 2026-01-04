-- =============================================
-- FIX: Thêm thông tin điểm tích lũy vào kết quả xuất hóa đơn
-- =============================================
USE HAPPYPET
GO

CREATE OR ALTER PROCEDURE sp_XuatHoaDonTrucTiep
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

    SELECT @PhanTramGiam = HTV.KhuyenMaiUuTien
    FROM XEP_HANG_NAM XHN
    JOIN HANG_TV HTV ON XHN.MaHang = HTV.MaHang
    WHERE XHN.MaKH = @MaKH AND XHN.Nam = YEAR(GETDATE()) - 1;

    SET @TienGiamHangTV = @TongTienHang * (ISNULL(@PhanTramGiam, 0) / 100.0);

    DECLARE @TienGiamDiem DECIMAL(18,2);
    SET @TienGiamDiem = @DiemMuonDung * 1000.0;

    DECLARE @TongKhuyenMai DECIMAL(18,2) = @TienGiamHangTV + @TienGiamDiem;
    DECLARE @TongThanhToan DECIMAL(18,2) = @TongTienHang - @TongKhuyenMai;

    IF @TongThanhToan < 0 SET @TongThanhToan = 0;

    BEGIN TRANSACTION;
    BEGIN TRY
        
        UPDATE HD_TRUC_TIEP
        SET TongThanhTien = @TongTienHang,
            KhuyenMai = @TongKhuyenMai,
            DiemQuyDoi = @DiemMuonDung,
            TongThanhTienSC = @TongThanhToan,
            PhuongThucTT = @PhuongThucTT,
            MaNV = @MaNV_XuatHD
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
        
        -- ❌ KHÔNG CẦN UPDATE TrangThai vì phiếu đã ở trạng thái 'DHT' (Đã Hoàn Tất) rồi
        -- Chỉ cần cập nhật thời gian thực hiện (nếu cần)
        -- UPDATE PHIEU_DICH_VU 
        -- SET TrangThai = 'HT',  -- ❌ LỖI: Constraint không cho phép giá trị 'HT'
        --     TG_ThucHienDV = GETDATE()
        -- WHERE MaPhieu = @MaPhieu;

        COMMIT TRANSACTION;

        -- ✅ TRẢ VỀ KẾT QUẢ ĐẦY ĐỦ (BAO GỒM ĐIỂM TÍCH LŨY)
        SELECT 
            @MaPhieu AS MaHoaDon,
            FORMAT(@TienDichVuCoBan, 'N0', 'vi-VN') AS TienDichVuCoBan,
            FORMAT(@TongTienHang, 'N0', 'vi-VN') AS TongTienHang,
            FORMAT(@TienGiamHangTV, 'N0', 'vi-VN') AS GiamHangTV,
            FORMAT(@TienGiamDiem, 'N0', 'vi-VN') AS GiamDiem,
            FORMAT(@TongThanhToan, 'N0', 'vi-VN') AS KhachCanTra,
            @DiemCongThem AS DiemDuocCong,
            @DiemHienCo AS DiemHienCoBanDau, -- 🔥 ĐIỂM TRƯỚC KHI GIAO DỊCH
            (@DiemHienCo - @DiemMuonDung + @DiemCongThem) AS DiemConLai; -- 🔥 ĐIỂM SAU KHI GIAO DỊCH

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã cập nhật SP sp_XuatHoaDonTrucTiep - Thêm thông tin điểm tích lũy vào kết quả';
