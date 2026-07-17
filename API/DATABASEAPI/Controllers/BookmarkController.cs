using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    [Authorize]
    public class BookmarkController : ControllerBase
    {
        private readonly MarvelTravelDbContext _context;

        public BookmarkController(MarvelTravelDbContext context)
        {
            _context = context;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserBookmarks(int userId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();
            if (currentUserId.Value != userId && !User.IsAdmin()) return Forbid();

            var bookmarks = await _context.Bookmarks
                .Where(b => b.MaNguoiDung == userId)
                .Select(b => b.MaDiaDiemNavigation)
                .ToListAsync();
            return Ok(bookmarks);
        }

        [HttpPost]
        public async Task<IActionResult> ToggleBookmark([FromBody] BookmarkRequest request)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();
            if (currentUserId.Value != request.MaNguoiDung && !User.IsAdmin()) return Forbid();

            var existing = await _context.Bookmarks
                .FirstOrDefaultAsync(b => b.MaNguoiDung == request.MaNguoiDung && b.MaDiaDiem == request.MaDiaDiem);

            if (existing != null)
            {
                _context.Bookmarks.Remove(existing);
                await _context.SaveChangesAsync();
                return Ok(new { message = "Đã bỏ lưu địa điểm!" });
            }

            _context.Bookmarks.Add(new Bookmark { MaNguoiDung = request.MaNguoiDung, MaDiaDiem = request.MaDiaDiem, NgayLuu = DateTime.Now });
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã lưu địa điểm thành công!" });
        }
    }

    public class BookmarkRequest
    {
        public int MaNguoiDung { get; set; }
        public int MaDiaDiem { get; set; }
    }
}
