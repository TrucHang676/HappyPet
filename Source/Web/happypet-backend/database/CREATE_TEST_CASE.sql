-- ============================================
-- TẠO TEST CASE: THÚ CƯNG CÓ GÓI DỞ (1/3 MŨI)
-- ============================================
USE HAPPYPET
GO

-- 1. Tạo thú cưng test mới
IF NOT EXISTS (SELECT 1 FROM THU_CUNG WHERE MaTC = 'TC_TEST99')
BEGIN
    INSERT INTO THU_CUNG (MaTC, Ten, Loai, Giong, NgSinh, GioiTinh, TinhTrangSucKhoe, MaChuNuoi)
    VALUES ('TC_TEST99', N'TestPet', N'Chó', N'Poodle', '2024-01-01', N'Đực', N'Khỏe mạnh', 'U000003');
    
    PRINT N'✅ Đã tạo TC_TEST99';
END

-- 2. Tạo phiếu đã tiêm mũi 1 (HOÀN TẤT)
DECLARE @PhieuCu NCHAR(10) = 'P_OLD99';

-- Xóa nếu có
DELETE FROM CT_TIEM_VC WHERE MaPhieu = @PhieuCu;
DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @PhieuCu;
DELETE FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @PhieuCu;
DELETE FROM PHIEU_DICH_VU WHERE MaPhieu = @PhieuCu;

-- Tạo phiếu cũ
INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_LapPhieu, TG_ThucHienDV, TrangThai, LoaiPhieu, MaCN, MaNV, MaKH)
VALUES (@PhieuCu, DATEADD(DAY, -10, GETDATE()), DATEADD(DAY, -10, GETDATE()), 'DHT', N'Tiêm vaccine', 'CN01', 'NV01', 'U000003');

INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC)
VALUES (@PhieuCu, 'TC_TEST99');

-- Thêm vaccine vào gói (mũi 1)
DECLARE @Gia MONEY = 350000;
DECLARE @GiamGia MONEY = 100000;

INSERT INTO CT_TIEM_VC (MaVaccine, MaPhieu, LieuLuong, ThanhTien, NhacLai)
VALUES ('MH0251', @PhieuCu, N'Mũi 1', @Gia - @GiamGia, 0);

INSERT INTO DANG_KI_GOI_TIEM (MaPhieu, MaVaccine, MaGoi, NgayHetHan, HieuLuc, ThanhTien)
VALUES (@PhieuCu, 'MH0251', 'GOI002', DATEADD(MONTH, 6, GETDATE()), 1, @Gia - @GiamGia);

PRINT N'✅ Đã tạo phiếu cũ: ' + @PhieuCu + N' (đã tiêm 1/3 mũi)';

-- 3. Tạo phiếu MỚI (CHỜ KHÁM)
DECLARE @PhieuMoi NCHAR(10) = 'P_NEW99';

DELETE FROM CT_TIEM_VC WHERE MaPhieu = @PhieuMoi;
DELETE FROM DANG_KI_GOI_TIEM WHERE MaPhieu = @PhieuMoi;
DELETE FROM PHIEU_TIEM_VACCINE WHERE MaPhieu = @PhieuMoi;
DELETE FROM PHIEU_DICH_VU WHERE MaPhieu = @PhieuMoi;

INSERT INTO PHIEU_DICH_VU (MaPhieu, TG_LapPhieu, TG_ThucHienDV, TrangThai, LoaiPhieu, MaCN, MaNV, MaKH)
VALUES (@PhieuMoi, GETDATE(), NULL, N'Chờ khám', N'Tiêm vaccine', 'CN01', 'NV01', 'U000003');

INSERT INTO PHIEU_TIEM_VACCINE (MaPhieu, MaTC)
VALUES (@PhieuMoi, 'TC_TEST99');

PRINT N'✅ Đã tạo phiếu mới: ' + @PhieuMoi;

-- 4. TEST
PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'🔥 TEST SP với TC_TEST99 (1/3 mũi):';
EXEC sp_KiemTraGoiDangTiem 'TC_TEST99';

PRINT N'';
PRINT N'💡 HƯỚNG DẪN TEST:';
PRINT N'1. Vào web, đăng nhập user U000003 (Dương Văn Đức)';
PRINT N'2. Đặt lịch mới hoặc vào phiếu P_NEW99';
PRINT N'3. Chọn thú cưng TC_TEST99';
PRINT N'4. Vào trang chọn vaccine';
PRINT N'5. PHẢI THẤY CARD "💉 Gói Đang Tiêm" hiện ra!';
PRINT N'   - Gói: Gói Nâng Cấp Bảo Vệ Toàn Diện';
PRINT N'   - Vaccine: MH0251 - Vaccine 7 Bệnh Chó';
PRINT N'   - Tiến độ: 1/3 mũi';
PRINT N'6. Click nút "✅ Tiêm Tiếp Gói Này" → Thêm mũi 2';

GO
