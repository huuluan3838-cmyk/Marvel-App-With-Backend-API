using System;
using System.Collections.Generic;
using Microsoft.EntityFrameworkCore;

namespace DATABASEAPI.Entities;

public partial class MarvelTravelDbContext : DbContext
{
    public MarvelTravelDbContext()
    {
    }

    public MarvelTravelDbContext(DbContextOptions<MarvelTravelDbContext> options)
        : base(options)
    {
    }

    public virtual DbSet<BaiViet> BaiViets { get; set; }

    public virtual DbSet<BaoCao> BaoCaos { get; set; }

    public virtual DbSet<BinhLuan> BinhLuans { get; set; }

    public virtual DbSet<Bookmark> Bookmarks { get; set; }

    public virtual DbSet<CamNang> CamNangs { get; set; }

    public virtual DbSet<DanhGium> DanhGia { get; set; }

    public virtual DbSet<DiaDiem> DiaDiems { get; set; }

    public virtual DbSet<DiaDiemChiTiet> DiaDiemChiTiets { get; set; }

    public virtual DbSet<LichTrinh> LichTrinhs { get; set; }

    public virtual DbSet<LuotThichBaiViet> LuotThichBaiViets { get; set; }

    public virtual DbSet<NguoiDung> NguoiDungs { get; set; }

    public virtual DbSet<ThongBao> ThongBaos { get; set; }

    public virtual DbSet<YeuCauHoTro> YeuCauHoTros { get; set; }

