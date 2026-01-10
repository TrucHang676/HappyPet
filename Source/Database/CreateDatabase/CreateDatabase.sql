CREATE DATABASE HAPPYPET
GO

USE HAPPYPET
GO

-----------------------------------------------------------------------------------------------------
-- PHẦN 1: TẠO TẤT CẢ CÁC BẢNG 
-----------------------------------------------------------------------------------------------------
--1. Bảng USER
CREATE TABLE [USER] (
    MaUser		nchar(10) PRIMARY KEY,
    HoTen		nvarchar(50) NOT NULL,
    NgaySinh	date CHECK (NgaySinh < GETDATE()),
    GioiTinh	nvarchar(3) NOT NULL CHECK (GioiTinh IN (N'Nam', N'Nữ')),
    LoaiUser	nchar(2) NOT NULL CHECK (LoaiUser IN ('KH', 'NV'))    
);

--2. Bảng NHAN_VIEN
CREATE TABLE NHAN_VIEN (
    MaNV		nchar(10) PRIMARY KEY,
    NgayVaoLam	date NOT NULL,
    LuongCoBan	decimal(12,2) NOT NULL CHECK (LuongCoBan > 0),
    Chucvu		nvarchar(50) NOT NULL,
    MaCN		nchar(10) NOT NULL
);

--3. Bảng CHI_NHANH
CREATE TABLE CHI_NHANH (
    MaCN       nchar(10) PRIMARY KEY,
    TenCN      nvarchar(50) NOT NULL UNIQUE,
    DiaChi     nvarchar(100) NOT NULL UNIQUE,
    SDT        varchar(10) NOT NULL UNIQUE,
    Giomocua   time NOT NULL,
    Giodongcua time NOT NULL,
    MaNVQL     nchar(10)
);

--4. Bảng LOAI_DICH_VU
CREATE TABLE LOAI_DICH_VU (
    MaLoaiDV   nchar(5) PRIMARY KEY,
    TenLoaiDV  nvarchar(30) NOT NULL UNIQUE,
    GiaCoBan   decimal(12,2) NOT NULL CHECK (GiaCoBan >= 0)
);

--5. Bảng DV_CN
CREATE TABLE DV_CN (
    MaCN      nchar(10),
    MaLoaiDV  nchar(5),
	PRIMARY KEY (MaCN, MaLoaiDV)
);

--6. Bảng PHAN_CONG_CN
CREATE TABLE PHAN_CONG_CN (
    MaCN     nchar(10),
    MaNV     nchar(10),
    NgayBD   date,
    NgayKT   date NOT NULL ,
    Ghichu   nvarchar(100),
	PRIMARY KEY (MaCN, MaNV, NgayBD),
	CONSTRAINT CHK_NgayKT_NgayBD CHECK (NgayKT > NgayBD)
);

--7. Bảng PHIEU_DV
CREATE TABLE PHIEU_DICH_VU (
    MaPhieu        nchar(10) PRIMARY KEY,
    TG_ThucHienDV  datetime NOT NULL,
    TG_LapPhieu    datetime NOT NULL,
    TrangThai      varchar(3) NOT NULL CHECK (TrangThai IN ('DD', 'DTH', 'DHT', 'DH')),
    LoaiPhieu      varchar(2) NOT NULL CHECK (LoaiPhieu IN ('KB', 'MH', 'TV')),
    MaCN           nchar(10) NOT NULL,
    MaNV           nchar(10),
    MaKH           nchar(10)
);

--8. Bảng KHACH_HANG
CREATE TABLE KHACH_HANG (
    MaKH             nchar(10) PRIMARY KEY,
    SDT              varchar(10) NOT NULL UNIQUE,
    Email            varchar(50) CHECK (Email LIKE '%_@_%._%'),
    CCCD             char(12),
    TongDiemTichLuy  int
);

