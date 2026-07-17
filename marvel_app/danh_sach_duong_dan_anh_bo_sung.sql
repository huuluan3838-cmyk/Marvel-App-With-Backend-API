-- File helper: danh_sach_duong_dan_anh_bo_sung.sql
-- Mục đích: lưu đường dẫn ảnh để anh bổ sung file ảnh sau vào Flutter assets.
-- Vị trí copy ảnh trong Flutter:
-- D:\Flutter_DoAn\Nhom7_MarvelApp\marvel_app_Flutter\marvel_app\assets\images

USE MarvelTravelDB;
GO

-- ============================================================================
-- 1) DANH SÁCH FILE ẢNH CẦN TẠO TRONG FLUTTER
-- ============================================================================

-- Ảnh địa điểm chính: assets/images/
-- PhongNha.jpg
-- BaNaHills.jpg
-- MuCangChai.jpg
-- DaLat.jpg
-- SaPa.jpg
-- ConDao.jpg
-- TrangAn.jpg
-- PhuQuoc.jpg
-- HoiAnDem.jpg
-- VanMieu.jpg

-- Ảnh địa điểm chi tiết: assets/images/details/
-- TuanChau.jpg, ThienCung.jpg
-- ChoHoiAn.jpg, GomThanhHa.jpg
-- Datanla.jpg, TuyenLam.jpg
-- BauSau.jpg, ThacTroi.jpg
-- ThapRua.jpg, CauTheHuc.jpg
-- SonDoong.jpg, DongPhongNha.jpg, HangToi.jpg
-- CauVang.jpg, LangPhap.jpg
-- KhauPha.jpg, BanMu.jpg
-- XuanHuong.jpg, CauDat.jpg, DinhBaoDai.jpg
-- Fansipan.jpg, RuongSaPa.jpg, CatCat.jpg
-- DamTrau.jpg, NhaTuConDao.jpg
-- BaiDinh.jpg, HangMua.jpg, TamCoc.jpg
-- BaiSao.jpg, HamNinh.jpg, HonThom.jpg
-- SongHoaiDem.jpg, ChoDemHoiAn.jpg
-- KhueVanCac.jpg, BiaTienSi.jpg

-- Ảnh cẩm nang: assets/images/cam_nang/
-- XepDo.jpg, AnDuongPho.jpg, VeMayBay.jpg
-- Trekking.jpg, DacSanHaNoi.jpg
-- LanBienConDao.jpg, ChupAnhMuCang.jpg
-- PhuQuocTietKiem.jpg, CamTrai.jpg

-- Ảnh bài viết: assets/images/posts/
-- HaLong3N2D.jpg, HoiAnChill.jpg, Spam.jpg
-- TrekkingLangBiang.jpg, QuanAnDaLat.jpg
-- SonDoong.jpg, SaPaLuaVang.jpg, HomestayMuCang.jpg
-- ConDao4N3D.jpg, FansipanCapTreo.jpg, NinhBinhXeMay.jpg

-- ============================================================================
-- 2) TẠO BẢNG TẠM DANH MỤC ĐƯỜNG DẪN ẢNH ĐỂ TRA CỨU
-- ============================================================================

IF OBJECT_ID('DuongDanAnhBoSung', 'U') IS NULL
BEGIN
    CREATE TABLE DuongDanAnhBoSung (
        MaAnh INT IDENTITY(1,1) PRIMARY KEY,
        Nhom NVARCHAR(50) NOT NULL,
        TenFile NVARCHAR(255) NOT NULL,
        DuongDan VARCHAR(500) NOT NULL,
        GhiChu NVARCHAR(255) NULL,
        DaBoSungFile BIT DEFAULT 0
    );
END;
GO

DELETE FROM DuongDanAnhBoSung;
GO

