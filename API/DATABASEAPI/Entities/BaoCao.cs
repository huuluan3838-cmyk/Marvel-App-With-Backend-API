using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class BaoCao
{
    public int MaBaoCao { get; set; }

    public int? MaBaiViet { get; set; }

    public int? MaNguoiDung { get; set; }

    public string LyDo { get; set; } = null!;

    public DateTime? NgayBaoCao { get; set; }

    public virtual BaiViet? MaBaiVietNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
