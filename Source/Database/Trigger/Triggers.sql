USE HAPPYPET
GO

-- Trigger "Đóng băng" phiếu đã hoàn tất
-- 1. Đóng băng phiếu mua hàng
CREATE OR ALTER TRIGGER trg_KhoaPhieuDaHoanTat_CT_MuaHang
ON CT_MUA_HANG
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;
    
    -- Kiểm tra bảng Inserted (cho lệnh Insert/Update)
    IF EXISTS (
        SELECT 1 FROM Inserted I JOIN PHIEU_DICH_VU P ON I.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT',  'DH')
    )
    OR EXISTS (
        -- Kiểm tra bảng Deleted (cho lệnh Delete)
        SELECT 1 FROM Deleted D JOIN PHIEU_DICH_VU P ON D.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    BEGIN
        RAISERROR(N'Lỗi Bảo mật: Không thể chỉnh sửa chi tiết khi phiếu đã kết thúc hoặc đã hủy.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 2. Đóng băng phiếu tiêm
-- 2.1 Chặn sửa bảng CT_TIEM_VC (Chi tiết mũi tiêm)
CREATE OR ALTER TRIGGER trg_KhoaPhieuDaHoanTat_CT_TiemVC
ON CT_TIEM_VC
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inserted I JOIN PHIEU_DICH_VU P ON I.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    OR EXISTS (
        SELECT 1 FROM Deleted D JOIN PHIEU_DICH_VU P ON D.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    BEGIN
        RAISERROR(N'Lỗi Bảo mật: Không thể chỉnh sửa chi tiết tiêm khi phiếu đã kết thúc hoặc đã hủy.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 2.2 Chặn sửa bảng DANG_KI_GOI_TIEM (Nếu phiếu đó có đăng ký gói)
CREATE OR ALTER TRIGGER trg_KhoaPhieuDaHoanTat_DangKiGoi
ON DANG_KI_GOI_TIEM
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inserted I JOIN PHIEU_DICH_VU P ON I.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    OR EXISTS (
        SELECT 1 FROM Deleted D JOIN PHIEU_DICH_VU P ON D.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    BEGIN
        RAISERROR(N'Lỗi Bảo mật: Không thể chỉnh sửa gói tiêm khi phiếu đã kết thúc hoặc đã hủy.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 3. Đóng băng phiếu khám bệnh
-- 3.1 Chặn sửa bảng CT_DON_THUOC (Chi tiết đơn thuốc)
CREATE OR ALTER TRIGGER trg_KhoaPhieuDaHoanTat_CT_DonThuoc
ON CT_DON_THUOC
AFTER INSERT, UPDATE, DELETE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1 FROM Inserted I JOIN PHIEU_DICH_VU P ON I.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    OR EXISTS (
        SELECT 1 FROM Deleted D JOIN PHIEU_DICH_VU P ON D.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    BEGIN
        RAISERROR(N'Lỗi Bảo mật: Không thể kê thêm hoặc xóa thuốc khi phiếu khám đã kết thúc.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO

-- 3.2 Chặn sửa bảng PHIEU_KHAM_BENH (Thông tin Chẩn đoán, Triệu chứng)
CREATE OR ALTER TRIGGER trg_KhoaPhieuDaHoanTat_ThongTinKham
ON PHIEU_KHAM_BENH
AFTER UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    -- Chỉ chặn khi phiếu đã hoàn tất mà cố tình sửa Chẩn đoán hoặc Triệu chứng
    IF EXISTS (
        SELECT 1 FROM Inserted I JOIN PHIEU_DICH_VU P ON I.MaPhieu = P.MaPhieu
        WHERE P.TrangThai IN ('DHT', 'DH')
    )
    BEGIN
        RAISERROR(N'Lỗi Bảo mật: Không thể sửa chẩn đoán/triệu chứng khi phiếu khám đã kết thúc.', 16, 1);
        ROLLBACK TRANSACTION;
    END
END;
GO
