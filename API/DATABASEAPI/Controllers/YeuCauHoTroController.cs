using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class YeuCauHoTroController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    public YeuCauHoTroController(MarvelTravelDbContext context) => _context = context;

    [HttpGet("mine")]
    public async Task<IActionResult> GetMine()
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        return Ok(await _context.YeuCauHoTros.Where(x => x.MaNguoiDung == userId.Value).OrderByDescending(x => x.NgayGui).ToListAsync());
    }

    [HttpGet("admin")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetAll()
    {
        return Ok(await _context.YeuCauHoTros.OrderByDescending(x => x.NgayGui).ToListAsync());
    }

    [HttpPost]
    public async Task<IActionResult> Create([FromBody] YeuCauHoTroRequest request)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.TieuDe) || string.IsNullOrWhiteSpace(request.NoiDung)) return BadRequest(new { message = "Thiếu tiêu đề hoặc nội dung hỗ trợ." });
        var item = new YeuCauHoTro { MaNguoiDung = userId.Value, LoaiYeuCau = request.LoaiYeuCau, TieuDe = request.TieuDe, NoiDung = request.NoiDung, TrangThai = "Open", NgayGui = DateTime.Now };
        _context.YeuCauHoTros.Add(item);
        await _context.SaveChangesAsync();
        return Ok(item);
    }

    [HttpPut("status/{id}")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> UpdateStatus(int id, [FromBody] UpdateSupportStatusRequest request)
    {
        var item = await _context.YeuCauHoTros.FindAsync(id);
        if (item == null) return NotFound();
        item.TrangThai = string.IsNullOrWhiteSpace(request.TrangThai) ? item.TrangThai : request.TrangThai;
        await _context.SaveChangesAsync();
        return Ok(item);
    }
}
public class YeuCauHoTroRequest { public string? LoaiYeuCau { get; set; } public string? TieuDe { get; set; } public string? NoiDung { get; set; } }
public class UpdateSupportStatusRequest { public string? TrangThai { get; set; } }
