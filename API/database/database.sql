USE master;
GO

IF EXISTS (SELECT name FROM sys.databases WHERE name = N'MarvelTravelDB')
BEGIN
    ALTER DATABASE MarvelTravelDB SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
    DROP DATABASE MarvelTravelDB;
END
GO

CREATE DATABASE MarvelTravelDB;
GO
USE MarvelTravelDB;
GO

-- ==============================================================================
-- PHẦN 1: TẠO BẢNG (TABLES) - ĐÃ SẮP XẾP CHUẨN THỨ TỰ KHÓA NGOẠI
-- ==============================================================================

-- 1. Bảng Vai trò (RBAC)
CREATE TABLE VaiTro (
    MaVaiTro INT IDENTITY(1,1) PRIMARY KEY,
    TenVaiTro VARCHAR(20) NOT NULL UNIQUE,
    MoTa NVARCHAR(255),
    NgayTao DATETIME DEFAULT GETDATE()
);

-- 2. Bảng Quyền (RBAC)
CREATE TABLE Quyen (
    MaQuyen INT IDENTITY(1,1) PRIMARY KEY,
    MaQuyenCode VARCHAR(100) NOT NULL UNIQUE,
    TenQuyen NVARCHAR(150) NOT NULL,
    MoTa NVARCHAR(255),
    NgayTao DATETIME DEFAULT GETDATE()
);

-- 3. Bảng Vai trò - Quyền (RBAC)
CREATE TABLE VaiTroQuyen (
    MaVaiTro INT NOT NULL,
    MaQuyen INT NOT NULL,
    NgayGan DATETIME DEFAULT GETDATE(),
    PRIMARY KEY (MaVaiTro, MaQuyen),
    CONSTRAINT FK_VaiTroQuyen_VaiTro FOREIGN KEY (MaVaiTro) REFERENCES VaiTro(MaVaiTro) ON DELETE CASCADE,
    CONSTRAINT FK_VaiTroQuyen_Quyen FOREIGN KEY (MaQuyen) REFERENCES Quyen(MaQuyen) ON DELETE CASCADE
);

-- 4. Bảng Người dùng
CREATE TABLE NguoiDung (
    MaNguoiDung INT IDENTITY(1,1) PRIMARY KEY,
    HoTen NVARCHAR(100) NOT NULL,
    Email VARCHAR(255) UNIQUE NOT NULL,
    SoDienThoai VARCHAR(20) UNIQUE,
    MatKhau VARCHAR(255) NOT NULL,
    -- Đã bổ sung 'Moderator' vào Check Constraint
    VaiTro VARCHAR(20) DEFAULT 'User' CHECK (VaiTro IN ('Admin', 'User', 'Moderator')), 
    AnhDaiDien VARCHAR(500),
    NgayTao DATETIME DEFAULT GETDATE(),
    CONSTRAINT FK_NguoiDung_VaiTro FOREIGN KEY (VaiTro) REFERENCES VaiTro(TenVaiTro)
);

-- 5. Bảng Địa điểm chính
CREATE TABLE DiaDiem (
    MaDiaDiem INT IDENTITY(1,1) PRIMARY KEY,
    TenDiaDiem NVARCHAR(200) NOT NULL,
    TinhThanh NVARCHAR(100) NOT NULL,
    MoTa NVARCHAR(MAX),
    KinhDo FLOAT NOT NULL,
    ViDo FLOAT NOT NULL,
    HinhAnh VARCHAR(500),
    DanhGiaTrungBinh FLOAT DEFAULT 5.0,
    NgayTao DATETIME DEFAULT GETDATE()
);

-- 6. Bảng Địa điểm chi tiết
CREATE TABLE DiaDiemChiTiet (
    MaChiTiet INT IDENTITY(1,1) PRIMARY KEY,
    MaDiaDiem INT FOREIGN KEY REFERENCES DiaDiem(MaDiaDiem) ON DELETE CASCADE,
    TenChiTiet NVARCHAR(200) NOT NULL,
    HinhAnh VARCHAR(500)
);

-- 7. Bảng Lịch trình
CREATE TABLE LichTrinh (
    MaLichTrinh INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    TieuDe NVARCHAR(255) NOT NULL,
    DanhSachDiaDiem NVARCHAR(MAX), 
    NgayBatDau DATE NOT NULL,
    NgayKetThuc DATE NOT NULL,
    PhongCach NVARCHAR(100),
    SoNguoi INT DEFAULT 1,
    TrangThai VARCHAR(50) DEFAULT 'Upcoming' CHECK (TrangThai IN ('Upcoming', 'Past'))
);

-- 8. Bảng Bài viết
CREATE TABLE BaiViet (
    MaBaiViet INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    TieuDe NVARCHAR(255) NOT NULL,
    NoiDung NVARCHAR(MAX) NOT NULL,
    TheLoai NVARCHAR(100),
    HinhAnh VARCHAR(500),
    TrangThai VARCHAR(50) DEFAULT 'Pending' CHECK (TrangThai IN ('Pending', 'Approved', 'Reported', 'Hidden')),
    NgayDang DATETIME DEFAULT GETDATE()
);