--9. Bảng THU_CUNG
CREATE TABLE THU_CUNG (
    MaTC             nchar(10) PRIMARY KEY,
    Ten              nvarchar(50),
    Loai             nvarchar(30) NOT NULL,
    Giong            nvarchar(30) NOT NULL,
    NgSinh           date NOT NULL CHECK (NgSinh < GETDATE()),
    GioiTinh         nvarchar(3) NOT NULL,
    TinhTrangSucKhoe nvarchar(100) NOT NULL,
    MaKH             nchar(10) NOT NULL
);

--10. Bảng TAI_KHOAN
CREATE TABLE TAI_KHOAN (
    TenDangNhap  varchar(30) PRIMARY KEY,
    MatKhau      varchar(50) NOT NULL,
    MaUser       nchar(10) NOT NULL
);


--11. Bảng HANG_TV
CREATE TABLE HANG_TV (
    MaHang             nchar(5) PRIMARY KEY,
    TenHang            nvarchar(50) NOT NULL,
    MucChiTieuHang     decimal(18,2)NOT NULL,
    MucDuyTri          decimal(18,2)NOT NULL,
    KhuyenMaiUuTien    decimal(1, 0)NOT NULL,
);

--12. Bảng XEP_HANG_NAM
CREATE TABLE XEP_HANG_NAM (
    MaKH         nchar(10) NOT NULL,
    Nam          int NOT NULL,
    MaHang       nchar(5),
    TongChiTieu  decimal(18,2),
    NgayCapNhat  date,

    CONSTRAINT PK_XEP_HANG_NAM PRIMARY KEY CLUSTERED (MaKH, Nam)
) ON PS_Xep_Hang_Nam(Nam);

--13. Bảng HD_TRUC_TUYEN 
CREATE TABLE HD_TRUC_TUYEN  (
    MaPhieu         nchar(10) PRIMARY KEY,
    TongThanhTien    decimal(18,2),
    KhuyenMai       decimal(18,2),
    DiemQuyDoi      int,
    TongThanhTienSC  decimal(18,2),
    PhuongThucTT     nvarchar(20) NOT NULL,
    DiaChiGiaoHang   nvarchar(100) NOT NULL,
    PhiGiaoHang      decimal(18,2) NOT NULL,
	TrangThaiHD		 varchar(3) NOT NULL CHECK (TrangThaiHD IN ('DTT', 'DH'))
);

--14. Bảng HD_TRUC_TIEP
CREATE TABLE HD_TRUC_TIEP (
    MaPhieu         nchar(10) PRIMARY KEY,
    TongThanhTien    decimal(18,2),
    KhuyenMai       decimal(18,2) DEFAULT 0,
    DiemQuyDoi      int,
    TongThanhTienSC  decimal(18,2),
    PhuongThucTT     nvarchar(20) NOT NULL,
    MaNV             nchar(10) NOT NULL
);

--15. Bảng PHIEU_KHAM_BENH
CREATE TABLE PHIEU_KHAM_BENH (
    MaPhieu        nchar(10) PRIMARY KEY,
    MaTC           nchar(10) NOT NULL,
    TrieuChung     nvarchar(200) NOT NULL,
    ChanDoan       nvarchar(200),
    NgayHenTaiKham date,
);

--16. Bảng MAT_HANG
CREATE TABLE MAT_HANG (
    MaMatHang    nchar(10) PRIMARY KEY,
    TenMatHang   nvarchar(80) NOT NULL,
    HangSX       nvarchar(50),
    NgaySanXuat  date,
    NgayHetHan   date,
    DonGia       decimal(18,2) NOT NULL CHECK (DonGia >= 0),
    LoaiMH       varchar(3) NOT NULL CHECK (LoaiMH IN ('T','VC','SPK'))
);

--17. Bảng THUOC
CREATE TABLE THUOC (
    MaThuoc     nchar(10) PRIMARY KEY,
    TacDungPhu  nvarchar(200),
    DangBaoChe  nvarchar(70),
    LoaiThuoc   nvarchar(20) NOT NULL CHECK (LoaiThuoc IN (N'Cần kê đơn', N'Không cần kê đơn')),
	DonGia decimal(18,2) NOT NULL CHECK (DonGia >= 0)
);

