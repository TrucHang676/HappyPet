USE HAPPYPET;
GO

-- Kiểm tra parameters của SP sp_XuatHoaDonTrucTiep
PRINT N'📋 Checking parameters của sp_XuatHoaDonTrucTiep:';
SELECT 
    PARAMETER_NAME,
    DATA_TYPE,
    PARAMETER_MODE
FROM INFORMATION_SCHEMA.PARAMETERS
WHERE SPECIFIC_NAME = 'sp_XuatHoaDonTrucTiep'
ORDER BY ORDINAL_POSITION;

PRINT N'';
PRINT N'✅ Phải có 4 parameters:';
PRINT N'   1. @MaPhieu';
PRINT N'   2. @DiemMuonDung';
PRINT N'   3. @PhuongThucTT';
PRINT N'   4. @MaNV_XuatHD (🔥 QUAN TRỌNG)';
PRINT N'';
PRINT N'Nếu thiếu @MaNV_XuatHD → Chạy lại file sp_Phieu_Dich_Vu.sql';
