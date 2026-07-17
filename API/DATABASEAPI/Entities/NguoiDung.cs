using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class NguoiDung
{
    public int MaNguoiDung { get; set; }

    public string HoTen { get; set; } = null!;

    public string Email { get; set; } = null!;

    public string? SoDienThoai { get; set; }

    public string MatKhau { get; set; } = null!;

    public string? VaiTro { get; set; }

    public string? AnhDaiDien { get; set; }

    public string? OtpCode { get; set; }

    public DateTime? OtpExpiry { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual ICollection<BaiViet> BaiViets { get; set; } = new List<BaiViet>();

    public virtual ICollection<BaoCao> BaoCaos { get; set; } = new List<BaoCao>();

    public virtual ICollection<BinhLuan> BinhLuans { get; set; } = new List<BinhLuan>();

    public virtual ICollection<Bookmark> Bookmarks { get; set; } = new List<Bookmark>();

    public virtual ICollection<DanhGium> DanhGia { get; set; } = new List<DanhGium>();

    public virtual ICollection<LichTrinh> LichTrinhs { get; set; } = new List<LichTrinh>();

    public virtual ICollection<LuotThichBaiViet> LuotThichBaiViets { get; set; } = new List<LuotThichBaiViet>();

    public virtual ICollection<ThongBao> ThongBaos { get; set; } = new List<ThongBao>();

    public virtual ICollection<YeuCauHoTro> YeuCauHoTros { get; set; } = new List<YeuCauHoTro>();
}
