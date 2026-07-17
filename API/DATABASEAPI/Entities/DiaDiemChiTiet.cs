using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class DiaDiemChiTiet
{
    public int MaChiTiet { get; set; }

    public int? MaDiaDiem { get; set; }

    public string TenChiTiet { get; set; } = null!;

    public string? HinhAnh { get; set; }

    public virtual DiaDiem? MaDiaDiemNavigation { get; set; }
}
