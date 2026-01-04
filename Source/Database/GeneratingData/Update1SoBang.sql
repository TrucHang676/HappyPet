-- Update data -- 

UPDATE PHAN_CONG_CN
SET NgayKT = DATEFROMPARTS(2026, MONTH(NgayKT), DAY(NgayKT));

UPDATE TAI_KHOAN
SET MatKhau = '$2b$10$I.NViZ1goAPnE7DSC/ZtTeGjuHq9rT1qX71gwYK/hU.9wn2jZ75se'

UPDATE PHIEU_DICH_VU
SET MaNV = NULL
WHERE TrangThai = 'DH'

-- Update sản phẩm -- 

update MAT_HANG
set TenMatHang = N'Áo mùa hè 3 lỗ cho chó'
where MaMatHang = 'MH0616    '

UPDATE MAT_HANG
SET TenMatHang = REPLACE(TenMatHang, N'Lông Thỏ', N'Lông Mềm')
WHERE TenMatHang LIKE N'%Lông%'

UPDATE MAT_HANG
SET TenMatHang = REPLACE(TenMatHang, N'Lông Cừu', N'Lông Mềm')
WHERE TenMatHang LIKE N'%Lông%'

update MAT_HANG
set TenMatHang = N'Áo hình con chó nhỏ'
where MaMatHang = 'MH1934    '