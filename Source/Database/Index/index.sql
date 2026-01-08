USE HAPPYPET
GO

DBCC FREEPROCCACHE; -- Xóa cache thực thi
DBCC DROPCLEANBUFFERS; -- Xóa cache dữ liệu trên RAM
-- =================================================================================
-- TV1: Tra cứu danh sách thú cưng đến hẹn tái khám
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_KHAM_BENH_NgayHen_T1
ON [dbo].[PHIEU_KHAM_BENH] ([NgayHenTaiKham])
INCLUDE ([MaTC], [ChanDoan]);
GO

CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_T1
ON [dbo].[PHIEU_DICH_VU] ([MaCN])
INCLUDE ([MaPhieu]); 
GO

DROP INDEX IX_PHIEU_KHAM_BENH_NgayHen_T1 ON dbo.PHIEU_KHAM_BENH;
DROP INDEX IX_PHIEU_DICH_VU_MaCN_T1 ON dbo.PHIEU_DICH_VU;

-- =================================================================================
-- TV2: Tra cứu sản phẩm (theo Tên/Loại) của một chi nhánh
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_MAT_HANG_LoaiMH_T2
ON [dbo].[MAT_HANG] ([LoaiMH]) 
INCLUDE ([TenMatHang], [DonGia]);

DROP INDEX IX_MAT_HANG_LoaiMH_T2 ON MAT_HANG;
GO

-- =================================================================================
-- TV3: Tra cứu Phiếu dịch vụ trong ngày của một chi nhánh (Lọc theo Ngày & Mã CN)
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_Ngay_T3
ON [dbo].[PHIEU_DICH_VU] ([MaCN], [TG_ThucHienDV])
INCLUDE ([TrangThai], [LoaiPhieu], [MaNV], [MaKH]);
GO

DROP INDEX IX_PHIEU_DICH_VU_MaCN_Ngay_T3 ON PHIEU_DICH_VU;

-- =================================================================================
-- TV7: Xem lịch sử khám bệnh của một thú cưng
-- =================================================================================
CREATE NONCLUSTERED INDEX IX_PHIEU_KHAM_BENH_MaTC_T7
ON [dbo].[PHIEU_KHAM_BENH] ([MaTC])
INCLUDE ([TrieuChung], [ChanDoan]);
GO

CREATE NONCLUSTERED INDEX IX_CT_DON_THUOC_MaPhieu_T7
ON [dbo].[CT_DON_THUOC] ([MaPhieu])
INCLUDE ([MaThuoc], [SoLuong], [LieuLuong]);
GO

DROP INDEX IX_PHIEU_KHAM_BENH_MaTC_T7 ON PHIEU_KHAM_BENH;
DROP INDEX IX_CT_DON_THUOC_MaPhieu_T7 ON CT_DON_THUOC;

-- =================================================================================
-- TV8: Xem lịch sử tiêm phòng của một thú cưng
-- =================================================================================
CREATE NONCLUSTERED INDEX IX_CT_TIEM_VC_MaPhieu_T8
ON [dbo].[CT_TIEM_VC] ([MaPhieu])
INCLUDE ([NhacLai], [LieuLuong]);
GO

CREATE NONCLUSTERED INDEX IX_PHIEU_TIEM_VACCINE_MaTC_T8
ON [dbo].[PHIEU_TIEM_VACCINE] ([MaTC]);
GO

CREATE NONCLUSTERED INDEX IX_PHIEU_TIEM_VACCINE_MaPhieu_T8
ON [dbo].[PHIEU_TIEM_VACCINE] ([MaPhieu]);
GO

DROP INDEX IX_PHIEU_TIEM_VACCINE_MaTC_T8 ON PHIEU_TIEM_VACCINE;
DROP INDEX IX_CT_TIEM_VC_MaPhieu_T8 ON CT_TIEM_VC;
DROP INDEX IX_PHIEU_TIEM_VACCINE_MaPhieu_T8 ON PHIEU_TIEM_VACCINE;


SELECT 
    t.name AS [Tên Bảng],
    i.name AS [Tên Index],
    i.type_desc AS [Loại Index],
    CASE 
        WHEN i.is_primary_key = 1 THEN 'Khoa Chinh (PK)'
        WHEN i.is_unique = 1 THEN 'Duy Nhat (Unique)'
        ELSE 'Thuong'
    END AS [Ghi Chu]
FROM sys.indexes i
INNER JOIN sys.tables t ON i.object_id = t.object_id
WHERE i.name IS NOT NULL -- Loại bỏ các bảng chưa có index (Heap)
ORDER BY t.name, i.name;
