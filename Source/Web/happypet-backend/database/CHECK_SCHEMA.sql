-- ============================================
-- KIỂM TRA SCHEMA THỰC TẾ CỦA DATABASE
-- ============================================
USE HAPPYPET
GO

PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'📋 1. BẢNG MAT_HANG (Vaccine + Sản phẩm)';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

-- Xem cấu trúc bảng MAT_HANG
SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'MAT_HANG'
ORDER BY ORDINAL_POSITION;

-- Lấy vài vaccine mẫu
SELECT TOP 5 * FROM MAT_HANG WHERE LoaiMH = 'T';

PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'📋 2. BẢNG CT_TIEM_VC (Chi tiết tiêm vaccine)';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'CT_TIEM_VC'
ORDER BY ORDINAL_POSITION;

-- Lấy mẫu
SELECT TOP 3 * FROM CT_TIEM_VC;

PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'📋 3. BẢNG DANG_KI_GOI_TIEM';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'DANG_KI_GOI_TIEM'
ORDER BY ORDINAL_POSITION;

-- Lấy mẫu
SELECT TOP 3 * FROM DANG_KI_GOI_TIEM;

PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'📋 4. BẢNG GOI_TIEM_VC';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';

SELECT 
    COLUMN_NAME,
    DATA_TYPE,
    CHARACTER_MAXIMUM_LENGTH,
    IS_NULLABLE
FROM INFORMATION_SCHEMA.COLUMNS
WHERE TABLE_NAME = 'GOI_TIEM_VC'
ORDER BY ORDINAL_POSITION;

-- Lấy tất cả gói
SELECT * FROM GOI_TIEM_VC;

PRINT N'';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'❓ CÂU HỎI QUAN TRỌNG:';
PRINT N'━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━';
PRINT N'';
PRINT N'1. CT_TIEM_VC có cột MaVaccine hay MaMatHang?';
PRINT N'2. DANG_KI_GOI_TIEM có cột MaVaccine hay MaMatHang?';
PRINT N'3. Có bảng VACCINE riêng không hay chỉ có MAT_HANG?';
PRINT N'';
PRINT N'👉 Cần xác nhận để sửa lại tất cả SP!';

GO