-- 9. Bảng Tương tác (Like)
CREATE TABLE LuotThichBaiViet (
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung),
    MaBaiViet INT FOREIGN KEY REFERENCES BaiViet(MaBaiViet) ON DELETE CASCADE,
    NgayThich DATETIME DEFAULT GETDATE(),
    PRIMARY KEY(MaNguoiDung, MaBaiViet)
);

-- 10. Bảng Bình luận
CREATE TABLE BinhLuan (
    MaBinhLuan INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiViet INT FOREIGN KEY REFERENCES BaiViet(MaBaiViet) ON DELETE CASCADE,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE NO ACTION,
    NoiDung NVARCHAR(MAX) NOT NULL,
    NgayBinhLuan DATETIME DEFAULT GETDATE()
);

-- 11. Bảng Báo cáo
CREATE TABLE BaoCao (
    MaBaoCao INT IDENTITY(1,1) PRIMARY KEY,
    MaBaiViet INT FOREIGN KEY REFERENCES BaiViet(MaBaiViet) ON DELETE CASCADE,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE NO ACTION,
    LyDo NVARCHAR(255) NOT NULL,
    NgayBaoCao DATETIME DEFAULT GETDATE()
);

-- 12. Bảng Cẩm nang
CREATE TABLE CamNang (
    MaCamNang INT IDENTITY(1,1) PRIMARY KEY,
    TieuDe NVARCHAR(255) NOT NULL,
    TheLoai NVARCHAR(100),
    NoiDung NVARCHAR(MAX) NOT NULL,
    HinhAnh VARCHAR(500),
    ThoiGianDoc NVARCHAR(50),
    LuotThich INT DEFAULT 0
);

-- 13. Bảng Đánh giá
CREATE TABLE DanhGia (
    MaDanhGia INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    MaDiaDiem INT FOREIGN KEY REFERENCES DiaDiem(MaDiaDiem) ON DELETE CASCADE,
    SoSao FLOAT CHECK (SoSao BETWEEN 1 AND 5),
    NoiDung NVARCHAR(MAX),
    NgayTao DATETIME DEFAULT GETDATE()
);

-- 14. Bảng Yêu thích (Bookmarks)
CREATE TABLE Bookmarks (
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    MaDiaDiem INT FOREIGN KEY REFERENCES DiaDiem(MaDiaDiem) ON DELETE CASCADE,
    NgayLuu DATETIME DEFAULT GETDATE(),
    PRIMARY KEY(MaNguoiDung, MaDiaDiem)
);

-- 15. Bảng Yêu cầu hỗ trợ
CREATE TABLE YeuCauHoTro (
    MaYeuCau INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    LoaiYeuCau NVARCHAR(100),
    TieuDe NVARCHAR(255),
    NoiDung NVARCHAR(MAX),
    TrangThai VARCHAR(20) DEFAULT 'Open',
    NgayGui DATETIME DEFAULT GETDATE()
);

-- 16. Bảng Thông báo
CREATE TABLE ThongBao (
    MaThongBao INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT FOREIGN KEY REFERENCES NguoiDung(MaNguoiDung) ON DELETE CASCADE,
    TieuDe NVARCHAR(200),
    NoiDung NVARCHAR(500),
    DaDoc BIT DEFAULT 0,
    NgayTao DATETIME DEFAULT GETDATE()
);
GO

-- ==============================================================================
-- PHẦN 2: THỦ TỤC LƯU TRỮ (PROCEDURES) & HÀM (FUNCTIONS) & VIEW
-- ==============================================================================

CREATE PROCEDURE sp_DangNhap
    @Email VARCHAR(255),
    @MatKhau VARCHAR(255)
AS
BEGIN
    SELECT MaNguoiDung, HoTen, Email, SoDienThoai, MatKhau, VaiTro, AnhDaiDien, NgayTao
    FROM NguoiDung 
    WHERE Email = @Email AND MatKhau = @MatKhau;
END;
GO

CREATE PROCEDURE sp_DuyetBaiViet
    @MaBaiViet INT
AS
BEGIN
    UPDATE BaiViet 
    SET TrangThai = 'Approved' 
    WHERE MaBaiViet = @MaBaiViet AND TrangThai = 'Pending';
END;
GO

CREATE PROCEDURE sp_BaoCaoBaiViet
    @MaBaiViet INT,
    @MaNguoiDung INT,
    @LyDo NVARCHAR(255)
AS
BEGIN
    INSERT INTO BaoCao (MaBaiViet, MaNguoiDung, LyDo)
    VALUES (@MaBaiViet, @MaNguoiDung, @LyDo);
    
    UPDATE BaiViet SET TrangThai = 'Reported' WHERE MaBaiViet = @MaBaiViet;
END;
GO

CREATE PROCEDURE sp_KiemTraQuyen
    @MaNguoiDung INT,
    @MaQuyenCode VARCHAR(100)
AS
BEGIN
    SET NOCOUNT ON;
    SELECT CAST(CASE WHEN EXISTS (
        SELECT 1
        FROM NguoiDung nd
        JOIN VaiTro vt ON vt.TenVaiTro = nd.VaiTro
        JOIN VaiTroQuyen vtq ON vtq.MaVaiTro = vt.MaVaiTro
        JOIN Quyen q ON q.MaQuyen = vtq.MaQuyen
        WHERE nd.MaNguoiDung = @MaNguoiDung
          AND q.MaQuyenCode = @MaQuyenCode
    ) THEN 1 ELSE 0 END AS BIT) AS CoQuyen;
