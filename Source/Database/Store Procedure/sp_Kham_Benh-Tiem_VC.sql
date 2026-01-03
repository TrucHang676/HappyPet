-- Nhân viên tiếp tân + bán hàng
GO
CREATE OR ALTER PROC sp_LayDanhSachBacSi_TrangThai
    @MaCN NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        NV.MaNV,
        U.HoTen AS TenNV, -- 🔥 Đổi tên cho đúng với frontend
        
        -- Đếm xem ổng đang ôm bao nhiêu ca 'DTH' (Đang thực hiện)
        (SELECT COUNT(*) 
         FROM PHIEU_DICH_VU P 
         WHERE P.MaNV = NV.MaNV AND P.TrangThai = 'DTH') AS SoCaDangKham,
         
        -- 🔥 Đánh dấu trạng thái: "Rảnh" hoặc "Bận"
        CASE 
            WHEN (SELECT COUNT(*) FROM PHIEU_DICH_VU P WHERE P.MaNV = NV.MaNV AND P.TrangThai = 'DTH') > 0 
            THEN N'Bận'
            ELSE N'Rảnh'
        END AS TrangThai

    FROM NHAN_VIEN NV
    JOIN [USER] U ON NV.MaNV = U.MaUser -- JOIN để lấy thông tin cá nhân
    
    WHERE NV.MaCN = @MaCN 
      AND NV.ChucVu IN (N'Bác sĩ thú y', N'Bác sĩ') -- Chỉ lấy bác sĩ
      -- AND U.TrangThai = 1 -- (Nếu bảng USER có cột TrangThai để check khóa nick thì bà mở dòng này ra)
END;
GO


-- sp - CheckinKhachHang
CREATE OR ALTER PROC sp_CheckInKhachHang
    @MaPhieu NCHAR(10),
    @MaNV_TiepTan NCHAR(10),   -- Người đang bấm nút (Tiếp tân/Quản lý)
    @MaBacSiChiDinh NCHAR(10)  -- Bác sĩ được chọn để khám ca này
AS
BEGIN
    SET NOCOUNT ON;
    SET XACT_ABORT ON;

    -- 1. Kiểm tra phiếu có tồn tại và đúng là đang chờ (DD) không
    IF NOT EXISTS (SELECT 1 FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu AND TrangThai = 'DD')
    BEGIN
        RAISERROR(N'Phiếu không hợp lệ hoặc đã check-in rồi!', 16, 1);
        RETURN;
    END

    -- 2. Kiểm tra Bác sĩ được chỉ định có thuộc chi nhánh này không (cho chắc)
    DECLARE @MaCN_Phieu NCHAR(10);
    SELECT @MaCN_Phieu = MaCN FROM PHIEU_DICH_VU WHERE MaPhieu = @MaPhieu;

    IF NOT EXISTS (SELECT 1 FROM NHAN_VIEN WHERE MaNV = @MaBacSiChiDinh AND MaCN = @MaCN_Phieu)
    BEGIN
         RAISERROR(N'Bác sĩ được chỉ định không thuộc chi nhánh này!', 16, 1);
         RETURN;
    END

    -- 3. THỰC THI
    BEGIN TRANSACTION;
    BEGIN TRY
        -- A. GÁN BÁC SĨ & ĐỔI TRẠNG THÁI
        UPDATE PHIEU_DICH_VU
        SET TrangThai = 'DTH',         -- Chuyển sang Đang thực hiện (Vàng)
            MaNV = @MaBacSiChiDinh     -- Gán cứng ca này cho Bác sĩ đó luôn
        WHERE MaPhieu = @MaPhieu;

        -- B. TẠO HÓA ĐƠN (Người tạo hóa đơn là Tiếp tân - để quản lý tiền nong)
        IF NOT EXISTS (SELECT 1 FROM HD_TRUC_TIEP WHERE MaPhieu = @MaPhieu)
        BEGIN
            INSERT INTO HD_TRUC_TIEP (
                MaPhieu, TongThanhTien, KhuyenMai, DiemQuyDoi, 
                TongThanhTienSC, PhuongThucTT, MaNV
            )
            VALUES (
                @MaPhieu, 0, 0, 0, 
                0, N'Tiền mặt', @MaNV_TiepTan -- Lưu mã Tiếp tân vào hóa đơn
            );
        END

        COMMIT TRANSACTION;
    END TRY
    BEGIN CATCH
        IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION;
        DECLARE @Err NVARCHAR(2000) = ERROR_MESSAGE();
        RAISERROR(@Err, 16, 1);
    END CATCH
