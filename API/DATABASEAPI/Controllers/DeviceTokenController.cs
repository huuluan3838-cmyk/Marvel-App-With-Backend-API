using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class DeviceTokenController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;

    public DeviceTokenController(MarvelTravelDbContext context)
    {
        _context = context;
    }

    [HttpPost("register")]
    public async Task<IActionResult> Register([FromBody] RegisterDeviceTokenRequest request)
    {
        var userIdString = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Token))
            return BadRequest(new { message = "Thiếu FCM token." });

        var existing = await _context.DeviceTokens
            .FirstOrDefaultAsync(x => x.Token == request.Token);

        if (existing == null)
        {
            existing = new DeviceToken
            {
                MaNguoiDung = userId,
                Token = request.Token,
                Platform = request.Platform,
                IsActive = true,
                NgayTao = DateTime.Now,
                NgayCapNhat = DateTime.Now,
              };

            _context.DeviceTokens.Add(existing);
        }
        else
        {
            existing.MaNguoiDung = userId;
            existing.Platform = request.Platform;
            existing.IsActive = true;
            existing.NgayCapNhat = DateTime.Now;
        }

        await _context.SaveChangesAsync();

        return Ok(new { message = "Đã lưu device token." });
    }

    [HttpPost("unregister")]
    public async Task<IActionResult> Unregister([FromBody] UnregisterDeviceTokenRequest request)
    {
        var userIdString = User.FindFirst(System.Security.Claims.ClaimTypes.NameIdentifier)?.Value;
        if (string.IsNullOrEmpty(userIdString) || !int.TryParse(userIdString, out int userId))
        {
            return Unauthorized();
        }

        if (string.IsNullOrWhiteSpace(request.Token))
            return BadRequest(new { message = "Thiếu FCM token." });

        var token = await _context.DeviceTokens
            .FirstOrDefaultAsync(x =>
                x.Token == request.Token &&
                x.MaNguoiDung == userId);

        if (token != null)
        {
            token.IsActive = false;
            token.NgayCapNhat = DateTime.Now;
            await _context.SaveChangesAsync();
        }

        return Ok(new { message = "Đã hủy device token." });
    }
}

public class RegisterDeviceTokenRequest
{
    public string? Token { get; set; }

    public string? Platform { get; set; }
}

public class UnregisterDeviceTokenRequest
{
    public string? Token { get; set; }
}
