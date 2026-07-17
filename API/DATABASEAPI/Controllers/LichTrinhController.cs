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
    public class LichTrinhController : ControllerBase
    {
        private readonly MarvelTravelDbContext _context;

        public LichTrinhController(MarvelTravelDbContext context)
        {
            _context = context;
        }

        [HttpGet("user/{userId}")]
        public async Task<IActionResult> GetUserItineraries(int userId)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();
            if (currentUserId.Value != userId && !User.IsAdmin()) return Forbid();

            var lichTrinhs = await _context.LichTrinhs
                .Where(l => l.MaNguoiDung == userId)
                .OrderByDescending(l => l.NgayBatDau)
                .ToListAsync();
            return Ok(lichTrinhs);
        }

        [HttpPost]
        public async Task<IActionResult> CreateLichTrinh([FromBody] LichTrinh lichTrinh)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();

            lichTrinh.MaNguoiDung = currentUserId.Value;
            lichTrinh.TrangThai = "Upcoming";
            _context.LichTrinhs.Add(lichTrinh);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã lưu lịch trình thành công!", data = lichTrinh });
        }
    }
}
