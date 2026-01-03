USE HAPPYPET;
GO

PRINT N'🔍 KIỂM TRA PHIẾU P0110167:';
PRINT N'';

-- 1. Check trạng thái phiếu
PRINT N'1️⃣ Trạng thái phiếu:';
SELECT 
    MaPhieu,
    TrangThai,
    CASE TrangThai
        WHEN 'DD' THEN N'❌ Đã đặt (chưa check-in)'
        WHEN 'DTH' THEN N'⏳ Đang thực hiện (chưa hoàn tất)'
        WHEN 'DHT' THEN N'✅ Đã hoàn tất (có thể xuất HD)'
        WHEN 'HUY' THEN N'❌ Đã hủy'
        ELSE N'❓ Không rõ'
    END AS MoTa
FROM PHIEU_DICH_VU
WHERE MaPhieu = 'P0110167';

-- 2. Check HD_TRUC_TIEP có tồn tại không
PRINT N'';
PRINT N'2️⃣ Kiểm tra HD_TRUC_TIEP:';
IF EXISTS (SELECT 1 FROM HD_TRUC_TIEP WHERE MaPhieu = 'P0110167')
BEGIN
    SELECT 
        MaPhieu,
        MaNV,
        TongThanhTien,
        PhuongThucTT,
        CASE 
            WHEN MaNV IS NULL THEN N'✅ Chưa xuất (MaNV = NULL)'
            ELSE N'❌ Đã xuất (MaNV có giá trị)'
        END AS TrangThai
    FROM HD_TRUC_TIEP 
    WHERE MaPhieu = 'P0110167';
END
ELSE
BEGIN
    PRINT N'❌ KHÔNG TỒN TẠI! Phiếu chưa được hoàn tất bởi bác sĩ.';
    PRINT N'';
    PRINT N'🔧 GIẢI PHÁP:';
    PRINT N'   1. Bác sĩ vào trang của mình, nhấn "Hoàn tất" phiếu này';
    PRINT N'   2. HOẶC chạy lệnh sau để test:';
    PRINT N'      EXEC sp_HoanTatDichVu @MaPhieu = ''P0110167'';';
END

PRINT N'';
