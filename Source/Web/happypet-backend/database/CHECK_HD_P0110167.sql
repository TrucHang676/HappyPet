-- CHECK HD_TRUC_TIEP của phiếu P0110167
USE HAPPYPET;
GO

SELECT 
    MaPhieu,
    TongThanhTien,
    KhuyenMai,
    DiemQuyDoi,
    TongThanhTienSC,
    PhuongThucTT,
    MaNV,
    CASE 
        WHEN PhuongThucTT IS NULL THEN N'❌ NULL (Chưa xuất)'
        WHEN RTRIM(PhuongThucTT) = '' THEN N'❌ EMPTY (Chưa xuất)'
        ELSE N'✅ CÓ GIÁ TRỊ (Đã xuất): ' + PhuongThucTT
    END AS TrangThaiXuat
FROM HD_TRUC_TIEP
WHERE MaPhieu = 'P0110167';

-- Kiểm tra structure của bảng
PRINT N'';
PRINT N'📋 Kiểm tra default value của PhuongThucTT:';
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    IS_NULLABLE,
    COLUMN_DEFAULT
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'HD_TRUC_TIEP' 
  AND COLUMN_NAME = 'PhuongThucTT';