--18. Bảng CT_DON_THUOC
CREATE TABLE CT_DON_THUOC (
    MaThuoc   nchar(10),
    MaPhieu   nchar(10),
    LieuLuong nvarchar(50),
    SoLuong   int NOT NULL CHECK (SoLuong >= 0),
    ThanhTien decimal(18,2) CHECK (ThanhTien >= 0),
    PRIMARY KEY (MaThuoc, MaPhieu)
);

--19. Bảng SAN_PHAM_KHAC
CREATE TABLE SAN_PHAM_KHAC (
    MaSP    nchar(10) PRIMARY KEY,
    LoaiSP  nvarchar(70) NOT NULL CHECK (LoaiSP IN (N'Đồ chơi', N'Phụ kiện', N'Thức ăn', N'Quần áo'))
);

--20. Bảng VACCINE
CREATE TABLE VACCINE (
    MaVaccine     nchar(10) PRIMARY KEY,
    ChongChiDinh  nvarchar(200),
	DonGia decimal(18,2) NOT NULL CHECK (DonGia >= 0)
);

--21. Bảng PHIEU_TIEM_VACCINE
CREATE TABLE PHIEU_TIEM_VACCINE (
    MaPhieu nchar(10) PRIMARY KEY,
    MaTC    nchar(10) NOT NULL
);

--22. Bảng CT_TIEM_VC
CREATE TABLE CT_TIEM_VC (
    MaVaccine nchar(10) NOT NULL,
    MaPhieu   nchar(10) NOT NULL,
    NhacLai   bit,
    LieuLuong nvarchar(70),
    ThanhTien decimal(18,2) CHECK (ThanhTien >= 0),
    PRIMARY KEY (MaVaccine, MaPhieu)
);

--23. Bảng GOI_TIEM_VC
CREATE TABLE GOI_TIEM_VC (
    MaGoi           nchar(10) PRIMARY KEY,
    TenGoi          nvarchar(50),
    ThoiHan         int NOT NULL CHECK (ThoiHan >= 0),
    GiamGia         decimal(18,2) NOT NULL CHECK (GiamGia >= 0),
    SoMuiTuongUng   int NOT NULL CHECK (SoMuiTuongUng >= 0),
    GhiChu          nvarchar(100)
);

--24. Bảng DANG_KI_GOI_TIEM
CREATE TABLE DANG_KI_GOI_TIEM (
    MaPhieu    nchar(10),
    MaVaccine  nchar(10),
    MaGoi      nchar(10),
    NgayHetHan date,
    HieuLuc    bit NOT NULL,
    ThanhTien  decimal(18,2) CHECK (ThanhTien >= 0),
    PRIMARY KEY (MaPhieu, MaVaccine, MaGoi)
);

--25. Bảng PHIEU_MUA_HANG
CREATE TABLE PHIEU_MUA_HANG (
    MaPhieu nchar(10) NOT NULL PRIMARY KEY
);

--26. Bảng CT_MUA_HANG
CREATE TABLE CT_MUA_HANG (
    MaPhieu   nchar(10),
    MaMatHang nchar(10),
    SoLuong   int NOT NULL CHECK (SoLuong >= 0),
    ThanhTien decimal(18,2) CHECK (ThanhTien >= 0),
    PRIMARY KEY (MaPhieu, MaMatHang)
);

--27. Bảng DANH_GIA_SP
CREATE TABLE DANH_GIA_SP (
    MaPhieu       nchar(10),
    MaMatHang     nchar(10),
    DiemChatLuong decimal(4,2) NOT NULL CHECK (DiemChatLuong >= 0 and DiemChatLuong <=5 ),
    BinhLuan      nvarchar(200),
    NgayDang      date,
    PRIMARY KEY (MaPhieu, MaMatHang)
);