END;
GO

CREATE FUNCTION fn_DemLuotThichBaiViet (@MaBaiViet INT)
RETURNS INT
AS
BEGIN
    RETURN (SELECT COUNT(*) FROM LuotThichBaiViet WHERE MaBaiViet = @MaBaiViet);
END;
GO

CREATE FUNCTION fn_TinhDiemTrungBinhDiaDiem (@MaDiaDiem INT)
RETURNS FLOAT
AS
BEGIN
    DECLARE @Diem FLOAT;
    SELECT @Diem = AVG(SoSao) FROM DanhGia WHERE MaDiaDiem = @MaDiaDiem;
    RETURN ISNULL(@Diem, 5.0);
END;
GO

CREATE VIEW vw_NguoiDung_Quyen
AS
SELECT 
    nd.MaNguoiDung, 
    nd.HoTen, 
    nd.Email, 
    nd.VaiTro, 
    q.MaQuyenCode, 
    q.TenQuyen
FROM NguoiDung nd
JOIN VaiTro vt ON vt.TenVaiTro = nd.VaiTro
JOIN VaiTroQuyen vtq ON vtq.MaVaiTro = vt.MaVaiTro
JOIN Quyen q ON q.MaQuyen = vtq.MaQuyen;
GO

-- ==============================================================================
-- PHẦN 3: DỮ LIỆU MẪU (TEST DATA)
-- ==============================================================================

-- 1. Seed Roles
INSERT INTO VaiTro (TenVaiTro, MoTa) VALUES 
('Admin', N'Quản trị viên toàn hệ thống'),
('User', N'Người dùng thông thường'),
('Moderator', N'Người kiểm duyệt nội dung');

-- 2. Seed Permissions
INSERT INTO Quyen (MaQuyenCode, TenQuyen, MoTa) VALUES
('auth.login', N'Đăng nhập', N'Cho phép đăng nhập hệ thống'),
('auth.register', N'Đăng ký', N'Cho phép tạo tài khoản'),
('diadiem.read', N'Xem địa điểm', N'Xem danh sách và chi tiết địa điểm'),
('bookmark.manage_own', N'Quản lý bookmark cá nhân', N'Thêm/xóa địa điểm yêu thích của chính mình'),
('lichtrinh.manage_own', N'Quản lý lịch trình cá nhân', N'Tạo và xem lịch trình của chính mình'),
('baiviet.read_approved', N'Xem bài viết đã duyệt', N'Xem bài viết cộng đồng đã được duyệt'),
('baiviet.create', N'Tạo bài viết', N'Tạo bài viết chờ kiểm duyệt'),
('baiviet.like', N'Thích bài viết', N'Thích hoặc bỏ thích bài viết'),
('baiviet.report', N'Báo cáo bài viết', N'Báo cáo bài viết vi phạm'),
('baiviet.read_all', N'Xem tất cả bài viết', N'Quyền quản trị xem cả Pending/Reported/Hidden'),
('baiviet.approve', N'Duyệt bài viết', N'Duyệt bài viết Pending thành Approved'),
('baiviet.hide', N'Ẩn bài viết', N'Ẩn bài viết vi phạm'),
('user.manage', N'Quản lý người dùng', N'Quản trị tài khoản người dùng'),
('report.manage', N'Quản lý báo cáo', N'Xử lý báo cáo vi phạm');

-- 3. Cấp quyền cho User
INSERT INTO VaiTroQuyen (MaVaiTro, MaQuyen)
SELECT vt.MaVaiTro, q.MaQuyen FROM VaiTro vt JOIN Quyen q ON q.MaQuyenCode IN (
    'auth.login','auth.register','diadiem.read','bookmark.manage_own',
    'lichtrinh.manage_own','baiviet.read_approved','baiviet.create',
    'baiviet.like','baiviet.report'
) WHERE vt.TenVaiTro = 'User';

-- 4. Cấp quyền cho Moderator
INSERT INTO VaiTroQuyen (MaVaiTro, MaQuyen)
SELECT vt.MaVaiTro, q.MaQuyen FROM VaiTro vt JOIN Quyen q ON q.MaQuyenCode IN (
    'auth.login','diadiem.read','bookmark.manage_own','lichtrinh.manage_own',
    'baiviet.read_approved','baiviet.create','baiviet.like','baiviet.report',
    'baiviet.read_all','baiviet.approve','baiviet.hide','report.manage'
) WHERE vt.TenVaiTro = 'Moderator';

-- 5. Cấp quyền cho Admin
INSERT INTO VaiTroQuyen (MaVaiTro, MaQuyen)
SELECT vt.MaVaiTro, q.MaQuyen FROM VaiTro vt CROSS JOIN Quyen q WHERE vt.TenVaiTro = 'Admin';

