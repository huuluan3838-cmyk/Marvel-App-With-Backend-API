using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class YeuCauHoTro
{
    public int MaYeuCau { get; set; }

    public int? MaNguoiDung { get; set; }

    public string? LoaiYeuCau { get; set; }

    public string? TieuDe { get; set; }

    public string? NoiDung { get; set; }

    public string? TrangThai { get; set; }

    public DateTime? NgayGui { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
