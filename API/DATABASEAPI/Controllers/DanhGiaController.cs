using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class DanhGiaController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    public DanhGiaController(MarvelTravelDbContext context) => _context = context;

    [HttpGet("diadiem/{diaDiemId}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetByDiaDiem(int diaDiemId)
    {
        var items = await _context.DanhGia
            .Where(x => x.MaDiaDiem == diaDiemId)
            .OrderByDescending(x => x.NgayTao)
            .Select(x => new { x.MaDanhGia, x.MaNguoiDung, x.MaDiaDiem, x.SoSao, x.NoiDung, x.NgayTao, HoTen = x.MaNguoiDungNavigation != null ? x.MaNguoiDungNavigation.HoTen : null })
            .ToListAsync();
        return Ok(items);
    }



    [HttpGet("mine")]
    [Authorize]
    public async Task<IActionResult> GetMyReviews()
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();

        var items = await _context.DanhGia
            .Where(x => x.MaNguoiDung == userId.Value)
            .OrderByDescending(x => x.NgayTao)
            .Select(x => new 
            { 
                x.MaDanhGia, 
                x.MaDiaDiem, 
                x.SoSao, 
                x.NoiDung, 
                x.NgayTao, 
                TenDiaDiem = x.MaDiaDiemNavigation != null ? x.MaDiaDiemNavigation.TenDiaDiem : null,
                TinhThanh = x.MaDiaDiemNavigation != null ? x.MaDiaDiemNavigation.TinhThanh : null
            })
            .ToListAsync();
        return Ok(items);
    }
    [HttpPost]
    [Authorize]
    public async Task<IActionResult> Create([FromBody] DanhGiaRequest request)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        if (request.MaDiaDiem <= 0 || request.SoSao < 1 || request.SoSao > 5) return BadRequest(new { message = "Dữ liệu đánh giá không hợp lệ." });

        var item = new DanhGium { MaNguoiDung = userId.Value, MaDiaDiem = request.MaDiaDiem, SoSao = request.SoSao, NoiDung = request.NoiDung, NgayTao = DateTime.Now };
        _context.DanhGia.Add(item);
        await _context.SaveChangesAsync();

        var avg = await _context.DanhGia.Where(x => x.MaDiaDiem == request.MaDiaDiem).AverageAsync(x => x.SoSao) ?? 5.0;
        var diaDiem = await _context.DiaDiems.FindAsync(request.MaDiaDiem);
        if (diaDiem != null) diaDiem.DanhGiaTrungBinh = avg;
        await _context.SaveChangesAsync();

        var count = await _context.DanhGia.CountAsync(x => x.MaDiaDiem == request.MaDiaDiem);
        return Ok(new { item.MaDanhGia, item.MaNguoiDung, item.MaDiaDiem, item.SoSao, item.NoiDung, item.NgayTao, danhGiaTrungBinh = Math.Round(avg, 1), soDanhGia = count });
    }
}
public class DanhGiaRequest { public int MaDiaDiem { get; set; } public double SoSao { get; set; } public string? NoiDung { get; set; } }