-- 6. Seed Users (Gộp 8 người)
INSERT INTO NguoiDung (HoTen, Email, SoDienThoai, MatKhau, VaiTro) VALUES 
(N'Quản trị viên', 'admin@marvel.vn', '0900000001', '123456', 'Admin'),
(N'Nguyễn Trường Như', 'nhu.nguyen@gmail.com', '0900000002', '123456', 'User'),
(N'Trần Minh Hải', 'hai.tran@gmail.com', '0900000003', '123456', 'User'),
(N'Lê Yến Nhi', 'nhi.le@gmail.com', '0900000004', '123456', 'User'),
(N'Phạm Tuấn Anh', 'anh.pham@gmail.com', '0900000005', '123456', 'User'),
(N'Đinh Thị Lan', 'lan.dinh@gmail.com', '0900000006', '123456', 'User'),
(N'Võ Minh Khoa', 'khoa.vo@gmail.com', '0900000007', '123456', 'User'),
(N'Nguyễn Bảo Châu', 'chau.nguyen@gmail.com', '0900000008', '123456', 'Moderator');

-- 7. Seed Địa Điểm Chính (Gộp 15 địa điểm)
INSERT INTO DiaDiem (TenDiaDiem, TinhThanh, MoTa, KinhDo, ViDo, HinhAnh, DanhGiaTrungBinh) VALUES 
(N'Vịnh Hạ Long', N'Quảng Ninh', N'Kỳ quan thiên nhiên thế giới, vùng biển tuyệt đẹp.', 107.1839, 20.9101, 'assets/images/VinhHaLong.jpg', 5.0),
(N'Phố Cổ Hội An', N'Quảng Nam', N'Thương cảng cổ kính, mang đậm nét kiến trúc truyền thống.', 108.3380, 15.8801, 'assets/images/PhoCoHoiAn.jpg', 5.0),
(N'Đỉnh Lang Biang', N'Lâm Đồng', N'Nóc nhà Đà Lạt, lý tưởng cho các hoạt động trekking.', 108.4289, 12.0464, 'assets/images/LangBiang.jpg', 5.0),
(N'Vườn Quốc Gia Nam Cát Tiên', N'Đồng Nai', N'Khu bảo tồn sinh quyển đa dạng.', 107.4267, 11.4251, 'assets/images/NamCatTien.jpg', 5.0),
(N'Hồ Hoàn Kiếm', N'Hà Nội', N'Trái tim thủ đô ngàn năm văn hiến.', 105.8523, 21.0285, 'assets/images/HoHoanKiem.jpg', 5.0),
(N'Hang Phong Nha', N'Quảng Bình', N'Hệ thống hang động kỳ vĩ, Di sản UNESCO.', 106.2891, 17.5596, 'assets/images/PhongNha.jpg', 4.9),
(N'Bà Nà Hills', N'Đà Nẵng', N'Khu du lịch núi cao với Cầu Vàng biểu tượng.', 107.9985, 15.9981, 'assets/images/BaNaHills.jpg', 4.7),
(N'Mù Cang Chải', N'Yên Bái', N'Thửa ruộng bậc thang vàng óng mùa gặt.', 104.0833, 21.8167, 'assets/images/MuCangChai.jpg', 4.8),
(N'Thành phố Đà Lạt', N'Lâm Đồng', N'Thành phố ngàn hoa, sương mù lãng mạn.', 108.4583, 11.9404, 'assets/images/DaLat.jpg', 4.8),
(N'Sa Pa', N'Lào Cai', N'Thị trấn núi cao sát mây, ruộng bậc thang.', 103.8438, 22.3364, 'assets/images/SaPa.jpg', 4.9),
(N'Côn Đảo', N'Bà Rịa – Vũng Tàu', N'Đảo nguyên sinh hoang sơ, lịch sử hào hùng.', 106.6167, 8.6833, 'assets/images/ConDao.jpg', 4.9),
(N'Tràng An – Bái Đính', N'Ninh Bình', N'Quần thể danh thắng núi non sông nước.', 105.9000, 20.2167, 'assets/images/TrangAn.jpg', 4.8),
(N'Phú Quốc', N'Kiên Giang', N'Đảo ngọc nhiệt đới, thiên đường nghỉ dưỡng.', 103.9869, 10.2899, 'assets/images/PhuQuoc.jpg', 4.9),
(N'Phố Đêm Hội An', N'Quảng Nam', N'Hội An về đêm lung linh đèn lồng.', 108.3274, 15.8795, 'assets/images/HoiAnDem.jpg', 4.7),
(N'Văn Miếu – Quốc Tử Giám', N'Hà Nội', N'Trường đại học đầu tiên của Việt Nam.', 105.8355, 21.0266, 'assets/images/VanMieu.jpg', 4.7);

