using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class Bookmark
{
    public int MaNguoiDung { get; set; }

    public int MaDiaDiem { get; set; }

    public DateTime? NgayLuu { get; set; }

    public virtual DiaDiem MaDiaDiemNavigation { get; set; } = null!;

    public virtual NguoiDung MaNguoiDungNavigation { get; set; } = null!;
}
