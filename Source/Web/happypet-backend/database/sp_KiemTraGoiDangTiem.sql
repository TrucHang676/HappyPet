-- ============================================
-- SP KIỂM TRA THÚ CƯNG CÓ GÓI VACCINE ĐANG TIÊM DỞ KHÔNG
-- Trả về: MaGoi, SoMuiDaTiem, TongSoMui nếu có gói đang tiêm
-- ============================================
USE HAPPYPET
GO

CREATE OR ALTER PROC sp_KiemTraGoiDangTiem
    @MaTC NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Tìm gói vaccine đang tiêm (có trong DANG_KI_GOI_TIEM, chưa tiêm đủ)
    SELECT TOP 1
        DK.MaGoi,
        DK.MaVaccine,
        MH.TenMatHang AS TenVaccine,
        GOI.TenGoi,
        GOI.SoMuiTuongUng AS TongSoMui,
        DK.NgayHetHan,
        -- Đếm số mũi đã tiêm của gói này (TẤT CẢ các mũi: NhacLai=0 và NhacLai=1)
        -- Lưu ý: Chỉ mũi đầu có record trong DANG_KI_GOI_TIEM, các mũi sau không có
        -- Nên đếm trực tiếp từ CT_TIEM_VC với MaVaccine, sau thời điểm đăng ký gói
        ISNULL((
            SELECT COUNT(*) 
            FROM CT_TIEM_VC CT
            INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
            INNER JOIN PHIEU_DICH_VU PDV2 ON CT.MaPhieu = PDV2.MaPhieu
            WHERE PTV.MaTC = @MaTC
              AND CT.MaVaccine = DK.MaVaccine
              AND PDV2.TrangThai = 'DHT'
              AND PDV2.TG_ThucHienDV >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
        ), 0) AS SoMuiDaTiem,
        -- Số mũi còn lại
        GOI.SoMuiTuongUng - ISNULL((
            SELECT COUNT(*) 
            FROM CT_TIEM_VC CT
            INNER JOIN PHIEU_TIEM_VACCINE PTV ON CT.MaPhieu = PTV.MaPhieu
            INNER JOIN PHIEU_DICH_VU PDV2 ON CT.MaPhieu = PDV2.MaPhieu
            WHERE PTV.MaTC = @MaTC
              AND CT.MaVaccine = DK.MaVaccine
              AND PDV2.TrangThai = 'DHT'
              AND PDV2.TG_ThucHienDV >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
        ), 0) AS SoMuiConLai
    FROM DANG_KI_GOI_TIEM DK
    INNER JOIN GOI_TIEM_VC GOI ON DK.MaGoi = GOI.MaGoi
    INNER JOIN PHIEU_TIEM_VACCINE PTV ON DK.MaPhieu = PTV.MaPhieu
    INNER JOIN MAT_HANG MH ON DK.MaVaccine = MH.MaMatHang
    INNER JOIN PHIEU_DICH_VU PDV ON DK.MaPhieu = PDV.MaPhieu
    WHERE PTV.MaTC = @MaTC
      AND DK.HieuLuc = 1
      AND PDV.TrangThai = 'DHT' -- CHỈ TÍNH PHIẾU ĐÃ HOÀN TẤT (đã tiêm thật)
      AND (DK.NgayHetHan IS NULL OR DK.NgayHetHan > GETDATE())
      -- CHỈ LẤY GÓI CHƯA TIÊM ĐỦ SỐ MŨI QUY ĐỊNH
      AND GOI.SoMuiTuongUng > ISNULL((
          SELECT COUNT(*) 
          FROM CT_TIEM_VC CT
          INNER JOIN PHIEU_TIEM_VACCINE PTV2 ON CT.MaPhieu = PTV2.MaPhieu
          INNER JOIN PHIEU_DICH_VU PDV3 ON CT.MaPhieu = PDV3.MaPhieu
          WHERE PTV2.MaTC = @MaTC
            AND CT.MaVaccine = DK.MaVaccine
            AND PDV3.TrangThai = 'DHT'
            AND PDV3.TG_ThucHienDV >= (SELECT P.TG_LapPhieu FROM PHIEU_DICH_VU P WHERE P.MaPhieu = DK.MaPhieu)
      ), 0)
    ORDER BY DK.MaPhieu DESC;
    
END;
GO

PRINT N'✅ Đã tạo SP sp_KiemTraGoiDangTiem'
GO