-- 8. Seed Địa Điểm Chi Tiết (Gộp toàn bộ)
INSERT INTO DiaDiemChiTiet (MaDiaDiem, TenChiTiet, HinhAnh) VALUES 
(1, N'Đảo Ti Tốp', 'assets/images/details/titop.jpg'),
(1, N'Hang Sửng Sốt', 'assets/images/details/sungsot.jpg'),
(1, N'Đảo Tuần Châu', 'assets/images/details/TuanChau.jpg'),
(1, N'Hang Thiên Cung', 'assets/images/details/ThienCung.jpg'),
(2, N'Chùa Cầu', 'assets/images/details/chuacau.jpg'),
(2, N'Chợ Hội An', 'assets/images/details/ChoHoiAn.jpg'),
(2, N'Làng gốm Thanh Hà', 'assets/images/details/GomThanhHa.jpg'),
(3, N'Đồi Radar', 'assets/images/details/radar.jpg'),
(3, N'Thác Datanla', 'assets/images/details/Datanla.jpg'),
(3, N'Hồ Tuyền Lâm', 'assets/images/details/TuyenLam.jpg'),
(4, N'Bàu Sấu', 'assets/images/details/BauSau.jpg'),
(4, N'Thác Trời', 'assets/images/details/ThacTroi.jpg'),
(5, N'Đền Ngọc Sơn', 'assets/images/details/ngocson.jpg'),
(5, N'Tháp Rùa', 'assets/images/details/ThapRua.jpg'),
(5, N'Cầu Thê Húc', 'assets/images/details/CauTheHuc.jpg'),
(6, N'Hang Sơn Đoòng', 'assets/images/details/SonDoong.jpg'),
(6, N'Động Phong Nha', 'assets/images/details/DongPhongNha.jpg'),
(6, N'Hang Tối', 'assets/images/details/HangToi.jpg'),
(7, N'Cầu Vàng Golden Bridge', 'assets/images/details/CauVang.jpg'),
(7, N'Làng Pháp Bà Nà', 'assets/images/details/LangPhap.jpg'),
(8, N'Đèo Khau Phạ', 'assets/images/details/KhauPha.jpg'),
(8, N'Bản Mù Ruộng Bậc Thang', 'assets/images/details/BanMu.jpg'),
(9, N'Hồ Xuân Hương', 'assets/images/details/XuanHuong.jpg'),
(9, N'Đồi Chè Cầu Đất', 'assets/images/details/CauDat.jpg'),
(9, N'Dinh Bảo Đại', 'assets/images/details/DinhBaoDai.jpg'),
(10, N'Đỉnh Fansipan', 'assets/images/details/Fansipan.jpg'),
(10, N'Ruộng Bậc Thang Sa Pa', 'assets/images/details/RuongSaPa.jpg'),
(10, N'Bản Cát Cát', 'assets/images/details/CatCat.jpg'),
(11, N'Bãi Đầm Trầu', 'assets/images/details/DamTrau.jpg'),
(11, N'Nhà Tù Côn Đảo', 'assets/images/details/NhaTuConDao.jpg'),
(12, N'Chùa Bái Đính', 'assets/images/details/BaiDinh.jpg'),
(12, N'Hang Múa – Mua Cave', 'assets/images/details/HangMua.jpg'),
(12, N'Tam Cốc Bích Động', 'assets/images/details/TamCoc.jpg'),
(13, N'Bãi Sao', 'assets/images/details/BaiSao.jpg'),
(13, N'Làng Chài Hàm Ninh', 'assets/images/details/HamNinh.jpg'),
(13, N'Cáp Treo Hòn Thơm', 'assets/images/details/HonThom.jpg'),
(14, N'Sông Hoài về đêm', 'assets/images/details/SongHoaiDem.jpg'),
(14, N'Chợ Đêm Hội An', 'assets/images/details/ChoDemHoiAn.jpg'),
(15, N'Khuê Văn Các', 'assets/images/details/KhueVanCac.jpg'),
(15, N'Bia Tiến Sĩ', 'assets/images/details/BiaTienSi.jpg');

-- 9. Seed Cẩm Nang (Đã gộp đường dẫn ảnh gốc)
INSERT INTO CamNang (TieuDe, TheLoai, NoiDung, ThoiGianDoc, LuotThich, HinhAnh) VALUES 
(N'Bí kíp xếp đồ cực gọn', N'Chuẩn bị', N'Học cách cuộn quần áo...', '5 phút đọc', 342, 'assets/images/cam_nang/XepDo.jpg'),
(N'Top 10 món ăn đường phố Hội An', N'Ẩm thực', N'Từ Cao Lầu, Mì Quảng...', '7 phút đọc', 890, 'assets/images/cam_nang/AnDuongPho.jpg'),
(N'Mẹo săn vé máy bay giá rẻ', N'Mẹo vặt', N'Thời điểm vàng để đặt vé...', '4 phút đọc', 156, 'assets/images/cam_nang/VeMayBay.jpg'),
(N'Cẩm nang trekking Lang Biang', N'Trải nghiệm', N'Chuẩn bị thể lực, dụng cụ...', '10 phút đọc', 512, 'assets/images/cam_nang/Trekking.jpg'),
(N'Lịch trình 1 ngày càn quét Hà Nội', N'Ẩm thực', N'Sáng phở bò, trưa bún chả...', '6 phút đọc', 430, 'assets/images/cam_nang/DacSanHaNoi.jpg'),
(N'Kinh nghiệm lặn biển Côn Đảo', N'Trải nghiệm', N'Tất tần tật từ chọn tour...', '8 phút đọc', 278, 'assets/images/cam_nang/LanBienConDao.jpg'),
(N'Chụp ảnh ruộng bậc thang', N'Nhiếp ảnh', N'Thời điểm vàng, góc máy ảnh...', '6 phút đọc', 614, 'assets/images/cam_nang/ChupAnhMuCang.jpg'),
(N'Du lịch Phú Quốc tự túc', N'Mẹo vặt', N'Thuê xe máy, ở homestay...', '9 phút đọc', 752, 'assets/images/cam_nang/PhuQuocTietKiem.jpg'),
(N'Top 5 điểm cắm trại đẹp nhất', N'Chuẩn bị', N'Từ núi cao đến ven biển...', '7 phút đọc', 489, 'assets/images/cam_nang/CamTrai.jpg');

