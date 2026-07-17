using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class LuotThichBaiViet
{
    public int MaNguoiDung { get; set; }

    public int MaBaiViet { get; set; }

    public DateTime? NgayThich { get; set; }

    public virtual BaiViet MaBaiVietNavigation { get; set; } = null!;

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