--28. Bảng DANH_GIA_DV
CREATE TABLE DANH_GIA_DV (
    MaPhieu        nchar(10) PRIMARY KEY,
    DiemChatLuong  decimal(4,2) NOT NULL CHECK (DiemChatLuong >= 0 and DiemChatLuong <=5 ),
    DiemThaiDoNV   decimal(4,2) NOT NULL CHECK (DiemThaiDoNV >= 0 and DiemThaiDoNV <= 5),
    DiemTongThe    decimal(4,2) NOT NULL CHECK (DiemTongThe >= 0 and DiemTongThe <= 5),
    BinhLuan       nvarchar(200),
    NgayDang       date
);

--29. Bảng TON_KHO
CREATE TABLE TON_KHO (
    MaCN       nchar(10),
    MaMatHang  nchar(10),
    SoLuongTon int NOT NULL CHECK (SoLuongTon >= 0),
    PRIMARY KEY (MaCN, MaMatHang)
);

-----------------------------------------------------------------------------------------------------
-- PHẦN 2: THÊM RÀNG BUỘC KHÓA NGOẠI
-----------------------------------------------------------------------------------------------------

--NHAN_VIEN
ALTER TABLE NHAN_VIEN ADD
	CONSTRAINT FK1_NV_USER FOREIGN KEY (MaNV) REFERENCES [USER](MaUser),
    CONSTRAINT FK2_NV_CN FOREIGN KEY (MaCN) REFERENCES CHI_NHANH(MaCN);

--CHI_NHANH
ALTER TABLE CHI_NHANH ADD
    CONSTRAINT FK1_CN_NV FOREIGN KEY (MaNVQL) REFERENCES NHAN_VIEN(MaNV); 

--DV_CN
ALTER TABLE DV_CN ADD
    CONSTRAINT FK1_DVCN_CN FOREIGN KEY (MaCN) REFERENCES CHI_NHANH(MaCN),
    CONSTRAINT FK2_DVCN_LOAIDV FOREIGN KEY (MaLoaiDV) REFERENCES LOAI_DICH_VU(MaLoaiDV);

--PHAN_CONG_CN
ALTER TABLE PHAN_CONG_CN ADD
    CONSTRAINT FK1_PCCN_CN FOREIGN KEY (MaCN) REFERENCES CHI_NHANH(MaCN),
    CONSTRAINT FK2_PCCN_NV FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV);

--PHIEU_DICH_VU
ALTER TABLE PHIEU_DICH_VU ADD
    CONSTRAINT FK1_PDV_CN FOREIGN KEY (MaCN) REFERENCES CHI_NHANH(MaCN),
    CONSTRAINT FK2_PDV_NV FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV);

--KHACH_HANG
ALTER TABLE KHACH_HANG ADD
    CONSTRAINT FK1_KH_USER FOREIGN KEY (MaKH) REFERENCES [USER](MaUser);

--THU_CUNG
ALTER TABLE THU_CUNG ADD
    CONSTRAINT FK1_TC_KH FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH);

--TAI_KHOAN
ALTER TABLE TAI_KHOAN ADD
    CONSTRAINT FK1_TK_USER FOREIGN KEY (MaUser) REFERENCES [USER](MaUser);

--XEP_HANG_NAM
ALTER TABLE XEP_HANG_NAM ADD
    CONSTRAINT FK1_XHN_KH FOREIGN KEY (MaKH) REFERENCES KHACH_HANG(MaKH),
    CONSTRAINT FK2_XHN_HANG FOREIGN KEY (MaHang) REFERENCES HANG_TV(MaHang);

--HD_TRUC_TUYEN
ALTER TABLE HD_TRUC_TUYEN ADD
    CONSTRAINT FK1_HDTTUYEN_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu);

--HD_TRUC_TIEP
ALTER TABLE HD_TRUC_TIEP ADD
    CONSTRAINT FK1_HDTTIEP_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu),
    CONSTRAINT FK2_HDTTIEP_NV FOREIGN KEY (MaNV) REFERENCES NHAN_VIEN(MaNV);