-- 10. Seed Bài Viết (Gộp 11 bài với ảnh chuẩn)
INSERT INTO BaiViet (MaNguoiDung, TieuDe, NoiDung, TheLoai, TrangThai, HinhAnh) VALUES 
(2, N'Review chi tiết chuyến đi Hạ Long 3N2Đ', N'Chuyến đi quá tuyệt vời...', N'Review', 'Approved', 'assets/images/posts/HaLong3N2D.jpg'),
(3, N'Góc sống ảo cực chill tại Hội An', N'Hoàng hôn ở Hội An bao đỉnh...', N'Check-in', 'Approved', 'assets/images/posts/HoiAnChill.jpg'),
(4, N'Click link nhận voucher Vinpearl 10tr', N'Truy cập ngay link này để nhận...', N'Khác', 'Reported', 'assets/images/posts/Spam.jpg'),
(5, N'Kinh nghiệm trekking Lang Biang', N'Đường đi không quá khó...', N'Kinh nghiệm', 'Pending', 'assets/images/posts/TrekkingLangBiang.jpg'),
(2, N'Quán ăn ngon rẻ ở Đà Lạt', N'Mọi người thử ghé quán...', N'Ẩm thực', 'Pending', 'assets/images/posts/QuanAnDaLat.jpg'),
(3, N'Chinh phục Sơn Đoòng – hành trình', N'Sau 7 ngày xuyên qua hệ thống...', N'Review', 'Approved', 'assets/images/posts/SonDoong.jpg'),
(6, N'Sa Pa tháng 9 – mùa lúa vàng rực rỡ', N'Đừng bỏ lỡ khoảng thời gian...', N'Check-in', 'Approved', 'assets/images/posts/SaPaLuaVang.jpg'),
(7, N'Review homestay view núi tuyệt đẹp', N'Ngủ dậy nhìn ra cửa sổ...', N'Review', 'Approved', 'assets/images/posts/HomestayMuCang.jpg'),
(4, N'Côn Đảo 4 ngày 3 đêm', N'Không ồn ào, không đông đúc...', N'Review', 'Approved', 'assets/images/posts/ConDao4N3D.jpg'),
(8, N'Bí kíp đặt vé cáp treo Fansipan', N'Đặt trước 2 tuần qua app...', N'Kinh nghiệm', 'Pending', 'assets/images/posts/FansipanCapTreo.jpg'),
(6, N'Hành trình Ninh Bình 2 ngày xe máy', N'Thuê xe từ Hà Nội, chạy thẳng...', N'Kinh nghiệm', 'Approved', 'assets/images/posts/NinhBinhXeMay.jpg');

-- 11. Seed Lịch Trình (Gộp 10 lịch)
INSERT INTO LichTrinh (MaNguoiDung, TieuDe, DanhSachDiaDiem, NgayBatDau, NgayKetThuc, PhongCach, SoNguoi, TrangThai) VALUES 
(2, N'Khám phá kỳ quan vịnh biển', N'Vịnh Hạ Long, Đảo Ti Tốp', '2026-08-15', '2026-08-18', N'Nghỉ dưỡng', 2, 'Upcoming'),
(3, N'Check-in Phố Cổ Hội An', N'Phố Cổ Hội An, Chợ đêm', '2026-09-01', '2026-09-03', N'Văn hóa', 4, 'Upcoming'),
(4, N'Trekking mạo hiểm', N'Đỉnh Lang Biang, Thác Datanla', '2026-07-20', '2026-07-22', N'Khám phá', 6, 'Upcoming'),
(2, N'Về với thiên nhiên', N'Vườn Quốc Gia Nam Cát Tiên', '2026-05-10', '2026-05-12', N'Khám phá', 2, 'Past'),
(5, N'Food tour Hà Nội', N'Hồ Hoàn Kiếm, Phố cổ', '2026-10-05', '2026-10-07', N'Tiết kiệm', 1, 'Upcoming'),
(6, N'Khám phá hang động Phong Nha', N'Hang Phong Nha, Hang Sơn Đoòng', '2026-09-10', '2026-09-13', N'Khám phá', 3, 'Upcoming'),
(7, N'Nghỉ dưỡng Phú Quốc', N'Phú Quốc, Bãi Sao', '2026-08-20', '2026-08-24', N'Nghỉ dưỡng', 2, 'Upcoming'),
(3, N'Săn mây Sa Pa – Mù Cang', N'Sa Pa, Đỉnh Fansipan', '2026-10-01', '2026-10-05', N'Khám phá', 2, 'Upcoming'),
(4, N'City tour Hà Nội 2 ngày', N'Hồ Hoàn Kiếm, Văn Miếu', '2026-07-12', '2026-07-13', N'Văn hóa', 4, 'Upcoming'),
(8, N'Trekking Côn Đảo hoang dã', N'Côn Đảo, Bãi Đầm Trầu', '2026-06-25', '2026-06-28', N'Khám phá', 5, 'Upcoming');

