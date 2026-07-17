using DATABASEAPI.Entities;
using DATABASEAPI.Extensions;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class BaiVietController : ControllerBase
    {
        private readonly MarvelTravelDbContext _context;

        public BaiVietController(MarvelTravelDbContext context)
        {
            _context = context;
        }

        [HttpGet]
        [AllowAnonymous]
        public async Task<IActionResult> GetApprovedPosts()
        {
            var currentUserId = User.GetUserId();
            var posts = await _context.BaiViets
                .AsNoTracking()
                .Where(b => b.TrangThai == "Approved")
                .OrderByDescending(b => b.NgayDang)
                .Select(b => new
                {
                    b.MaBaiViet,
                    b.MaNguoiDung,
                    b.TieuDe,
                    b.NoiDung,
                    b.TheLoai,
                    b.HinhAnh,
                    b.TrangThai,
                    b.NgayDang,
                    luotThich = b.LuotThichBaiViets.Count,
                    luotBinhLuan = b.BinhLuans.Count,
                    luotChiaSe = 0,
                    isLiked = currentUserId != null && b.LuotThichBaiViets.Any(l => l.MaNguoiDung == currentUserId.Value)
                })
                .ToListAsync();
            return Ok(posts);
        }

        [HttpGet("admin")]
        [Authorize(Policy = "ContentModerator")]
        public async Task<IActionResult> GetAllPostsForAdmin()
        {
            var posts = await _context.BaiViets.OrderByDescending(b => b.NgayDang).ToListAsync();
            return Ok(posts);
        }

        [HttpPost]
        [Authorize]
        public async Task<IActionResult> CreatePost([FromBody] BaiViet post)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();

            post.MaNguoiDung = currentUserId.Value;
            post.TrangThai = "Pending";
            post.NgayDang = DateTime.Now;
            _context.BaiViets.Add(post);
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đăng bài thành công, chờ kiểm duyệt!" });
        }

        [HttpPut("approve/{id}")]
        [Authorize(Policy = "ContentModerator")]
        public async Task<IActionResult> ApprovePost(int id)
        {
            await _context.Database.ExecuteSqlRawAsync("EXEC sp_DuyetBaiViet @MaBaiViet = {0}", id);
            return Ok(new { message = "Đã duyệt bài viết!" });
        }

        [HttpPost("like/{id}")]
        [Authorize]
        public async Task<IActionResult> ToggleLike(int id)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();

            var existingLike = await _context.LuotThichBaiViets
                .FirstOrDefaultAsync(l => l.MaBaiViet == id && l.MaNguoiDung == currentUserId.Value);

            if (existingLike != null)
                _context.LuotThichBaiViets.Remove(existingLike);
            else
                _context.LuotThichBaiViets.Add(new LuotThichBaiViet { MaBaiViet = id, MaNguoiDung = currentUserId.Value, NgayThich = DateTime.Now });

            await _context.SaveChangesAsync();
            var likeCount = await _context.LuotThichBaiViets.CountAsync(l => l.MaBaiViet == id);
            var isLiked = await _context.LuotThichBaiViets.AnyAsync(l => l.MaBaiViet == id && l.MaNguoiDung == currentUserId.Value);
            return Ok(new { maBaiViet = id, luotThich = likeCount, isLiked });
        }


        [HttpGet("stats")]
        [AllowAnonymous]
        public async Task<IActionResult> GetPostStats([FromQuery] string? ids)
        {
            var idList = (ids ?? "")
                .Split(',', StringSplitOptions.RemoveEmptyEntries | StringSplitOptions.TrimEntries)
                .Select(x => int.TryParse(x, out var id) ? id : 0)
                .Where(x => x > 0)
                .Distinct()
                .ToList();
            var currentUserId = User.GetUserId();
            var query = _context.BaiViets.AsNoTracking().Where(b => b.TrangThai == "Approved");
            if (idList.Count > 0) query = query.Where(b => idList.Contains(b.MaBaiViet));
            var stats = await query.Select(b => new
            {
                maBaiViet = b.MaBaiViet,
                luotThich = b.LuotThichBaiViets.Count,
                luotBinhLuan = b.BinhLuans.Count,
                luotChiaSe = 0,
                isLiked = currentUserId != null && b.LuotThichBaiViets.Any(l => l.MaNguoiDung == currentUserId.Value)
            }).ToListAsync();
            return Ok(stats);
        }
        [HttpPost("report")]
        [Authorize]
        public async Task<IActionResult> ReportPost([FromBody] BaoCao report)
        {
            var currentUserId = User.GetUserId();
            if (currentUserId is null) return Unauthorized();
            if (report.MaBaiViet is null || string.IsNullOrWhiteSpace(report.LyDo))
                return BadRequest(new { message = "Thiếu mã bài viết hoặc lý do báo cáo." });

            await _context.Database.ExecuteSqlRawAsync(
                "EXEC sp_BaoCaoBaiViet @MaBaiViet = {0}, @MaNguoiDung = {1}, @LyDo = {2}",
                report.MaBaiViet.Value, currentUserId.Value, report.LyDo);

            return Ok(new { message = "Đã gửi báo cáo vi phạm!" });
        }
        [HttpPut("hide/{id}")]
        [Authorize(Policy = "ContentModerator")]
        public async Task<IActionResult> HidePost(int id)
        {
            var post = await _context.BaiViets.FindAsync(id);
            if (post == null) return NotFound(new { message = "Không tìm thấy bài viết." });

            post.TrangThai = "Hidden";
            await _context.SaveChangesAsync();
            return Ok(new { message = "Đã ẩn bài viết!" });
        }
    }
}

