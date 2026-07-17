using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class BinhLuanController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    public BinhLuanController(MarvelTravelDbContext context) => _context = context;

    [HttpGet("baiviet/{baiVietId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetByPost(int baiVietId)
    {
        var items = await _context.BinhLuans
            .Where(x => x.MaBaiViet == baiVietId)
            .OrderBy(x => x.NgayBinhLuan)
            .Select(x => new { x.MaBinhLuan, x.MaBaiViet, x.MaNguoiDung, x.NoiDung, x.NgayBinhLuan, HoTen = x.MaNguoiDungNavigation != null ? x.MaNguoiDungNavigation.HoTen : null })
            .ToListAsync();
        return Ok(items);
    }

    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] BinhLuanRequest request)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        if (request.MaBaiViet <= 0 || string.IsNullOrWhiteSpace(request.NoiDung)) return BadRequest(new { message = "Thiếu bài viết hoặc nội dung bình luận." });
        var item = new BinhLuan { MaBaiViet = request.MaBaiViet, MaNguoiDung = userId.Value, NoiDung = request.NoiDung, NgayBinhLuan = DateTime.Now };
        _context.BinhLuans.Add(item);
        await _context.SaveChangesAsync();
        return Ok(item);
    }
}
public class BinhLuanRequest { public int MaBaiViet { get; set; } public string? NoiDung { get; set; } }