-- PHIEU_KHAM_BENH
ALTER TABLE PHIEU_KHAM_BENH ADD
    CONSTRAINT FK1_PKB_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu),
    CONSTRAINT FK2_PKB_TC FOREIGN KEY (MaTC) REFERENCES THU_CUNG(MaTC);

-- THUOC
ALTER TABLE THUOC ADD
    CONSTRAINT FK1_THUOC_MH FOREIGN KEY (MaThuoc) REFERENCES MAT_HANG(MaMatHang);

-- CT_DON_THUOC
ALTER TABLE CT_DON_THUOC ADD
    CONSTRAINT FK1_CTDT_THUOC FOREIGN KEY (MaThuoc) REFERENCES THUOC(MaThuoc),
    CONSTRAINT FK2_CTDT_PKB FOREIGN KEY (MaPhieu) REFERENCES PHIEU_KHAM_BENH(MaPhieu);

-- SAN_PHAM_KHAC
ALTER TABLE SAN_PHAM_KHAC ADD
    CONSTRAINT FK1_SPK_MH FOREIGN KEY (MaSP) REFERENCES MAT_HANG(MaMatHang);

-- VACCINE
ALTER TABLE VACCINE ADD
    CONSTRAINT FK1_VC_MH FOREIGN KEY (MaVaccine) REFERENCES MAT_HANG(MaMatHang);

-- PHIEU_TIEM_VACCINE
ALTER TABLE PHIEU_TIEM_VACCINE ADD
    CONSTRAINT FK1_PTV_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu),
    CONSTRAINT FK2_PTV_TC FOREIGN KEY (MaTC) REFERENCES THU_CUNG(MaTC);

-- CT_TIEM_VC
ALTER TABLE CT_TIEM_VC ADD
    CONSTRAINT FK1_CTV_VC FOREIGN KEY (MaVaccine) REFERENCES VACCINE(MaVaccine),
    CONSTRAINT FK2_CTV_PTV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_TIEM_VACCINE(MaPhieu);

-- DANG_KI_GOI_TIEM
ALTER TABLE DANG_KI_GOI_TIEM ADD
    CONSTRAINT FK1_DK_PTV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_TIEM_VACCINE(MaPhieu),
    CONSTRAINT FK2_DK_VC FOREIGN KEY (MaVaccine) REFERENCES VACCINE(MaVaccine),
    CONSTRAINT FK3_DK_GOI FOREIGN KEY (MaGoi) REFERENCES GOI_TIEM_VC(MaGoi);

-- PHIEU_MUA_HANG
ALTER TABLE PHIEU_MUA_HANG ADD
    CONSTRAINT FK1_PMH_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu);

-- CT_MUA_HANG
ALTER TABLE CT_MUA_HANG ADD
    CONSTRAINT FK1_CTMH_PMH FOREIGN KEY (MaPhieu) REFERENCES PHIEU_MUA_HANG(MaPhieu),
    CONSTRAINT FK2_CTMH_MH FOREIGN KEY (MaMatHang) REFERENCES MAT_HANG(MaMatHang);

-- DANH_GIA_SP
ALTER TABLE DANH_GIA_SP ADD
    CONSTRAINT FK1_DGSP_CTMH FOREIGN KEY (MaPhieu,MaMatHang) REFERENCES CT_MUA_HANG(MaPhieu,MaMatHang);

-- DANH_GIA_DV
ALTER TABLE DANH_GIA_DV ADD
    CONSTRAINT FK1_DGDV_PDV FOREIGN KEY (MaPhieu) REFERENCES PHIEU_DICH_VU(MaPhieu);

--TON_KHO
ALTER TABLE TON_KHO ADD
    CONSTRAINT FK1_TK_CN FOREIGN KEY (MaCN) REFERENCES CHI_NHANH(MaCN),
    CONSTRAINT FK2_TK_MH FOREIGN KEY (MaMatHang) REFERENCES MAT_HANG(MaMatHang);
