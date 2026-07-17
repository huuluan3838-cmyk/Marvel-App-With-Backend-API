using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class DanhGium
{
    public int MaDanhGia { get; set; }

    public int? MaNguoiDung { get; set; }

    public int? MaDiaDiem { get; set; }

    public double? SoSao { get; set; }

    public string? NoiDung { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual DiaDiem? MaDiaDiemNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
