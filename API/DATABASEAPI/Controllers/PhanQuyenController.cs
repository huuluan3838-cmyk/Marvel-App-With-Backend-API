using DATABASEAPI.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize(Policy = "AdminOnly")]
    public class PhanQuyenController : ControllerBase
    {
        private readonly MarvelTravelDbContext _context;

        public PhanQuyenController(MarvelTravelDbContext context)
        {
            _context = context;
        }

        // GET: api/phanquyen/user/1
        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserPermissions(int userId)
        {
            var permissions = await _context.Database
                .SqlQueryRaw<UserPermissionDto>(@"
                    SELECT MaNguoiDung, HoTen, Email, VaiTro, MaQuyenCode, TenQuyen
                    FROM vw_NguoiDung_Quyen
                    WHERE MaNguoiDung = {0}
                    ORDER BY MaQuyenCode", userId)
                .ToListAsync();

            if (permissions.Count == 0)
                return NotFound(new { message = "Không tìm thấy người dùng hoặc người dùng chưa có quyền." });

            return Ok(new
            {
                user = new
                {
                    permissions[0].MaNguoiDung,
                    permissions[0].HoTen,
                    permissions[0].Email,
                    permissions[0].VaiTro
                },
                permissions = permissions.Select(p => new { p.MaQuyenCode, p.TenQuyen })
            });
        }

        // GET: api/phanquyen/check?userId=1&permission=baiviet.approve
        [HttpGet("check")]
        public async Task<IActionResult> CheckPermission([FromQuery] int userId, [FromQuery] string permission)
        {
            if (string.IsNullOrWhiteSpace(permission))
                return BadRequest(new { message = "Thiếu mã quyền cần kiểm tra." });

            var result = await _context.Database
                .SqlQueryRaw<PermissionCheckDto>("EXEC sp_KiemTraQuyen @MaNguoiDung = {0}, @MaQuyenCode = {1}", userId, permission)
                .ToListAsync();

            return Ok(new { userId, permission, allowed = result.FirstOrDefault()?.CoQuyen ?? false });
        }
    }

    public class UserPermissionDto
    {
        public int MaNguoiDung { get; set; }
        public string HoTen { get; set; } = string.Empty;
        public string Email { get; set; } = string.Empty;
        public string VaiTro { get; set; } = string.Empty;
        public string MaQuyenCode { get; set; } = string.Empty;
        public string TenQuyen { get; set; } = string.Empty;
    }

    public class PermissionCheckDto
    {
        public bool CoQuyen { get; set; }
    }
}

