using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class CamNang
{
    public int MaCamNang { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? TheLoai { get; set; }

    public string NoiDung { get; set; } = null!;

    public string? HinhAnh { get; set; }

    public string? ThoiGianDoc { get; set; }

    public int? LuotThich { get; set; }
}