-- 12. Seed Lượt Thích
INSERT INTO LuotThichBaiViet (MaNguoiDung, MaBaiViet) VALUES 
(2, 2), (3, 1), (4, 1), (5, 2), (2, 4),
(2, 6), (4, 6), (7, 6), (8, 6),
(3, 7), (5, 7), (6, 7),
(2, 8), (3, 8), (4, 8), (5, 8), (6, 8),
(3, 9), (7, 9), (8, 9),
(2, 11),(4, 11),(6, 11);

-- 13. Seed Bình Luận
INSERT INTO BinhLuan (MaBaiViet, MaNguoiDung, NoiDung) VALUES 
(1, 3, N'Bài viết rất chi tiết, cảm ơn bạn!'),
(1, 4, N'Mình xin infor khách sạn bạn ở với.'),
(2, 2, N'Góc chụp đẹp quá.'),
(2, 5, N'Xin địa chỉ quán cafe này ạ.'),
(4, 3, N'Đường dốc không bạn ơi?'),
(6, 2, N'Ước gì mình có tiền đi Sơn Đoòng một lần!'),
(6, 5, N'Bạn có thể share tên tour không?'),
(7, 4, N'Mình đặt vé tháng 10 rồi, quá hóng!'),
(8, 3, N'Địa chỉ homestay bạn ở là gì vậy?'),
(8, 7, N'350k/đêm mà view đẹp vậy, không tin nổi.'),
(9, 6, N'Côn Đảo yên tĩnh thật, mình vừa về tuần trước.'),
(11, 2, N'Cung đường này đi không thuê xe ôm được không?'),
(11, 5, N'Bái Đính hơi thương mại hóa nhưng vẫn đẹp lắm.');

-- 14. Seed Đánh Giá
INSERT INTO DanhGia (MaNguoiDung, MaDiaDiem, SoSao, NoiDung) VALUES 
(2, 1, 5.0, N'Cảnh quan hùng vĩ, dịch vụ du thuyền rất tốt.'),
(3, 2, 4.5, N'Phố cổ đẹp nhưng cuối tuần hơi đông đúc.'),
(4, 3, 5.0, N'Trải nghiệm tuyệt vời, không khí trong lành.'),
(5, 4, 4.0, N'Nhiều muỗi, cần mang thuốc chống côn trùng.'),
(2, 5, 5.0, N'Rất yên bình khi đi dạo vào sáng sớm.'),
(3, 6, 5.0, N'Sơn Đoòng không có gì có thể diễn tả hết.'),
(4, 7, 4.5, N'Cầu Vàng rất đẹp nhưng buổi chiều hay bị sương mù.'),
(5, 8, 5.0, N'Mùa lúa chín tháng 9 đẹp mê hồn, nhớ mang máy ảnh xịn.'),
(6, 9, 4.8, N'Đà Lạt se lạnh rất dễ chịu, cà phê ngon.'),
(7, 10, 5.0, N'Fansipan lên bằng cáp treo vẫn rất đáng.'),
(2, 11, 5.0, N'Côn Đảo yên bình, nước biển trong vắt.'),
(3, 12, 4.7, N'Tràng An chèo thuyền qua hang động rất thư giãn.'),
(8, 13, 4.9, N'Phú Quốc bây giờ nhiều resort đẹp.'),
(6, 14, 4.6, N'Hội An về đêm thả đèn hoa đăng rất lãng mạn.'),
(7, 15, 4.5, N'Văn Miếu yên tĩnh, phù hợp tham quan sáng sớm.');

-- 15. Cập nhật Điểm Đánh Giá Trung Bình
UPDATE DiaDiem SET DanhGiaTrungBinh = dbo.fn_TinhDiemTrungBinhDiaDiem(MaDiaDiem);

-- 16. Seed Báo Cáo
INSERT INTO BaoCao (MaBaiViet, MaNguoiDung, LyDo) VALUES 
(3, 2, N'Spam hoặc lừa đảo'),
(3, 3, N'Chứa đường dẫn không an toàn'),
(3, 4, N'Thông tin lừa đảo'),
(3, 5, N'Quảng cáo rác'),
(1, 5, N'Vi phạm bản quyền hình ảnh');

-- 17. Seed Bookmarks
INSERT INTO Bookmarks (MaNguoiDung, MaDiaDiem) VALUES 
(2, 1), (2, 2), (3, 3), (4, 4), (5, 5),
(2, 6), (2, 10), (2, 13), (3, 7), (3, 11),
(4, 8), (4, 12), (5, 9), (5, 13), (6, 1),
(6, 10), (7, 6), (7, 11), (8, 7), (8, 14);

-- 18. Seed Yêu Cầu Hỗ Trợ
INSERT INTO YeuCauHoTro (MaNguoiDung, LoaiYeuCau, TieuDe, NoiDung, TrangThai) VALUES 
(2, N'Hỗ trợ kỹ thuật', N'Lỗi tải ảnh', N'App bị văng khi tải ảnh lên', 'Open'),
(3, N'Góp ý ứng dụng', N'Thêm tính năng chat', N'Mong app có phần nhắn tin', 'Open'),
(4, N'Vấn đề tài khoản', N'Không nhận được OTP', N'Tôi đã bấm gửi lại 3 lần', 'Resolved'),
(5, N'Báo cáo vi phạm', N'User mạo danh', N'Có tài khoản lấy ảnh của tôi', 'Open'),
(2, N'Khác', N'Cảm ơn đội ngũ', N'App hoạt động rất mượt mà', 'Resolved');