    public virtual DbSet<DeviceToken> DeviceTokens { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
        {
            optionsBuilder.UseSqlServer("Server=AURORA\\SQLEXPRESS;Database=MarvelTravelDB;Integrated Security=True;TrustServerCertificate=True");
        }
    }
    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<BaiViet>(entity =>
        {
            entity.HasKey(e => e.MaBaiViet).HasName("PK__BaiViet__AEDD5647D6563B01");

            entity.ToTable("BaiViet");

            entity.Property(e => e.HinhAnh)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.NgayDang)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.TheLoai).HasMaxLength(100);
            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValue("Pending");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.BaiViets)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__BaiViet__MaNguoi__239E4DCF");
        });

        modelBuilder.Entity<BaoCao>(entity =>
        {
            entity.HasKey(e => e.MaBaoCao).HasName("PK__BaoCao__25A9188C467E49AD");

            entity.ToTable("BaoCao");

            entity.Property(e => e.LyDo).HasMaxLength(255);
            entity.Property(e => e.NgayBaoCao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaBaiVietNavigation).WithMany(p => p.BaoCaos)
                .HasForeignKey(d => d.MaBaiViet)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__BaoCao__MaBaiVie__32E0915F");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.BaoCaos)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__BaoCao__MaNguoiD__33D4B598");
        });

        modelBuilder.Entity<BinhLuan>(entity =>
        {
            entity.HasKey(e => e.MaBinhLuan).HasName("PK__BinhLuan__87CB66A02850BC64");

            entity.ToTable("BinhLuan");

            entity.Property(e => e.NgayBinhLuan)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaBaiVietNavigation).WithMany(p => p.BinhLuans)
                .HasForeignKey(d => d.MaBaiViet)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__BinhLuan__MaBaiV__2E1BDC42");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.BinhLuans)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__BinhLuan__MaNguo__2F10007B");
        });

        modelBuilder.Entity<Bookmark>(entity =>
        {
            entity.HasKey(e => new { e.MaNguoiDung, e.MaDiaDiem }).HasName("PK__Bookmark__7A388E005E188AAF");

            entity.Property(e => e.NgayLuu)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaDiaDiemNavigation).WithMany(p => p.Bookmarks)
                .HasForeignKey(d => d.MaDiaDiem)
                .HasConstraintName("FK__Bookmarks__MaDia__412EB0B6");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.Bookmarks)
                .HasForeignKey(d => d.MaNguoiDung)
                .HasConstraintName("FK__Bookmarks__MaNgu__403A8C7D");
        });

        modelBuilder.Entity<CamNang>(entity =>
        {
            entity.HasKey(e => e.MaCamNang).HasName("PK__CamNang__8177BE7E45A6342F");

            entity.ToTable("CamNang");

            entity.Property(e => e.HinhAnh)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.LuotThich).HasDefaultValue(0);
            entity.Property(e => e.TheLoai).HasMaxLength(100);
            entity.Property(e => e.ThoiGianDoc).HasMaxLength(50);
            entity.Property(e => e.TieuDe).HasMaxLength(255);
        });

        modelBuilder.Entity<DanhGium>(entity =>
        {
            entity.HasKey(e => e.MaDanhGia).HasName("PK__DanhGia__AA9515BF3F84C20B");

            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaDiaDiemNavigation).WithMany(p => p.DanhGia)
                .HasForeignKey(d => d.MaDiaDiem)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__DanhGia__MaDiaDi__3B75D760");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.DanhGia)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__DanhGia__MaNguoi__3A81B327");
        });

        modelBuilder.Entity<DiaDiem>(entity =>
        {
            entity.HasKey(e => e.MaDiaDiem).HasName("PK__DiaDiem__F015962A5CEEC4C6");

            entity.ToTable("DiaDiem");

            entity.Property(e => e.DanhGiaTrungBinh).HasDefaultValue(5.0);
            entity.Property(e => e.HinhAnh)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.TenDiaDiem).HasMaxLength(200);
            entity.Property(e => e.TinhThanh).HasMaxLength(100);
        });

        modelBuilder.Entity<DiaDiemChiTiet>(entity =>
        {
            entity.HasKey(e => e.MaChiTiet).HasName("PK__DiaDiemC__CDF0A1147870BD5B");

            entity.ToTable("DiaDiemChiTiet");

            entity.Property(e => e.HinhAnh)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.TenChiTiet).HasMaxLength(200);

            entity.HasOne(d => d.MaDiaDiemNavigation).WithMany(p => p.DiaDiemChiTiets)
                .HasForeignKey(d => d.MaDiaDiem)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__DiaDiemCh__MaDia__1B0907CE");
        });

        modelBuilder.Entity<LichTrinh>(entity =>
        {
            entity.HasKey(e => e.MaLichTrinh).HasName("PK__LichTrin__32E7201DD20289E4");

            entity.ToTable("LichTrinh");

            entity.Property(e => e.PhongCach).HasMaxLength(100);
            entity.Property(e => e.SoNguoi).HasDefaultValue(1);
            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(50)
                .IsUnicode(false)
                .HasDefaultValue("Upcoming");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.LichTrinhs)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__LichTrinh__MaNgu__1DE57479");
        });

        modelBuilder.Entity<LuotThichBaiViet>(entity =>
        {
            entity.HasKey(e => new { e.MaNguoiDung, e.MaBaiViet }).HasName("PK__LuotThic__AFD40206A6DF3390");

            entity.ToTable("LuotThichBaiViet");

            entity.Property(e => e.NgayThich)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");

            entity.HasOne(d => d.MaBaiVietNavigation).WithMany(p => p.LuotThichBaiViets)
                .HasForeignKey(d => d.MaBaiViet)
                .HasConstraintName("FK__LuotThich__MaBai__2A4B4B5E");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.LuotThichBaiViets)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__LuotThich__MaNgu__29572725");
        });

        modelBuilder.Entity<NguoiDung>(entity =>
        {
            entity.HasKey(e => e.MaNguoiDung).HasName("PK__NguoiDun__C539D762E062EF21");

            entity.ToTable("NguoiDung");

            entity.HasIndex(e => e.SoDienThoai, "UQ__NguoiDun__0389B7BD5E7E812F").IsUnique();

            entity.HasIndex(e => e.Email, "UQ__NguoiDun__A9D1053469AE7548").IsUnique();

            entity.Property(e => e.AnhDaiDien)
                .HasMaxLength(500)
                .IsUnicode(false);
            entity.Property(e => e.Email)
                .HasMaxLength(255)
                .IsUnicode(false);
            entity.Property(e => e.HoTen).HasMaxLength(100);
            entity.Property(e => e.MatKhau)
                .HasMaxLength(255)
                .IsUnicode(false);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.SoDienThoai)
                .HasMaxLength(20)
                .IsUnicode(false);
            entity.Property(e => e.VaiTro)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValue("User");
        });

        modelBuilder.Entity<ThongBao>(entity =>
        {
            entity.HasKey(e => e.MaThongBao).HasName("PK__ThongBao__04DEB54E17923B24");

            entity.ToTable("ThongBao");

            entity.Property(e => e.DaDoc).HasDefaultValue(false);
            entity.Property(e => e.NgayTao)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.NoiDung).HasMaxLength(500);
            entity.Property(e => e.TieuDe).HasMaxLength(200);

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.ThongBaos)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__ThongBao__MaNguo__49C3F6B7");
        });

        modelBuilder.Entity<YeuCauHoTro>(entity =>
        {
            entity.HasKey(e => e.MaYeuCau).HasName("PK__YeuCauHo__CFA5DF4EC920680D");

            entity.ToTable("YeuCauHoTro");

            entity.Property(e => e.LoaiYeuCau).HasMaxLength(100);
            entity.Property(e => e.NgayGui)
                .HasDefaultValueSql("(getdate())")
                .HasColumnType("datetime");
            entity.Property(e => e.TieuDe).HasMaxLength(255);
            entity.Property(e => e.TrangThai)
                .HasMaxLength(20)
                .IsUnicode(false)
                .HasDefaultValue("Open");

            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany(p => p.YeuCauHoTros)
                .HasForeignKey(d => d.MaNguoiDung)
                .OnDelete(DeleteBehavior.Cascade)
                .HasConstraintName("FK__YeuCauHoT__MaNgu__44FF419A");
        });

        modelBuilder.Entity<DeviceToken>(entity =>
        {
            entity.HasKey(e => e.MaDeviceToken);
            entity.ToTable("DeviceToken");
            entity.HasIndex(e => e.Token).IsUnique();
            entity.Property(e => e.Token).HasMaxLength(500);
            entity.Property(e => e.Platform).HasMaxLength(50);
            entity.Property(e => e.IsActive).HasDefaultValue(true);
            entity.Property(e => e.NgayTao).HasDefaultValueSql("(getdate())").HasColumnType("datetime");
            entity.Property(e => e.NgayCapNhat).HasDefaultValueSql("(getdate())").HasColumnType("datetime");
            entity.HasOne(d => d.MaNguoiDungNavigation).WithMany().HasForeignKey(d => d.MaNguoiDung).OnDelete(DeleteBehavior.Cascade);
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}



