USE HAPPYPET
GO

PRINT '--- BAT DAU NAP DU LIEU ---'

-- 1. Tao Chi Nhanh (chua co NVQL)
PRINT '1. Dang chay GenCHI_NHANH...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenCHI_NHANH.sql"

-- 2. Tao User
PRINT '2. Dang chay GenUSER...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenUSER.sql"

-- 3. Tao Nhan Vien
PRINT '3. Dang chay GenNHAN_VIEN...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenNHAN_VIEN.sql"

-- 4. Update lai Nhan vien quan ly cho Chi Nhanh
PRINT '4. Dang chay GenCHI_NHANH_UpdateMaNVQL...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenCHI_NHANH_UpdateMaNVQL.sql"

-- 5. Tao Khach Hang
PRINT '5. Dang chay GenKHACH_HANG...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenKHACH_HANG.sql"

-- 6. Tao Tai Khoan
PRINT '6. Dang chay GenTAI_KHOAN...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenTAI_KHOAN.sql"

-- 7. Tao Thu Cung
PRINT '7. Dang chay GenTHU_CUNG...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenTHU_CUNG.sql"

-- 8. Danh muc Loai Dich Vu
PRINT '8. Dang chay GenLOAI_DICH_VU...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenLOAI_DICH_VU.sql"

-- 9. Dich vu tai Chi Nhanh
PRINT '9. Dang chay GenDV_CN...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenDV_CN.sql"

-- 10. Phan cong Chi Nhanh
PRINT '10. Dang chay GenPHAN_CONG_CN...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenPHAN_CONG_CN.sql"

-- 11. Danh muc Mat Hang
PRINT '11. Dang chay GenMAT_HANG...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenMAT_HANG.sql"

-- 12. Vaccine
PRINT '12. Dang chay GenVACCINE...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenVACCINE.sql"

-- 13. San pham khac
PRINT '13. Dang chay GenSAN_PHAM_KHAC...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenSAN_PHAM_KHAC.sql"

-- 14. Thuoc
PRINT '14. Dang chay GenTHUOC...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenTHUOC.sql"

-- 15. Ton Kho
PRINT '15. Dang chay GenTON_KHO...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenTON_KHO.sql"

-- 16. Phieu Dich Vu (Goc cua cac loai phieu)
PRINT '16. Dang chay GenPHIEU_DICH_VU...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenPHIEU_DICH_VU.sql"

-- 17. Phieu Kham Benh
PRINT '17. Dang chay GenPHIEU_KHAM_BENH...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenPHIEU_KHAM_BENH.sql"

-- 18. Phieu Mua Hang
PRINT '18. Dang chay GenPHIEU_MUA_HANG...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenPHIEU_MUA_HANG.sql"

-- 19. Phieu Tiem Vaccine
PRINT '19. Dang chay GenPHIEU_TIEM_VACCINE...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenPHIEU_TIEM_VACCINE.sql"

-- 20. Chi tiet Don Thuoc
PRINT '20. Dang chay GenCT_DON_THUOC...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenCT_DON_THUOC.sql"

-- 21. Chi tiet Mua Hang
PRINT '21. Dang chay GenCT_MUA_HANG...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenCT_MUA_HANG.sql"

-- 22. Goi Tiem Vaccine
PRINT '22. Dang chay GenGOI_TIEM_VC...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenGOI_TIEM_VC.sql"

-- 23. Dang ky Goi Tiem
PRINT '23. Dang chay GenDANG_KI_GOI_TIEM...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenDANG_KI_GOI_TIEM.sql"

-- 24. Chi tiet Tiem Vaccine
PRINT '24. Dang chay GenCT_TIEM_VC...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenCT_TIEM_VC.sql"

-- 25. Danh gia Dich Vu
PRINT '25. Dang chay GenDANH_GIA_DV...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenDANH_GIA_DV.sql"

-- 26. Danh gia San Pham
PRINT '26. Dang chay GenDANH_GIA_SP...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenDANH_GIA_SP.sql"

-- 27. Danh muc Hang Thanh Vien
PRINT '27. Dang chay GenHANG_TV...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenHANG_TV.sql"

-- 28. Hoa Don Truc Tiep
PRINT '28. Dang chay GenHD_TRUC_TIEP...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenHD_TRUC_TIEP.sql"

-- 29. Hoa Don Truc Tuyen
PRINT '29. Dang chay GenHD_TRUC_TUYEN...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenHD_TRUC_TUYEN.sql"

-- 30. Xep Hang Nam
PRINT '30. Dang chay GenXEP_HANG_NAM...'
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\GenXEP_HANG_NAM.sql"

-- 31. Buoc cuoi cung
:r "D:\Bai tap ki 1 nam 3\CSDL NC\Project\Database\GeneratingData\UpdateData.sql"

PRINT '--- DA NAP XONG TOAN BO DU LIEU ---'
GO