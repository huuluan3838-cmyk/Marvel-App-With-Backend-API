using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class BinhLuan
{
    public int MaBinhLuan { get; set; }

    public int? MaBaiViet { get; set; }

    public int? MaNguoiDung { get; set; }

    public string NoiDung { get; set; } = null!;

    public DateTime? NgayBinhLuan { get; set; }

    public virtual BaiViet? MaBaiVietNavigation { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
