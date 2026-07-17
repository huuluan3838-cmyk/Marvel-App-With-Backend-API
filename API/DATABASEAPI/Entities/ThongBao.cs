using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class ThongBao
{
    public int MaThongBao { get; set; }

    public int? MaNguoiDung { get; set; }

    public string? TieuDe { get; set; }

    public string? NoiDung { get; set; }

    public bool? DaDoc { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
