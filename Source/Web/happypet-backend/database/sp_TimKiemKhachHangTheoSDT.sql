USE HAPPYPET
GO

CREATE OR ALTER PROCEDURE sp_TimKiemKhachHangTheoSDT
    @SDT VARCHAR(15)
AS
BEGIN
    SET NOCOUNT ON;
    
    DECLARE @MaKH NCHAR(10);
    
    -- Tìm mã khách hàng theo SĐT từ bảng KHACH_HANG
    SELECT @MaKH = MaKH 
    FROM KHACH_HANG 
    WHERE SDT = @SDT;
    
    -- Nếu không tìm thấy khách hàng
    IF @MaKH IS NULL
    BEGIN
        -- Trả về recordset rỗng với cấu trúc cột chính xác
        SELECT CAST(NULL AS NCHAR(10)) AS MaKH, CAST(NULL AS NVARCHAR(50)) AS HoTen, CAST(NULL AS VARCHAR(10)) AS SDT, CAST(NULL AS VARCHAR(50)) AS Email;
        SELECT CAST(NULL AS NCHAR(10)) AS MaTC, CAST(NULL AS NVARCHAR(50)) AS Ten, CAST(NULL AS NVARCHAR(30)) AS Loai, CAST(NULL AS NVARCHAR(3)) AS GioiTinh, CAST(NULL AS DATE) AS NgSinh;
        SELECT CAST(NULL AS NCHAR(10)) AS MaPhieu, CAST(NULL AS DATETIME) AS NgayKham, CAST(NULL AS NVARCHAR(20)) AS LoaiDV, CAST(NULL AS NVARCHAR(50)) AS BacSi, CAST(NULL AS NVARCHAR(200)) AS ChanDoan;
        RETURN;
    END
    
    -- 1. Thông tin khách hàng (Lấy HoTen từ bảng [USER])
    SELECT 
        kh.MaKH, 
        u.HoTen, 
        kh.SDT, 
        kh.Email,
        kh.TongDiemTichLuy,
        u.GioiTinhUser,
        kh.DiaChi
    FROM KHACH_HANG kh
    JOIN [USER] u ON kh.MaKH = u.MaUser
    WHERE kh.MaKH = @MaKH;
    
    -- 2. Danh sách thú cưng của khách
    -- Sửa tên cột: NgSinh (thay vì NgaySinh), bỏ cột CanNang (không có trong schema)
    SELECT 
        MaTC, 
        Ten, 
        Loai, 
        Giong,
        GioiTinh, 
        NgSinh, 
        TinhTrangSucKhoe
    FROM THU_CUNG
    WHERE MaKH = @MaKH;
    
    -- 3. Lịch sử khám/tiêm/mua hàng (10 lần gần nhất)
    -- Kết nối qua PHIEU_DICH_VU, PHIEU_KHAM_BENH và NHAN_VIEN (thông qua bảng USER để lấy tên)
    SELECT TOP 10
        p.MaPhieu,
        p.TG_LapPhieu AS NgayKham,
        CASE p.LoaiPhieu
            WHEN 'KB' THEN N'Khám bệnh'
            WHEN 'TV' THEN N'Tiêm vaccine'
            WHEN 'MH' THEN N'Mua hàng'
            ELSE p.LoaiPhieu
        END AS LoaiDV,
        u_nv.HoTen AS BacSi,
        ISNULL(pkb.ChanDoan, N'N/A') AS ChanDoan,
        p.TrangThai
    FROM PHIEU_DICH_VU p
    LEFT JOIN PHIEU_KHAM_BENH pkb ON p.MaPhieu = pkb.MaPhieu
    LEFT JOIN [USER] u_nv ON p.MaNV = u_nv.MaUser -- Lấy tên nhân viên lập phiếu từ bảng USER
    WHERE p.MaKH = @MaKH
    ORDER BY p.TG_LapPhieu DESC;
END;
GO