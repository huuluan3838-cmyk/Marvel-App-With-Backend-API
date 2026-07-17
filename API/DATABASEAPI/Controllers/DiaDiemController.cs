using DATABASEAPI.Entities;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Authorization;
using Microsoft.EntityFrameworkCore;

namespace MarvelTravelAPI.Controllers
{
    [Route("api/[controller]")]
    [ApiController]
    public class DiaDiemController : ControllerBase
    {
        private readonly MarvelTravelDbContext _context;

        public DiaDiemController(MarvelTravelDbContext context)
        {
            _context = context;
        }

        // GET: api/diadiem
        [HttpGet]
        public async Task<IActionResult> GetAllDiaDiem()
        {
            // Trả DTO phẳng để Flutter đọc ổn định và tránh lỗi vòng lặp JSON từ EF navigation.
            var diaDiems = await _context.DiaDiems
                .AsNoTracking()
                .Include(d => d.DiaDiemChiTiets)
                .Select(d => new
                {
                    maDiaDiem = d.MaDiaDiem,
                    tenDiaDiem = d.TenDiaDiem,
                    tinhThanh = d.TinhThanh,
                    moTa = d.MoTa,
                    kinhDo = d.KinhDo,
                    viDo = d.ViDo,
                    hinhAnh = d.HinhAnh,
                    danhGiaTrungBinh = d.DanhGiaTrungBinh,
                    ngayTao = d.NgayTao,
                    diaDiemChiTiets = d.DiaDiemChiTiets.Select(ct => new
                    {
                        maChiTiet = ct.MaChiTiet,
                        maDiaDiem = ct.MaDiaDiem,
                        tenChiTiet = ct.TenChiTiet,
                        hinhAnh = ct.HinhAnh
                    })
                })
                .ToListAsync();

            return Ok(diaDiems);
        }

        // GET: api/diadiem/5
        [HttpGet("{id}")]
        public async Task<IActionResult> GetDiaDiemDetail(int id)
        {
            var diaDiem = await _context.DiaDiems
                .AsNoTracking()
                .Where(d => d.MaDiaDiem == id)
                .Select(d => new
                {
                    maDiaDiem = d.MaDiaDiem,
                    tenDiaDiem = d.TenDiaDiem,
                    tinhThanh = d.TinhThanh,
                    moTa = d.MoTa,
                    kinhDo = d.KinhDo,
                    viDo = d.ViDo,
                    hinhAnh = d.HinhAnh,
                    danhGiaTrungBinh = d.DanhGiaTrungBinh,
                    ngayTao = d.NgayTao,
                    diaDiemChiTiets = d.DiaDiemChiTiets.Select(ct => new
                    {
                        maChiTiet = ct.MaChiTiet,
                        maDiaDiem = ct.MaDiaDiem,
                        tenChiTiet = ct.TenChiTiet,
                        hinhAnh = ct.HinhAnh
                    })
                })
                .FirstOrDefaultAsync();

            if (diaDiem == null) return NotFound();

            return Ok(diaDiem);
        }

        // POST: api/diadiem/admin
        [HttpPost("admin")]
        [Authorize(Policy = "AdminOnly")]
        public async Task<IActionResult> CreateDiaDiem([FromBody] CreateDiaDiemRequest request)
        {
            if (string.IsNullOrWhiteSpace(request.TenDiaDiem) || string.IsNullOrWhiteSpace(request.TinhThanh))
                return BadRequest(new { message = "Vui lòng nhập tên địa điểm và tỉnh/thành." });

            var diaDiem = new DiaDiem
            {
                TenDiaDiem = request.TenDiaDiem.Trim(),
                TinhThanh = request.TinhThanh.Trim(),
                MoTa = request.MoTa,
                KinhDo = request.KinhDo,
                ViDo = request.ViDo,
                HinhAnh = request.HinhAnh,
                DanhGiaTrungBinh = request.DanhGiaTrungBinh ?? 5,
                NgayTao = DateTime.Now
            };
            _context.DiaDiems.Add(diaDiem);
            await _context.SaveChangesAsync();

            if (request.ChiTiets != null)
            {
                foreach (var ct in request.ChiTiets.Where(x => !string.IsNullOrWhiteSpace(x.TenChiTiet)))
                {
                    _context.DiaDiemChiTiets.Add(new DiaDiemChiTiet
                    {
                        MaDiaDiem = diaDiem.MaDiaDiem,
                        TenChiTiet = ct.TenChiTiet.Trim(),
                        HinhAnh = ct.HinhAnh
                    });
                }
                await _context.SaveChangesAsync();
            }

            return Ok(new { message = "Đã tạo địa điểm mới.", maDiaDiem = diaDiem.MaDiaDiem });
        }
    }

    public class CreateDiaDiemRequest
    {
        public string? TenDiaDiem { get; set; }
        public string? TinhThanh { get; set; }
        public string? MoTa { get; set; }
        public double KinhDo { get; set; }
        public double ViDo { get; set; }
        public string? HinhAnh { get; set; }
        public double? DanhGiaTrungBinh { get; set; }
        public List<CreateDiaDiemChiTietRequest>? ChiTiets { get; set; }
    }

    public class CreateDiaDiemChiTietRequest
    {
        public string? TenChiTiet { get; set; }
        public string? HinhAnh { get; set; }
    }
}