-- 19. Seed Thông Báo
INSERT INTO ThongBao (MaNguoiDung, TieuDe, NoiDung, DaDoc) VALUES 
(2, N'Lịch trình sắp tới', N'Hành trình Khám phá kỳ quan của bạn sắp bắt đầu.', 0),
(3, N'Bài viết được duyệt', N'Bài viết Góc sống ảo cực chill đã được đăng.', 1),
(4, N'Cảnh báo vi phạm', N'Bài viết của bạn đã bị khóa do nhiều báo cáo.', 0),
(5, N'Phản hồi yêu cầu', N'Yêu cầu hỗ trợ của bạn đang được xử lý.', 1),
(2, N'Bình luận mới', N'Trần Minh Hải đã bình luận về bài viết của bạn.', 0),
(6, N'Chào mừng bạn!', N'Khám phá các địa điểm du lịch nổi bật.', 0),
(7, N'Chào mừng bạn!', N'Bắt đầu lên kế hoạch chuyến đi đầu tiên.', 0),
(3, N'Bài viết được duyệt', N'Bài viết "Chinh phục Sơn Đoòng" đã được duyệt.', 0),
(6, N'Có người thích bài viết', N'4 người đã thích bài viết của bạn.', 1),
(8, N'Bài viết đang chờ duyệt', N'Bài viết của bạn đang chờ kiểm duyệt.', 1),
(2, N'Địa điểm mới được thêm', N'10 địa điểm mới vừa được cập nhật.', 0);
GO

-- ==============================================================================
-- KIỂM TRA KẾT QUẢ TỔNG QUAN
-- ==============================================================================
SELECT 'NguoiDung' AS Bang, COUNT(*) AS Tong FROM NguoiDung UNION ALL
SELECT 'DiaDiem', COUNT(*) FROM DiaDiem UNION ALL
SELECT 'DiaDiemChiTiet', COUNT(*) FROM DiaDiemChiTiet UNION ALL
SELECT 'CamNang', COUNT(*) FROM CamNang UNION ALL
SELECT 'BaiViet', COUNT(*) FROM BaiViet UNION ALL
SELECT 'LichTrinh', COUNT(*) FROM LichTrinh UNION ALL
SELECT 'DanhGia', COUNT(*) FROM DanhGia UNION ALL
SELECT 'BinhLuan', COUNT(*) FROM BinhLuan UNION ALL
SELECT 'LuotThich', COUNT(*) FROM LuotThichBaiViet UNION ALL
SELECT 'Bookmarks', COUNT(*) FROM Bookmarks UNION ALL
SELECT 'ThongBao', COUNT(*) FROM ThongBao UNION ALL
SELECT 'VaiTro', COUNT(*) FROM VaiTro UNION ALL
SELECT 'Quyen', COUNT(*) FROM Quyen UNION ALL
SELECT 'VaiTroQuyen', COUNT(*) FROM VaiTroQuyen;
GO
--- DỮ LIỆU TRONG BẢNG
USE MarvelTravelDB;
GO

-- ==============================================================================
-- 1. NHÓM BẢNG PHÂN QUYỀN (RBAC)
-- ==============================================================================
SELECT * FROM VaiTro;
SELECT * FROM Quyen;
SELECT * FROM VaiTroQuyen;

-- ==============================================================================
-- 2. NHÓM BẢNG NGƯỜI DÙNG & HỆ THỐNG
-- ==============================================================================
SELECT * FROM NguoiDung;
SELECT * FROM ThongBao;
SELECT * FROM YeuCauHoTro;

-- ==============================================================================
-- 3. NHÓM BẢNG ĐỊA ĐIỂM & ĐÁNH GIÁ & BOOKMARKS
-- ==============================================================================
SELECT * FROM DiaDiem;
SELECT * FROM DiaDiemChiTiet;
SELECT * FROM Bookmarks;
SELECT * FROM DanhGia;

-- ==============================================================================
-- 4. NHÓM BẢNG BÀI VIẾT & TƯƠNG TÁC & LỊCH TRÌNH
-- ==============================================================================
SELECT * FROM LichTrinh;
SELECT * FROM BaiViet;
SELECT * FROM LuotThichBaiViet;
SELECT * FROM BinhLuan;
SELECT * FROM BaoCao;

-- ==============================================================================
-- 5. BẢNG CẨM NANG DU LỊCH
-- ==============================================================================
SELECT * FROM CamNang;
GO

CREATE TABLE DeviceToken (
    MaDeviceToken INT IDENTITY(1,1) PRIMARY KEY,
    MaNguoiDung INT NOT NULL,
    Token NVARCHAR(500) NOT NULL,
    Platform NVARCHAR(50) NULL,
    IsActive BIT NOT NULL DEFAULT 1,
    NgayTao DATETIME DEFAULT GETDATE(),
    NgayCapNhat DATETIME DEFAULT GETDATE(),

    CONSTRAINT FK_DeviceToken_NguoiDung
        FOREIGN KEY (MaNguoiDung)
        REFERENCES NguoiDung(MaNguoiDung)
        ON DELETE CASCADE
);

CREATE UNIQUE INDEX IX_DeviceToken_Token
ON DeviceToken(Token);
GO