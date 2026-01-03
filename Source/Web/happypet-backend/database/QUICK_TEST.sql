USE HAPPYPET
GO

-- Test nhanh SP với TC00005
PRINT N'🔥 TEST SP sp_KiemTraGoiDangTiem với TC00005:';
EXEC sp_KiemTraGoiDangTiem 'TC00005';

-- Nếu không có kết quả, check xem tại sao:
PRINT N'';
PRINT N'📊 Kiểm tra data:';
SELECT 
    'Có gói tiêm' AS CheckPoint,
    COUNT(*) AS SoLuong
FROM DANG_KI_GOI_TIEM DK
INNER JOIN PHIEU_TIEM_VACCINE PTV ON DK.MaPhieu = PTV.MaPhieu
INNER JOIN PHIEU_DICH_VU P ON DK.MaPhieu = P.MaPhieu
WHERE PTV.MaTC = 'TC00005'
  AND DK.HieuLuc = 1
  AND P.TrangThai = 'DHT';

PRINT N'';
PRINT N'📊 Số mũi đã tiêm:';
SELECT 
    COUNT(*) AS SoMuiDaTiem
FROM CT_TIEM_VC CT
INNER JOIN DANG_KI_GOI_TIEM DK ON CT.MaPhieu = DK.MaPhieu 
    AND CT.MaVaccine = DK.MaVaccine
    AND DK.MaGoi = 'GOI002'
INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
INNER JOIN PHIEU_DICH_VU P ON CT.MaPhieu = P.MaPhieu
WHERE PTV.MaTC = 'TC00005'
  AND P.TrangThai = 'DHT';

PRINT N'';
PRINT N'📊 Gói GOI002 có mấy mũi:';
SELECT SoMuiTuongUng FROM GOI_TIEM_VC WHERE MaGoi = 'GOI002';
