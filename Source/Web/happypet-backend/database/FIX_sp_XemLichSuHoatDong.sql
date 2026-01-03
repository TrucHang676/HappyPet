USE HAPPYPET
GO

-- Sửa SP xem lịch sử để đảm bảo trả đầy đủ thông tin cho cả phiếu đã hủy
CREATE OR ALTER PROC sp_XemLichSuHoatDong
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
        
        -- ✅ Lấy tên thú cưng (luôn hiện dù đã hủy)
        COALESCE(TC.Ten, N'Không rõ') AS TenThuCung,
        COALESCE(TC.Ten, N'Không rõ') AS TenPet,
        
        -- ✅ Lấy triệu chứng từ phiếu khám bệnh (luôn hiện dù đã hủy)
        COALESCE(PKB.TrieuChung, N'') AS TrieuChung,
        
        -- Các thông tin khác
        PKB.ChanDoan,
        PKB.NgayHenTaiKham, -- ✅ Thêm ngày hẹn tái khám
        
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
    
    -- ✅ LEFT JOIN để luôn lấy được thông tin dù phiếu đã hủy
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON RTRIM(COALESCE(PKB.MaTC, PTV.MaTC)) = RTRIM(TC.MaTC)
    
    LEFT JOIN HD_TRUC_TIEP HD ON P.MaPhieu = HD.MaPhieu
    LEFT JOIN DANH_GIA_DV DG_DV ON P.MaPhieu = DG_DV.MaPhieu
    
    WHERE P.MaKH = @MaKH
    ORDER BY P.TG_ThucHienDV DESC;
END;
GO

PRINT N'✅ Đã sửa SP sp_XemLichSuHoatDong - Giờ sẽ hiển thị đầy đủ thông tin cho cả phiếu đã hủy';
