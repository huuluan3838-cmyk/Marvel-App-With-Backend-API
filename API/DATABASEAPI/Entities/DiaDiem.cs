using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class DiaDiem
{
    public int MaDiaDiem { get; set; }

    public string TenDiaDiem { get; set; } = null!;

    public string TinhThanh { get; set; } = null!;

    public string? MoTa { get; set; }

    public double KinhDo { get; set; }

    public double ViDo { get; set; }

    public string? HinhAnh { get; set; }

    public double? DanhGiaTrungBinh { get; set; }

    public DateTime? NgayTao { get; set; }

    public virtual ICollection<Bookmark> Bookmarks { get; set; } = new List<Bookmark>();

    public virtual ICollection<DanhGium> DanhGia { get; set; } = new List<DanhGium>();

    public virtual ICollection<DiaDiemChiTiet> DiaDiemChiTiets { get; set; } = new List<DiaDiemChiTiet>();
}
