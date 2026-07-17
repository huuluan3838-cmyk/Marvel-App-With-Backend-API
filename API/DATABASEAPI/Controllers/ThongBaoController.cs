using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using DATABASEAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ThongBaoController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    private readonly IFcmNotificationService _fcmService;

    public ThongBaoController(MarvelTravelDbContext context, IFcmNotificationService fcmService)
    {
        _context = context;
        _fcmService = fcmService;
    }

    [HttpGet]
    public async Task<IActionResult> GetMine()
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        var items = await _context.ThongBaos.Where(x => x.MaNguoiDung == userId.Value).OrderByDescending(x => x.NgayTao).ToListAsync();
        return Ok(items);
    }

    [HttpPut("read/{id}")]
    public async Task<IActionResult> MarkRead(int id)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        var item = await _context.ThongBaos.FirstOrDefaultAsync(x => x.MaThongBao == id && x.MaNguoiDung == userId.Value);
        if (item == null) return NotFound();
        item.DaDoc = true;
        await _context.SaveChangesAsync();
        return Ok(item);
    }

    [HttpGet("admin/users")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> GetUsersForNotify()
    {
        var users = await _context.NguoiDungs
            .OrderBy(x => x.HoTen)
            .Select(x => new
            {
                x.MaNguoiDung,
                x.HoTen,
                x.Email,
                x.VaiTro,
                x.AnhDaiDien
            })
            .ToListAsync();
        return Ok(users);
    }

    [HttpGet("unread/latest")]
    public async Task<IActionResult> GetLatestUnread()
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        var item = await _context.ThongBaos
            .Where(x => x.MaNguoiDung == userId.Value && x.DaDoc != true)
            .OrderByDescending(x => x.NgayTao)
            .FirstOrDefaultAsync();
        return item == null ? NoContent() : Ok(item);
    }

    [HttpPost]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> Create([FromBody] ThongBao item)
    {
        item.MaThongBao = 0;
        item.NgayTao = DateTime.Now;
        item.DaDoc ??= false;
        _context.ThongBaos.Add(item);
        await _context.SaveChangesAsync();
        return Ok(item);
    }

    [HttpPost("admin/send")]
    [Authorize(Policy = "AdminOnly")]
    public async Task<IActionResult> SendFromAdmin([FromBody] AdminSendThongBaoRequest request)
    {
        if (string.IsNullOrWhiteSpace(request.TieuDe) || string.IsNullOrWhiteSpace(request.NoiDung))
            return BadRequest(new { message = "Vui lòng nhập tiêu đề và nội dung thông báo." });

        List<int> targetUserIds;
        if (request.SendAll)
        {
            targetUserIds = await _context.NguoiDungs
                .Where(x => x.VaiTro != "Admin")
                .Select(x => x.MaNguoiDung)
                .ToListAsync();
        }
        else
        {
            targetUserIds = request.UserIds?.Distinct().ToList() ?? new List<int>();
        }

        if (targetUserIds.Count == 0)
            return BadRequest(new { message = "Chưa chọn người dùng nhận thông báo." });

        var now = DateTime.Now;
        var items = targetUserIds.Select(userId => new ThongBao
        {
            MaNguoiDung = userId,
            TieuDe = request.TieuDe.Trim(),
            NoiDung = request.NoiDung.Trim(),
            DaDoc = false,
            NgayTao = now
        }).ToList();

        _context.ThongBaos.AddRange(items);
        await _context.SaveChangesAsync();

        // --- Gửi Push Notification qua FCM ---
        try
        {
            var tokens = await _context.DeviceTokens
                .Where(x => targetUserIds.Contains(x.MaNguoiDung) && x.IsActive)
                .Select(x => x.Token)
                .ToListAsync();

            if (tokens.Count > 0)
            {
                await _fcmService.SendToTokensAsync(
                    tokens,
                    request.TieuDe.Trim(),
                    request.NoiDung.Trim(),
                    new Dictionary<string, string>
                    {
                        ["type"] = "admin_notification",
                        ["title"] = request.TieuDe.Trim()
                    }
                );
            }
        }
        catch (Exception ex)
        {
            // Log lỗi nhưng vẫn trả về Ok vì tin nhắn trong DB đã được lưu thành công
            Console.WriteLine($"Lỗi gửi FCM: {ex.Message}");
        }
        // -------------------------------------

        return Ok(new { message = "Đã gửi thông báo.", sentCount = items.Count });
    }
}

public class AdminSendThongBaoRequest
{
    public string? TieuDe { get; set; }
    public string? NoiDung { get; set; }
    public bool SendAll { get; set; }
    public List<int>? UserIds { get; set; }
}
