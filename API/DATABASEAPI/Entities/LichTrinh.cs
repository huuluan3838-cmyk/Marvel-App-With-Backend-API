using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class LichTrinh
{
    public int MaLichTrinh { get; set; }

    public int? MaNguoiDung { get; set; }

    public string TieuDe { get; set; } = null!;

    public string? DanhSachDiaDiem { get; set; }

    public DateOnly NgayBatDau { get; set; }

    public DateOnly NgayKetThuc { get; set; }

    public string? PhongCach { get; set; }

    public int? SoNguoi { get; set; }

    public string? TrangThai { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
