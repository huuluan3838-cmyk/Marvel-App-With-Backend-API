using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class BaiViet
{
    public int MaBaiViet { get; set; }

    public int? MaNguoiDung { get; set; }

    public string TieuDe { get; set; } = null!;

    public string NoiDung { get; set; } = null!;

    public string? TheLoai { get; set; }

    public string? HinhAnh { get; set; }

    public string? TrangThai { get; set; }

    public DateTime? NgayDang { get; set; }

    public virtual ICollection<BaoCao> BaoCaos { get; set; } = new List<BaoCao>();

    public virtual ICollection<BinhLuan> BinhLuans { get; set; } = new List<BinhLuan>();

    public virtual ICollection<LuotThichBaiViet> LuotThichBaiViets { get; set; } = new List<LuotThichBaiViet>();

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
