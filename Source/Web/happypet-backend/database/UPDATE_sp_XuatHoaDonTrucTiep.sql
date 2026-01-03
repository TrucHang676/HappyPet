USE HAPPYPET
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
        
        -- B4: Update trạng thái phiếu (GIỮ NGUYÊN DHT - không đổi thành HT vì constraint)
        -- Phiếu đã DHT rồi, chỉ cần cập nhật thời gian thanh toán
        UPDATE PHIEU_DICH_VU 
        SET TG_ThucHienDV = GETDATE()      -- Cập nhật thời gian thanh toán
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
            @DiemCongThem AS DiemDuocCong,
            @DiemHienCo AS DiemHienCoBanDau, -- Trả về điểm ban đầu để frontend biết
            (@DiemHienCo - @DiemMuonDung + @DiemCongThem) AS DiemConLai; -- Điểm sau khi trừ và cộng

    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO

PRINT N'✅ Đã cập nhật stored procedure sp_XuatHoaDonTrucTiep'
PRINT N'   - Loại bỏ lỗi: SET TrangThai = ''HT'' (không hợp lệ với constraint)'
PRINT N'   - Giữ nguyên TrangThai = ''DHT'' sau khi xuất hóa đơn'
PRINT N'   - Chỉ cập nhật thời gian thanh toán (TG_ThucHienDV)'
GO