INSERT INTO DuongDanAnhBoSung (Nhom, TenFile, DuongDan, GhiChu) VALUES
-- Địa điểm chính
(N'DiaDiem', N'PhongNha.jpg', 'assets/images/PhongNha.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'BaNaHills.jpg', 'assets/images/BaNaHills.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'MuCangChai.jpg', 'assets/images/MuCangChai.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'DaLat.jpg', 'assets/images/DaLat.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'SaPa.jpg', 'assets/images/SaPa.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'ConDao.jpg', 'assets/images/ConDao.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'TrangAn.jpg', 'assets/images/TrangAn.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'PhuQuoc.jpg', 'assets/images/PhuQuoc.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'HoiAnDem.jpg', 'assets/images/HoiAnDem.jpg', N'Ảnh địa điểm chính'),
(N'DiaDiem', N'VanMieu.jpg', 'assets/images/VanMieu.jpg', N'Ảnh địa điểm chính'),

-- Địa điểm chi tiết
(N'DiaDiemChiTiet', N'TuanChau.jpg', 'assets/images/details/TuanChau.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'ThienCung.jpg', 'assets/images/details/ThienCung.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'ChoHoiAn.jpg', 'assets/images/details/ChoHoiAn.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'GomThanhHa.jpg', 'assets/images/details/GomThanhHa.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'Datanla.jpg', 'assets/images/details/Datanla.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'TuyenLam.jpg', 'assets/images/details/TuyenLam.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'BauSau.jpg', 'assets/images/details/BauSau.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'ThacTroi.jpg', 'assets/images/details/ThacTroi.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'ThapRua.jpg', 'assets/images/details/ThapRua.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'CauTheHuc.jpg', 'assets/images/details/CauTheHuc.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'SonDoong.jpg', 'assets/images/details/SonDoong.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'DongPhongNha.jpg', 'assets/images/details/DongPhongNha.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'HangToi.jpg', 'assets/images/details/HangToi.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'CauVang.jpg', 'assets/images/details/CauVang.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'LangPhap.jpg', 'assets/images/details/LangPhap.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'KhauPha.jpg', 'assets/images/details/KhauPha.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'BanMu.jpg', 'assets/images/details/BanMu.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'XuanHuong.jpg', 'assets/images/details/XuanHuong.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'CauDat.jpg', 'assets/images/details/CauDat.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'DinhBaoDai.jpg', 'assets/images/details/DinhBaoDai.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'Fansipan.jpg', 'assets/images/details/Fansipan.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'RuongSaPa.jpg', 'assets/images/details/RuongSaPa.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'CatCat.jpg', 'assets/images/details/CatCat.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'DamTrau.jpg', 'assets/images/details/DamTrau.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'NhaTuConDao.jpg', 'assets/images/details/NhaTuConDao.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'BaiDinh.jpg', 'assets/images/details/BaiDinh.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'HangMua.jpg', 'assets/images/details/HangMua.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'TamCoc.jpg', 'assets/images/details/TamCoc.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'BaiSao.jpg', 'assets/images/details/BaiSao.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'HamNinh.jpg', 'assets/images/details/HamNinh.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'HonThom.jpg', 'assets/images/details/HonThom.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'SongHoaiDem.jpg', 'assets/images/details/SongHoaiDem.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'ChoDemHoiAn.jpg', 'assets/images/details/ChoDemHoiAn.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'KhueVanCac.jpg', 'assets/images/details/KhueVanCac.jpg', N'Ảnh chi tiết địa điểm'),
(N'DiaDiemChiTiet', N'BiaTienSi.jpg', 'assets/images/details/BiaTienSi.jpg', N'Ảnh chi tiết địa điểm'),

-- Cẩm nang
(N'CamNang', N'XepDo.jpg', 'assets/images/cam_nang/XepDo.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'AnDuongPho.jpg', 'assets/images/cam_nang/AnDuongPho.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'VeMayBay.jpg', 'assets/images/cam_nang/VeMayBay.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'Trekking.jpg', 'assets/images/cam_nang/Trekking.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'DacSanHaNoi.jpg', 'assets/images/cam_nang/DacSanHaNoi.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'LanBienConDao.jpg', 'assets/images/cam_nang/LanBienConDao.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'ChupAnhMuCang.jpg', 'assets/images/cam_nang/ChupAnhMuCang.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'PhuQuocTietKiem.jpg', 'assets/images/cam_nang/PhuQuocTietKiem.jpg', N'Ảnh cẩm nang'),
(N'CamNang', N'CamTrai.jpg', 'assets/images/cam_nang/CamTrai.jpg', N'Ảnh cẩm nang'),

-- Bài viết
(N'BaiViet', N'HaLong3N2D.jpg', 'assets/images/posts/HaLong3N2D.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'HoiAnChill.jpg', 'assets/images/posts/HoiAnChill.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'Spam.jpg', 'assets/images/posts/Spam.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'TrekkingLangBiang.jpg', 'assets/images/posts/TrekkingLangBiang.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'QuanAnDaLat.jpg', 'assets/images/posts/QuanAnDaLat.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'SonDoong.jpg', 'assets/images/posts/SonDoong.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'SaPaLuaVang.jpg', 'assets/images/posts/SaPaLuaVang.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'HomestayMuCang.jpg', 'assets/images/posts/HomestayMuCang.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'ConDao4N3D.jpg', 'assets/images/posts/ConDao4N3D.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'FansipanCapTreo.jpg', 'assets/images/posts/FansipanCapTreo.jpg', N'Ảnh bài viết'),
(N'BaiViet', N'NinhBinhXeMay.jpg', 'assets/images/posts/NinhBinhXeMay.jpg', N'Ảnh bài viết');
GO

SELECT * FROM DuongDanAnhBoSung ORDER BY Nhom, MaAnh;
GO

-- 1. Thêm Địa điểm chính (Quần đảo Hoàng Sa và Trường Sa)
INSERT INTO DiaDiem (TenDiaDiem, TinhThanh, MoTa, KinhDo, ViDo, HinhAnh, DanhGiaTrungBinh) VALUES 
(N'Quần đảo Hoàng Sa', N'Đà Nẵng', N'Quần đảo thiêng liêng của Tổ quốc, biểu tượng lịch sử và chủ quyền biển đảo không thể tách rời của Việt Nam.', 112.0000, 16.5000, 'assets/images/HoangSa.jpg', 5.0),
(N'Quần đảo Trường Sa', N'Khánh Hòa', N'Vùng lãnh hải máu thịt của Việt Nam, quần đảo kiên cường hiên ngang giữa Biển Đông.', 114.0000, 10.0000, 'assets/images/TruongSa.jpg', 5.0);
GO

select * from DiaDiemChiTiet
-- 2. Thêm Địa điểm chi tiết (Các đảo/thực thể trực thuộc)
-- LƯU Ý QUAN TRỌNG: Bạn cần kiểm tra lại MaDiaDiem của Hoàng Sa và Trường Sa vừa được tạo ra là số mấy (ví dụ 16, 17) để thay vào cột đầu tiên nhé, tránh bị lỗi Khóa ngoại (Foreign Key).
-- Ở đây mình đang giả sử Hoàng Sa có ID là 16, Trường Sa có ID là 17.
INSERT INTO DiaDiemChiTiet (MaDiaDiem, TenChiTiet, HinhAnh) VALUES 
-- Chi tiết Quần đảo Hoàng Sa (Giả sử MaDiaDiem = 16)
(16, N'Đảo Hoàng Sa', 'assets/images/details/DaoHoangSa.jpg'),
(16, N'Đảo Tri Tôn', 'assets/images/details/DaoTriTon.jpg'),
(16, N'Đảo Phú Lâm', 'assets/images/details/DaoPhuLam.jpg')

INSERT INTO DiaDiemChiTiet (MaDiaDiem, TenChiTiet, HinhAnh) VALUES
-- Chi tiết Quần đảo Trường Sa (Giả sử MaDiaDiem = 17)
(17, N'Đảo Trường Sa Lớn', 'assets/images/details/TruongSaLon.jpg'),
(17, N'Đảo Sinh Tồn', 'assets/images/details/DaoSinhTon.jpg'),
(17, N'Đảo Song Tử Tây', 'assets/images/details/SongTuTay.jpg'),
(17, N'Đảo Nam Yết', 'assets/images/details/DaoNamYet.jpg');