END;
GO



CREATE OR ALTER PROC sp_BacSi_LayDanhSachChoKham
    @MaCN NCHAR(10),
    @MaBacSi NCHAR(10)
AS
BEGIN
    SET NOCOUNT ON;

    SELECT 
        RTRIM(P.MaPhieu) AS MaPhieu,
        P.TG_LapPhieu AS ThoiGian, -- Tên cột cho Bác sĩ
        RTRIM(P.MaNV) AS MaNV,
        U.HoTen AS ChuNuoi,        -- Tên cột cho Bác sĩ
        TC.Ten AS TenThuCung,
        TC.Loai AS LoaiThuCung,
        CASE RTRIM(P.LoaiPhieu)
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            ELSE N'Dịch vụ'
        END AS DichVu,             -- Tên cột cho Bác sĩ
        RTRIM(ISNULL(P.TrangThai, '')) AS TrangThai
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    WHERE P.MaCN = @MaCN 
      AND RTRIM(P.MaNV) = RTRIM(@MaBacSi) -- Chỉ lấy đúng ca của ổng
      AND P.TrangThai IN ('DD', 'DTH')    -- Chỉ hiện ca chờ hoặc đang khám
    ORDER BY P.TG_LapPhieu ASC
END;
GO



CREATE OR ALTER PROC sp_LayDanhSachDatLich
    @MaCN NCHAR(10),
    @TuNgay DATE,
    @DenNgay DATE,
    @TrangThai VARCHAR(5) = NULL,
    @MaNV_Xem NCHAR(10) = NULL,   
    @Role_Xem NVARCHAR(50) = NULL 
AS
BEGIN
    SET NOCOUNT ON;
    SELECT 
        RTRIM(P.MaPhieu) AS MaPhieu,
        CONVERT(VARCHAR(23), P.TG_LapPhieu, 121) AS TG_LapPhieu,
        CONVERT(VARCHAR(23), P.TG_ThucHienDV, 121) AS TG_ThucHienDV,               
        RTRIM(P.MaNV) AS MaNV,
        U.HoTen AS TenKhachHang,       
        TC.Ten AS TenThuCung,
        CASE RTRIM(P.LoaiPhieu)
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            ELSE N'Dịch vụ khác'
        END AS LoaiDichVu,
        RTRIM(ISNULL(P.TrangThai, 'DD')) AS TrangThai,
        KH.SDT,
        HTT.DiaChiGiaoHang AS DiaChi,
        HTT.TongThanhTien AS TongThanhTien,
        HTT.MaPhieu AS MaHD,  -- Để biết có HD_TRUC_TUYEN không
        U_BacSi.HoTen AS TenBacSi -- 🔥 LẤY TÊN BÁC SĨ ĐÃ GÁN
    FROM PHIEU_DICH_VU P
    JOIN KHACH_HANG KH ON P.MaKH = KH.MaKH
    JOIN [USER] U ON KH.MaKH = U.MaUser
    LEFT JOIN [USER] U_BacSi ON P.MaNV = U_BacSi.MaUser -- 🔥 JOIN ĐỂ LẤY TÊN BÁC SĨ
    LEFT JOIN PHIEU_KHAM_BENH PKB ON P.MaPhieu = PKB.MaPhieu
    LEFT JOIN PHIEU_TIEM_VACCINE PTV ON P.MaPhieu = PTV.MaPhieu
    LEFT JOIN THU_CUNG TC ON ISNULL(PKB.MaTC, PTV.MaTC) = TC.MaTC
    LEFT JOIN HD_TRUC_TUYEN HTT ON P.MaPhieu = HTT.MaPhieu
    WHERE P.MaCN = @MaCN 
      AND (@TrangThai IS NULL OR RTRIM(P.TrangThai) = @TrangThai)
      AND CAST(P.TG_ThucHienDV AS DATE) BETWEEN @TuNgay AND @DenNgay 
      AND (
          -- Cho phép các role nhân viên xem hết
          (RTRIM(@Role_Xem) IN (N'Nhân viên Tiếp tân', N'Nhân viên bán hàng', N'Quản lý chi nhánh', N'Admin'))
          OR 
          -- Bác sĩ chỉ thấy đúng ca của mình (bao gồm 'Bác sĩ thú y')
          (RTRIM(P.MaNV) = RTRIM(@MaNV_Xem))
      )
    ORDER BY P.TG_ThucHienDV ASC
END;