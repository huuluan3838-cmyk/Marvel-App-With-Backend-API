using System;
using System.Collections.Generic;

namespace DATABASEAPI.Entities;

public partial class DeviceToken
{
    public int MaDeviceToken { get; set; }

    public int MaNguoiDung { get; set; }

    public string Token { get; set; } = string.Empty;

    public string? Platform { get; set; }

    public bool IsActive { get; set; } = true;

    public DateTime? NgayTao { get; set; }

    public DateTime? NgayCapNhat { get; set; }

    public virtual NguoiDung? MaNguoiDungNavigation { get; set; }
}
