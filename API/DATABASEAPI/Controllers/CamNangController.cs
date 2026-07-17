using DATABASEAPI.Entities;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
public class CamNangController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    public CamNangController(MarvelTravelDbContext context) => _context = context;

    [HttpGet]
    [AllowAnonymous]
    public async Task<IActionResult> GetAll([FromQuery] string? category)
    {
        var query = _context.CamNangs.AsQueryable();
        if (!string.IsNullOrWhiteSpace(category)) query = query.Where(x => x.TheLoai == category);
        return Ok(await query.OrderByDescending(x => x.MaCamNang).ToListAsync());
    }

    [HttpGet("{id}")]
    [AllowAnonymous]
    public async Task<IActionResult> GetById(int id)
    {
        var item = await _context.CamNangs.FindAsync(id);
        return item == null ? NotFound() : Ok(item);
    }

    [HttpPost]
    [Authorize(Policy = "ContentModerator")]
    public async Task<IActionResult> Create([FromBody] CamNang item)
    {
        item.MaCamNang = 0;
        item.LuotThich ??= 0;
        _context.CamNangs.Add(item);
        await _context.SaveChangesAsync();
        return Ok(item);
    }

    [HttpPost("like/{id}")]
    [Authorize]
    public async Task<IActionResult> Like(int id)
    {
        var item = await _context.CamNangs.FindAsync(id);
        if (item == null) return NotFound();
        item.LuotThich = (item.LuotThich ?? 0) + 1;
        await _context.SaveChangesAsync();
        return Ok(new { item.MaCamNang, item.LuotThich });
    }
}
