-- ===================================================
-- SCRIPT TEST: KIỂM TRA KHO CÓ BỊ TRỪ KHI ĐẶT LỊCH KHÔNG?
-- ===================================================
USE HAPPYPET
GO

-- ===================================================
-- CÁCH 1: KIỂM TRA SP ĐẶT LỊCH CÓ UPDATE TON_KHO KHÔNG
-- ===================================================
PRINT N'=== CÁCH 1: Kiểm tra code SP sp_DatLichHen ===';
SELECT 
    OBJECT_NAME(object_id) AS TenSP,
    definition AS NoiDungSP
FROM sys.sql_modules
WHERE OBJECT_NAME(object_id) = 'sp_DatLichHen'
  AND definition LIKE '%TON_KHO%'; -- Nếu có UPDATE kho thì sẽ có chữ TON_KHO

-- ❌ Nếu không trả về kết quả -> KHÔNG CÓ UPDATE KHO trong SP đặt lịch
GO

-- ===================================================
-- CÁCH 2: TEST THỰC TẾ (QUAN TRỌNG NHẤT)
-- ===================================================
PRINT N'=== CÁCH 2: Test thực tế ===';
PRINT N'';

-- Bước 1: Lấy thông tin vaccine để test
DECLARE @MaVaccine NCHAR(10);
DECLARE @MaCN NCHAR(10) = 'CN001'; -- Thay chi nhánh của bạn
DECLARE @SoLuongTonTruoc INT;
DECLARE @SoLuongTonSau INT;

-- Lấy 1 vaccine bất kỳ còn tồn kho
SELECT TOP 1 @MaVaccine = MaMatHang, @SoLuongTonTruoc = SoLuongTon
FROM TON_KHO 
WHERE MaCN = @MaCN AND LoaiMH = 'VC' AND SoLuongTon > 0;

IF @MaVaccine IS NULL
BEGIN
    PRINT N'❌ Không có vaccine nào trong kho để test!';
    RETURN;
END

PRINT N'📦 Vaccine test: ' + @MaVaccine;
PRINT N'📊 Số lượng tồn TRƯỚC khi đặt lịch: ' + CAST(@SoLuongTonTruoc AS NVARCHAR(10));
PRINT N'';

-- Bước 2: Lấy thông tin khách hàng và thú cưng
DECLARE @MaKH NCHAR(10);
DECLARE @MaTC NCHAR(10);

SELECT TOP 1 @MaKH = MaKH FROM KHACH_HANG;
SELECT TOP 1 @MaTC = MaTC FROM THU_CUNG WHERE MaKH = @MaKH;

IF @MaKH IS NULL OR @MaTC IS NULL
BEGIN
    PRINT N'❌ Không có dữ liệu KH/TC để test!';
    RETURN;
END

-- Bước 3: GỌI SP ĐẶT LỊCH
DECLARE @NgayHen DATE = DATEADD(DAY, 3, GETDATE()); -- Đặt lịch 3 ngày sau
DECLARE @GioHen TIME = '10:00:00';
DECLARE @MaPhieuMoi NCHAR(10);

BEGIN TRANSACTION TestDatLich;

BEGIN TRY
    -- Đặt lịch tiêm vaccine
    EXEC sp_DatLichHen 
        @MaKH = @MaKH,
        @MaTC = @MaTC,
        @MaCN = @MaCN,
        @LoaiPhieu = 'TV',
        @NgayHen = @NgayHen,
        @GioHen = @GioHen,
        @TrieuChung = N'Test kho';

    -- Lấy mã phiếu vừa tạo
    SELECT TOP 1 @MaPhieuMoi = MaPhieu 
    FROM PHIEU_DICH_VU 
    WHERE MaKH = @MaKH AND LoaiPhieu = 'TV' 
    ORDER BY TG_LapPhieu DESC;

    PRINT N'✅ Đã tạo phiếu đặt lịch: ' + @MaPhieuMoi;
    PRINT N'';

    -- Bước 4: KIỂM TRA SỐ LƯỢNG TỒN SAU KHI ĐẶT LỊCH
    SELECT @SoLuongTonSau = SoLuongTon
    FROM TON_KHO 
    WHERE MaCN = @MaCN AND MaMatHang = @MaVaccine;

    PRINT N'📊 Số lượng tồn SAU khi đặt lịch: ' + CAST(@SoLuongTonSau AS NVARCHAR(10));
    PRINT N'';

    -- Bước 5: SO SÁNH VÀ KẾT LUẬN
    IF @SoLuongTonTruoc = @SoLuongTonSau
    BEGIN
        PRINT N'✅ KẾT LUẬN: KHO KHÔNG BỊ TRỪ KHI ĐẶT LỊCH!';
        PRINT N'    → Phiếu trạng thái DD (Đã Đặt) KHÔNG LẤY HÀNG TỪ KHO';
        PRINT N'    → Khi hủy phiếu DD KHÔNG CẦN HOÀN TRẢ KHO';
    END
    ELSE
    BEGIN
        PRINT N'⚠️ KẾT LUẬN: KHO ĐÃ BỊ TRỪ KHI ĐẶT LỊCH!';
        PRINT N'    → Phiếu trạng thái DD đã lấy hàng từ kho';
        PRINT N'    → Khi hủy phiếu DD CẦN HOÀN TRẢ KHO';
        PRINT N'    → Số lượng thay đổi: ' + CAST((@SoLuongTonTruoc - @SoLuongTonSau) AS NVARCHAR(10));
    END

    -- Rollback để không ảnh hưởng DB thật
    ROLLBACK TRANSACTION TestDatLich;
    PRINT N'';
    PRINT N'🔄 Đã rollback transaction test (không ảnh hưởng DB thật)';

END TRY
BEGIN CATCH
    IF @@TRANCOUNT > 0 ROLLBACK TRANSACTION TestDatLich;
    PRINT N'❌ Lỗi: ' + ERROR_MESSAGE();
END CATCH

GO

-- ===================================================
-- CÁCH 3: KIỂM TRA CÁC SP KHÁC CÓ TRỪ KHO KHÔNG
-- ===================================================
PRINT N'';
PRINT N'=== CÁCH 3: Kiểm tra SP nào UPDATE kho ===';

SELECT 
    OBJECT_NAME(object_id) AS TenSP,
    CASE 
        WHEN definition LIKE '%UPDATE%TON_KHO%SET%SoLuongTon%-%' THEN N'✅ Có TRỪ kho'
        WHEN definition LIKE '%UPDATE%TON_KHO%SET%SoLuongTon%+%' THEN N'✅ Có HOÀN kho'
        WHEN definition LIKE '%TON_KHO%' THEN N'⚠️ Có đọc kho'
        ELSE N'❌ Không động kho'
    END AS HanhDong
FROM sys.sql_modules
WHERE OBJECTPROPERTY(object_id, 'IsProcedure') = 1
  AND definition LIKE '%TON_KHO%'
ORDER BY TenSP;

GO

PRINT N'';
PRINT N'=== HOÀN TẤT TEST ===';
PRINT N'Kết quả: Nếu CÁCH 2 hiện "KHO KHÔNG BỊ TRỪ" → SP hủy phiếu KHÔNG NÊN HOÀN KHO';
