USE HAPPYPET
GO
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
-- =================================================================================
-- TV2: Tra cứu sản phẩm (theo Tên/Loại) của một chi nhánh
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_MAT_HANG_LoaiMH_T2
ON [dbo].[MAT_HANG] ([LoaiMH]) 
INCLUDE ([TenMatHang], [DonGia]);
-- =================================================================================
-- TV3: Tra cứu Phiếu dịch vụ trong ngày của một chi nhánh (Lọc theo Ngày & Mã CN)
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_DICH_VU_MaCN_Ngay_T3
ON [dbo].[PHIEU_DICH_VU] ([MaCN], [TG_ThucHienDV])
INCLUDE ([TrangThai], [LoaiPhieu], [MaNV], [MaKH]);
GO
-- =================================================================================
-- TV7: Xem lịch sử khám bệnh của một thú cưng
-- =================================================================================
-- Cài đặt index
CREATE NONCLUSTERED INDEX IX_PHIEU_KHAM_BENH_MaTC_T7
ON [dbo].[PHIEU_KHAM_BENH] ([MaTC])
INCLUDE ([TrieuChung], [ChanDoan]);
GO

CREATE NONCLUSTERED INDEX IX_CT_DON_THUOC_MaPhieu_T7
ON [dbo].[CT_DON_THUOC] ([MaPhieu])
INCLUDE ([MaThuoc], [SoLuong], [LieuLuong]);
GO
-- =================================================================================
-- TV8: Xem lịch sử tiêm phòng của một thú cưng
-- =================================================================================
-- Cài đặt index
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
