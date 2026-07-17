using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using DATABASEAPI.Services;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;
using Microsoft.AspNetCore.StaticFiles;

namespace MarvelTravelAPI.Controllers;

[Route("api/[controller]")]
[ApiController]
[Authorize]
public class ProfileController : ControllerBase
{
    private readonly MarvelTravelDbContext _context;
    private readonly IAuthService _authService;
    public ProfileController(MarvelTravelDbContext context, IAuthService authService) { _context = context; _authService = authService; }

    [HttpGet("me")]
    public async Task<IActionResult> Me()
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        var user = await _context.NguoiDungs.FindAsync(userId.Value);
        return user == null ? NotFound() : Ok(ToDto(user));
    }

    [HttpPut("me")]
    public async Task<IActionResult> UpdateMe([FromBody] UpdateProfileRequest request)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        var user = await _context.NguoiDungs.FindAsync(userId.Value);
        if (user == null) return NotFound();
        if (!string.IsNullOrWhiteSpace(request.HoTen)) user.HoTen = request.HoTen;
        user.SoDienThoai = request.SoDienThoai;
        user.AnhDaiDien = request.AnhDaiDien;
        await _context.SaveChangesAsync();
        return Ok(ToDto(user));
    }

    [HttpPost("avatar")]
    [RequestSizeLimit(5_000_000)]
    public async Task<IActionResult> UploadAvatar(IFormFile file)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        if (file == null || file.Length == 0) return BadRequest(new { message = "Thiếu file ảnh." });
        if (file.Length > 5_000_000) return BadRequest(new { message = "Ảnh tối đa 5MB." });

        var provider = new FileExtensionContentTypeProvider();
        if (!provider.TryGetContentType(file.FileName, out var contentType) || !contentType.StartsWith("image/"))
            return BadRequest(new { message = "Chỉ cho phép upload file ảnh." });

        var user = await _context.NguoiDungs.FindAsync(userId.Value);
        if (user == null) return NotFound();

        var ext = Path.GetExtension(file.FileName).ToLowerInvariant();
        var allowed = new[] { ".jpg", ".jpeg", ".png", ".webp" };
        if (!allowed.Contains(ext)) return BadRequest(new { message = "Ảnh phải là jpg, jpeg, png hoặc webp." });

        var uploadsRoot = Path.Combine(Directory.GetCurrentDirectory(), "wwwroot", "uploads", "avatars");
        Directory.CreateDirectory(uploadsRoot);
        var fileName = $"user_{userId.Value}_{Guid.NewGuid():N}{ext}";
        var fullPath = Path.Combine(uploadsRoot, fileName);
        await using (var stream = System.IO.File.Create(fullPath))
        {
            await file.CopyToAsync(stream);
        }

        user.AnhDaiDien = $"/uploads/avatars/{fileName}";
        await _context.SaveChangesAsync();
        return Ok(ToDto(user));
    }

    [HttpPut("password")]
    public async Task<IActionResult> ChangePassword([FromBody] ChangePasswordRequest request)
    {
        var userId = User.GetUserId();
        if (userId == null) return Unauthorized();
        if (string.IsNullOrWhiteSpace(request.CurrentPassword) || string.IsNullOrWhiteSpace(request.NewPassword)) return BadRequest(new { message = "Thiếu mật khẩu." });
        var user = await _context.NguoiDungs.FindAsync(userId.Value);
        if (user == null) return NotFound();
        if (!_authService.VerifyPassword(user, request.CurrentPassword)) return BadRequest(new { message = "Mật khẩu hiện tại không đúng." });
        user.MatKhau = _authService.HashPassword(user, request.NewPassword);
        await _context.SaveChangesAsync();
        return Ok(new { message = "Đổi mật khẩu thành công." });
    }

    private static object ToDto(NguoiDung user) => new { user.MaNguoiDung, user.HoTen, user.Email, user.SoDienThoai, user.VaiTro, user.AnhDaiDien, user.NgayTao };
}
public class UpdateProfileRequest { public string? HoTen { get; set; } public string? SoDienThoai { get; set; } public string? AnhDaiDien { get; set; } }
public class ChangePasswordRequest { public string? CurrentPassword { get; set; } public string? NewPassword { get; set; } }
